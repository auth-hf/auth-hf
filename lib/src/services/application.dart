library auth_hf.src.services.application;

import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:mongo_dart/mongo_dart.dart';

AngelConfigurer configureServer(Db db) {
  return (Angel app) async {
    HookedService service = app.use(
        '/api/applications', new MongoService(db.collection('applications')),);

    app.inject('applicationService', service);
  };
}
