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
                      onEditar: () => _mostrarEdicion(context, vehiculo),
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
          vehiculoId: vehiculo.id,
          vehiculoNombre: '${vehiculo.marca} ${vehiculo.modelo}',
        ),
      ),
    );
  }

  void _mostrarEdicion(BuildContext context, VehiculoModel vehiculo) {
    final kmController = TextEditingController(
        text: vehiculo.kilometrajeActual.toString());
    final colorController =
        TextEditingController(text: vehiculo.color ?? '');
    String? combustible = vehiculo.tipoCombustible;

    const combustibles = [
      'Gasolina',
      'Diesel',
      'GNV',
      'Gasolina + GNV',
      'Híbrido',
      'Eléctrico',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar ${vehiculo.marca} ${vehiculo.modelo}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Solo puedes editar kilometraje, color y combustible',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              // Kilometraje
              TextField(
                controller: kmController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Kilometraje actual',
                  prefixIcon: const Icon(Icons.speed_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Color
              TextField(
                controller: colorController,
                decoration: InputDecoration(
                  labelText: 'Color',
                  prefixIcon: const Icon(Icons.color_lens_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Combustible
              DropdownButtonFormField<String>(
                value: combustible,
                hint: const Text('Tipo de combustible'),
                decoration: InputDecoration(
                  labelText: 'Combustible',
                  prefixIcon:
                      const Icon(Icons.local_gas_station_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: combustibles
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setModalState(() => combustible = v),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final km = int.tryParse(kmController.text);
                    if (km == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Kilometraje inválido')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    await ref
                        .read(vehiculoProvider.notifier)
                        .actualizarVehiculo(
                          vehiculo.id,
                          kilometraje: km,
                          color: colorController.text.trim().isEmpty
                              ? null
                              : colorController.text.trim(),
                          tipoCombustible: combustible,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vehículo actualizado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Guardar cambios',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
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
                      ref.read(vehiculoProvider).error ??
                          'Error al eliminar',
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
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaVehiculo({
    required this.vehiculo,
    required this.onHistorial,
    required this.onEditar,
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
                      if (vehiculo.placa != null ||
                          vehiculo.color != null ||
                          vehiculo.tipoCombustible != null)
                        Text(
                          [
                            if (vehiculo.placa != null)
                              'Placa: ${vehiculo.placa}',
                            if (vehiculo.color != null) vehiculo.color!,
                            if (vehiculo.tipoCombustible != null)
                              vehiculo.tipoCombustible!,
                          ].join(' • '),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppTheme.primaryColor),
                  onPressed: onEditar,
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