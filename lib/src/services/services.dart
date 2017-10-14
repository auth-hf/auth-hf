import 'package:angel_framework/angel_framework.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'user.dart' as user;

AngelConfigurer configureServer(Db db) {
  return (Angel app) async {
    await app.configure(user.configureServer(db));
  };
}