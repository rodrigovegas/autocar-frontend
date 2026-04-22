import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class PublicarContenidoScreen extends ConsumerStatefulWidget {
  const PublicarContenidoScreen({super.key});

  @override
  ConsumerState<PublicarContenidoScreen> createState() =>
      _PublicarContenidoScreenState();
}

class _PublicarContenidoScreenState
    extends ConsumerState<PublicarContenidoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _cuerpoController = TextEditingController();
  final _urlVideoController = TextEditingController();
  final _urlImagenController = TextEditingController();
  String _categoriaSeleccionada = 'Aceite';
  bool _isLoading = false;

  final List<String> _categorias = [
    'Aceite',
    'Frenos',
    'Neumáticos',
    'Batería',
    'Motor',
    'General',
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _cuerpoController.dispose();
    _urlVideoController.dispose();
    _urlImagenController.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      await apiService.dio.post(
        '${ApiConstants.educativo}/',
        data: {
          'titulo': _tituloController.text.trim(),
          'cuerpo': _cuerpoController.text.trim(),
          'categoria': _categoriaSeleccionada,
          'url_video': _urlVideoController.text.trim().isEmpty ? null : _urlVideoController.text.trim(),
          'url_imagen': _urlImagenController.text.trim().isEmpty ? null : _urlImagenController.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Contenido enviado. Será revisado por el administrador.'),
            backgroundColor: Colors.green,
          ),
        );
        _tituloController.clear();
        _cuerpoController.clear();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.response?.data['detail'] ?? 'Error al publicar'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text('Publicar contenido educativo'),
        backgroundColor: const Color(0xFF15803D),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'El contenido será validado por IA y revisado por el administrador antes de publicarse.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              const Text('Categoría',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _categorias
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _categoriaSeleccionada = v!),
              ),
              const SizedBox(height: 16),
              const Text('Título',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  hintText: 'Ej: ¿Cada cuánto cambiar el aceite?',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'El título es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('Contenido',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cuerpoController,
                decoration: InputDecoration(
                  hintText:
                      'Escribe el contenido educativo aquí...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 10,
                validator: (v) => v == null || v.length < 50
                    ? 'El contenido debe tener al menos 50 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlVideoController,
                decoration: InputDecoration(
                  labelText: 'Link de video (opcional)',
                  hintText: 'Ej: https://youtube.com/watch?v=...',
                  prefixIcon: const Icon(Icons.play_circle_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _urlImagenController,
                decoration: InputDecoration(
                  labelText: 'Link de imagen o PDF (opcional)',
                  hintText: 'Ej: https://drive.google.com/...',
                  prefixIcon: const Icon(Icons.attach_file_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Puedes usar Google Drive, Dropbox u otro servicio para compartir el enlace',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _publicar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : const Text(
                          'Enviar para revisión',
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