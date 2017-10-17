library auth_hf.src.services.trusted_device;

import 'package:angel_framework/angel_framework.dart';
import 'package:angel_mongo/angel_mongo.dart';
import 'package:mongo_dart/mongo_dart.dart';

AngelConfigurer configureServer(Db db) {
  return (Angel app) async {
    HookedService service =app.use('/api/trusted_devices',
        new MongoService(db.collection('trusted_devices')));
    app.inject('trustedDeviceService', service);
  };
}
