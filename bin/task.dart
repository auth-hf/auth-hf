import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:angel_task/angel_task.dart';
import 'package:auth_hf/auth_hf.dart' as auth_hf;
import 'package:logging/logging.dart';
import 'package:mongo_dart/mongo_dart.dart';

main(bool logToFile) {
  var app = new Angel();

  app.logger = new Logger('auth_hf.task')
    ..onRecord.listen((rec) {
      if (rec.error != null) {
        IOSink sink = logToFile
            ? new File('task_log.txt').openWrite(mode: FileMode.APPEND)
            : stderr;
        sink
          ..writeln(rec)
          ..writeln(rec.error)
          ..writeln(rec.stackTrace)
          ..close();
      } else if (!logToFile) {
        print(rec);
      }
    });

  app.configure(auth_hf.configureServer).then((_) {
    var scheduler = new AngelTaskScheduler(app);
    var logger = app.logger;

    scheduler.hours(12, () async {
      logger.info('Sweeping...');

      await Future
          .wait(['api/tfas', 'api/auth_codes', 'api/users'].map((path) async {
        var service = app.service(path) as HookedService;
        logger.info('Sweeping $path...');

        var yesterday =
            new DateTime.now().toUtc().subtract(const Duration(days: 1));

        var outdated = await service.index();

        outdated = outdated.where((Map m) {
          var createdAt = DateTime.parse(m['created_at']);
          var dueForDeletion = createdAt.isBefore(yesterday);

          if (path != 'api/users') return dueForDeletion;
          return dueForDeletion && m['confirmed'] != true;
        });

        if (outdated.isEmpty) {
          logger.info('$path is clean');
        } else {
          return Future.wait(outdated.map((Map m) {
            return service.remove(m['id']);
          })).then((done) {
            logger.info('Cleaned ${done.length} from $path');
          });
        }
      }))
          .catchError((e, st) {
        logger.severe('sweep failure', e, st);
      });
    }, name: 'sweep');

    scheduler.start();
    scheduler.run('sweep');
  });
}
