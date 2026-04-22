import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class ContenidoAdminModel {
  final String id;
  final String tallerId;
  final String titulo;
  final String cuerpo;
  final String categoria;
  final String estado;
  final String? informeIa;
  final String? urlVideo;
  final String? urlImagen;

  ContenidoAdminModel({
    required this.id,
    required this.tallerId,
    required this.titulo,
    required this.cuerpo,
    required this.categoria,
    required this.estado,
    this.informeIa,
    this.urlVideo,
    this.urlImagen,
  });

  factory ContenidoAdminModel.fromJson(Map<String, dynamic> json) {
    return ContenidoAdminModel(
      id: json['id'].toString(),
      tallerId: json['taller_id'].toString(),
      titulo: json['titulo'],
      cuerpo: json['cuerpo'] ?? '',
      categoria: json['categoria'],
      estado: json['estado'],
      informeIa: json['informe_ia'],
      urlVideo: json['url_video'],
      urlImagen: json['url_imagen'],
    );
  }
}

class ContenidosAdminScreen extends StatefulWidget {
  const ContenidosAdminScreen({super.key});

  @override
  State<ContenidosAdminScreen> createState() =>
      _ContenidosAdminScreenState();
}

class _ContenidosAdminScreenState extends State<ContenidosAdminScreen> {
  bool _isLoading = false;
  List<ContenidoAdminModel> _todos = [];
  String _filtro = 'pendiente';

  List<ContenidoAdminModel> get _filtrados =>
      _todos.where((c) => c.estado == _filtro).toList();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await ApiService().dio.get('/admin/contenidos/todos');
      setState(() {
        _todos = (response.data as List)
            .map((e) => ContenidoAdminModel.fromJson(e))
            .toList();
      });
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar contenidos')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _aprobar(ContenidoAdminModel c) async {
    try {
      await ApiService().dio.patch('/admin/contenidos/${c.id}/aprobar');
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contenido aprobado y publicado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al aprobar')),
        );
      }
    }
  }

  Future<void> _rechazar(ContenidoAdminModel c) async {
    final controller = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rechazar contenido'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Motivo del rechazo...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true && controller.text.isNotEmpty) {
      try {
        await ApiService().dio.patch(
          '/admin/contenidos/${c.id}/rechazar',
          data: {'motivo': controller.text},
        );
        await _cargar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contenido rechazado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } on DioException catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al rechazar')),
          );
        }
      }
    }
  }

  Future<void> _eliminar(ContenidoAdminModel c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar contenido'),
        content: Text(
            '¿Seguro que quieres eliminar "${c.titulo}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ApiService().dio.delete('/admin/contenidos/${c.id}');
        await _cargar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contenido eliminado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on DioException catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar')),
          );
        }
      }
    }
  }

  void _verDetalle(ContenidoAdminModel c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  _EstadoChip(estado: c.estado),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(c.categoria,
                        style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                c.titulo,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                c.cuerpo,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    height: 1.6),
              ),
              if (c.urlVideo != null) ...[
                const SizedBox(height: 16),
                _BottomSheetMediaTile(
                  icon: Icons.play_circle,
                  iconColor: Colors.red,
                  label: 'Ver video',
                  url: c.urlVideo!,
                ),
              ],
              if (c.urlImagen != null) ...[
                const SizedBox(height: 8),
                _BottomSheetMediaTile(
                  icon: c.urlImagen!.toLowerCase().contains('pdf')
                      ? Icons.picture_as_pdf
                      : Icons.image,
                  iconColor: c.urlImagen!.toLowerCase().contains('pdf')
                      ? Colors.orange
                      : Colors.blue,
                  label: 'Ver archivo adjunto',
                  url: c.urlImagen!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contenidos educativos'),
        backgroundColor: const Color(0xFF7C3AED),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _FiltroChip(
                  label: 'Pendientes',
                  selected: _filtro == 'pendiente',
                  onTap: () => setState(() => _filtro = 'pendiente'),
                ),
                const SizedBox(width: 8),
                _FiltroChip(
                  label: 'Publicados',
                  selected: _filtro == 'publicado',
                  onTap: () => setState(() => _filtro = 'publicado'),
                ),
                const SizedBox(width: 8),
                _FiltroChip(
                  label: 'Rechazados',
                  selected: _filtro == 'rechazado',
                  onTap: () => setState(() => _filtro = 'rechazado'),
                ),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Sin contenido ${_filtro == 'pendiente' ? 'pendiente de revisión' : _filtro}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtrados.length,
                          itemBuilder: (context, index) {
                            final c = filtrados[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                onTap: () => _verDetalle(c),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF7C3AED)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(c.categoria,
                                                style: const TextStyle(
                                                    color: Color(0xFF7C3AED),
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          const Spacer(),
                                          const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 13,
                                              color:
                                                  AppTheme.textSecondary),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(c.titulo,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      if (c.informeIa != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue
                                                .withValues(alpha: 0.05),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.blue
                                                    .withValues(alpha: 0.2)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.smart_toy,
                                                  size: 14,
                                                  color: Colors.blue),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'IA: ${c.informeIa!}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.blue),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      if (_filtro == 'pendiente')
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    _rechazar(c),
                                                style:
                                                    OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.red,
                                                  side: const BorderSide(
                                                      color: Colors.red),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8)),
                                                ),
                                                child: const Text('Rechazar'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () => _aprobar(c),
                                                style:
                                                    ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(
                                                          0xFF15803D),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8)),
                                                ),
                                                child: const Text('Aprobar',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: () => _eliminar(c),
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red),
                                              tooltip: 'Eliminar',
                                            ),
                                          ],
                                        )
                                      else
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () => _eliminar(c),
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 18),
                                            label: const Text('Eliminar',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7C3AED)
              : const Color(0xFF7C3AED).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? Colors.white : const Color(0xFF7C3AED),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String estado;

  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = estado == 'publicado'
        ? Colors.green
        : estado == 'rechazado'
            ? Colors.red
            : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _BottomSheetMediaTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String url;

  const _BottomSheetMediaTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(url,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.open_in_new,
                size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
