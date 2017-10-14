import 'dart:async';
import 'package:angel_configuration/angel_configuration.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_jael/angel_jael.dart';
import 'package:angel_static/angel_static.dart';
import 'package:file/local.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:uuid/uuid.dart';
import 'src/services/services.dart' as services;
import 'src/auth.dart' as auth;

Future configureServer(Angel app) async {
  // Config
  const fs = const LocalFileSystem();
  await app.configure(configuration(fs));
  await app.configure(jael(fs.directory('views')));

  // DI
  app.container.singleton(new Uuid());

  // Routing
  var db = new Db(app.configuration['mongo_db']);
  await db.open();

  await app.configure(services.configureServer(db));
  await app.configure(auth.configureServer);

  var webRoot = null;//fs.directory('web');
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
      'status_code': e.statusCode,
      'error': e.message ?? e.toString(),
    });
  };
}
