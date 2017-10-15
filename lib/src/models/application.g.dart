// GENERATED CODE - DO NOT MODIFY BY HAND

part of auth_hf.src.models.application;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class Application extends _Application {
  @override
  String id;

  @override
  String userId;

  @override
  String name;

  @override
  String description;

  @override
  String publicKey;

  @override
  String secretKey;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Application(
      {this.id,
      this.userId,
      this.name,
      this.description,
      this.publicKey,
      this.secretKey,
      this.createdAt,
      this.updatedAt});

  factory Application.fromJson(Map data) {
    return new Application(
        id: data['id'],
        userId: data['user_id'],
        name: data['name'],
        description: data['description'],
        publicKey: data['public_key'],
        secretKey: data['secret_key'],
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
        'name': name,
        'description': description,
        'public_key': publicKey,
        'secret_key': secretKey,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Application parse(Map map) => new Application.fromJson(map);

  Application clone() {
    return new Application.fromJson(toJson());
  }
}
