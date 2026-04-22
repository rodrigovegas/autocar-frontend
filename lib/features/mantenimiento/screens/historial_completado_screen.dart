import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class MantenimientoHistorial {
  final String id;
  final String vehiculoId;
  final String? vehiculoNombre;
  final String tallerId;
  final String? tallerNombre;
  final int kilometrajeRegistro;
  final String fechaRealizado;
  final double? costo;
  final String? detalleTecnico;
  final String? problemasDetectados;
  final String? gravedadProblemas;
  final int? kmProximoMantenimiento;
  final String? fechaProximoMantenimiento;
  final String? recomendaciones;
  final String? observaciones;

  MantenimientoHistorial({
    required this.id,
    required this.vehiculoId,
    this.vehiculoNombre,
    required this.tallerId,
    this.tallerNombre,
    required this.kilometrajeRegistro,
    required this.fechaRealizado,
    this.costo,
    this.detalleTecnico,
    this.problemasDetectados,
    this.gravedadProblemas,
    this.kmProximoMantenimiento,
    this.fechaProximoMantenimiento,
    this.recomendaciones,
    this.observaciones,
  });

  factory MantenimientoHistorial.fromJson(Map<String, dynamic> json) {
    return MantenimientoHistorial(
      id: json['id'].toString(),
      vehiculoId: json['vehiculo_id'].toString(),
      vehiculoNombre: json['vehiculo_nombre'],
      tallerId: json['taller_id'].toString(),
      tallerNombre: json['taller_nombre'],
      kilometrajeRegistro: json['kilometraje_registro'],
      fechaRealizado: json['fecha_realizado'].toString(),
      costo: json['costo'] != null
          ? double.parse(json['costo'].toString())
          : null,
      detalleTecnico: json['detalle_tecnico'],
      problemasDetectados: json['problemas_detectados'],
      gravedadProblemas: json['gravedad_problemas'],
      kmProximoMantenimiento: json['km_proximo_mantenimiento'],
      fechaProximoMantenimiento:
          json['fecha_proximo_mantenimiento']?.toString(),
      recomendaciones: json['recomendaciones'],
      observaciones: json['observaciones'],
    );
  }
}

class _VehiculoFiltro {
  final String id;
  final String nombre;
  const _VehiculoFiltro({required this.id, required this.nombre});
}

class HistorialCompletadoScreen extends ConsumerStatefulWidget {
  const HistorialCompletadoScreen({super.key});

  @override
  ConsumerState<HistorialCompletadoScreen> createState() =>
      _HistorialCompletadoScreenState();
}

