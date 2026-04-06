class MantenimientoModel {
  final int id;
  final String vehiculoId;
  final String tipoMantenimientoId;
  final String fecha;
  final int? kilometraje;
  final double? costo;
  final String? descripcion;
  final String? tallerNombre;

  MantenimientoModel({
    required this.id,
    required this.vehiculoId,
    required this.tipoMantenimientoId,
    required this.fecha,
    this.kilometraje,
    this.costo,
    this.descripcion,
    this.tallerNombre,
  });

  factory MantenimientoModel.fromJson(Map<String, dynamic> json) {
    return MantenimientoModel(
      id: json['id'],
      vehiculoId: json['vehiculo_id'],
      tipoMantenimientoId: json['tipo_mantenimiento_id'].toString(),
      fecha: json['fecha'],
      kilometraje: json['kilometraje'],
      costo: json['costo'] != null ? (json['costo'] as num).toDouble() : null,
      descripcion: json['descripcion'],
      tallerNombre: json['taller_nombre'],
    );
  }
}

class TipoMantenimientoModel {
  final String id;
  final String nombre;
  final String? descripcion;
  final int? intervaloKm;
  final int? intervaloDias;

  TipoMantenimientoModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.intervaloKm,
    this.intervaloDias,
  });

  factory TipoMantenimientoModel.fromJson(Map<String, dynamic> json) {
    return TipoMantenimientoModel(
      id: json['id'].toString(),
      nombre: json['nombre'],
      descripcion: json['descripcion_base'],
      intervaloKm: json['intervalo_km'],
      intervaloDias: json['intervalo_dias'],
    );
  }
}