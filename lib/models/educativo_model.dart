class ContenidoEducativoModel {
  final String id;
  final String tallerId;
  final String titulo;
  final String cuerpo;
  final String categoria;
  final String? urlImagen;
  final String? urlVideo;
  final String estado;
  final String? informeIa;
  final String? motivoRechazo;
  final String fechaPublicacion;

  ContenidoEducativoModel({
    required this.id,
    required this.tallerId,
    required this.titulo,
    required this.cuerpo,
    required this.categoria,
    this.urlImagen,
    this.urlVideo,
    required this.estado,
    this.informeIa,
    this.motivoRechazo,
    required this.fechaPublicacion,
  });

  factory ContenidoEducativoModel.fromJson(Map<String, dynamic> json) {
    return ContenidoEducativoModel(
      id: json['id'].toString(),
      tallerId: json['taller_id'].toString(),
      titulo: json['titulo'],
      cuerpo: json['cuerpo'],
      categoria: json['categoria'],
      urlImagen: json['url_imagen'],
      urlVideo: json['url_video'],
      estado: json['estado'],
      informeIa: json['informe_ia'],
      motivoRechazo: json['motivo_rechazo'],
      fechaPublicacion: json['fecha_publicacion'],
    );
  }
}