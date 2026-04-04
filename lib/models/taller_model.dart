class TallerModel {
  final String id;
  final String nombre;
  final String especialidad;
  final String direccionTexto;
  final String telefono;
  final double? latitud;
  final double? longitud;

  TallerModel({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.direccionTexto,
    required this.telefono,
    this.latitud,
    this.longitud,
  });

  factory TallerModel.fromJson(Map<String, dynamic> json) {
    return TallerModel(
      id: json['id'],
      nombre: json['nombre'],
      especialidad: json['especialidad'],
      direccionTexto: json['direccion_texto'],
      telefono: json['telefono'],
      latitud: json['latitud'] != null
          ? double.parse(json['latitud'].toString())
          : null,
      longitud: json['longitud'] != null
          ? double.parse(json['longitud'].toString())
          : null,
    );
  }
}