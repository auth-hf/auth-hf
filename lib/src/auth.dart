import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'models/models.dart';

String pepperedHash(String plain, String salt, String pepper) {
  return new String.fromCharCodes(sha256.convert('$pepper:$plain:$salt'.codeUnits).bytes);
}

Future<bool> filter(
    Service userService, RequestContext req, ResponseContext res) async {
  if (!req.session.containsKey('user_id')) {
    res.statusCode = 403;
    await res.render('error', {
      'title': 'Authentication Required',
      'error': 'You must log in to view this content.',
    });
    return false;
  }

  req.inject(
    User,
    await userService.read(req.session['user_id']).then(User.parse),
  );
  return true;
}

Future configureServer(Angel app) async {
  String jwtSecret = app.configuration['jwt_secret'];

  app.get('/login', (res) {
    res.render('login', {'title': 'Log In', 'errors': []});
  });

  var loginValidator = new Validator({
    'email*': [isNonEmptyString, isEmail],
    'password*': isNonEmptyString,
  });

  app.post('/login', (
    @Query('ref', required: false) String ref,
    Service userService,
    RequestContext req,
    ResponseContext res,
  ) async {
    var validation = loginValidator.check(await req.lazyBody());

    if (validation.errors.isNotEmpty) {
      return await res.render('login', {
        'title': 'Login Error',
        'errors': validation.errors,
      });
    } else {
      String email = validation.data['email'].toLowerCase(),
          password = validation.data['password'];

      Iterable<User> existing = await userService.index({
        'query': {'email': email}
      }).then((it) => it.map(User.parse));

      if (existing.isEmpty) {
        return await res.render('login', {
          'title': 'Login Error',
          'errors': [
            'No user exists with that e-mail address.',
          ],
        });
      }

      var user = existing.first;
      var hash = pepperedHash(password, user.salt, jwtSecret);

      if (hash != user.password) {
        return await res.render('login', {
          'title': 'Login Error',
          'errors': [
            'Invalid password.',
          ],
        });
      }

      req.session['user_id'] = user.id;
      var redirect = req.session.remove('auth_redirect');
      res.redirect(redirect ?? '/dashboard');
    }
  });

  app.get('/signup', (res) {
    return res.render('signup', {'title': 'Sign Up', 'errors': []});
  });

  var signupValidator = loginValidator.extend({
    'confirm_password*': isNonEmptyString,
  });

  app.post('/signup', (
    Service userService,
    Uuid uuid,
    RequestContext req,
    ResponseContext res,
  ) async {
    var validation = signupValidator.check(await req.lazyBody());

    if (validation.errors.isNotEmpty) {
      return await res.render('signup', {
        'title': 'Signup Error',
        'errors': validation.errors,
      });
    } else if (validation.data['confirm_password'] !=
        validation.data['password']) {
      return await res.render('signup', {
        'title': 'Signup Error',
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
          'errors': [
            'An account is already registered with that e-mail address.',
          ],
        });
      }

      var salt = uuid.v4();
      await userService.create(new User(
              email: email,
              salt: salt,
              password: pepperedHash(password, salt, jwtSecret),
              confirmed: false)
          .toJson());
      res.redirect('/login?ref=signup');
    }
  });
}
