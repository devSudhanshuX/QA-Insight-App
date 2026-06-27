class UserModel {
  const UserModel({required this.email, this.name});

  final String email;
  final String? name;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] as String,
      name: json['name'] as String?,
    );
  }
}
