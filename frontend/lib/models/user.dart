/// Modelo de usuario (autenticación)
class User {
  final String id;
  final String email;
  final String fullName;
  final String? profileImageUrl;
  final String token; // JWT token para autorización

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.token,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      token: json['token'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'token': token,
      'profileImageUrl': profileImageUrl,
    };
  }
}
