library auth_hf.src.models.user;

import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'user.g.dart';

@serializable
class _User extends Model {
  String email, salt, password, apiKey;
  bool confirmed;
}
