import 'package:angel_framework/angel_framework.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'application.dart' as applications;
import 'auth_code.dart' as auth_code;
import 'auth_token.dart' as auth_token;
import 'user.dart' as user;

AngelConfigurer configureServer(Db db) {
  return (Angel app) async {
    await app.configure(user.configureServer(db));
    await app.configure(applications.configureServer(db));
    await app.configure(auth_code.configureServer(db));
    await app.configure(auth_token.configureServer(db));
  };
}