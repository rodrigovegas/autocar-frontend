import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mantenimiento_provider.dart';
import '../../../core/theme/app_theme.dart';

class RegistroMantenimientoScreen extends ConsumerStatefulWidget {
  final String vehiculoId;

  const RegistroMantenimientoScreen({super.key, required this.vehiculoId});

  @override
  ConsumerState<RegistroMantenimientoScreen> createState() =>
      _RegistroMantenimientoScreenState();
}

class _RegistroMantenimientoScreenState
    extends ConsumerState<RegistroMantenimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _tipoSeleccionado;
  DateTime _fechaSeleccionada = DateTime.now();
  final _kmController = TextEditingController();
  final _costoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _tallerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(mantenimientoProvider.notifier).cargarTipos();
    });
  }

  @override
  void dispose() {
    _kmController.dispose();
    _costoController.dispose();
    _descripcionController.dispose();
    _tallerController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (fecha != null) setState(() => _fechaSeleccionada = fecha);
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate() && _tipoSeleccionado != null) {
      await ref.read(mantenimientoProvider.notifier).registrar(
            vehiculoId: widget.vehiculoId,
            tipoMantenimientoId: _tipoSeleccionado!,
            fecha:
                '${_fechaSeleccionada.year}-${_fechaSeleccionada.month.toString().padLeft(2, '0')}-${_fechaSeleccionada.day.toString().padLeft(2, '0')}',
            kilometraje: _kmController.text.isNotEmpty
                ? int.tryParse(_kmController.text)
                : null,
            costo: _costoController.text.isNotEmpty
                ? double.tryParse(_costoController.text)
                : null,
            descripcion: _descripcionController.text,
            tallerNombre: _tallerController.text,
          );

      if (context.mounted) {
        Navigator.pop(context);
      }
    } else if (_tipoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un tipo de mantenimiento')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mantenimientoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar mantenimiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tipo de mantenimiento',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _tipoSeleccionado,
                hint: const Text('Selecciona el tipo'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: state.tipos
                    .map((t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.nombre),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _tipoSeleccionado = v),
              ),
              const SizedBox(height: 16),
              const Text('Fecha',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _seleccionarFecha,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Campo(
                label: 'Kilometraje (opcional)',
                controller: _kmController,
                keyboardType: TextInputType.number,
                hint: 'Ej: 45000',
              ),
              const SizedBox(height: 16),
              _Campo(
                label: 'Costo en Bs. (opcional)',
                controller: _costoController,
                keyboardType: TextInputType.number,
                hint: 'Ej: 250.00',
              ),
              const SizedBox(height: 16),
              _Campo(
                label: 'Nombre del taller (opcional)',
                controller: _tallerController,
                hint: 'Ej: Taller Central',
              ),
              const SizedBox(height: 16),
              _Campo(
                label: 'Notas (opcional)',
                controller: _descripcionController,
                hint: 'Observaciones del mantenimiento...',
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Guardar registro',
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

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;

  const _Campo({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}