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
  final String? especialidadNombre;
  final String direccionTexto;
  final String telefono;
  final double? latitud;
  final double? longitud;
  final List<ServicioTallerModel> servicios;
  final double? calificacionPromedio;
  final int? totalCalificaciones;

  TallerModel({
    required this.id,
    required this.nombre,
    this.especialidadNombre,
    required this.direccionTexto,
    required this.telefono,
    this.latitud,
    this.longitud,
    this.servicios = const [],
    this.calificacionPromedio,
    this.totalCalificaciones,
  });

  factory TallerModel.fromJson(Map<String, dynamic> json) {
    return TallerModel(
      id: json['id'],
      nombre: json['nombre'],
      especialidadNombre: json['especialidad_nombre'],
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
      calificacionPromedio: json['calificacion_promedio'] != null
          ? double.parse(json['calificacion_promedio'].toString())
          : null,
      totalCalificaciones: json['total_calificaciones'],
    );
  }
}