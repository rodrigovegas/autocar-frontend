import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';

// ─────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────

class _Servicio {
  final String id;
  final String tipoNombre;
  final int tiempoEstimadoMinutos;
  final bool activo;

  const _Servicio({
    required this.id,
    required this.tipoNombre,
    required this.tiempoEstimadoMinutos,
    required this.activo,
  });

  factory _Servicio.fromJson(Map<String, dynamic> j) => _Servicio(
        id: j['id'],
        tipoNombre: j['tipo_nombre'],
        tiempoEstimadoMinutos: j['tiempo_estimado_minutos'] ?? 60,
        activo: j['activo'],
      );
}

class _TipoDisponible {
  final String id;
  final String nombre;
  final bool yaAgregado;

  const _TipoDisponible({
    required this.id,
    required this.nombre,
    required this.yaAgregado,
  });

  factory _TipoDisponible.fromJson(Map<String, dynamic> j) => _TipoDisponible(
        id: j['id'],
        nombre: j['nombre'],
        yaAgregado: j['ya_agregado'] ?? false,
      );
}

class _Propuesta {
  final String id;
  final String nombre;
  final String descripcionBase;
  final String estado;

  const _Propuesta({
    required this.id,
    required this.nombre,
    required this.descripcionBase,
    required this.estado,
  });

  factory _Propuesta.fromJson(Map<String, dynamic> j) => _Propuesta(
        id: j['id'],
        nombre: j['nombre'],
        descripcionBase: j['descripcion_base'],
        estado: j['estado'],
      );
}

// ─────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────

class ServiciosTallerScreen extends StatefulWidget {
  const ServiciosTallerScreen({super.key});

  @override
  State<ServiciosTallerScreen> createState() => _ServiciosTallerScreenState();
}

