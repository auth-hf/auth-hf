import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:auth_hf/auth_hf.dart' as auth_hf;
import 'package:logging/logging.dart';
import 'package:pool/pool.dart';
import 'task.dart' as task;

const String host = '127.0.0.1';
const int port = 80;

main() async {
  var onDie = new ReceivePort()
    ..listen((_) {
      throw new StateError('An isolate died!');
    });

  var sessions = <String, Map>{};
  var sessionPools = <String, Pool>{};

  var sessionSync = new ReceivePort()
    ..listen((List packet) {
      String sessionId = packet[0];
      var arg = packet[1];

      if (arg is SendPort) {
        arg.send(sessions.putIfAbsent(sessionId, () => {}));
      } else if (arg is Map) {
        var pool = sessionPools.putIfAbsent(sessionId, () => new Pool(1));
        pool.withResource(() {
          sessions[sessionId] = arg;
        });
      }
    });

  for (int i = 0; i < Platform.numberOfProcessors; i++) {
    Isolate.spawn(startServer, [i + 1, sessionSync.sendPort]).then((isolate) {
      isolate.addOnExitListener(onDie.sendPort);
    });
  }

  task.main(true);
}

void startServer(List args) {
  new Future(() {
    int id = args[0];
    SendPort sessionSync = args[1];

    var rootUri = Platform.script.resolve('..');

    var ctx = new SecurityContext()
      ..useCertificateChain(rootUri.resolve('keys/server.pem').toString())
      ..usePrivateKey(rootUri.resolve('keys/key.pem').toString());
    var app = new Angel.custom(startSharedSecure(ctx))
      ..lazyParseBodies = true;

    String getSessionId(RequestContext req, ResponseContext res) {
      var cookie = req.cookies
          .firstWhere((c) => c.name == 'sync_sess', orElse: () => null);

      if (cookie == null) {
        cookie = new Cookie('sync_sess', req.session.id);
        res.cookies.add(cookie);
      }

      return cookie.value;
    }

    app.use((RequestContext req, ResponseContext res) {
      // Pull session changes
      var c = new Completer();
      var recv = new ReceivePort();

      recv.listen((Map session) {
        req.session.addAll(session);
        recv.close();
        c.complete(true);
      });

      sessionSync.send([getSessionId(req, res), recv.sendPort]);
      return c.future.timeout(
          const Duration(seconds: 10), onTimeout: () => true);
    });

    return app.configure(auth_hf.configureServer).then((_) async {
      app.responseFinalizers.add((req, res) async {
        // Push session changes
        sessionSync.send([
          getSessionId(req, res),
          new Map.from(req.session),
        ]);
      });

      app.logger = new Logger.detached('auth_hf')
        ..onRecord.listen((rec) {
          if (rec.error != null) {
            var sink =
            new File('server_log.txt').openWrite(mode: FileMode.APPEND);
            sink
              ..writeln(rec)..writeln(rec.error)..writeln(rec.stackTrace)
              ..close();
          }
        });

      var server = await app.startServer(host, port);
      print(
          'Server #$id istening at http://${server.address.address}:${server
              .port}');
    });
  }).catchError((e, st) {
    print(e);
    print(st);
    Isolate.current.kill();
  });
}
