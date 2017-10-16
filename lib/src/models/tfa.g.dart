// GENERATED CODE - DO NOT MODIFY BY HAND

part of auth_hf.src.models.tfa;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class Tfa extends _Tfa {
  @override
  String id;

  @override
  String userId;

  @override
  int lifeSpan;

  @override
  List<int> code;

  @override
  User user;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Tfa(
      {this.id,
      this.userId,
      this.lifeSpan,
      this.code,
      this.user,
      this.createdAt,
      this.updatedAt});

  factory Tfa.fromJson(Map data) {
    return new Tfa(
        id: data['id'],
        userId: data['user_id'],
        lifeSpan: data['life_span'],
        code: data['code'],
        user: data['user'] == null
            ? null
            : (data['user'] is User
                ? data['user']
                : new User.fromJson(data['user'])),
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
        'life_span': lifeSpan,
        'code': code,
        'user': user,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Tfa parse(Map map) => new Tfa.fromJson(map);

  Tfa clone() {
    return new Tfa.fromJson(toJson());
  }
}
