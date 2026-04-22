import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────

class TallerAdminModel {
  final String id;
  final String nombre;
  final String? especialidadNombre;
  final String direccionTexto;
  final String telefono;
  final String correo;
  final String estado;
  final double? latitud;
  final double? longitud;

  TallerAdminModel({
    required this.id,
    required this.nombre,
    this.especialidadNombre,
    required this.direccionTexto,
    required this.telefono,
    required this.correo,
    required this.estado,
    this.latitud,
    this.longitud,
  });

  factory TallerAdminModel.fromJson(Map<String, dynamic> json) {
    return TallerAdminModel(
      id: json['id'].toString(),
      nombre: json['nombre'],
      especialidadNombre: json['especialidad_nombre'],
      direccionTexto: json['direccion_texto'],
      telefono: json['telefono'],
      correo: json['correo'],
      estado: json['estado'],
      latitud: json['latitud'] != null
          ? double.parse(json['latitud'].toString())
          : null,
      longitud: json['longitud'] != null
          ? double.parse(json['longitud'].toString())
          : null,
    );
  }
}

// ─────────────────────────────────────────────
// MAPA SELECTOR — widget interno reutilizable
// ─────────────────────────────────────────────

class _MapLocationPicker extends StatefulWidget {
  final LatLng initialPosition;

  const _MapLocationPicker({required this.initialPosition});

  @override
  State<_MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<_MapLocationPicker> {
  late LatLng _selected;
  late final MapController _mapController;

  // Centro de Tarija — punto de partida si el taller no tiene coordenadas
  static const LatLng _tarijaCenter = LatLng(-21.5355, -64.7296);

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPosition;
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Encabezado del bottom sheet ──────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: const BoxDecoration(
            color: Color(0xFF7C3AED),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Seleccionar ubicación del taller',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Toca el mapa para marcar la posición exacta',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),

        // ── Mapa ─────────────────────────────────────────────────
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selected,
                  initialZoom: 15.0,
                  onTap: (tapPosition, point) {
                    setState(() => _selected = point);
                  },
                ),
                children: [
                  // Tiles de OpenStreetMap — sin API key
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.autocar.app',
                    maxZoom: 19,
                  ),
                  // Marcador de posición seleccionada
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected,
                        width: 48,
                        height: 56,
                        child: const Column(
                          children: [
                            Icon(
                              Icons.location_pin,
                              color: Color(0xFF7C3AED),
                              size: 40,
                            ),
                            // sombra visual debajo del pin
                            SizedBox(
                              width: 8,
                              height: 4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Coordenadas en vivo (esquina inferior izquierda) ──
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    'Lat: ${_selected.latitude.toStringAsFixed(5)}'
                    '   Lng: ${_selected.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),

              // ── Botón de re-centrar (esquina superior derecha) ────
              Positioned(
                top: 12,
                right: 12,
                child: FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    _mapController.move(_tarijaCenter, 14.0);
                  },
                  child: const Icon(Icons.my_location,
                      color: Color(0xFF7C3AED), size: 20),
                ),
              ),
            ],
          ),
        ),

        // ── Botón de confirmación ─────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Confirmar ubicación',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────

class TalleresAdminScreen extends StatefulWidget {
  const TalleresAdminScreen({super.key});

  @override
  State<TalleresAdminScreen> createState() => _TalleresAdminScreenState();
}

