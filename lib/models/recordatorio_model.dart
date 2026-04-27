class RecordatorioModel {
  final String id;
  final String vehiculoId;
  final String vehiculoMarca;
  final String vehiculoModelo;
  final String? vehiculoPlaca;
  final String tipoMantenimientoId;
  final String tipoMantenimientoNombre;
  final String origen;
  final DateTime? fechaProgramada;
  final int? kilometrajeProgramado;
  final String? textoPersonalizado;
  final String estado;
  final DateTime fechaCreacion;

  RecordatorioModel({
    required this.id,
    required this.vehiculoId,
    required this.vehiculoMarca,
    required this.vehiculoModelo,
    this.vehiculoPlaca,
    required this.tipoMantenimientoId,
    required this.tipoMantenimientoNombre,
    required this.origen,
    this.fechaProgramada,
    this.kilometrajeProgramado,
    this.textoPersonalizado,
    required this.estado,
    required this.fechaCreacion,
  });

  factory RecordatorioModel.fromJson(Map<String, dynamic> json) {
    return RecordatorioModel(
      id: json['id'],
      vehiculoId: json['vehiculo']['id'],
      vehiculoMarca: json['vehiculo']['marca'],
      vehiculoModelo: json['vehiculo']['modelo'],
      vehiculoPlaca: json['vehiculo']['placa'],
      tipoMantenimientoId: json['tipo_mantenimiento']['id'],
      tipoMantenimientoNombre: json['tipo_mantenimiento']['nombre'],
      origen: json['origen'],
      fechaProgramada: json['fecha_programada'] != null
          ? DateTime.parse(json['fecha_programada'])
          : null,
      kilometrajeProgramado: json['kilometraje_programado'],
      textoPersonalizado: json['texto_personalizado'],
      estado: json['estado'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }
}
