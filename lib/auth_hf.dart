import 'dart:async';
import 'package:angel_configuration/angel_configuration.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_jael/angel_jael.dart';
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

  // DI
  Map mailConfig = app.configuration['mail'];
  app.inject('baseUrl', Uri.parse(app.configuration['base_url']));
  app.container.singleton(new Uuid());
  app.container.singleton(
    new SmtpTransport(new SmtpOptions()
      ..requiresAuthentication = mailConfig['secure'] == 'true'
      ..secured = mailConfig['secure'] == 'true'
      ..hostName = mailConfig['host']
      ..port = int.parse(mailConfig['port'])
      ..username = mailConfig['username']
      ..password = mailConfig['password']),
  );

  if (!app.isProduction) {
    printDebugInformation();
  }

  // Routing
  var db = new Db(app.configuration['mongo_db']);
  await db.open();

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
  VirtualDirectory vDir;

  if (app.isProduction) {
    vDir = new CachingVirtualDirectory(app, fs, source: webRoot);
  } else {
    vDir = new VirtualDirectory(app, fs, source: webRoot);
  }

  app.use(vDir.handleRequest);

  app.use((RequestContext req) {
    throw new AngelHttpException.notFound(
      message: 'No file exists at path "${req.uri}".',
    );
  });

  var oldHandler = app.errorHandler;

  app.errorHandler = (e, req, res) {
    if (req.path.endsWith('.js') || req.path.endsWith('.css'))
      return oldHandler(e, req, res);
    return res.render('error', {
      'title': 'Error ${e.statusCode}',
      'user': req.injections[User],
      'status_code': e.statusCode,
      'error': e.message ?? e.toString(),
    });
  };
}
