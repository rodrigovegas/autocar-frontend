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
  final _placaController = TextEditingController();
  final _colorController = TextEditingController();
  String? _tipoCombustible;

  final List<String> _combustibles = [
    'Gasolina',
    'Diesel',
    'GNV',
    'Gasolina + GNV',
    'Híbrido',
    'Eléctrico',
  ];

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _kilometrajeController.dispose();
    _placaController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(vehiculoProvider.notifier)
        .registrarVehiculo(
          _marcaController.text.trim(),
          _modeloController.text.trim(),
          int.parse(_anioController.text),
          int.parse(_kilometrajeController.text),
          placa: _placaController.text.trim().isEmpty
              ? null
              : _placaController.text.trim().toUpperCase(),
          color: _colorController.text.trim().isEmpty
              ? null
              : _colorController.text.trim(),
          tipoCombustible: _tipoCombustible,
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

              // Marca
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  labelText: 'Marca *',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  hintText: 'Ej: Toyota, Honda, Chevrolet',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese la marca' : null,
              ),
              const SizedBox(height: 16),

              // Modelo
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(
                  labelText: 'Modelo *',
                  prefixIcon: Icon(Icons.car_repair),
                  hintText: 'Ej: Corolla, Civic, Aveo',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese el modelo' : null,
              ),
              const SizedBox(height: 16),

              // Año y placa en fila
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _anioController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Año *',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        hintText: 'Ej: 2020',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        final anio = int.tryParse(v);
                        if (anio == null || anio < 1990 || anio > 2026) {
                          return 'Año inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _placaController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Placa',
                        prefixIcon: Icon(Icons.badge_outlined),
                        hintText: 'Ej: 1234ABC',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Kilometraje
              TextFormField(
                controller: _kilometrajeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kilometraje actual *',
                  prefixIcon: Icon(Icons.speed_outlined),
                  hintText: 'Ej: 45000',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese el kilometraje';
                  if (int.tryParse(v) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Color y tipo combustible en fila
              // Color
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  prefixIcon: Icon(Icons.color_lens_outlined),
                  hintText: 'Ej: Blanco',
                ),
              ),
              const SizedBox(height: 16),

              // Tipo combustible
              DropdownButtonFormField<String>(
                value: _tipoCombustible,
                hint: const Text('Tipo de combustible'),
                decoration: const InputDecoration(
                  labelText: 'Combustible',
                  prefixIcon: Icon(Icons.local_gas_station_outlined),
                ),
                items: _combustibles
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _tipoCombustible = v),
              ),
              const SizedBox(height: 8),
              const Text(
                '* Campos obligatorios',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              if (state.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                ),

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
