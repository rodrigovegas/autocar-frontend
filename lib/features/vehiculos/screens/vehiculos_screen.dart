import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vehiculo_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/vehiculo_model.dart';
import 'registro_vehiculo_screen.dart';
import '../../mantenimiento/screens/historial_mantenimiento_screen.dart';

class VehiculosScreen extends ConsumerStatefulWidget {
  const VehiculosScreen({super.key});

  @override
  ConsumerState<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends ConsumerState<VehiculosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(vehiculoProvider.notifier).cargarVehiculos(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehiculoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis vehículos'),
        automaticallyImplyLeading: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.vehiculos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    size: 80,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes vehículos registrados',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _irARegistro(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar vehículo'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.vehiculos.length,
              itemBuilder: (context, index) {
                final vehiculo = state.vehiculos[index];
                return _TarjetaVehiculo(
                  vehiculo: vehiculo,
                  onHistorial: () => _irAHistorial(context, vehiculo),
                  onEliminar: () => _confirmarEliminar(
                    context,
                    vehiculo.id,
                    '${vehiculo.marca} ${vehiculo.modelo}',
                  ),
                );
              },
            ),
      floatingActionButton: state.vehiculos.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _irARegistro(context),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _irARegistro(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroVehiculoScreen()),
    );
  }

  void _irAHistorial(BuildContext context, VehiculoModel vehiculo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistorialMantenimientoScreen(
          vehiculoId: vehiculo.id, // ← sin int.parse
          vehiculoNombre: '${vehiculo.marca} ${vehiculo.modelo}',
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, String id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text('¿Deseas eliminar $nombre?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(vehiculoProvider.notifier)
                  .eliminarVehiculo(id);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ref.read(vehiculoProvider).error ?? 'Error al eliminar',
                    ),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaVehiculo extends StatelessWidget {
  final VehiculoModel vehiculo;
  final VoidCallback onHistorial;
  final VoidCallback onEliminar;

  const _TarjetaVehiculo({
    required this.vehiculo,
    required this.onHistorial,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.directions_car, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehiculo.marca} ${vehiculo.modelo}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Año ${vehiculo.anio} • ${vehiculo.kilometrajeActual} km',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  onPressed: onEliminar,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onHistorial,
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Ver historial de mantenimiento'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
