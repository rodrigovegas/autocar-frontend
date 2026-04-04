class UsuarioModel {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final String token;

  UsuarioModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.token,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      nombre: json['nombre'],
      correo: json['correo'] ?? '',
      rol: json['rol'],
      token: json['token'],
    );
  }
}