import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/recordatorio_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/services/api_service.dart';
import '../../../models/vehiculo_model.dart';
import '../../vehiculos/providers/vehiculo_provider.dart';

// ─── Modelo local para el dropdown de tipos ──────────────────

class _TipoItem {
  final String id;
  final String nombre;
  final int? intervaloKm;
  final int? intervaloDias;

  _TipoItem({
    required this.id,
    required this.nombre,
    this.intervaloKm,
    this.intervaloDias,
  });

  factory _TipoItem.fromJson(Map<String, dynamic> json) => _TipoItem(
        id: json['id'],
        nombre: json['nombre'],
        intervaloKm: json['intervalo_km'],
        intervaloDias: json['intervalo_dias'],
      );
}

// ─── Pantalla ─────────────────────────────────────────────────

class RegistroRecordatorioScreen extends ConsumerStatefulWidget {
  const RegistroRecordatorioScreen({super.key});

  @override
  ConsumerState<RegistroRecordatorioScreen> createState() =>
      _RegistroRecordatorioScreenState();
}

class _RegistroRecordatorioScreenState
    extends ConsumerState<RegistroRecordatorioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  final _notasController = TextEditingController();

  List<_TipoItem> _tipos = [];
  bool _loadingTipos = true;

  VehiculoModel? _vehiculoSeleccionado;
  _TipoItem? _tipoSeleccionado;
  DateTime? _fechaProgramada;
  String? _errorFormulario;

  @override
  void initState() {
    super.initState();
    _cargarTipos();
    Future.microtask(
      () => ref.read(vehiculoProvider.notifier).cargarVehiculos(),
    );
  }

  @override
  void dispose() {
    _kmController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _cargarTipos() async {
    try {
      final response =
          await ApiService().dio.get(ApiConstants.tiposMantenimiento);
      if (mounted) {
        setState(() {
          _tipos = (response.data as List)
              .map((t) => _TipoItem.fromJson(t))
              .toList();
          _loadingTipos = false;
        });
      }
    } on DioException catch (_) {
      if (mounted) setState(() => _loadingTipos = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaProgramada ?? hoy,
      firstDate: hoy,
      lastDate: DateTime(hoy.year + 5),
      locale: const Locale('es'),
    );
    if (picked != null) setState(() => _fechaProgramada = picked);
  }

  String _formatearFecha(DateTime fecha) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }

  Future<void> _crear() async {
    setState(() => _errorFormulario = null);

    if (!_formKey.currentState!.validate()) return;

    final kmTexto = _kmController.text.trim();
    final kmValor = kmTexto.isNotEmpty ? int.tryParse(kmTexto) : null;

    // Validación: al menos fecha o kilometraje
    if (_fechaProgramada == null && kmTexto.isEmpty) {
      setState(() => _errorFormulario =
          'Debe especificar una fecha o un kilometraje (al menos uno)');
      return;
    }

    // Validación: km > km actual del vehículo
    if (kmValor != null &&
        _vehiculoSeleccionado != null &&
        kmValor <= _vehiculoSeleccionado!.kilometrajeActual) {
      setState(() => _errorFormulario =
          'El kilometraje debe ser mayor al actual (${_vehiculoSeleccionado!.kilometrajeActual} km)');
      return;
    }

    if (kmTexto.isNotEmpty && kmValor == null) {
      setState(() => _errorFormulario = 'Kilometraje inválido');
      return;
    }

    final exito = await ref.read(recordatorioProvider.notifier).crearRecordatorio(
          vehiculoId: _vehiculoSeleccionado!.id,
          tipoMantenimientoId: _tipoSeleccionado!.id,
          fechaProgramada: _fechaProgramada,
          kilometrajeProgramado: kmValor,
          textoPersonalizado: _notasController.text.trim().isEmpty
              ? null
              : _notasController.text.trim(),
        );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recordatorio creado'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      setState(() {
        _errorFormulario = ref.read(recordatorioProvider).error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculoState = ref.watch(vehiculoProvider);
    final recordatorioState = ref.watch(recordatorioProvider);
    final vehiculosActivos =
        vehiculoState.vehiculos.where((v) => v.activo).toList();
    final sinVehiculos = !vehiculoState.isLoading && vehiculosActivos.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear recordatorio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nuevo recordatorio',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // ── Alerta sin vehículos ──────────────────────────
              if (sinVehiculos)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Registra un vehículo primero para poder crear recordatorios.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Dropdown vehículos ────────────────────────────
              DropdownButtonFormField<VehiculoModel>(
                initialValue: _vehiculoSeleccionado,
                hint: const Text('Selecciona un vehículo'),
                decoration: InputDecoration(
                  labelText: 'Vehículo *',
                  prefixIcon: const Icon(Icons.directions_car_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: vehiculosActivos
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text('${v.marca} ${v.modelo}'),
                      ),
                    )
                    .toList(),
                onChanged: sinVehiculos
                    ? null
                    : (v) => setState(() {
                          _vehiculoSeleccionado = v;
                          _kmController.clear();
                        }),
                validator: (v) =>
                    v == null ? 'Selecciona un vehículo' : null,
              ),
              const SizedBox(height: 16),

              // ── Dropdown tipos de mantenimiento ───────────────
              _loadingTipos
                  ? const Center(
                      heightFactor: 1,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : DropdownButtonFormField<_TipoItem>(
                      initialValue: _tipoSeleccionado,
                      hint: const Text('Selecciona el tipo'),
                      decoration: InputDecoration(
                        labelText: 'Tipo de mantenimiento *',
                        prefixIcon: const Icon(Icons.build_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _tipos
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: (t) =>
                          setState(() => _tipoSeleccionado = t),
                      validator: (v) =>
                          v == null ? 'Selecciona un tipo' : null,
                    ),
              const SizedBox(height: 16),

              // ── Fecha programada (opcional) ───────────────────
              InkWell(
                onTap: _seleccionarFecha,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha programada',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    suffixIcon: _fechaProgramada != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setState(() => _fechaProgramada = null),
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _fechaProgramada != null
                        ? _formatearFecha(_fechaProgramada!)
                        : 'Sin fecha (opcional)',
                    style: TextStyle(
                      color: _fechaProgramada != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Kilometraje programado (opcional) ─────────────
              TextFormField(
                controller: _kmController,
                keyboardType: TextInputType.number,
                enabled: !sinVehiculos,
                decoration: InputDecoration(
                  labelText: 'Kilometraje programado',
                  prefixIcon: const Icon(Icons.speed_outlined),
                  hintText: _vehiculoSeleccionado != null
                      ? 'Actual: ${_vehiculoSeleccionado!.kilometrajeActual} km'
                      : 'Opcional',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // ── Notas (opcional) ──────────────────────────────
              TextFormField(
                controller: _notasController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notas',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  hintText: 'Información adicional (opcional)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '* Campos obligatorios. Debes indicar fecha o kilometraje (o ambos).',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              // ── Error de formulario ───────────────────────────
              if (_errorFormulario != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorFormulario!,
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                ),

              // ── Botón ─────────────────────────────────────────
              recordatorioState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: sinVehiculos ? null : _crear,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Crear recordatorio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
