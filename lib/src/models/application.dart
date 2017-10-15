library auth_hf.src.models.application;

import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'application.g.dart';

@serializable
class _Application extends Model {
  String userId, name, description, publicKey, secretKey;
}
