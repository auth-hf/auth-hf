import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/hooks.dart' as hooks;
import 'package:mongo_dart/mongo_dart.dart';
import 'application.dart' as applications;
import 'auth_code.dart' as auth_code;
import 'auth_token.dart' as auth_token;
import 'tfa.dart' as tfa;
import 'user.dart' as user;

AngelConfigurer configureServer(Db db) {
  return (Angel app) async {
    var sub = app.onService.listen((service) {
      if (service is HookedService) {
        // Lock down all services
        service.beforeAll(hooks.disable());
      }
    });

    app.shutdownHooks.add((_) async {
      sub.cancel();
    });

    await app.configure(user.configureServer(db));
    await app.configure(applications.configureServer(db));
    await app.configure(auth_code.configureServer(db));
    await app.configure(auth_token.configureServer(db));
    await app.configure(tfa.configureServer(db));
  };
}