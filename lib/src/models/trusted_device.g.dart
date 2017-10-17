// GENERATED CODE - DO NOT MODIFY BY HAND

part of auth_hf.src.models.trusted_device;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class TrustedDevice extends _TrustedDevice {
  @override
  String id;

  @override
  String userId;

  @override
  String ip;

  @override
  String userAgent;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  TrustedDevice(
      {this.id,
      this.userId,
      this.ip,
      this.userAgent,
      this.createdAt,
      this.updatedAt});

  factory TrustedDevice.fromJson(Map data) {
    return new TrustedDevice(
        id: data['id'],
        userId: data['user_id'],
        ip: data['ip'],
        userAgent: data['user_agent'],
        createdAt: data['created_at'] is DateTime
            ? data['created_at']
            : (data['created_at'] is String
                ? DateTime.parse(data['created_at'])
                : null),
        updatedAt: data['updated_at'] is DateTime
            ? data['updated_at']
            : (data['updated_at'] is String
                ? DateTime.parse(data['updated_at'])
                : null));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'ip': ip,
        'user_agent': userAgent,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static TrustedDevice parse(Map map) => new TrustedDevice.fromJson(map);

  TrustedDevice clone() {
    return new TrustedDevice.fromJson(toJson());
  }
}
