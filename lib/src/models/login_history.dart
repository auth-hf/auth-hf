library auth_hf.src.models.login_history;

import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'login_history.g.dart';

@serializable
class _LoginHistory extends Model {
  String ip;
  int successes, failures;

  bool get isAttacker {
    successes ??= 0;
    failures ??= 0;
    var total = successes + failures;

    if (total < 10)
      return false;

    return (successes / failures) < 0.1;
  }
}
