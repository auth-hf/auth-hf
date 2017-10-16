import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_test/angel_test.dart';
import 'package:auth_hf/src/models/models.dart';
import 'package:auth_hf/src/account_settings.dart';
import 'package:auth_hf/src/auth.dart';
import 'package:auth_hf/auth_hf.dart' as auth_hf;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:uuid/uuid.dart';
import 'package:test/test.dart';

main() {
  Logger.root.onRecord.listen((rec) {
    print(rec);
    if (rec.error != null) {
      print(rec.error);
      print(rec.stackTrace);
    }
  });

  Application application;
  User user;
  String authCode, authToken;
  Angel app;
  Uri authorizationEndpoint, loginEndpoint, tokenEndpoint;
  var uuid = new Uuid();

  tearDownAll(() => exit(0));

  setUp(() async {
    app = new Angel()
      ..lazyParseBodies = true
      ..logger = new Logger('auth_hf');
    await app.configure(auth_hf.configureServer);

    var oldHandler = app.errorHandler;
    app.errorHandler = (e, req, res) {
      print(e.error ?? e);
      print(e.stackTrace);
      return oldHandler(e, req, res);
    };

    // A bunch of work to create a mock user... :)
    var salt = 'bae', pepper = app.configuration['jwt_secret'];
    var aes = createAesEngine(salt, pepper, true);

    try {
      user = await app
          .service('api/users')
          .create(new User(
                  email: 'a@b.c',
                  salt: salt,
                  password: pepperedHash('123', salt, pepper),
                  apiKey:
                      encryptApiKey(aes, 'abcdefghijklmnpqrstuvwxyz0123456'))
              .toJson())
          .then(User.parse);
    } on AngelHttpException catch (e, st) {
      print(e.error);
      print(st);
      rethrow;
    }

    application = await app
        .service('api/applications')
        .create(new Application(
                userId: user.id,
                name: 'Foo',
                description: 'Bar',
                publicKey: uuid.v4(),
                secretKey: uuid.v4())
            .toJson())
        .then(Application.parse);

    var server = await app.startServer();
    var url = 'http://${server.address.address}:${server.port}';
    authorizationEndpoint = Uri.parse('$url/oauth2/authorize');
    loginEndpoint = Uri.parse('$url/login');
    tokenEndpoint = Uri.parse('$url/oauth2/token');
  });

  tearDown(() async {
    if (authToken != null)
      await app.service('api/auth_tokens').remove(authToken);
    if (authCode != null) await app.service('api/auth_codes').remove(authCode);
    if (application != null)
      await app.service('api/applications').remove(application.id);
    if (user != null) await app.service('api/users').remove(user.id);
    await app.close();
  });

  Future<String> getAuthenticatedCookie() async {
    var client = new HttpClient();
    var rq = await client.openUrl('POST', loginEndpoint);
    rq
      ..headers.contentType = ContentType.JSON
      ..write(JSON.encode({
        'email': user.email,
        'password': '123',
      }));
    var rs = await rq.close();
    expect(rs.statusCode, 302);
    await client.close(force: true);
    return rs.cookies.firstWhere((c) => c.name == 'DARTSESSID').value;
  }

  group('flow', () {
    Angel childApp;
    oauth2.AuthorizationCodeGrant grant;
    Uri redirect;
    http.Client client;

    setUp(() async {
      client = new http.Client();
      grant = new oauth2.AuthorizationCodeGrant(
          application.publicKey, authorizationEndpoint, tokenEndpoint,
          secret: application.secretKey, httpClient: client);

      childApp = new Angel()
        ..lazyParseBodies = true
        ..logger = new Logger('child_app');

      childApp.get('/auth/hf/callback', (RequestContext req) {
        print(req.query);
      });

      var childServer = await childApp.startServer();
      var base = Uri.parse(
          'http://${childServer.address.address}:${childServer.port}/auth/hf/callback');
      redirect = grant.getAuthorizationUrl(base, scopes: const [
        '/user',
        '/user/:id',
        '/inbox',
      ]);
    });

    tearDown(() async {
      await childApp.close();
      grant.close();
      client.close();
    });

    test('403 if not logged in', () async {
      var response = await client.get(redirect);
      print('Response: ${response.body}');

      expect(response, hasStatus(403));
    });

    test('renders html if logged in', () async {
      var cookie = await getAuthenticatedCookie();
      var response =
          await client.get(redirect, headers: {'cookie': 'DARTSESSID=$cookie'});
      print('Response: ${response.body}');

      expect(response, hasStatus(200));
    });

    test('deny authorization', () async {
      var cookie = await getAuthenticatedCookie();
      var response =
          await client.get(redirect, headers: {'cookie': 'DARTSESSID=$cookie'});
      print('Response: ${response.body}');

      var doc = html.parse(response.body);
      var $input = doc.querySelector('input[name="confirm"]');

      authCode = $input.attributes['value'];

      response = await client.post(
        authorizationEndpoint,
        headers: {
          'cookie': 'DARTSESSID=$cookie',
        },
        body: {
          'mode': 'deny',
          'confirm': authCode,
        },
      );

      var location = Uri.parse(response.headers['location']);
      expect(location.queryParameters.keys,
          allOf(contains('error'), contains('error_description')));
      expect(location.queryParameters['error'], 'access_denied');
      authCode = null;
    });

    test('accept authorization', () async {
      var cookie = await getAuthenticatedCookie();
      var response =
          await client.get(redirect, headers: {'cookie': 'DARTSESSID=$cookie'});
      print('Response: ${response.body}');

      var doc = html.parse(response.body);
      var $input = doc.querySelector('input[name="confirm"]');

      authCode = $input.attributes['value'];

      var authed = await grant.handleAuthorizationCode(authCode);
      authCode = null;
      print(authToken = authed.credentials.accessToken);
    });
  });
}
