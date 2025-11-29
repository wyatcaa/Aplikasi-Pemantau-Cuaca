class UserModel {
  int? id;
  String username;
  String email;
  String password;
  String tempUnit; 
  String? photoPath;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.tempUnit, 
    this.photoPath,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
      tempUnit: map['tempUnit'] ?? 'c', 
      photoPath: map['photoPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'tempUnit': tempUnit, 
      'photoPath': photoPath,
    };
  }
}
