import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class MantenimientoTallerModel {
  final String id;
  final String fechaRealizado;
  final int kilometrajeRegistro;
  final String? observaciones;
  final double? costo;
  final String? detalleTecnico;
  final String? problemasDetectados;
  final String? gravedadProblemas;
  final int? kmProximoMantenimiento;
  final String? fechaProximoMantenimiento;
  final String? recomendaciones;
  final String marca;
  final String modelo;
  final int anio;
  final String? placa;
  final String? color;

  MantenimientoTallerModel({
    required this.id,
    required this.fechaRealizado,
    required this.kilometrajeRegistro,
    this.observaciones,
    this.costo,
    this.detalleTecnico,
    this.problemasDetectados,
    this.gravedadProblemas,
    this.kmProximoMantenimiento,
    this.fechaProximoMantenimiento,
    this.recomendaciones,
    required this.marca,
    required this.modelo,
    required this.anio,
    this.placa,
    this.color,
  });

  factory MantenimientoTallerModel.fromJson(Map<String, dynamic> json) {
    return MantenimientoTallerModel(
      id: json['id'],
      fechaRealizado: json['fecha_realizado'],
      kilometrajeRegistro: json['kilometraje_registro'],
      observaciones: json['observaciones'],
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
      marca: json['marca'],
      modelo: json['modelo'],
      anio: json['anio'],
      placa: json['placa'],
      color: json['color'],
    );
  }

  String get vehiculo => '$marca $modelo $anio';
}

class HistorialTallerScreen extends StatefulWidget {
  const HistorialTallerScreen({super.key});

  @override
  State<HistorialTallerScreen> createState() => _HistorialTallerScreenState();
}

class _HistorialTallerScreenState extends State<HistorialTallerScreen> {
  bool _isLoading = false;
  List<MantenimientoTallerModel> _todos = [];
  List<MantenimientoTallerModel> _filtrados = [];
  final _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
    _busquedaController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().dio.get(
        '${ApiConstants.mantenimientos}/historial/taller',
      );
      final lista = (response.data as List)
          .map((e) => MantenimientoTallerModel.fromJson(e))
          .toList();
      setState(() {
        _todos = lista;
        _filtrados = lista;
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

  void _filtrar() {
    final query = _busquedaController.text.toLowerCase();
    setState(() {
      _filtrados = _todos.where((m) {
        return m.vehiculo.toLowerCase().contains(query) ||
            m.marca.toLowerCase().contains(query) ||
            m.modelo.toLowerCase().contains(query) ||
            (m.placa?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Historial de mantenimientos'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar por placa, marca o modelo...',
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.primaryColor),
                suffixIcon: _busquedaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaController.clear();
                          _filtrar();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${_filtrados.length} registro${_filtrados.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.build_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _busquedaController.text.isEmpty
                                  ? 'Sin mantenimientos registrados'
                                  : 'Sin resultados para "${_busquedaController.text}"',
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtrados.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final m = _filtrados[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.05),
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
                                        _DetalleTallerScreen(m: m),
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
                                              m.vehiculo,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
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

// ─── PANTALLA DE DETALLE ──────────────────────────────────────

class _DetalleTallerScreen extends StatelessWidget {
  final MantenimientoTallerModel m;

  const _DetalleTallerScreen({required this.m});

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
              // Header
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mantenimiento completado',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Registro del taller',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
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
                icono: Icons.directions_car_outlined,
                label: 'Vehículo',
                valor: m.vehiculo,
              ),
              if (m.placa != null) ...[
                const SizedBox(height: 14),
                _CampoDetalle(
                  icono: Icons.confirmation_number_outlined,
                  label: 'Placa',
                  valor: m.placa!,
                ),
              ],
              if (m.color != null) ...[
                const SizedBox(height: 14),
                _CampoDetalle(
                  icono: Icons.color_lens_outlined,
                  label: 'Color',
                  valor: m.color!,
                ),
              ],
              const SizedBox(height: 14),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
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
