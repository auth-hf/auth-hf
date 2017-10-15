import 'dart:async';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_oauth2/angel_oauth2.dart' as auth;
import 'package:angel_validate/angel_validate.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'models/models.dart';
import 'account_settings.dart' as account_settings;
import 'auth.dart' as auth;
import 'scopes.dart' as access_scopes;

Future configureServer(Angel app) async {
  app.group('/oauth2', (router) {
    var oauth2 = new _OAuth2(app);
    router.post('/token', oauth2.tokenEndpoint);
    router.chain(auth.filter)
      ..get('/authorize', oauth2.authorizationEndpoint)
      ..post('/authorize', oauth2.handleFormSubmission);
  });

  var client = new http.Client();
  var rgxBasic = new RegExp(r'[Bb]earer ([^$]+)$');
  var leadingSlashes = new RegExp(r'^/+');
  var callValidator = new Validator({
    'endpoint*': isNonEmptyString,
    'query': isString,
  });

  app.post('/api/call', (@Header('Authorization') String authHeader,
      Service authTokenService,
      Service userService,
      RequestContext req,
      ResponseContext res) async {
    var m = rgxBasic.firstMatch(authHeader);
    if (m == null)
      throw new AngelHttpException.badRequest(
          message: 'Malformed Authorizaton header.');

    var tokenId = m[1];
    AuthToken token;

    try {
      token = await authTokenService.read(tokenId).then(AuthToken.parse);
    } catch (e, st) {
      throw new AngelHttpException.badRequest(
          message: 'Invalid authorization token.')
        ..error = e
        ..stackTrace = st;
    }

    var validation = callValidator.check(await req.lazyBody());

    var expirationDate =
        token.createdAt.add(new Duration(milliseconds: token.lifeSpan));
    var now = new DateTime.now().toUtc();

    if (now.isAfter(expirationDate))
      throw new AngelHttpException.notAuthenticated(
          message: 'This authorization token is expired.');

    var endpoint = validation.data['endpoint'];

    // Check if the auth token permits this scope...
    var scopes = _OAuth2.findScopes(token.scopes);
    var requestedScope = access_scopes.all
        .firstWhere((a) => a.stub == endpoint, orElse: () => null);

    if (requestedScope == null)
      throw new AngelHttpException.badRequest(
          message: 'Invalid endpoint "$endpoint".');

    if (!scopes.contains(requestedScope))
      throw new AngelHttpException.forbidden(
          message: 'The user has not granted you access to this endpoint.');

    endpoint = endpoint.replaceAll(leadingSlashes, '');
    var uri = Uri.parse('https://hackforums.net/api/v1/$endpoint');

    if (validation.data['query'] != null)
      uri = uri.replace(query: validation.data['query']);

    // Resolve API key...
    var user = await userService.read(token.userId).then(User.parse);
    var aes = account_settings.createAesEngine(
        user.salt, app.configuration['jwt_secret'], false);
    var apiKey = account_settings.decryptApiKey(aes, user.apiKey);
    var headers = {
      'Authorization': 'Basic ' + BASE64URL.encode('$apiKey:'.codeUnits),
    };

    print('Outgoing headers: $headers');
    print('Proxying $uri');

    var rq = new http.Request('GET', uri)..headers.addAll(headers);
    var response = await client.send(rq);

    print('Status: ${response.statusCode}');
    print('Incoming headers: ${response.headers}');

    res
      ..statusCode = response.statusCode
      ..headers.addAll(response.headers)
      ..headers.remove('content-encoding')
      ..headers.remove('content-length');

    await response.stream.pipe(res);
  });

  app.shutdownHooks.add((_) async {
    client.close();
  });
}

class _OAuth2 extends auth.Server<Application, User> {
  final Angel app;

  _OAuth2(this.app);

  Service get applicationService => app.service('api/applications');

  Service get authCodeService => app.service('api/auth_codes');

  Service get authTokenService => app.service('api/auth_tokens');

  @override
  Future<Application> findClient(String clientId) async {
    Iterable<Application> applications = await applicationService.index({
      'query': {
        'public_key': clientId,
      }
    }).then((it) => it.map(Application.parse));

    return applications.isEmpty ? null : applications.first;
  }

  static List<access_scopes.AccessScope> findScopes(Iterable<String> scopes) {
    scopes ??= [];
    return scopes
        .map((s) => access_scopes.all
            .firstWhere((a) => a.stub == s, orElse: () => null))
        .where((a) => a != null)
        .toList();
  }

