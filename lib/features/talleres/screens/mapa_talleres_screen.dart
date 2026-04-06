import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/taller_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/taller_model.dart';
import '../../reservas/screens/crear_reserva_screen.dart';

class MapaTalleresScreen extends ConsumerStatefulWidget {
  const MapaTalleresScreen({super.key});

  @override
  ConsumerState<MapaTalleresScreen> createState() =>
      _MapaTalleresScreenState();
}

class _MapaTalleresScreenState extends ConsumerState<MapaTalleresScreen> {
  final MapController _mapController = MapController();
  static const LatLng _centroTarija = LatLng(-21.5355, -64.7296);

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(tallerProvider.notifier).cargarTalleres());
  }

  Future<void> _abrirReserva(BuildContext context, TallerModel taller) async {
    Navigator.pop(context); // cierra el bottom sheet

    // Muestra loading mientras carga el detalle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final tallerDetalle = await ref
        .read(tallerDetalleProvider.notifier)
        .cargarDetalle(taller.id);

    if (context.mounted) Navigator.pop(context); // cierra loading

    if (tallerDetalle != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CrearReservaScreen(taller: tallerDetalle),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar el detalle del taller'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tallerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Talleres cercanos'),
        automaticallyImplyLeading: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _centroTarija,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.autocar.autocar_app',
                    ),
                    MarkerLayer(
                      markers: state.talleres
                          .where((t) =>
                              t.latitud != null && t.longitud != null)
                          .map((taller) => Marker(
                                point: LatLng(
                                    taller.latitud!, taller.longitud!),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () =>
                                      _mostrarDetalleTaller(context, taller),
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: AppTheme.primaryColor,
                                    size: 40,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 180,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                '${state.talleres.length} talleres disponibles',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.talleres.length,
                            itemBuilder: (context, index) {
                              final taller = state.talleres[index];
                              return GestureDetector(
                                onTap: () {
                                  if (taller.latitud != null &&
                                      taller.longitud != null) {
                                    _mapController.move(
                                      LatLng(taller.latitud!,
                                          taller.longitud!),
                                      15,
                                    );
                                  }
                                  _mostrarDetalleTaller(context, taller);
                                },
                                child: Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        taller.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        taller.especialidad,
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              taller.direccionTexto,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
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
            ),
    );
  }

  void _mostrarDetalleTaller(BuildContext context, TallerModel taller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taller.nombre,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.build_outlined,
                    size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(taller.especialidad),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(child: Text(taller.direccionTexto)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(taller.telefono),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirReserva(context, taller),
                    icon: const Icon(Icons.calendar_today,
                        size: 16, color: Colors.white),
                    label: const Text('Reservar',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}