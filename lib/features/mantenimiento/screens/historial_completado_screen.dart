import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class MantenimientoHistorial {
  final String id;
  final String vehiculoId;
  final String tallerId;
  final int kilometrajeRegistro;
  final String fechaRealizado;
  final String? observaciones;
  final String? fechaRegistro;

  MantenimientoHistorial({
    required this.id,
    required this.vehiculoId,
    required this.tallerId,
    required this.kilometrajeRegistro,
    required this.fechaRealizado,
    this.observaciones,
    this.fechaRegistro,
  });

  factory MantenimientoHistorial.fromJson(Map<String, dynamic> json) {
    return MantenimientoHistorial(
      id: json['id'].toString(),
      vehiculoId: json['vehiculo_id'].toString(),
      tallerId: json['taller_id'].toString(),
      kilometrajeRegistro: json['kilometraje_registro'],
      fechaRealizado: json['fecha_realizado'],
      observaciones: json['observaciones'],
      fechaRegistro: json['fecha_registro'],
    );
  }
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

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().dio.get(
        '${ApiConstants.mantenimientos}/historial/usuario',
      );
      setState(() {
        _historial = (response.data as List)
            .map((e) => MantenimientoHistorial.fromJson(e))
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de mantenimientos'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historial.isEmpty
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
                            fontSize: 16, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aquí aparecerán los mantenimientos\ncompletados en talleres',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _historial.length,
                    itemBuilder: (context, index) {
                      final m = _historial[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.build,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Mantenimiento completado',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          m.fechaRealizado,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
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
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              _InfoFila(
                                icono: Icons.speed,
                                label: 'Kilometraje',
                                valor: '${m.kilometrajeRegistro} km',
                              ),
                              const SizedBox(height: 6),
                              _InfoFila(
                                icono: Icons.store,
                                label: 'Taller',
                                valor: m.tallerId.substring(0, 8) + '...',
                              ),
                              if (m.observaciones != null &&
                                  m.observaciones!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _InfoFila(
                                  icono: Icons.notes,
                                  label: 'Observaciones',
                                  valor: m.observaciones!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _InfoFila extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _InfoFila({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}