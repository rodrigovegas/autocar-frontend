import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../reservas/providers/reserva_taller_provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class RegistrarMantenimientoScreen extends ConsumerStatefulWidget {
  final String reservaId;
  final String servicioNombre;
  final String vehiculoInfo;

  const RegistrarMantenimientoScreen({
    super.key,
    required this.reservaId,
    required this.servicioNombre,
    required this.vehiculoInfo,
  });

  @override
  ConsumerState<RegistrarMantenimientoScreen> createState() =>
      _RegistrarMantenimientoScreenState();
}

class _RegistrarMantenimientoScreenState
    extends ConsumerState<RegistrarMantenimientoScreen> {
  final _kmController = TextEditingController();
  final _detalleTecnicoController = TextEditingController();
  final _problemasController = TextEditingController();
  final _costoController = TextEditingController();
  final _kmProximoController = TextEditingController();
  final _recomendacionesController = TextEditingController();

  DateTime _fechaSeleccionada = DateTime.now();
  DateTime? _fechaProximo;
  String? _gravedad;
  bool _seccion2Abierta = false;
  bool _seccion3Abierta = false;
  bool _guardando = false;
  bool _crearRecordatorio = false;

  @override
  void dispose() {
    _kmController.dispose();
    _detalleTecnicoController.dispose();
    _problemasController.dispose();
    _costoController.dispose();
    _kmProximoController.dispose();
    _recomendacionesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatDateDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _guardar() async {
    if (_kmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el kilometraje')),
      );
      return;
    }

    if (_crearRecordatorio &&
        _kmProximoController.text.isEmpty &&
        _fechaProximo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Para crear el recordatorio debe especificar '
            'fecha o kilometraje del próximo mantenimiento',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await ApiService().dio.post(
        '${ApiConstants.mantenimientos}/',
        data: {
          'reserva_id': widget.reservaId,
          'kilometraje_registro': int.parse(_kmController.text),
          'fecha_realizado': _formatDate(_fechaSeleccionada),
          'costo': _costoController.text.isNotEmpty
              ? double.tryParse(_costoController.text)
              : null,
          'detalle_tecnico': _detalleTecnicoController.text.isNotEmpty
              ? _detalleTecnicoController.text
              : null,
          'problemas_detectados': _problemasController.text.isNotEmpty
              ? _problemasController.text
              : null,
          'gravedad_problemas': _gravedad,
          'km_proximo_mantenimiento': _kmProximoController.text.isNotEmpty
              ? int.tryParse(_kmProximoController.text)
              : null,
          'fecha_proximo_mantenimiento': _fechaProximo != null
              ? _formatDate(_fechaProximo!)
              : null,
          'recomendaciones': _recomendacionesController.text.isNotEmpty
              ? _recomendacionesController.text
              : null,
          'crear_recordatorio_proximo': _crearRecordatorio,
        },
      );
      await ref.read(reservaTallerProvider.notifier).cargarReservas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mantenimiento registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data['detail'] ?? 'Error al registrar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Registrar mantenimiento'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Sección 1: Información básica (siempre visible) ──
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(Icons.info_outline, 'Información básica'),
                const SizedBox(height: 16),
                _ReadOnlyField(
                  label: 'Tipo de servicio',
                  value: widget.servicioNombre,
                ),
                const SizedBox(height: 12),
                _ReadOnlyField(
                  label: 'Vehículo',
                  value: widget.vehiculoInfo,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate: _fechaSeleccionada,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (fecha != null) {
                      setState(() => _fechaSeleccionada = fecha);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fecha realizado',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                            Text(
                              _formatDateDisplay(_fechaSeleccionada),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _kmController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Kilometraje *',
                    prefixIcon: const Icon(Icons.speed),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Sección 2: Detalle técnico (colapsable) ──
          _ColapsableSection(
            titulo: 'Detalle técnico',
            icono: Icons.build_outlined,
            abierta: _seccion2Abierta,
            onToggle: () =>
                setState(() => _seccion2Abierta = !_seccion2Abierta),
            child: Column(
              children: [
                TextField(
                  controller: _detalleTecnicoController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Detalle técnico',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _problemasController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Problemas detectados',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _gravedad,
                  decoration: InputDecoration(
                    labelText: 'Gravedad',
                    prefixIcon:
                        const Icon(Icons.warning_amber_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'ninguno', child: Text('Ninguno')),
                    DropdownMenuItem(value: 'leve', child: Text('Leve')),
                    DropdownMenuItem(
                        value: 'moderado', child: Text('Moderado')),
                    DropdownMenuItem(value: 'grave', child: Text('Grave')),
                  ],
                  onChanged: (v) => setState(() => _gravedad = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _costoController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Costo en Bs.',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Sección 3: Próximo mantenimiento (colapsable) ──
          _ColapsableSection(
            titulo: 'Próximo mantenimiento',
            icono: Icons.event_outlined,
            abierta: _seccion3Abierta,
            onToggle: () =>
                setState(() => _seccion3Abierta = !_seccion3Abierta),
            child: Column(
              children: [
                TextField(
                  controller: _kmProximoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Km próximo mantenimiento',
                    prefixIcon: const Icon(Icons.speed_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.now().add(const Duration(days: 180)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 1095)),
                    );
                    if (fecha != null) {
                      setState(() => _fechaProximo = fecha);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined,
                            color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fecha próximo mantenimiento',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                            Text(
                              _fechaProximo != null
                                  ? _formatDateDisplay(_fechaProximo!)
                                  : 'Sin definir',
                              style: TextStyle(
                                fontSize: 15,
                                color: _fechaProximo != null
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _recomendacionesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Recomendaciones',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: _crearRecordatorio
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _crearRecordatorio
                          ? AppTheme.primaryColor.withValues(alpha: 0.4)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _crearRecordatorio,
                    onChanged: (v) =>
                        setState(() => _crearRecordatorio = v ?? false),
                    activeColor: AppTheme.primaryColor,
                    title: const Text(
                      'Crear recordatorio del próximo mantenimiento para el cliente',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Se enviará al cliente el aviso del próximo mantenimiento. '
                      'Requiere completar fecha o kilometraje del próximo mantenimiento.',
                      style: TextStyle(fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Guardar mantenimiento',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icono, String titulo) {
    return Row(
      children: [
        Icon(icono, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(titulo,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

// ─── WIDGETS ──────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}

class _ColapsableSection extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final bool abierta;
  final VoidCallback onToggle;
  final Widget child;

  const _ColapsableSection({
    required this.titulo,
    required this.icono,
    required this.abierta,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icono, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(titulo,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const Text('Opcional',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 8),
                  Icon(
                    abierta
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (abierta)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(value,
              style: const TextStyle(
                  fontSize: 15, color: AppTheme.textPrimary)),
        ),
      ],
    );
  }
}
