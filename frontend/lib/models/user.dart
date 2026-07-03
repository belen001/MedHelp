/// Modelo de usuario (autenticación) alineado con la respuesta del backend
class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final String token; // JWT token para autorización

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.token,
  });

  /// Construye User a partir del objeto `user` del JSON del backend.
  /// El token se proporciona por separado (campo `token` en la respuesta raíz).
  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      token: token ?? (json['token'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'token': token,
    };
  }
}
