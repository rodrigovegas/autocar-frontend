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
      appBar: AppBar(
        title: const Text('Historial de mantenimientos'),
        backgroundColor: const Color(0xFF15803D),
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
                    color: Color(0xFF15803D)),
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
                  borderSide:
                      const BorderSide(color: Color(0xFF15803D)),
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
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtrados.length,
                          itemBuilder: (context, index) {
                            final m = _filtrados[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF15803D)
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.directions_car,
                                            color: Color(0xFF15803D),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m.vehiculo,
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              if (m.placa != null)
                                                Text(
                                                  'Placa: ${m.placa}',
                                                  style: const TextStyle(
                                                    color: Color(
                                                        0xFF15803D),
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                  ),
                                                ),
                                              Text(
                                                m.fechaRealizado,
                                                style: const TextStyle(
                                                  color: AppTheme
                                                      .textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.green
                                                    .withValues(
                                                        alpha: 0.3)),
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
                                    const SizedBox(height: 10),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(Icons.speed,
                                            size: 14,
                                            color: AppTheme.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${m.kilometrajeRegistro} km',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color:
                                                  AppTheme.textSecondary),
                                        ),
                                        if (m.color != null) ...[
                                          const SizedBox(width: 16),
                                          const Icon(
                                              Icons.color_lens_outlined,
                                              size: 14,
                                              color:
                                                  AppTheme.textSecondary),
                                          const SizedBox(width: 6),
                                          Text(
                                            m.color!,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color:
                                                    AppTheme.textSecondary),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (m.observaciones != null &&
                                        m.observaciones!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.notes,
                                              size: 14,
                                              color:
                                                  AppTheme.textSecondary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              m.observaciones!,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme
                                                      .textSecondary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
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