import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

class UsuarioAdminModel {
  final String id;
  final String nombre;
  final String correo;
  final bool activo;

  UsuarioAdminModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.activo,
  });

  factory UsuarioAdminModel.fromJson(Map<String, dynamic> json) {
    return UsuarioAdminModel(
      id: json['id'].toString(),
      nombre: json['nombre_completo'] ?? json['nombre'] ?? 'Sin nombre',
      correo: json['correo'],
      activo: json['activo'],
    );
  }
}

class UsuariosAdminScreen extends StatefulWidget {
  const UsuariosAdminScreen({super.key});

  @override
  State<UsuariosAdminScreen> createState() => _UsuariosAdminScreenState();
}

class _UsuariosAdminScreenState extends State<UsuariosAdminScreen> {
  bool _isLoading = false;
  List<UsuarioAdminModel> _usuarios = [];
  List<UsuarioAdminModel> _filtrados = [];
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
      final response = await ApiService().dio.get('/admin/usuarios');
      final lista = (response.data as List)
          .map((e) => UsuarioAdminModel.fromJson(e))
          .toList();
      setState(() {
        _usuarios = lista;
        _filtrados = lista;
      });
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar usuarios')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrar() {
    final query = _busquedaController.text.toLowerCase();
    setState(() {
      _filtrados = _usuarios.where((u) {
        return u.nombre.toLowerCase().contains(query) ||
            u.correo.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _toggleEstado(UsuarioAdminModel usuario) async {
    final accion = usuario.activo ? 'desactivar' : 'activar';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${accion[0].toUpperCase()}${accion.substring(1)} usuario'),
        content: Text('¿Deseas $accion a "${usuario.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: usuario.activo
                  ? Colors.red
                  : const Color(0xFF7C3AED),
            ),
            child: Text(
              accion[0].toUpperCase() + accion.substring(1),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ApiService().dio.patch('/admin/usuarios/${usuario.id}/$accion');
        await _cargar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuario ${accion}do correctamente'),
              backgroundColor: usuario.activo ? Colors.orange : Colors.green,
            ),
          );
        }
      } on DioException catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al $accion el usuario')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
        backgroundColor: const Color(0xFF7C3AED),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o correo...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7C3AED)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED)),
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
                    '${_filtrados.length} usuario${_filtrados.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                ? const Center(
                    child: Text(
                      'Sin usuarios',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargar,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtrados.length,
                      itemBuilder: (context, index) {
                        final u = _filtrados[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: u.activo
                                      ? const Color(
                                          0xFF7C3AED,
                                        ).withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: u.activo
                                        ? const Color(0xFF7C3AED)
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        u.correo,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: u.activo
                                              ? Colors.green.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.red.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          u.activo ? 'Activo' : 'Inactivo',
                                          style: TextStyle(
                                            color: u.activo
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: u.activo,
                                  onChanged: (_) => _toggleEstado(u),
                                  activeThumbColor: const Color(0xFF7C3AED),
                                ),
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