  @override
  Future<bool> verifyClient(Application client, String clientSecret) async {
    return client.secretKey == clientSecret;
  }

  @override
  Future<String> authCodeGrant(Application client, String redirectUri,
      User user, Iterable<String> scopes, String state) {
    throw new UnsupportedError('Nope');
  }

  @override
  Future authorize(
      Application client,
      String redirectUri,
      Iterable<String> scopes,
      String state,
      RequestContext req,
      ResponseContext res) async {
    var accessScopes = findScopes(scopes);

    if (accessScopes.isEmpty) {
      throw new AngelHttpException.badRequest(
          message: 'You must request at least one access scope.');
    }

    var user = req.grab<User>(User);
    var code = new AuthCode(
      userId: user.id,
      applicationId: client.id,
      redirectUri: redirectUri,
      state: state,
      scopes: accessScopes.map((a) => a.stub).toList(),
    );

    // Create an authorization code. The user must sign in to confirm this code.
    //
    // Otherwise, it is deleted.
    code = await authCodeService.create(code.toJson()).then(AuthCode.parse);
    await res.render('authorize', {
      'title': 'Authorize ${client.name}',
      'app': client,
      'code': code,
      'scopes': accessScopes,
      'user': user,
    });
  }

  final Validator formValidator = new Validator({
    'confirm*': isNonEmptyString,
    'mode*': [
      isNonEmptyString,
      isIn(['accept', 'deny'])
    ],
    'scopes*': [
      isList,
      isNotEmpty,
      everyElement(allOf(
        isNonEmptyString,
        predicate(
          (String s) => access_scopes.all.any((sc) => sc.stub == s),
          'is a valid access scope',
        ),
      )),
    ]
  });

  @override
  Future handleFormSubmission(RequestContext req, ResponseContext res) async {
    print(await req.lazyBody());
    var validation = formValidator.check(await req.lazyBody());

    // Send them right back on an error...
    if (validation.errors.isNotEmpty) {
      print(validation.errors);
      return res.redirect(req.headers.value('referer') ?? req.uri.toString());
    }

    String codeId = validation.data['confirm'], mode = validation.data['mode'];
    var code = await authCodeService.read(codeId).then(AuthCode.parse);
    var redirectUri = Uri.parse(code.redirectUri);
    var user = req.grab<User>(User);

    if (user.id != code.userId)
      throw new AngelHttpException.forbidden(
          message: 'That authorization code does not belong to you.');

    var grantedScopes = validation.data['scopes'] as List<String>;
    Map queryParameters =
        new Map<String, String>.from(redirectUri.queryParameters);

    if (grantedScopes.isEmpty) {
      await authCodeService.remove(codeId);
      queryParameters.addAll({
        'error': 'access_denied',
        'error_description':
            'The user did not grant access to any of the requested access scopes.',
        'state': code.state ?? '',
      });
    } else if (mode == 'deny') {
      await authCodeService.remove(codeId);
      queryParameters.addAll({
        'error': 'access_denied',
        'error_description': 'The user refused to grant access.',
        'state': code.state ?? '',
      });
    } else {
      // Change the scopes to whatever the user has granted.
      code.scopes = grantedScopes;
      await authCodeService.modify(codeId, code.toJson());
      queryParameters.addAll({
        'code': code.id,
        'state': code.state ?? '',
      });
    }

    redirectUri = redirectUri.replace(queryParameters: queryParameters);
    return res.redirect(redirectUri.toString());
  }

  @override
  Future<auth.AuthorizationCodeResponse> exchangeAuthCodeForAccessToken(
      String authCode,
      String redirectUri,
      RequestContext req,
      ResponseContext res) async {
    var code = await authCodeService.read(authCode).then(AuthCode.parse);
    var uuid = req.grab<Uuid>(Uuid);

    await authCodeService.remove(authCode);

    // Create a relevant auth token...
    var token = new AuthToken(
      userId: code.userId,
      applicationId: code.applicationId,
      refreshToken: uuid.v4(),
      lifeSpan: const Duration(hours: 24).inMilliseconds,
      state: code.state,
      scopes: code.scopes,
    );
    token = await authTokenService.create(token.toJson()).then(AuthToken.parse);
    return new auth.AuthorizationCodeResponse(token.id,
        refreshToken: token.refreshToken);
  }
}
