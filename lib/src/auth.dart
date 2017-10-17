import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:mailer/mailer.dart';
import 'package:uuid/uuid.dart';
import 'models/models.dart';

List<int> pepperedHash(String plain, String salt, String pepper) {
  return sha256.convert('$pepper:$plain:$salt'.codeUnits).bytes;
}

Hmac createHmac(String salt, String pepper) {
  return new Hmac(sha256, '$salt:$pepper'.codeUnits);
}

Future<bool> parse(Service userService, RequestContext req) async {
  if (req.session.containsKey('user_id')) {
    req.inject(
      User,
      await userService.read(req.session['user_id']).then(User.parse),
    );
  }

  return true;
}

Future<bool> filter(
    Service userService, RequestContext req, ResponseContext res) async {
  if (!req.injections.containsKey(User)) {
    req.session['auth_redirect'] = req.uri.toString();
    res.statusCode = 403;
    await res.render('login', {
      'title': 'Authentication Required',
      'user': req.injections[User],
      'errors': [
        'You must log in to view this content.',
      ],
    });
    return false;
  } else {
    var user = req.injections[User] as User;

    if (!user.confirmed) {
      await res.render('confirm', {
        'title': 'Confirm your Account',
        'user': user,
      });
      return false;
    }
  }

  return true;
}

Future<LoginHistory> resolveOrCreateLoginHistory(String ip, Angel app) async {
  var service = app.service('api/login_histories');
  var histories = await service.index({
    'query': {
      'ip': ip,
    },
  });

  if (histories.isNotEmpty) return LoginHistory.parse(histories.first);

  return await service
      .create(new LoginHistory(ip: ip, successes: 0, failures: 0).toJson())
      .then(LoginHistory.parse);
}

Future sendConfirmationEmail(String confirmationCode, String to, String from,
    Uri baseUrl, SmtpTransport transport) {
  var envelope = new Envelope()
    ..from = from
    ..fromName = 'Auth HF'
    ..subject = 'Confirm your Auth HF account'
    ..recipients.add(to);

  var confirmationUrl = baseUrl.resolve('login');

  envelope.html = '''
  <h1>${envelope.subject}</h1>
  <p>
    You received this e-mail because your Auth HF is yet unconfirmed.
    <br>
    The following is your confirmation code: <b>$confirmationCode</b>.
    <br>
    Log in <a href="$confirmationUrl">here</a> to receive a prompt to confirm your account.
    <br>
    Can't see the link? $confirmationUrl
    <br>
    If you think you have received this e-mail in error, simply ignore it.
    The account will automatically be wiped within 24 hours.
  </p>
'''
      .trim();

  return transport.send(envelope);
}

