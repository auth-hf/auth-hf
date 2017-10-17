import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/hooks.dart' as hooks;
import 'package:mongo_dart/mongo_dart.dart';
import 'application.dart' as applications;
import 'auth_code.dart' as auth_code;
import 'auth_token.dart' as auth_token;
import 'login_history.dart' as login_history;
import 'tfa.dart' as tfa;
import 'trusted_device.dart' as trusted_device;
import 'user.dart' as user;

AngelConfigurer configureServer(Db db) {
  return (Angel app) async {
    var sub = app.onService.listen((service) {
      if (service is HookedService) {
        // Lock down all services
        service.beforeAll(hooks.disable());
        service.beforeCreated.listen(hooks.addCreatedAt(key: 'created_at'));
        service.beforeModify(hooks.addUpdatedAt(key: 'updated_at'));
      }
    });

    app.shutdownHooks.add((_) async {
      sub.cancel();
    });

    await app.configure(user.configureServer(db));
    await app.configure(applications.configureServer(db));
    await app.configure(auth_code.configureServer(db));
    await app.configure(auth_token.configureServer(db));
    await app.configure(login_history.configureServer(db));
    await app.configure(tfa.configureServer(db));
    await app.configure(trusted_device.configureServer(db));
  };
}
