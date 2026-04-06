class ServicioTallerModel {
  final String id;
  final String nombre;
  final String? descripcion;
  final int? tiempoEstimadoMinutos;
  final double? precio;

  ServicioTallerModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.tiempoEstimadoMinutos,
    this.precio,
  });

  factory ServicioTallerModel.fromJson(Map<String, dynamic> json) {
    return ServicioTallerModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      tiempoEstimadoMinutos: json['tiempo_estimado_minutos'],
      precio: json['precio'] != null
          ? double.parse(json['precio'].toString())
          : null,
    );
  }
}

class TallerModel {
  final String id;
  final String nombre;
  final String especialidad;
  final String direccionTexto;
  final String telefono;
  final double? latitud;
  final double? longitud;
  final List<ServicioTallerModel> servicios;

  TallerModel({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.direccionTexto,
    required this.telefono,
    this.latitud,
    this.longitud,
    this.servicios = const [],
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
      servicios: json['servicios'] != null
          ? (json['servicios'] as List)
              .map((s) => ServicioTallerModel.fromJson(s))
              .toList()
          : [],
    );
  }
}