class _TalleresAdminScreenState extends State<TalleresAdminScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  List<TallerAdminModel> _talleres = [];
  late TabController _tabController;

  // Centro de Tarija usado como fallback cuando el taller no tiene coordenadas
  static const LatLng _tarijaDefault = LatLng(-21.5355, -64.7296);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Carga desde el backend ────────────────────────────────────

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().dio.get('/admin/talleres');
      setState(() {
        _talleres = (response.data as List)
            .map((e) => TallerAdminModel.fromJson(e))
            .toList();
      });
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar talleres')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Abre el mapa y devuelve la ubicación elegida ──────────────

  Future<LatLng?> _abrirMapaPicker(TallerAdminModel taller) async {
    final initialPos = (taller.latitud != null && taller.longitud != null)
        ? LatLng(taller.latitud!, taller.longitud!)
        : _tarijaDefault;

    return showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,      // ocupa altura personalizada
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        // 88% de la pantalla: deja un pequeño margen superior
        height: MediaQuery.of(context).size.height * 0.88,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: _MapLocationPicker(initialPosition: initialPos),
        ),
      ),
    );
  }

  // ── Activar taller ────────────────────────────────────────────

  Future<void> _activar(TallerAdminModel taller) async {
    // 1. El admin elige la ubicación en el mapa
    final ubicacion = await _abrirMapaPicker(taller);
    if (ubicacion == null || !mounted) return;

    // 2. Confirmación final antes de llamar al backend
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF7C3AED)),
            const SizedBox(width: 8),
            Expanded(child: Text('Activar ${taller.nombre}')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ubicación seleccionada:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
              ),
              child: Text(
                'Lat: ${ubicacion.latitude.toStringAsFixed(6)}\n'
                'Lng: ${ubicacion.longitude.toStringAsFixed(6)}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFF4C1D95),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('¿Confirmas la activación con esta ubicación?',
                style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver al mapa'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                const Text('Activar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    // 3. Llamada al backend
    try {
      await ApiService().dio.patch(
        '/admin/talleres/${taller.id}/activar',
        data: {
          'latitud': ubicacion.latitude,
          'longitud': ubicacion.longitude,
        },
      );
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Taller activado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al activar el taller'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Editar ubicación de un taller ya activo ───────────────────

  Future<void> _editarUbicacion(TallerAdminModel taller) async {
    final ubicacion = await _abrirMapaPicker(taller);
    if (ubicacion == null || !mounted) return;

    try {
      await ApiService().dio.patch(
        '/admin/talleres/${taller.id}/activar',
        data: {
          'latitud': ubicacion.latitude,
          'longitud': ubicacion.longitude,
        },
      );
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar la ubicación')),
        );
      }
    }
  }

  // ── Desactivar taller ─────────────────────────────────────────

  Future<void> _desactivar(TallerAdminModel taller) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar taller'),
        content: Text('¿Deseas desactivar "${taller.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desactivar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ApiService().dio.patch('/admin/talleres/${taller.id}/desactivar');
        await _cargar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Taller desactivado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } on DioException catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al desactivar')),
          );
        }
      }
    }
  }

  // ── Lista de tarjetas ─────────────────────────────────────────

  Widget _buildLista(List<TallerAdminModel> lista) {
    if (lista.isEmpty) {
      return const Center(
        child: Text(
          'Sin talleres en esta categoría',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lista.length,
        itemBuilder: (context, index) {
          final t = lista[index];

          Color estadoColor;
          switch (t.estado) {
            case 'activo':
              estadoColor = Colors.green;
              break;
            case 'pendiente':
              estadoColor = Colors.orange;
              break;
            default:
              estadoColor = Colors.red;
          }

          final tieneUbicacion = t.latitud != null && t.longitud != null;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Nombre + badge de estado ──────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(t.especialidadNombre ?? 'Sin especialidad',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: estadoColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: estadoColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          t.estado.toUpperCase(),
                          style: TextStyle(
                              color: estadoColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Info de contacto ──────────────────────────
                  Text(t.correo,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  Text(t.telefono,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  Text(t.direccionTexto,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),

                  // ── Coordenadas actuales (si existen) ─────────
                  if (tieneUbicacion) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 13, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 4),
                        Text(
                          '${t.latitud!.toStringAsFixed(5)}, '
                          '${t.longitud!.toStringAsFixed(5)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // ── Botones de acción ─────────────────────────
                  Row(
                    children: [
                      if (t.estado != 'activo')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _activar(t),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.location_on,
                                color: Colors.white, size: 16),
                            label: const Text('Activar con mapa',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),

                      if (t.estado == 'activo') ...[
                        // Editar ubicación
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _editarUbicacion(t),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF7C3AED),
                              side: const BorderSide(
                                  color: Color(0xFF7C3AED)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.edit_location_alt,
                                size: 16),
                            label: const Text('Ubicación'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Desactivar
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _desactivar(t),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon:
                                const Icon(Icons.block, size: 16),
                            label: const Text('Desactivar'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Build principal ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pendientes =
        _talleres.where((t) => t.estado == 'pendiente').toList();
    final activos = _talleres.where((t) => t.estado == 'activo').toList();
    final inactivos =
        _talleres.where((t) => t.estado == 'inactivo').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de talleres'),
        backgroundColor: const Color(0xFF7C3AED),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pendientes'),
                  if (pendientes.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${pendientes.length}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Activos'),
            const Tab(text: 'Inactivos'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLista(pendientes),
                _buildLista(activos),
                _buildLista(inactivos),
              ],
            ),
    );
  }
}