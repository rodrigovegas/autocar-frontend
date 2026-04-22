
class ServicioReservaModel {
  final String id;
  final String nombre;

  ServicioReservaModel({required this.id, required this.nombre});

  factory ServicioReservaModel.fromJson(Map<String, dynamic> json) {
    return ServicioReservaModel(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}

class ReservaModel {
  final String id;
  final String tallerNombre;
  final String vehiculo;
  final String fecha;
  final String horaInicio;
  final String estado;
  final List<ServicioReservaModel> servicios;
  final String? motivoRechazo;
  final String? descripcionOtro;
  final String fechaCreacion;
  final int? calificacion;
  final String? comentarioCalificacion;

  ReservaModel({
    required this.id,
    required this.tallerNombre,
    required this.vehiculo,
    required this.fecha,
    required this.horaInicio,
    required this.estado,
    required this.servicios,
    this.motivoRechazo,
    this.descripcionOtro,
    required this.fechaCreacion,
    this.calificacion,
    this.comentarioCalificacion,
  });

  factory ReservaModel.fromJson(Map<String, dynamic> json) {
    return ReservaModel(
      id: json['id'],
      tallerNombre: json['taller_nombre'],
      vehiculo: json['vehiculo'],
      fecha: json['fecha'],
      horaInicio: json['hora_inicio'],
      estado: json['estado'],
      servicios: (json['servicios'] as List)
          .map((s) => ServicioReservaModel.fromJson(s))
          .toList(),
      motivoRechazo: json['motivo_rechazo'],
      descripcionOtro: json['descripcion_otro'],
      fechaCreacion: json['fecha_creacion'],
      calificacion: json['calificacion'],
      comentarioCalificacion: json['comentario_calificacion'],
    );
  }
}

class DisponibilidadModel {
  final String id;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final int cuposDisponibles;

  DisponibilidadModel({
    required this.id,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.cuposDisponibles,
  });

  factory DisponibilidadModel.fromJson(Map<String, dynamic> json) {
    return DisponibilidadModel(
      id: json['id'],
      fecha: json['fecha'],
      horaInicio: json['hora_inicio'],
      horaFin: json['hora_fin'],
      cuposDisponibles: json['cupos_disponibles'],
    );
  }

  String get etiqueta {
    try {
      final fechaObj = DateTime.parse(fecha);
      final fechaFormateada =
          '${fechaObj.day.toString().padLeft(2, '0')}/${fechaObj.month.toString().padLeft(2, '0')}/${fechaObj.year}';
      return '$fechaFormateada — ${horaInicio.substring(0, 5)} a ${horaFin.substring(0, 5)}';
    } catch (_) {
      return '$fecha $horaInicio';
    }
  }
}