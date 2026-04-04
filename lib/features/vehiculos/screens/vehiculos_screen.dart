import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vehiculo_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'registro_vehiculo_screen.dart';

class VehiculosScreen extends ConsumerStatefulWidget {
  const VehiculosScreen({super.key});

  @override
  ConsumerState<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends ConsumerState<VehiculosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(vehiculoProvider.notifier).cargarVehiculos());
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(
                            Icons.directions_car,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          '${vehiculo.marca} ${vehiculo.modelo}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Año: ${vehiculo.anio} • ${vehiculo.kilometrajeActual} km',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.errorColor,
                          ),
                          onPressed: () => _confirmarEliminar(
                            context, vehiculo.id, 
                            '${vehiculo.marca} ${vehiculo.modelo}'
                          ),
                        ),
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
      MaterialPageRoute(
        builder: (context) => const RegistroVehiculoScreen(),
      ),
    );
  }

  void _confirmarEliminar(
      BuildContext context, String id, String nombre) {
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