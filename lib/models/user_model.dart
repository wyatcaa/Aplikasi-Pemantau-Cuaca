class UserModel {
  final int? id;
  final String username;
  final String email;
  final String password;

  UserModel({this.id, required this.username, required this.email, required this.password});

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> m) {
    return UserModel(
      id: m['id'] as int?,
      username: m['username'] as String? ?? '',
      email: m['email'] as String? ?? '',
      password: m['password'] as String? ?? '',
    );
  }
}