class UserModel {
  int? id;
  String username;
  String email;
  String password;
  String tempUnit; // ★ tambahan
  String? photoPath;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.tempUnit, // ★ tambahan
    this.photoPath,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'], // sesuai DB kamu
      email: map['email'],
      password: map['password'],
      tempUnit: map['tempUnit'] ?? 'c', // ★ default jika null
      photoPath: map['photoPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'tempUnit': tempUnit, // ★ tambahan
      'photoPath': photoPath,
    };
  }
}
