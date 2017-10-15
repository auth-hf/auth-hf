library auth_hf.src.models.auth_token;

import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'application.dart';
part 'auth_token.g.dart';

@serializable
class _AuthToken extends Model {
  String userId, applicationId, state, refreshToken;
  List<String> scopes;
  int lifeSpan;

  Application application;
}
