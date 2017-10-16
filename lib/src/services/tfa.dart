library auth_hf.src.services.tfa;

import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/hooks.dart' as hooks;
import 'package:angel_mongo/angel_mongo.dart';
import 'package:mongo_dart/mongo_dart.dart';

AngelConfigurer configureServer(Db db) {
  return (Angel app) async {
    HookedService service =
        app.use('/api/tfas', new MongoService(db.collection('tfas')));
    app.inject('tfaService', service);

    service.beforeAll(hooks.disable());
    service.beforeCreated.listen(hooks.chainListeners([
      hooks.addCreatedAt(key: 'created_at'),
      hooks.transform(
        (Map m) =>
            m..['life_span'] = const Duration(minutes: 10).inMilliseconds,
      )
    ]));
    service.afterAll(hooks.transform((Map token) async {
      Map user;

      try {
        user = await app.service('api/users').read(token['user_id']);
      } catch (_) {
        // Ignore
      }

      return token..['user'] = user;
    }));
  };
}
