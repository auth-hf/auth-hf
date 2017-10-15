import 'dart:convert';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_auth_oauth2/angel_auth_oauth2.dart';
import 'package:angel_configuration/angel_configuration.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:auth_hf/src/models/models.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';
import 'package:mongo_dart/mongo_dart.dart';

main() async {
  var app = new Angel()..lazyParseBodies = true;
  app.logger = new Logger('example')
    ..onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) print(rec.error);
      if (rec.stackTrace != null) print(rec.stackTrace);
    });
  await app.configure(configuration(const LocalFileSystem()));

  var auth = new AngelAuth<Map>();
  auth.serializer = (m) => JSON.encode(m);
  auth.deserializer = (s) => JSON.decode(s);

  // Find an application
  var db = new Db(app.configuration['mongo_db']);
  await db.open();

  var apps = await db.collection('applications').find().toList();

  if (apps.isEmpty)
    throw new StateError('No applications available. Register at least one to run the example client.');

  var application = Application.parse(apps.first);

  var strategy =
      new OAuth2Strategy('hf', new AngelAuthOAuth2Options(
        key: application.publicKey,
        secret: application.secretKey,
        authorizationEndpoint: 'http://localhost:3000/oauth2/authorize',
        tokenEndpoint: 'http://localhost:3000/oauth2/token',
        callback: 'http://localhost:8080/auth/hf/callback'
      ), (client) async {
    // Fetch current user
    var response = await client.post(
      'http://localhost:3000/api/call',
      headers: {
        'content-type': 'application/json',
      },
      body: JSON.encode({
        'endpoint': '/user',
      }),
    );

    print('Body: ${response.body}');
    var user = JSON.decode(response.body);
    print('User: $user');
    return user;
  });

  auth.strategies.add(strategy);

  app.get('/auth/hf', auth.authenticate('hf'));

  app.get('/auth/hf/callback', auth.authenticate('hf', new AngelAuthOptions(tokenCallback: (req, res, jwt, user) {
    return user;
  })));

  var server = await app.startServer('127.0.0.1', 8080);
  print('Example flow: http://${server.address.address}:${server.port}/auth/hf');
}
