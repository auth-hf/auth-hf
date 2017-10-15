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
              publicKey: uuid.v4(),
              secretKey: uuid.v4())
          .toJson());
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
      'tokens': tokens,
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
      } catch(_) {
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
