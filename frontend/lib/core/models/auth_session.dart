class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.username,
    required this.role,
    required this.roleName,
  });

  final String token;
  final int userId;
  final String username;
  final String role;
  final String roleName;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      userId: json['user_id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      roleName: json['role_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user_id': userId,
      'username': username,
      'role': role,
      'role_name': roleName,
    };
  }
}