class _HistorialCompletadoScreenState
    extends ConsumerState<HistorialCompletadoScreen> {
  bool _isLoading = false;
  List<MantenimientoHistorial> _historial = [];
  List<_VehiculoFiltro> _vehiculos = [];
  String? _vehiculoFiltroId; // null = "Todos"

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService().dio.get(
          '${ApiConstants.mantenimientos}/historial/usuario',
        ),
        ApiService().dio.get(ApiConstants.vehiculos),
      ]);
      setState(() {
        _historial = (results[0].data as List)
            .map((e) => MantenimientoHistorial.fromJson(e))
            .toList();
        _vehiculos = (results[1].data as List)
            .map((e) => _VehiculoFiltro(
                  id: e['id'].toString(),
                  nombre: '${e['marca']} ${e['modelo']}',
                ))
            .toList();
      });
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar el historial')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<MantenimientoHistorial> get _historialFiltrado {
    if (_vehiculoFiltroId == null) return _historial;
    return _historial
        .where((m) => m.vehiculoId == _vehiculoFiltroId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtrado = _historialFiltrado;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Historial de mantenimientos'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Chips de filtro ──────────────────────────
                if (_vehiculos.isNotEmpty)
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      children: [
                        _Chip(
                          label: 'Todos',
                          activo: _vehiculoFiltroId == null,
                          onTap: () =>
                              setState(() => _vehiculoFiltroId = null),
                        ),
                        ..._vehiculos.map(
                          (v) => _Chip(
                            label: v.nombre,
                            activo: _vehiculoFiltroId == v.id,
                            onTap: () =>
                                setState(() => _vehiculoFiltroId = v.id),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Lista ────────────────────────────────────
                Expanded(
                  child: filtrado.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.build_outlined,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text(
                                'Sin historial de mantenimientos',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Aquí aparecerán los mantenimientos\ncompletados en talleres',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargar,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtrado.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final m = filtrado[index];
                              final titulo = m.tallerNombre ??
                                  'Mantenimiento completado';
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          _DetalleMantenimientoScreen(
                                              m: m),
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.build_circle_outlined,
                                            color: AppTheme.primaryColor,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                titulo,
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              if (m.vehiculoNombre != null)
                                                Text(
                                                  m.vehiculoNombre!,
                                                  style: const TextStyle(
                                                    color: AppTheme
                                                        .primaryColor,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                  ),
                                                ),
                                              Text(
                                                m.fechaRealizado,
                                                style: const TextStyle(
                                                  color:
                                                      AppTheme.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.green
                                                    .withValues(alpha: 0.4)),
                                          ),
                                          child: const Text(
                                            'COMPLETADO',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_ios,
                                            size: 13,
                                            color: AppTheme.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

// ─── CHIP DE FILTRO ───────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF0369A1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? const Color(0xFF0369A1) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: activo ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight:
                activo ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── PANTALLA DE DETALLE ──────────────────────────────────────

class _DetalleMantenimientoScreen extends StatelessWidget {
  final MantenimientoHistorial m;

  const _DetalleMantenimientoScreen({required this.m});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Detalle del mantenimiento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.build_circle_outlined,
                        color: AppTheme.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.tallerNombre ?? 'Mantenimiento completado',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        if (m.vehiculoNombre != null)
                          Text(
                            m.vehiculoNombre!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500),
                          )
                        else
                          const Text(
                            'Realizado en taller',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 20),
              _CampoDetalle(
                icono: Icons.calendar_today,
                label: 'Fecha',
                valor: m.fechaRealizado,
              ),
              const SizedBox(height: 14),
              _CampoDetalle(
                icono: Icons.speed,
                label: 'Kilometraje',
                valor: '${m.kilometrajeRegistro} km',
              ),
              if (m.costo != null) ...[
                const SizedBox(height: 14),
                _CampoDetalle(
                  icono: Icons.attach_money,
                  label: 'Costo',
                  valor: 'Bs. ${m.costo!.toStringAsFixed(2)}',
                ),
              ],
              if (m.detalleTecnico != null &&
                  m.detalleTecnico!.isNotEmpty) ...[
                const SizedBox(height: 14),
                _CampoDetalle(
                  icono: Icons.build_outlined,
                  label: 'Detalle técnico',
                  valor: m.detalleTecnico!,
                ),
              ],
              if (m.problemasDetectados != null &&
                  m.problemasDetectados!.isNotEmpty) ...[
                const SizedBox(height: 14),
                _CampoDetalle(
                  icono: Icons.warning_amber_outlined,
                  label: 'Problemas detectados',
                  valor: m.problemasDetectados!,
                ),
              ],
              if (m.gravedadProblemas != null) ...[
                const SizedBox(height: 14),
                _CampoGravedad(gravedad: m.gravedadProblemas!),
              ],
              if (m.kmProximoMantenimiento != null) ...[
                const SizedBox(height: 14),
                _CampoDetalle(
                  icono: Icons.speed_outlined,
                  label: 'Km próximo mantenimiento',
                  valor: '${m.kmProximoMantenimiento} km',
                ),
              ],
              if (m.fechaProximoMantenimiento != null) ...[
                const SizedBox(height: 14),
                _CampoDetalle(
                  icono: Icons.event_outlined,
                  label: 'Fecha próximo mantenimiento',
                  valor: m.fechaProximoMantenimiento!,
                ),
              ],
              if (m.recomendaciones != null &&
                  m.recomendaciones!.isNotEmpty) ...[
                const SizedBox(height: 14),
                _CampoDetalle(
                  icono: Icons.notes,
                  label: 'Recomendaciones',
                  valor: m.recomendaciones!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── WIDGETS COMPARTIDOS ──────────────────────────────────────

class _CampoDetalle extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _CampoDetalle({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CampoGravedad extends StatelessWidget {
  final String gravedad;

  const _CampoGravedad({required this.gravedad});

  Color get _color {
    switch (gravedad.toLowerCase()) {
      case 'leve':
        return Colors.amber;
      case 'moderado':
        return Colors.orange;
      case 'grave':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_rounded, size: 18, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gravedad',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text(
                gravedad[0].toUpperCase() + gravedad.substring(1),
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
