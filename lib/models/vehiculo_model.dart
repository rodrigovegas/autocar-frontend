class VehiculoModel {
  final String id;
  final String marca;
  final String modelo;
  final int anio;
  final int kilometrajeActual;
  final String? placa;
  final String? color;
  final String? tipoCombustible;
  final bool activo;

  VehiculoModel({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.kilometrajeActual,
    this.placa,
    this.color,
    this.tipoCombustible,
    required this.activo,
  });

  factory VehiculoModel.fromJson(Map<String, dynamic> json) {
    return VehiculoModel(
      id: json['id'],
      marca: json['marca'],
      modelo: json['modelo'],
      anio: json['anio'],
      kilometrajeActual: json['kilometraje_actual'],
      placa: json['placa'],
      color: json['color'],
      tipoCombustible: json['tipo_combustible'],
      activo: json['activo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'marca': marca,
      'modelo': modelo,
      'anio': anio,
      'kilometraje_actual': kilometrajeActual,
      if (placa != null) 'placa': placa,
      if (color != null) 'color': color,
      if (tipoCombustible != null) 'tipo_combustible': tipoCombustible,
    };
  }
}