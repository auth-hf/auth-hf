// GENERATED CODE - DO NOT MODIFY BY HAND

part of auth_hf.src.models.user;

// **************************************************************************
// Generator: JsonModelGenerator
// **************************************************************************

class User extends _User {
  @override
  String id;

  @override
  String email;

  @override
  String salt;

  @override
  String password;

  @override
  String apiKey;

  @override
  bool confirmed;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  User(
      {this.id,
      this.email,
      this.salt,
      this.password,
      this.apiKey,
      this.confirmed,
      this.createdAt,
      this.updatedAt});

  factory User.fromJson(Map data) {
    return new User(
        id: data['id'],
        email: data['email'],
        salt: data['salt'],
        password: data['password'],
        apiKey: data['api_key'],
        confirmed: data['confirmed'],
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
        'email': email,
        'salt': salt,
        'password': password,
        'api_key': apiKey,
        'confirmed': confirmed,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static User parse(Map map) => new User.fromJson(map);

  User clone() {
    return new User.fromJson(toJson());
  }
}
