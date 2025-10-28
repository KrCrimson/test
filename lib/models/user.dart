class User {
  final String rango;
  final String? nombre;
  final String? token;

  User({required this.rango, this.nombre, this.token});

  factory User.fromJson(Map<String, dynamic> json) {
    // El backend puede devolver 'name' o 'nombre'
    final nombre = (json['nombre'] ?? json['name']) != null ? (json['nombre'] ?? json['name']) as String : null;
    return User(
      rango: json['rango'] ?? json['role'] ?? '',
      nombre: nombre,
      token: json['token'] != null ? json['token'] as String : null,
    );
  }
}
