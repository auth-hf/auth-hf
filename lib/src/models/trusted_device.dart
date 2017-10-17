library auth_hf.src.models.trusted_device;

import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'trusted_device.g.dart';

@serializable
class _TrustedDevice extends Model {
  String userId, ip, userAgent;
}
