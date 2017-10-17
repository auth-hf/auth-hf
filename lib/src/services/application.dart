library auth_hf.src.services.application;

import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:mongo_dart/mongo_dart.dart';

AngelConfigurer configureServer(Db db) {
  return (Angel app) async {
    HookedService service = app.use(
      '/api/applications',
      new MongoService(db.collection('applications')),
    );

    app.inject('applicationService', service);

    service.beforeRemoved.listen((e) async {
      // Delete all related auth codes + tokens
      await Future.wait(['api/auth_codes', 'api/auth_tokens'].map((path) async {
        var service = app.service(path);
        var matching = await service.index({
          'query': {
            'application_id': e.id,
          },
        });
        return await Future.wait(matching.map((Map m) {
          return service.remove(m['id']);
        }));
      }));
    });
  };
}
