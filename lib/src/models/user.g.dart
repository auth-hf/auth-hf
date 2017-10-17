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
  bool confirmed;

  @override
  bool alwaysTfa;

  @override
  List<int> apiKey;

  @override
  List<int> password;

  @override
  List<int> confirmationCode;

  @override
  List<Application> applications;

  @override
  int loginAttempts;

  @override
  int firstLogin;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  User(
      {this.id,
      this.email,
      this.salt,
      this.confirmed,
      this.alwaysTfa,
      this.apiKey,
      this.password,
      this.confirmationCode,
      this.applications,
      this.loginAttempts,
      this.firstLogin,
      this.createdAt,
      this.updatedAt});

  factory User.fromJson(Map data) {
    return new User(
        id: data['id'],
        email: data['email'],
        salt: data['salt'],
        confirmed: data['confirmed'],
        alwaysTfa: data['always_tfa'],
        apiKey: data['api_key'],
        password: data['password'],
        confirmationCode: data['confirmation_code'],
        applications: data['applications'] is List
            ? data['applications']
                .map((x) => x == null
                    ? null
                    : (x is Application ? x : new Application.fromJson(x)))
                .toList()
            : null,
        loginAttempts: data['login_attempts'],
        firstLogin: data['first_login'],
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
        'confirmed': confirmed,
        'always_tfa': alwaysTfa,
        'api_key': apiKey,
        'password': password,
        'confirmation_code': confirmationCode,
        'applications': applications,
        'login_attempts': loginAttempts,
        'first_login': firstLogin,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static User parse(Map map) => new User.fromJson(map);

  User clone() {
    return new User.fromJson(toJson());
  }
}
