import 'dart:async';
import 'dart:typed_data';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/api.dart';
import 'models/models.dart';
import 'auth.dart' as auth;
import 'package:uuid/uuid.dart';

AESFastEngine createAesEngine(String salt, String pepper, bool forEncryption) {
  var str = '$salt:$pepper';
  var key = new List<int>.from(str.codeUnits);

  if (key.length > 32)
    key.length = 32;
  else if (key.length < 32) {
    var len = key.length;
    var remaining = 32 - len;
    key.length = 32;

    for (int i = 0; i < remaining; i++) {
      int ch;

      if (i < str.length) {
        ch = str[i].codeUnitAt(0);
      } else {
        var j = i;

        while (j >= str.length) j -= str.length;
        ch = str[j].codeUnitAt(0);
      }

      key[len + i] = ch;
    }
  }

  //print('key(${key.length}): $key');

  return new AESFastEngine()
    ..init(forEncryption, new KeyParameter(new Uint8List.fromList(key)));
}

List<int> encryptApiKey(AESFastEngine aes, String apiKey) {
  // API key is 32 characters... Encrypt both
  var a =
      aes.process(new Uint8List.fromList(apiKey.substring(0, 16).codeUnits));
  var b = aes.process(new Uint8List.fromList(apiKey.substring(16).codeUnits));
  return []..addAll(a)..addAll(b);
}

String decryptApiKey(AESFastEngine aes, List<int> apiKey) {
  // Decrypt both sets of 16
  var a = aes.process(new Uint8List.fromList(apiKey.take(16).toList()));
  var b = aes.process(new Uint8List.fromList(apiKey.skip(16).toList()));
  return new String.fromCharCodes(a) + new String.fromCharCodes(b);
}

Future configureServer(Angel app) async {
  var jwtSecret = app.configuration['jwt_secret'];
  var router = app.chain(auth.filter);

  router.get('/applications', (User user, ResponseContext res) {
    return res.render('applications', {
      'title': 'Applications (${user.applications.length})',
      'user': user,
    });
  });

  var applicationValidator = new Validator({
    'name*,description*': isNonEmptyString,
    'redirect_uris': isString,
  });

  router.post('/applications', (User user, Service applicationService,
      Uuid uuid, RequestContext req, res) async {
    var validation = applicationValidator.check(await req.lazyBody());

    if (user.apiKey != null && validation.errors.isEmpty) {
      String name = validation.data['name'],
          description = validation.data['description'];
      await applicationService.create(new Application(
              userId: user.id,
              name: name,
              description: description,
              redirectUris: validation.data['redirect_uris'] ?? '',
              publicKey: uuid.v4(),
              secretKey: uuid.v4())
          .toJson());
    }

    res.redirect('/applications');
  });

  Future<bool> resolveApplication(String id, User user,
      Service applicationService, RequestContext req) async {
    var application = await applicationService.read(id).then(Application.parse);

    if (application.userId != user.id) {
      throw new AngelHttpException.forbidden(
          message: 'That is not your application.');
    }

    req.inject(Application, application);
    return true;
  }

  var modifyApplicationValidator = applicationValidator.extend({
    'csrf_token*': isNonEmptyString,
    'mode*': isIn(['edit', 'delete']),
  });

  router.chain(resolveApplication)
    ..get('/applications/:id', (Application application, User user, Uuid uuid,
        RequestContext req, ResponseContext res) {
      req.session
        ..['csrf_token'] = uuid.v4()
        ..['csrf_expiry'] = new DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch;
      return res.render('application', {
        'title': application.name,
        'user': user,
        'app': application,
        'csrf_token': req.session['csrf_token'],
        'errors': [],
      });
    })
    ..post('/applications/:id', (Application application,
        Service applicationService,
        RequestContext req,
        ResponseContext res) async {
      var csrfToken = req.session.remove('csrf_token') as String;
      var csrfExpiry = req.session.remove('csrf_expiry') as int;

      if (csrfToken != null && csrfExpiry != null) {
        var validation = modifyApplicationValidator.check(await req.lazyBody());

        if (validation.errors.isEmpty) {
          if (validation.data['csrf_token'] == csrfToken) {
            var now = new DateTime.now().toUtc();
            var expiry = new DateTime.fromMillisecondsSinceEpoch(csrfExpiry);

            if (now.isBefore(expiry)) {
              if (validation.data['mode'] == 'edit') {
                application
                  ..name = validation.data['name']
                  ..description = validation.data['description']
                  ..redirectUris = validation.data['redirect_uris'];
                var modified = await applicationService.modify(
                    application.id, application.toJson());
                print('Modified: $modified');
              } else if (validation.data['mode'] == 'delete') {
                var deleted =
                    await await applicationService.remove(application.id);
                print('Deleted: $deleted');
              }
            } else {
              print('CSRF expired: $expiry');
            }
          } else {
            print(
                'CSRF mismatch: ${validation.data['csrf_token']} != $csrfToken');
          }
        } else {
          print('Validation errors: ${validation.errors}');
        }
      } else {
        print('No CSRF token or expiry');
      }

      res.redirect('/applications');
    });

  router.get('/settings',
      (User user, Service authTokenService, ResponseContext res) async {
    // Fetch all auth tokens
    Iterable<AuthToken> tokens = await authTokenService.index({
      'query': {
        'user_id': user.id,
      },
    }).then((it) => it.map(AuthToken.parse));

    await res.render('settings', {
      'title': 'Account Settings',
      'user': user,
      'tokens': tokens.where((t) => !t.expired),
    });
  });

  var apiKeyValidator = new Validator({
    'api_key*': isNonEmptyString,
  });

  router.post('/settings',
      (User user, Service userService, RequestContext req, res) async {
    var validation = apiKeyValidator.check(await req.lazyBody());

    if (validation.errors.isEmpty) {
      String apiKey = validation.data['api_key'];
      print('Plain API key: $apiKey');
      var aes = createAesEngine(user.salt, jwtSecret, true);
      user.apiKey = encryptApiKey(aes, apiKey);
      print('Encrypted API key: ${user.apiKey}');
      await userService.modify(user.id, user.toJson());
    }

    res.redirect('/settings');
  });

  router.post('/settings/tfa',
      (User user, Service userService, RequestContext req, res) async {
    if (user.alwaysTfa != true) {
      user.alwaysTfa = true;
      await userService.modify(user.id, user.toJson());
    }

    res.redirect('/settings');
  });

  var revokeValidator = new Validator({
    'token*': isNonEmptyString,
  });

  router.post('/settings/revoke',
      (User user, Service authTokenService, RequestContext req, res) async {
    var validation = revokeValidator.check(await req.lazyBody());

    if (validation.errors.isNotEmpty) {
      throw new AngelHttpException.badRequest();
    } else {
      AuthToken token;

      try {
        token = await authTokenService
            .read(validation.data['token'])
            .then(AuthToken.parse);
      } catch (_) {
        // Ignore
      }

      if (token?.userId != user.id) {
        // If we throw a different error, then it is obvious that this
        // auth token exists... Which is a security risk.
        //
        // So, any error at this endpoint produces the same output.
        throw new AngelHttpException.badRequest();
      } else {
        await authTokenService.remove(token.id);
      }
    }

    res.redirect('/settings');
  });
}