class _ServiciosTallerScreenState extends State<ServiciosTallerScreen>
    with SingleTickerProviderStateMixin {
  static const verde = Color(0xFF15803D);

  late TabController _tabController;
  List<_Servicio> _servicios = [];
  List<_TipoDisponible> _tiposDisponibles = [];
  List<_Propuesta> _propuestas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);

    await Future.wait([
      ApiService()
          .dio
          .get('/talleres/mis-servicios')
          .then((r) {
            print('[DEBUG] mis-servicios raw: ${r.data}');
            final raw = r.data;
            final list = raw is List ? raw : (raw as Map)['items'] as List;
            _servicios = list.map((e) => _Servicio.fromJson(e)).toList();
            print('[DEBUG] _servicios count: ${_servicios.length}');
          })
          .catchError((e, st) {
            print('[DEBUG] mis-servicios ERROR: $e');
          }),
      ApiService()
          .dio
          .get('/talleres/tipos-mantenimiento-disponibles')
          .then((r) {
            print('[DEBUG] tipos-disponibles raw: ${r.data}');
            final raw = r.data;
            final list = raw is List ? raw : (raw as Map)['items'] as List;
            _tiposDisponibles =
                list.map((e) => _TipoDisponible.fromJson(e)).toList();
            print('[DEBUG] _tiposDisponibles count: ${_tiposDisponibles.length}');
            if (_tiposDisponibles.isNotEmpty) {
              print('[DEBUG] primer tipo: ${_tiposDisponibles.first.nombre} | ya_agregado: ${_tiposDisponibles.first.yaAgregado}');
            }
          })
          .catchError((e, st) {
            print('[DEBUG] tipos-disponibles ERROR: $e');
            print('[DEBUG] tipos-disponibles STACKTRACE: $st');
          }),
      ApiService()
          .dio
          .get('/talleres/mis-propuestas')
          .then((r) {
            print('[DEBUG] mis-propuestas raw: ${r.data}');
            final raw = r.data;
            final list = raw is List ? raw : (raw as Map)['items'] as List;
            _propuestas = list.map((e) => _Propuesta.fromJson(e)).toList();
            print('[DEBUG] _propuestas count: ${_propuestas.length}');
          })
          .catchError((e, st) {
            print('[DEBUG] mis-propuestas ERROR: $e');
          }),
    ]);

    print('[DEBUG] _cargar completo → isLoading=false | tiposDisponibles=${_tiposDisponibles.length}');
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Toggle ────────────────────────────────────────────────

  Future<void> _toggle(_Servicio s) async {
    try {
      await ApiService().dio.patch('/talleres/mis-servicios/${s.id}/toggle');
      await _cargar();
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cambiar estado')),
        );
      }
    }
  }

  // ── Eliminar ──────────────────────────────────────────────

  Future<void> _eliminar(_Servicio s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitar servicio'),
        content: Text('¿Quitar "${s.tipoNombre}" de tus servicios?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Quitar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService().dio.delete('/talleres/mis-servicios/${s.id}');
      await _cargar();
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al quitar servicio')),
        );
      }
    }
  }

  // ── Agregar tipo con tiempo ───────────────────────────────

  void _abrirAgregar(_TipoDisponible tipo) {
    final ctrl = TextEditingController(text: '60');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(tipo.nombre,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tiempo estimado de atención:',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: 'minutos',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final tiempo = int.tryParse(ctrl.text.trim()) ?? 60;
              Navigator.pop(context);
              try {
                await ApiService().dio.post(
                  '/talleres/mis-servicios/${tipo.id}',
                  data: {'tiempo_estimado_minutos': tiempo},
                );
                await _cargar();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Servicio agregado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } on DioException catch (e) {
                if (mounted) {
                  final msg =
                      e.response?.data?['detail'] ?? 'Error al agregar';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(msg), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: verde,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Agregar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Proponer nuevo tipo ───────────────────────────────────

  void _abrirPropuesta() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioPropuesta(onEnviado: _cargar),
    );
  }

  // ── Tab 1: Mis servicios ──────────────────────────────────

  Widget _buildActivos() {
    if (_servicios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_outlined, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No tienes servicios configurados',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ir a Agregar',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: verde,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: verde,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _servicios.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final s = _servicios[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(
                    Icons.build,
                    color: s.activo ? verde : Colors.grey.shade400,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.tipoNombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: s.activo
                            ? Colors.black87
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: s.activo
                          ? verde.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: s.activo
                            ? verde.withValues(alpha: 0.4)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      s.activo ? 'ACTIVO' : 'INACTIVO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: s.activo ? verde : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.schedule,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text('${s.tiempoEstimadoMinutos} min estimados',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ]),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _toggle(s),
                      icon: Icon(
                        s.activo
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 15,
                      ),
                      label: Text(s.activo ? 'Desactivar' : 'Activar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            s.activo ? Colors.orange : verde,
                        side: BorderSide(
                            color: s.activo ? Colors.orange : verde),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _eliminar(s),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Icon(Icons.delete_outline, size: 18),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Tab 2: Agregar ────────────────────────────────────────

  Widget _buildAgregar() {
    final disponibles =
        _tiposDisponibles.where((t) => !t.yaAgregado).toList();
    final agregados =
        _tiposDisponibles.where((t) => t.yaAgregado).toList();

    if (_tiposDisponibles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No hay tipos aprobados para tu especialidad.\nPuede proponer uno nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(2),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Proponer tipo',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: verde,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: verde,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (disponibles.isNotEmpty) ...[
            const Text('Disponibles',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87)),
            const SizedBox(height: 10),
            ...disponibles.map((t) => _buildTipoTile(t)),
            const SizedBox(height: 20),
          ],
          if (agregados.isNotEmpty) ...[
            Text('Ya agregados',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            ...agregados.map((t) => _buildTipoTile(t)),
          ],
        ],
      ),
    );
  }

  Widget _buildTipoTile(_TipoDisponible t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Icon(
          t.yaAgregado ? Icons.check_circle : Icons.build_outlined,
          color: t.yaAgregado ? verde : Colors.grey.shade400,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(t.nombre,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          child: t.yaAgregado
              ? Text(
                  'Agregado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: verde,
                      fontWeight: FontWeight.w600),
                )
              : ElevatedButton(
                  onPressed: () => _abrirAgregar(t),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: verde,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Agregar',
                      style:
                          TextStyle(color: Colors.white, fontSize: 12)),
                ),
        ),
      ]),
    );
  }

  // ── Tab 3: Propuestas ─────────────────────────────────────

  Widget _buildPropuestas() {
    if (_propuestas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pending_outlined,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No has propuesto ningún tipo aún',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: verde,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _propuestas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final p = _propuestas[i];
          Color estadoColor;
          IconData estadoIcono;
          switch (p.estado) {
            case 'aprobado':
              estadoColor = Colors.green;
              estadoIcono = Icons.check_circle;
              break;
            case 'rechazado':
              estadoColor = Colors.red;
              estadoIcono = Icons.cancel;
              break;
            default:
              estadoColor = Colors.orange;
              estadoIcono = Icons.hourglass_empty;
          }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(children: [
              Icon(estadoIcono, color: estadoColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(p.descripcionBase,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: estadoColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  p.estado.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: estadoColor),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Mis servicios'),
        backgroundColor: verde,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Activos'),
            Tab(text: 'Agregar'),
            Tab(text: 'Propuestas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActivos(),
                _buildAgregar(),
                _buildPropuestas(),
              ],
            ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
              onPressed: _abrirPropuesta,
              backgroundColor: verde,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Proponer tipo',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────
// FORMULARIO PROPUESTA
// ─────────────────────────────────────────────

class _FormularioPropuesta extends StatefulWidget {
  final VoidCallback onEnviado;
  const _FormularioPropuesta({required this.onEnviado});

  @override
  State<_FormularioPropuesta> createState() => _FormularioPropuestaState();
}

class _FormularioPropuestaState extends State<_FormularioPropuesta> {
  static const verde = Color(0xFF15803D);
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_nombreCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }
    setState(() => _enviando = true);
    try {
      await ApiService().dio.post('/talleres/tipos-mantenimiento', data: {
        'nombre': _nombreCtrl.text.trim(),
        'descripcion_base': _descCtrl.text.trim(),
      });
      widget.onEnviado();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Propuesta enviada. El administrador la revisará.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['detail'] ?? 'Error al enviar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
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
              const Text('Proponer nuevo tipo de mantenimiento',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Tu especialidad se asignará automáticamente. '
                'El administrador aprobará la propuesta.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              const Text('Nombre *',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ej: Revisión del sistema de arranque',
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
                controller: _descCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Describe en qué consiste este mantenimiento',
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
                  onPressed: _enviando ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: verde,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Enviar propuesta',
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
}