Future configureServer(Angel app) async {
  String jwtSecret = app.configuration['jwt_secret'];

  var router = app.chain((RequestContext req, ResponseContext res) async {
    if (req.injections.containsKey(User)) {
      res.redirect('/settings');
      return false;
    }

    return true;
  });

  router.get('/login', (req, res) {
    return res.render('login',
        {'title': 'Log In', 'user': req.injections[User], 'errors': []});
  });

  var loginValidator = new Validator({
    'email*': [isNonEmptyString, isEmail],
    'password*': isNonEmptyString,
  });

  router.post('/login', (
    @Query('ref', required: false) String ref,
    Service tfaService,
    Service authTokenService,
    Service loginHistoryService,
    Service trustedDeviceService,
    Service userService,
    Uuid uuid,
    SmtpTransport transport,
    Uri baseUrl,
    RequestContext req,
    ResponseContext res,
  ) async {
    var validation = loginValidator.check(await req.lazyBody());

    if (validation.errors.isNotEmpty) {
      return await res.render('login', {
        'title': 'Login Error',
        'user': req.injections[User],
        'errors': validation.errors,
      });
    } else {
      String email = validation.data['email'].toLowerCase(),
          password = validation.data['password'];

      Iterable<User> existing = await userService.index({
        'query': {'email': email}
      }).then((it) => it.map(User.parse));

      if (existing.isEmpty) {
        var loginHistory = await resolveOrCreateLoginHistory(req.ip, app);
        loginHistory.failures ??= 0;
        loginHistory.failures++;
        await loginHistoryService.modify(
            loginHistory.id, loginHistory.toJson());

        return await res.render('login', {
          'title': 'Login Error',
          'user': req.injections[User],
          'errors': [
            'No user exists with that e-mail address.',
          ],
        });
      }

      var user = existing.first..applications = [];
      user.loginAttempts ??= 0;

      if (user.loginAttempts >= 5) {
        var now = new DateTime.now().toUtc();
        var firstLogin =
            new DateTime.fromMillisecondsSinceEpoch(user.firstLogin);
        var elapsed = now.difference(firstLogin);
        var unlocked = elapsed.inHours >= 1;

        if (unlocked) {
          user
            ..firstLogin = null
            ..loginAttempts = 0;
        } else {
          user.loginAttempts++;
        }

        await userService.modify(user.id, user.toJson());

        if (!unlocked) {
          var loginHistory = await resolveOrCreateLoginHistory(req.ip, app);
          loginHistory.failures ??= 0;
          loginHistory.failures++;
          await loginHistoryService.modify(
              loginHistory.id, loginHistory.toJson());

          print('Blocked! ${user.loginAttempts} attempts');
          res.statusCode = 403;
          return await res.render('login', {
            'title': 'Account Locked',
            'user': null,
            'errors': [
              'Your account has been temporarily locked due to excessive login attempts. '
                  'Try again within an hour. Further attempts may result in you being banned as a spammer.',
            ],
          });
        }
      }

      var hash = pepperedHash(password, user.salt, jwtSecret);

      if (!(const ListEquality<int>().equals(hash, user.password))) {
        // Update login attempts...
        user.loginAttempts ??= 0;

        if (user.firstLogin != null) {
          var now = new DateTime.now().toUtc();
          var firstLogin =
              new DateTime.fromMillisecondsSinceEpoch(user.firstLogin);
          var elapsed = now.difference(firstLogin);
          if (elapsed.inHours >= 1) user.firstLogin = null;
        }

        if (user.loginAttempts++ == 0 || user.firstLogin == null) {
          user.firstLogin = new DateTime.now().toUtc().millisecondsSinceEpoch;
        }

        if (user.loginAttempts == 5) {
          // Lock account down, and destroy all existing auth tokens
          var authTokens = await authTokenService.index({
            'query': {
              'user_id': user.id,
            },
          });
          await Future.wait(authTokens.map((Map token) {
            return authTokenService.remove(token['id']);
          }));

          var envelope = new Envelope()
            ..from = app.configuration['mail']['from']
            ..fromName = 'Auth HF 2FA'
            ..subject = 'Auth HF Locked for Security'
            ..recipients.add(user.email);

          envelope.html = '''
            <h1>${envelope.subject}</h1>
            Someone has attempted to log in to your Auth HF account several times within
            the past hour, providing invalid passwords each time.
            <br><br>
            To keep your account secure and prevent brute-forcing, we have locked your account from
            further login attempts. You have also been logged out of all third-party applications.
            <br><br>
            If you believe you have received this e-mail in error, send a response immediately.
            '''
              .trim();
          await transport.send(envelope).timeout(const Duration(minutes: 1));
        }

        await userService.modify(user.id, user.toJson());

        var loginHistory = await resolveOrCreateLoginHistory(req.ip, app);
        loginHistory.failures ??= 0;
        loginHistory.failures++;
        await loginHistoryService.modify(
            loginHistory.id, loginHistory.toJson());

        return await res.render('login', {
          'title': 'Login Error',
          'user': null,
          'errors': [
            'Invalid password.',
          ],
        });
      }

      bool suspicious = user.loginAttempts >= 3;

      if (!suspicious) {
        Iterable<TrustedDevice> trustedDevices =
            await trustedDeviceService.index({
          'query': {
            'user_id': user.id,
          },
        }).then((it) => it.map(TrustedDevice.parse));

        suspicious = !trustedDevices.any((d) => d.ip == req.ip);
      }

      user
        ..loginAttempts = 0
        ..firstLogin = null;
      await userService.modify(user.id, user.toJson());

      var loginHistory = await resolveOrCreateLoginHistory(req.ip, app);
      loginHistory.successes ??= 0;
      loginHistory.successes++;
      await loginHistoryService.modify(loginHistory.id, loginHistory.toJson());

      if (!suspicious && user.alwaysTfa != true) {
        req.session['user_id'] = user.id;
        var redirect = req.session.remove('auth_redirect');
        res.redirect(redirect ?? '/settings');
      } else {
        String code = uuid.v4();
        var hmac = createHmac(user.salt, jwtSecret);
        var tfa =
            new Tfa(userId: user.id, code: hmac.convert(code.codeUnits).bytes);
        tfa = await tfaService.create(tfa.toJson()).then(Tfa.parse);

        var envelope = new Envelope()
          ..from = app.configuration['mail']['from']
          ..fromName = 'Auth HF 2FA'
          ..recipients.add(user.email);
        print(transport.options.hostName);

        var url = baseUrl.resolve('2fa/${tfa.id}').toString();
        print(url);

        envelope.subject = 'Confirm Auth HF Login Attempt';

        if (suspicious) {
          envelope.html = '''
        <h1>${envelope.subject}</h1>
        <p>
          You received this e-mail because someone attempted to sign in to
          your Auth HF account under suspicious circumstances.
          <br><br>
          Either of the following occurred:
          <ul>
            <li>A new device accessed your account</li>
            <li>Someone has tried to sign in to your account many times within the past hour</li>
          </ul>
          <br><br>
          For your security, we have forced two-factor authentication. Your 2FA code is <b>$code</b>.
          <br><br>
          Enter your code <a href="$url">here</a> to confirm this login attempt.
          <br><br>
          If you can't see the link: $url
          <br><br>
          If you didn't attempt this login, then send a response to this e-mail
          immediately. We will change your password to a new one. The 2FA attempt
          will time out within <b>10 minutes</b>, and your account will be safe.
        </p>
        '''
              .trim();
        } else {
          envelope.html = '''
        <h1>${envelope.subject}</h1>
        <p>
          You received this e-mail because someone attempted to sign in to
          your Auth HF account, and you have configured your account to
          use two-factor authentication at all times.
          <br><br>
          Your 2FA code is <b>$code</b>.
          <br><br>
          Enter your code <a href="$url">here</a> to confirm this login attempt.
          <br><br>
          If you can't see the link: $url
          <br><br>
          If you didn't attempt this login, then send a response to this e-mail
          immediately. We will change your password to a new one. The 2FA attempt
          will time out within <b>10 minutes</b>, and your account will be safe.
        </p>
        '''
              .trim();
        }

        await transport.send(envelope).timeout(const Duration(minutes: 1));
        res.redirect('/2fa/${tfa.id}');
      }
    }
  });

  router.get('/signup', (req, res) {
    return res.render('signup',
        {'title': 'Sign Up', 'user': req.injections[User], 'errors': []});
  });

  var signupValidator = loginValidator.extend({
    'confirm_password*': isNonEmptyString,
  });

  router.post('/signup', (
    Service trustedDeviceService,
    Service userService,
    Uuid uuid,
    Uri baseUrl,
    SmtpTransport transport,
    RequestContext req,
    ResponseContext res,
  ) async {
    var validation = signupValidator.check(await req.lazyBody());

    if (validation.errors.isNotEmpty) {
      return await res.render('signup', {
        'title': 'Signup Error',
        'user': req.injections[User],
        'errors': validation.errors,
      });
    } else if (validation.data['confirm_password'] !=
        validation.data['password']) {
      return await res.render('signup', {
        'title': 'Signup Error',
        'user': req.injections[User],
        'errors': [
          'The two passwords do not match.',
        ],
      });
    } else {
      String email = validation.data['email'].toLowerCase(),
          password = validation.data['password'];
      Iterable existing = await userService.index({
        'query': {'email': email}
      });

      if (existing.isNotEmpty) {
        return await res.render('signup', {
          'title': 'Signup Error',
          'user': req.injections[User],
          'errors': [
            'An account is already registered with that e-mail address.',
          ],
        });
      }

      var salt = uuid.v4();
      var code = uuid.v4();
      var user = await userService
          .create(new User(
                  email: email,
                  salt: salt,
                  password: pepperedHash(password, salt, jwtSecret),
                  confirmationCode: pepperedHash(code, salt, jwtSecret),
                  confirmed: false)
              .toJson())
          .then(User.parse);

      // Trust this device
      await trustedDeviceService.create(new TrustedDevice(
              userId: user.id,
              ip: req.ip,
              userAgent: req.headers.value('user-agent') ??
                  'None, but this is the original registration point')
          .toJson());

      await sendConfirmationEmail(code, user.email,
              app.configuration['mail']['from'], baseUrl, transport)
          .timeout(const Duration(minutes: 1));

      res.redirect('/login?ref=signup');
    }
  });

  app.get('/signout', (RequestContext req, ResponseContext res) {
    req.session.remove('user_id');
    return res.redirect('/login');
  });

  var tfaValidator = new Validator({
    'code*': isNonEmptyString,
  });

  router.chain((String id, Service tfaService, RequestContext req,
      ResponseContext res) async {
    var tfa = await tfaService.read(id).then(Tfa.parse).catchError((_) => null);

    if (tfa == null || tfa.expired) {
      if (tfa != null) await tfaService.remove(tfa.id);

      return await res.render('login', {
        'title': '2FA Expired or Invalid',
        'user': null,
        'errors': [
          'Whoops! Your 2FA code is expired or invalid. You must sign in again.',
        ],
      });
    }

    req.inject(Tfa, tfa);
    return true;
  })
    ..get('/2fa/:id', (Tfa tfa, RequestContext req, ResponseContext res) {
      return res.render('2fa', {
        'title': 'Two-factor Authentication',
        'user': req.injections[User],
        'tfa': tfa,
      });
    })
    ..post('/2fa/:id', (Tfa tfa,
        SmtpTransport transport,
        Service trustedDeviceService,
        Service tfaService,
        Service userService,
        RequestContext req,
        ResponseContext res) async {
      var validation = tfaValidator.check(await req.lazyBody());

      if (validation.errors.isNotEmpty) {
        return res.redirect(req.headers.value('referer') ?? req.uri);
      }

      await tfaService.remove(tfa.id);
      String code = validation.data['code'];
      var hmac = createHmac(tfa.user.salt, jwtSecret);
      var hash = hmac.convert(code.codeUnits).bytes;

      if (!(const ListEquality().equals(hash, tfa.code))) {
        return await res.render('login', {
          'title': '2FA Failure',
          'user': null,
          'errors': [
            'Invalid 2FA code. You must log in again.',
          ],
        });
      }

      // Trust this device
      Iterable<TrustedDevice> trustedDevices =
          await trustedDeviceService.index({
        'query': {
          'user_id': tfa.user.id,
        },
      }).then((it) => it.map(TrustedDevice.parse));

      if (!trustedDevices.any((d) => d.ip == req.ip)) {
        var device = new TrustedDevice(
          userId: tfa.user.id,
          ip: req.ip,
          userAgent: req.headers.value('user-agent') ??
              'None provided; this may be a bot.',
        );
        await trustedDeviceService.create(device.toJson());

        var envelope = new Envelope()
          ..from = app.configuration['mail']['from']
          ..fromName = 'Auth HF Sentinel'
          ..subject =
              'You recently signed in to Auth HF from an unrecognized device.'
          ..recipients.add(tfa.user.email);

        envelope.html = '''
        <h1>${envelope.subject}</h1>
        <p>
          You received this e-mail because someone successfully signed in
          to your Auth HF account from a location you have not signed in from before.
          <br><br>
          The following device is now registered as trusted for your account:
          <ul>
            <li><b>IP Address: </b>${device.ip}</li>
            <li><b>User Agent: </b>${device.userAgent}</li>
          </ul>
          <br><br>
          If you didn't attempt this login, then send a response to this e-mail
          immediately.
          <br><br>
          To immediately lock your account for an hour, attempt to log into your
          account 5 times consecutively, using invalid passwords.
        </p>
        '''
            .trim();

        await transport.send(envelope).timeout(const Duration(minutes: 1));
      }

      req.session['user_id'] = tfa.user.id;
      var redirect = req.session.remove('auth_redirect');
      res.redirect(redirect ?? '/settings');
    });

  var confirmValidator = new Validator({
    'mode*': [
      isString,
      isIn(['reset', 'confirm']),
    ],
    'code': isNonEmptyString,
  });

  app.post('/confirm', (Uri baseUrl,
      Uuid uuid,
      SmtpTransport transport,
      Service loginHistoryService,
      Service userService,
      RequestContext req,
      ResponseContext res) async {
    if (!req.injections.containsKey(User)) return res.redirect('/login');

    var user = req.injections[User] as User;
    user.applications = null; // No headaches

    if (user.confirmed == true) return res.redirect('/settings');

    var validation = confirmValidator.check(await req.lazyBody());

    if (validation.errors.isNotEmpty) {
      return res.redirect('/login');
    }

    String mode = validation.data['mode'];
    var target = req.headers.value('referer') ?? '/settings';

    if (mode == 'reset') {
      var code = uuid.v4();
      user.confirmationCode = pepperedHash(code, user.salt, jwtSecret);
      await userService.modify(user.id, user.toJson());
      await sendConfirmationEmail(code, user.email,
              app.configuration['mail']['from'], baseUrl, transport)
          .timeout(const Duration(minutes: 1));
    } else if (mode == 'confirm') {
      if (!validation.data.containsKey('code')) return res.redirect('/login');

      String code = validation.data['code'];
      var hash = pepperedHash(code, user.salt, jwtSecret);

      if (!(const ListEquality().equals(hash, user.confirmationCode))) {
        var history = await resolveOrCreateLoginHistory(req.ip, app);
        history.failures ??= 0;
        history.failures++;
        await loginHistoryService.modify(history.id, history.toJson());
      } else {
        user
          ..confirmationCode = null
          ..confirmed = true;
        await userService.modify(user.id, user.toJson());
      }
    }

    res.redirect(target);
  });
}
