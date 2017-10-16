library auth_hf.src.models.tfa;

import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'user.dart';
part 'tfa.g.dart';

@serializable
class _Tfa extends Model {
  String userId;
  int lifeSpan;
  List<int> code;
  User user;

  bool get expired {
    var now = new DateTime.now().toUtc();
    var expiry = createdAt.add(new Duration(milliseconds: lifeSpan));
    return now.isAfter(expiry);
  }
}
