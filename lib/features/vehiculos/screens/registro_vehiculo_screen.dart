import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vehiculo_provider.dart';
import '../../../core/theme/app_theme.dart';

class RegistroVehiculoScreen extends ConsumerStatefulWidget {
  const RegistroVehiculoScreen({super.key});

  @override
  ConsumerState<RegistroVehiculoScreen> createState() =>
      _RegistroVehiculoScreenState();
}

class _RegistroVehiculoScreenState
    extends ConsumerState<RegistroVehiculoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _kilometrajeController = TextEditingController();

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _kilometrajeController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(vehiculoProvider.notifier).registrarVehiculo(
      _marcaController.text.trim(),
      _modeloController.text.trim(),
      int.parse(_anioController.text),
      int.parse(_kilometrajeController.text),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehículo registrado exitosamente'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehiculoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar vehículo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos del vehículo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  hintText: 'Ej: Toyota, Honda, Chevrolet',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la marca del vehículo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  prefixIcon: Icon(Icons.car_repair),
                  hintText: 'Ej: Corolla, Civic, Aveo',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el modelo del vehículo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _anioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Año',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  hintText: 'Ej: 2020',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el año del vehículo';
                  }
                  final anio = int.tryParse(value);
                  if (anio == null || anio < 1990 || anio > 2026) {
                    return 'Ingrese un año válido entre 1990 y 2026';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _kilometrajeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kilometraje actual',
                  prefixIcon: Icon(Icons.speed_outlined),
                  hintText: 'Ej: 45000',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el kilometraje actual';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              if (state.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                ),

              const SizedBox(height: 16),

              state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registrar,
                      child: const Text('Registrar vehículo'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}