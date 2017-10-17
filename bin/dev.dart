import 'dart:isolate';
import 'package:angel_framework/angel_framework.dart';
import 'package:auth_hf/auth_hf.dart' as auth_hf;
import 'package:logging/logging.dart';
import 'task.dart' as task;

main() async {
  var app = new Angel()..lazyParseBodies = true;
  await app.configure(auth_hf.configureServer);

  app.logger = new Logger('auth_hf')
    ..onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) print(rec.error);
      if (rec.stackTrace != null) print(rec.stackTrace);
    });

  var server = await app.startServer('127.0.0.1', 3000);
  print('Listening at http://${server.address.address}:${server.port}');

  Isolate.spawn(task.main, false);
}