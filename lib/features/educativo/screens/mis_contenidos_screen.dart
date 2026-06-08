import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/educativo_model.dart';
import 'publicar_contenido_screen.dart';

class MisContenidosScreen extends ConsumerStatefulWidget {
  const MisContenidosScreen({super.key});

  @override
  ConsumerState<MisContenidosScreen> createState() =>
      _MisContenidosScreenState();
}

class _MisContenidosScreenState extends ConsumerState<MisContenidosScreen> {
  bool _isLoading = false;
  List<ContenidoEducativoModel> _contenidos = [];
  String _filtroEstado = 'Todos';

  List<ContenidoEducativoModel> get _contenidosFiltrados {
    if (_filtroEstado == 'Todos') return _contenidos;
    return _contenidos.where((c) => c.estado == _filtroEstado.toLowerCase()).toList();
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().dio.get(
        '${ApiConstants.educativo}/taller',
      );
      setState(() {
        _contenidos = (response.data as List)
            .map((e) => ContenidoEducativoModel.fromJson(e))
            .toList();
      });
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar contenidos')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'publicado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'rechazado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis contenidos'),
        backgroundColor: const Color(0xFF15803D),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF15803D),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PublicarContenidoScreen(),
            ),
          );
          _cargar();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ['Todos', 'Publicado', 'Pendiente', 'Rechazado'].map((estado) {
                final seleccionado = _filtroEstado == estado;
                final colores = {
                  'Publicado': Colors.green,
                  'Pendiente': Colors.orange,
                  'Rechazado': Colors.red,
                  'Todos': const Color(0xFF15803D),
                };
                final color = colores[estado] ?? const Color(0xFF15803D);
                return GestureDetector(
                  onTap: () => setState(() => _filtroEstado = estado),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: seleccionado ? color : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: seleccionado ? color : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      estado,
                      style: TextStyle(
                        color: seleccionado ? Colors.white : color,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _contenidosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _filtroEstado == 'Todos'
                                  ? 'No has publicado contenido aún'
                                  : 'No hay contenidos ${_filtroEstado.toLowerCase()}s',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _contenidosFiltrados.length,
                          itemBuilder: (context, index) {
                            final c = _contenidosFiltrados[index];
                            final color = _colorEstado(c.estado);
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
                                        Expanded(
                                          child: Text(
                                            c.titulo,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                                color: color.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            c.estado.toUpperCase(),
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c.categoria,
                                      style: const TextStyle(
                                        color: Color(0xFF15803D),
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (c.informeIa != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.blue.withValues(alpha: 0.2)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.smart_toy,
                                                size: 14, color: Colors.blue),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                c.informeIa!,
                                                style: const TextStyle(
                                                    fontSize: 12, color: Colors.blue),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (c.motivoRechazo != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.red.withValues(alpha: 0.2)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.info_outline,
                                                size: 14, color: Colors.red),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                c.motivoRechazo!,
                                                style: const TextStyle(
                                                    fontSize: 12, color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
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