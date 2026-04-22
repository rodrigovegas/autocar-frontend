import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vehiculo_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/vehiculo_model.dart';
import 'registro_vehiculo_screen.dart';

class VehiculosScreen extends ConsumerStatefulWidget {
  const VehiculosScreen({super.key});

  @override
  ConsumerState<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends ConsumerState<VehiculosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    Future.microtask(
      () => ref.read(vehiculoProvider.notifier).cargarVehiculos(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehiculoProvider);
    final activos = state.vehiculos.where((v) => v.activo).toList();
    final inactivos = state.vehiculos.where((v) => !v.activo).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Mis vehículos'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Activos'),
            Tab(text: 'Inactivos'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _TabVehiculos(
                  vehiculos: activos,
                  onEditar: (v) => _mostrarEdicion(context, v),
                  onToggle: (v) => _toggleVehiculo(context, v),
                  mensajeVacio: 'No tienes vehículos activos',
                  onRegistrar: () => _irARegistro(context),
                ),
                _TabVehiculos(
                  vehiculos: inactivos,
                  onEditar: (v) => _mostrarEdicion(context, v),
                  onToggle: (v) => _toggleVehiculo(context, v),
                  mensajeVacio: 'No tienes vehículos inactivos',
                ),
              ],
            ),
      floatingActionButton: _tabController.index == 0
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
      MaterialPageRoute(builder: (_) => const RegistroVehiculoScreen()),
    );
  }

  Future<void> _toggleVehiculo(
      BuildContext context, VehiculoModel vehiculo) async {
    final error =
        await ref.read(vehiculoProvider.notifier).toggleVehiculo(vehiculo.id);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarEdicion(BuildContext context, VehiculoModel vehiculo) {
    final kmController =
        TextEditingController(text: vehiculo.kilometrajeActual.toString());
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
                style:
                    TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
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
              DropdownButtonFormField<String>(
                initialValue: combustible,
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
}

// ─── TAB CON LISTA DE VEHÍCULOS ───────────────────────────────

class _TabVehiculos extends StatelessWidget {
  final List<VehiculoModel> vehiculos;
  final void Function(VehiculoModel) onEditar;
  final void Function(VehiculoModel) onToggle;
  final String mensajeVacio;
  final VoidCallback? onRegistrar;

  const _TabVehiculos({
    required this.vehiculos,
    required this.onEditar,
    required this.onToggle,
    required this.mensajeVacio,
    this.onRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    if (vehiculos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              mensajeVacio,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            if (onRegistrar != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRegistrar,
                icon: const Icon(Icons.add),
                label: const Text('Registrar vehículo'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehiculos.length,
      itemBuilder: (context, index) {
        final vehiculo = vehiculos[index];
        return _TarjetaVehiculo(
          vehiculo: vehiculo,
          onEditar: () => onEditar(vehiculo),
          onToggle: () => onToggle(vehiculo),
        );
      },
    );
  }
}

// ─── TARJETA DE VEHÍCULO ──────────────────────────────────────

class _TarjetaVehiculo extends StatelessWidget {
  final VehiculoModel vehiculo;
  final VoidCallback onEditar;
  final VoidCallback onToggle;

  const _TarjetaVehiculo({
    required this.vehiculo,
    required this.onEditar,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final esActivo = vehiculo.activo;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: esActivo
                      ? AppTheme.primaryColor
                      : Colors.grey.shade400,
                  child:
                      const Icon(Icons.directions_car, color: Colors.white),
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
                          style: TextStyle(
                            color: esActivo
                                ? AppTheme.primaryColor
                                : Colors.grey.shade500,
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
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onToggle,
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      esActivo ? Colors.orange : Colors.green,
                  side: BorderSide(
                      color: esActivo ? Colors.orange : Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(esActivo ? 'Desactivar' : 'Activar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
