library auth_hf.src.services.user;

import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:angel_relations/angel_relations.dart' as relations;
import 'package:mongo_dart/mongo_dart.dart';

AngelConfigurer configureServer(Db db) {
  return (Angel app) async {
    HookedService service =
        app.use('/api/users', new MongoService(db.collection('users')));
    app.inject('userService', service);

    service.afterAll(
      relations.hasMany(
        'api/applications',
        as: 'applications',
        foreignKey: 'user_id',
      ),
    );
  };
}
