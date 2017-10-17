library auth_hf.src.models.user;

import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'application.dart';
part 'user.g.dart';

@serializable
class _User extends Model {
  String email, salt;
  bool confirmed, alwaysTfa;
  List<int> apiKey, password, confirmationCode;
  List<Application> applications;
  int loginAttempts, firstLogin;
}
