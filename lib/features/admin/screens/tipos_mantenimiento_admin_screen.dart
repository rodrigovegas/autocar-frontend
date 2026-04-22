import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';

class _Tipo {
  final String id;
  final String nombre;
  final String descripcionBase;
  final String estado;

  const _Tipo({
    required this.id,
    required this.nombre,
    required this.descripcionBase,
    required this.estado,
  });

  factory _Tipo.fromJson(Map<String, dynamic> j) => _Tipo(
        id: j['id'].toString(),
        nombre: j['nombre'],
        descripcionBase: j['descripcion_base'],
        estado: j['estado'],
      );
}

class TiposMantenimientoAdminScreen extends StatefulWidget {
  const TiposMantenimientoAdminScreen({super.key});

  @override
  State<TiposMantenimientoAdminScreen> createState() =>
      _TiposMantenimientoAdminScreenState();
}

class _TiposMantenimientoAdminScreenState
    extends State<TiposMantenimientoAdminScreen> {
  static const morado = Color(0xFF7C3AED);

  List<_Tipo> _todos = [];
  String _filtro = 'todos';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().dio.get('/admin/tipos-mantenimiento');
      setState(() {
        _todos = (res.data as List).map((e) => _Tipo.fromJson(e)).toList();
      });
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar tipos')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_Tipo> get _filtrados {
    if (_filtro == 'todos') return _todos;
    return _todos.where((t) => t.estado == _filtro).toList();
  }

  Future<void> _aprobar(_Tipo tipo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Color(0xFF15803D)),
          SizedBox(width: 8),
          Text('Aprobar tipo'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${tipo.nombre}"',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(tipo.descripcionBase,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Aprobar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService()
          .dio
          .patch('/admin/tipos-mantenimiento/${tipo.id}/aprobar');
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo aprobado — disponible para todos los talleres'),
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

  Future<void> _rechazar(_Tipo tipo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.cancel, color: Colors.red),
          SizedBox(width: 8),
          Text('Rechazar tipo'),
        ]),
        content: Text('¿Rechazar "${tipo.nombre}"?'),
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
    if (ok != true) return;
    try {
      await ApiService()
          .dio
          .patch('/admin/tipos-mantenimiento/${tipo.id}/rechazar');
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo rechazado'),
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

  void _abrirCrear() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Crear tipo de mantenimiento',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'El tipo quedará aprobado automáticamente y '
                'disponible para todos los talleres.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              const Text('Nombre *',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ej: Cambio de aceite',
                  hintStyle:
                      TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Descripción *',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Describe en qué consiste',
                  hintStyle:
                      TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nombreCtrl.text.trim().isEmpty ||
                        descCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Completa todos los campos')),
                      );
                      return;
                    }
                    try {
                      await ApiService().dio.post(
                        '/admin/tipos-mantenimiento',
                        data: {
                          'nombre': nombreCtrl.text.trim(),
                          'descripcion_base': descCtrl.text.trim(),
                        },
                      );
                      await _cargar();
                      if (mounted) Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tipo creado y aprobado'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } on DioException catch (e) {
                      if (mounted) {
                        final msg =
                            e.response?.data?['detail'] ?? 'Error al crear';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(msg),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: morado,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Crear tipo',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = _filtrados;
    final pendientes = _todos.where((t) => t.estado == 'pendiente').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Tipos de mantenimiento'),
        backgroundColor: morado,
      ),
      body: Column(
        children: [
          // ── Chips de filtro ───────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _FiltroChip(
                  label: 'Todos',
                  activo: _filtro == 'todos',
                  onTap: () => setState(() => _filtro = 'todos'),
                ),
                _FiltroChip(
                  label: 'Aprobados',
                  activo: _filtro == 'aprobado',
                  color: Colors.green,
                  onTap: () => setState(() => _filtro = 'aprobado'),
                ),
                _FiltroChipBadge(
                  label: 'Pendientes',
                  badge: pendientes,
                  activo: _filtro == 'pendiente',
                  color: Colors.orange,
                  onTap: () => setState(() => _filtro = 'pendiente'),
                ),
                _FiltroChip(
                  label: 'Rechazados',
                  activo: _filtro == 'rechazado',
                  color: Colors.red,
                  onTap: () => setState(() => _filtro = 'rechazado'),
                ),
              ]),
            ),
          ),
          const Divider(height: 1),

          // ── Lista ─────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : lista.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.build_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              _filtro == 'todos'
                                  ? 'No hay tipos de mantenimiento'
                                  : 'No hay tipos en esta categoría',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: lista.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final t = lista[i];
                            Color estadoColor;
                            switch (t.estado) {
                              case 'aprobado':
                                estadoColor = Colors.green;
                                break;
                              case 'pendiente':
                                estadoColor = Colors.orange;
                                break;
                              default:
                                estadoColor = Colors.red;
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(t.nombre,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: estadoColor
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: estadoColor
                                                .withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        t.estado.toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: estadoColor),
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(t.descripcionBase,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600)),
                                  if (t.estado == 'pendiente') ...[
                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _aprobar(t),
                                          icon: const Icon(Icons.check,
                                              color: Colors.white, size: 16),
                                          label: const Text('Aprobar',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF15803D),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _rechazar(t),
                                          icon: const Icon(Icons.close,
                                              size: 16),
                                          label: const Text('Rechazar'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(
                                                color: Colors.red),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                    ]),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrear,
        backgroundColor: morado,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Crear tipo',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CHIPS DE FILTRO
// ─────────────────────────────────────────────

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final Color color;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.activo,
    this.color = const Color(0xFF7C3AED),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: activo ? color : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  activo ? FontWeight.w600 : FontWeight.normal,
              color: activo ? Colors.white : Colors.grey.shade600,
            )),
      ),
    );
  }
}

class _FiltroChipBadge extends StatelessWidget {
  final String label;
  final int badge;
  final bool activo;
  final Color color;
  final VoidCallback onTap;

  const _FiltroChipBadge({
    required this.label,
    required this.badge,
    required this.activo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: activo ? color : Colors.grey.shade300),
        ),
        child: Row(children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    activo ? FontWeight.w600 : FontWeight.normal,
                color: activo ? Colors.white : Colors.grey.shade600,
              )),
          if (badge > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: activo ? Colors.white : color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$badge',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: activo ? color : Colors.white)),
            ),
          ],
        ]),
      ),
    );
  }
}