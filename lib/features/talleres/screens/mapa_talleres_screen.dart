import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../providers/taller_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/taller_model.dart';
import '../../../shared/services/api_service.dart';
import '../../reservas/screens/crear_reserva_screen.dart';

class MapaTalleresScreen extends ConsumerStatefulWidget {
  const MapaTalleresScreen({super.key});

  @override
  ConsumerState<MapaTalleresScreen> createState() =>
      _MapaTalleresScreenState();
}

class _MapaTalleresScreenState extends ConsumerState<MapaTalleresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  static const LatLng _centroTarija = LatLng(-21.5355, -64.7296);

  List<String> _especialidades = [];
  String _filtroSeleccionado = 'Todos';
  bool _loadingEspecialidades = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(tallerProvider.notifier).cargarTalleres();
      _cargarEspecialidades();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _cargarEspecialidades() async {
    try {
      final res = await ApiService().dio.get('/especialidades');
      setState(() {
        _especialidades = (res.data as List)
            .map<String>((e) => e['nombre'].toString())
            .toList();
        _loadingEspecialidades = false;
      });
    } on DioException catch (_) {
      setState(() => _loadingEspecialidades = false);
    }
  }

  List<TallerModel> _filtrados(List<TallerModel> todos) {
    if (_filtroSeleccionado == 'Todos') return todos;
    return todos
        .where((t) => t.especialidadNombre == _filtroSeleccionado)
        .toList();
  }

  Future<void> _abrirReserva(BuildContext context, TallerModel taller) async {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final detalle = await ref
        .read(tallerDetalleProvider.notifier)
        .cargarDetalle(taller.id);
    if (context.mounted) Navigator.pop(context);
    if (detalle != null && context.mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => CrearReservaScreen(taller: detalle)));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al cargar el detalle del taller'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _mostrarDetalle(BuildContext context, TallerModel taller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
            Text(taller.nombre,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            if (taller.calificacionPromedio != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${taller.calificacionPromedio}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${taller.totalCalificaciones} reseñas)',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ]),
            ],
            const SizedBox(height: 12),
            _DetalleRow(
              icono: Icons.build_outlined,
              texto: taller.especialidadNombre ?? 'Sin especialidad',
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 6),
            _DetalleRow(
              icono: Icons.location_on_outlined,
              texto: taller.direccionTexto,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 6),
            _DetalleRow(
              icono: Icons.phone_outlined,
              texto: taller.telefono,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _abrirReserva(ctx, taller),
                  icon: const Icon(Icons.calendar_today,
                      size: 16, color: Colors.white),
                  label: const Text('Reservar',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Tab Lista ─────────────────────────────────────────────

  Widget _buildLista(List<TallerModel> todos) {
    final lista = _filtrados(todos);
    return Column(
      children: [
        // Chips de filtro — igual al módulo educativo
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _loadingEspecialidades
              ? const SizedBox(
                  height: 36,
                  child: Center(
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FiltroChip(
                        label: 'Todos',
                        activo: _filtroSeleccionado == 'Todos',
                        onTap: () =>
                            setState(() => _filtroSeleccionado = 'Todos'),
                      ),
                      ..._especialidades.map((e) => _FiltroChip(
                            label: e,
                            activo: _filtroSeleccionado == e,
                            onTap: () =>
                                setState(() => _filtroSeleccionado = e),
                          )),
                    ],
                  ),
                ),
        ),

        // Lista
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_outlined,
                          size: 52, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        _filtroSeleccionado == 'Todos'
                            ? 'No hay talleres disponibles'
                            : 'No hay talleres de esta especialidad',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(tallerProvider.notifier).cargarTalleres(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _TarjetaTaller(
                      taller: lista[i],
                      onTap: () => _mostrarDetalle(context, lista[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Tab Mapa ──────────────────────────────────────────────

  Widget _buildMapa(List<TallerModel> talleres) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _centroTarija,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.autocar.autocar_app',
            ),
            MarkerLayer(
              markers: talleres
                  .where((t) => t.latitud != null && t.longitud != null)
                  .map((t) => Marker(
                        point: LatLng(t.latitud!, t.longitud!),
                        width: 40, height: 40,
                        child: GestureDetector(
                          onTap: () => _mostrarDetalle(context, t),
                          child: const Icon(Icons.location_pin,
                              color: AppTheme.primaryColor, size: 40),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),

        // Panel inferior
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 170,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10)
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Text(
                      '${talleres.length} talleres disponibles',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: talleres.length,
                    itemBuilder: (_, i) {
                      final t = talleres[i];
                      return GestureDetector(
                        onTap: () {
                          if (t.latitud != null && t.longitud != null) {
                            _mapController.move(
                                LatLng(t.latitud!, t.longitud!), 15);
                          }
                          _mostrarDetalle(context, t);
                        },
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 3),
                              Text(
                                t.especialidadNombre ?? 'Sin especialidad',
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 11),
                              ),
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 11,
                                    color: AppTheme.textSecondary),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(t.direccionTexto,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tallerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Talleres cercanos'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Lista'),
            Tab(icon: Icon(Icons.map_outlined), text: 'Mapa'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(state.error!,
                          style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(tallerProvider.notifier)
                            .cargarTalleres(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLista(state.talleres),
                    _buildMapa(state.talleres),
                  ],
                ),
    );
  }
}

// ─────────────────────────────────────────────
// CHIP DE FILTRO — mismo estilo que educativo
// ─────────────────────────────────────────────

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
            color: activo ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE TALLER — mismo estilo que reservas
// ─────────────────────────────────────────────

class _TarjetaTaller extends StatelessWidget {
  final TallerModel taller;
  final VoidCallback onTap;

  const _TarjetaTaller({required this.taller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            const Icon(Icons.store_outlined,
                color: AppTheme.primaryColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(taller.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    taller.especialidadNombre ?? 'Sin especialidad',
                    style: const TextStyle(
                        color: AppTheme.primaryColor, fontSize: 13),
                  ),
                  if (taller.calificacionPromedio != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${taller.calificacionPromedio}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${taller.totalCalificaciones} reseñas)',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(taller.direccionTexto,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FILA DE DETALLE EN BOTTOM SHEET
// ─────────────────────────────────────────────

class _DetalleRow extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;

  const _DetalleRow({
    required this.icono,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto,
              style: TextStyle(fontSize: 14, color: color)),
        ),
      ],
    );
  }
}