import 'dart:async';
import 'package:angel_configuration/angel_configuration.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_jael/angel_jael.dart';
import 'package:angel_oauth2/angel_oauth2.dart';
import 'package:angel_static/angel_static.dart';
import 'package:code_buffer/code_buffer.dart';
import 'package:file/local.dart';
import 'package:mailer/mailer.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';
import 'src/models/models.dart';
import 'src/services/services.dart' as services;
import 'src/auth.dart' as auth;
import 'src/account_settings.dart' as account_settings;
import 'src/oauth2.dart' as oauth2;

Future configureServer(Angel app) async {
  // Config
  const fs = const LocalFileSystem();
  await app.configure(configuration(fs));
  await app.configure(jael(fs.directory('views'), createBuffer: () {
    // Minified HTML
    return new CodeBuffer(
      newline: '',
      space: '',
    );
  }));

  // Temp fix for AdSense
  var renderer = app.viewGenerator;

  app.viewGenerator = (path, [locals]) {
    return renderer(
        path,
        new Map.from(locals ?? {})
          ..['gad'] = '''
    <script async src="//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"></script>
    <script>
        (adsbygoogle = window.adsbygoogle || []).push({
            google_ad_client: "ca-pub-2116133816688639",
            enable_page_level_ads: true
        });
    </script>'''
              .trim());
  };

  // DI
  Map mailConfig = app.configuration['mail'];
  app.inject('baseUrl', Uri.parse(app.configuration['base_url']));
  app.container.singleton(new Uuid());
  app.container.singleton(
    new SmtpTransport(new SmtpOptions()
      ..requiresAuthentication = mailConfig['secure'] == 'true'
      ..secured = mailConfig['secure'] == 'true'
      ..hostName = mailConfig['host']
      ..port = int.parse(mailConfig['port'] ?? '465')
      ..username = mailConfig['username']
      ..password = mailConfig['password']),
  );

  // Routing
  var db = new Db(app.configuration['mongo_db']);
  await db.open();

  // Blacklist potential attackers
  app.use((RequestContext req, ResponseContext res) async {
    var loginHistory = await auth.resolveOrCreateLoginHistory(req.ip, app);

    if (!loginHistory.isAttacker ||
        req.path.endsWith('.js') ||
        req.path.endsWith('.woff2') ||
        req.path.endsWith('.woff') ||
        req.path.endsWith('.ttf') ||
        req.path.endsWith('.svg') ||
        req.path.endsWith('.map') ||
        req.path.endsWith('.css')) return true;

    // B-B-B-B-B-B-B-BAN HAMMER
    throw new AngelHttpException.forbidden(
      message:
          'You have been identified as a potential abuser, and have been banned from this service.',
    );
  });

  app.use(auth.parse);

  app.get('/', (RequestContext req, ResponseContext res) {
    return res.render('index', {
      'title': 'Home',
      'user': req.injections[User],
    });
  });

  await app.configure(services.configureServer(db));
  await app.configure(auth.configureServer);
  await app.configure(account_settings.configureServer);
  await app.configure(oauth2.configureServer);

  var webRoot = fs.directory('web');

  if (!app.isProduction) {
    var vDir = new VirtualDirectory(app, fs, source: webRoot);
    app.use(vDir.handleRequest);
  }

  app.use((RequestContext req) {
    throw new AngelHttpException.notFound(
      message: 'No file exists at path "${req.uri}".',
    );
  });

  var oldHandler = app.errorHandler;

  app.errorHandler = (e, req, res) {
    if (e.statusCode == 500) {
      print(e.error ?? e);
      print(e.stackTrace);
    }

    if (e is AuthorizationException) return e.toJson();

    if (req.path.endsWith('.js') || req.path.endsWith('.css'))
      return oldHandler(e, req, res);

    var errorMessage = e.error?.toString() ?? e.message ?? e.toString();

    if (app.isProduction) errorMessage = 'Hang in there. We\'re working on it.';

    return res.render('error', {
      'title': 'Error ${e.statusCode}',
      'user': req.injections[User],
      'status_code': e.statusCode,
      'error': errorMessage,
    });
  };
}
