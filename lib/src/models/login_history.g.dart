// GENERATED CODE - DO NOT MODIFY BY HAND

part of auth_hf.src.models.login_history;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class LoginHistory extends _LoginHistory {
  @override
  String id;

  @override
  String ip;

  @override
  int successes;

  @override
  int failures;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  LoginHistory(
      {this.id,
      this.ip,
      this.successes,
      this.failures,
      this.createdAt,
      this.updatedAt});

  factory LoginHistory.fromJson(Map data) {
    return new LoginHistory(
        id: data['id'],
        ip: data['ip'],
        successes: data['successes'],
        failures: data['failures'],
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
        'ip': ip,
        'successes': successes,
        'failures': failures,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static LoginHistory parse(Map map) => new LoginHistory.fromJson(map);

  LoginHistory clone() {
    return new LoginHistory.fromJson(toJson());
  }
}
