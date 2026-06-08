import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
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
  final List<TextEditingController> _videoControllers = [TextEditingController()];
  final List<bool> _videosValidos = [false];
  String _categoriaSeleccionada = 'Aceite';
  bool _isLoading = false;
  final List<File> _archivosSeleccionados = [];
  final List<String> _nombresArchivos = [];
  final List<String?> _urlsCloudinary = [];
  final List<bool> _subiendoArchivos = [];

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
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _agregarArchivo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null) {
      final index = _archivosSeleccionados.length;
      setState(() {
        _archivosSeleccionados.add(File(result.files.single.path!));
        _nombresArchivos.add(result.files.single.name);
        _urlsCloudinary.add(null);
        _subiendoArchivos.add(true);
      });
      await _subirArchivoEnIndice(index);
    }
  }

  void _eliminarArchivo(int index) {
    setState(() {
      _archivosSeleccionados.removeAt(index);
      _nombresArchivos.removeAt(index);
      _urlsCloudinary.removeAt(index);
      _subiendoArchivos.removeAt(index);
    });
  }

  Future<void> _subirArchivoEnIndice(int index) async {
    try {
      final archivo = _archivosSeleccionados[index];
      final nombre = _nombresArchivos[index];
      final extension = nombre.split('.').last.toLowerCase();
      final mimeTypes = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
        'pdf': 'application/pdf',
      };
      final mimeType = mimeTypes[extension] ?? 'application/octet-stream';
      final partes = mimeType.split('/');

      final formData = FormData.fromMap({
        'archivo': await MultipartFile.fromFile(
          archivo.path,
          filename: nombre,
          contentType: DioMediaType(partes[0], partes[1]),
        ),
      });

      final response = await ApiService().dio.post(
        ApiConstants.educativoUpload,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (mounted) {
        setState(() {
          _urlsCloudinary[index] = response.data['url'];
          _subiendoArchivos[index] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _subiendoArchivos[index] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir archivo: $e')),
        );
      }
    }
  }

  void _validarVideo(int index, String url) {
    final esValida = url.contains('youtube.com/watch') || url.contains('youtu.be/');
    setState(() => _videosValidos[index] = esValida);
  }

  void _agregarVideo() {
    setState(() {
      _videoControllers.add(TextEditingController());
      _videosValidos.add(false);
    });
  }

  void _eliminarVideo(int index) {
    setState(() {
      _videoControllers[index].dispose();
      _videoControllers.removeAt(index);
      _videosValidos.removeAt(index);
    });
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_subiendoArchivos.any((s) => s)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperá a que terminen de subir los archivos')),
      );
      return;
    }
    if (_videoControllers.any((c) => c.text.isNotEmpty) &&
        !_videosValidos.any((v) => v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ningún link de YouTube es válido')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      await apiService.dio.post(
        '${ApiConstants.educativo}/',
        data: {
          'titulo': _tituloController.text.trim(),
          'cuerpo': _cuerpoController.text.trim(),
          'categoria': _categoriaSeleccionada,
          'url_imagen': _urlsCloudinary.whereType<String>().isNotEmpty
              ? _urlsCloudinary.whereType<String>().join(',')
              : null,
          'url_video': () {
            final urlsVideo = _videoControllers
                .asMap()
                .entries
                .where((e) => _videosValidos[e.key])
                .map((e) => e.value.text.trim())
                .toList();
            return urlsVideo.isNotEmpty ? urlsVideo.join(',') : null;
          }(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contenido enviado. Será revisado por el administrador.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  '💡 Formato: **negrita**, - elemento de lista, ## título',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Imágenes y PDFs (opcional)',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ..._nombresArchivos.asMap().entries.map((entry) {
                    final i = entry.key;
                    final nombre = entry.value;
                    final subiendo = _subiendoArchivos[i];
                    final urlLista = _urlsCloudinary[i];
                    final esPDF = nombre.toLowerCase().endsWith('.pdf');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            esPDF ? Icons.picture_as_pdf : Icons.image,
                            color: esPDF ? Colors.orange : Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nombre,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (subiendo)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              urlLista != null ? Icons.check_circle : Icons.error,
                              color: urlLista != null ? Colors.green : Colors.red,
                              size: 18,
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _eliminarArchivo(i),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  }),
                  OutlinedButton.icon(
                    onPressed: _agregarArchivo,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar imagen o PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Videos de YouTube (opcional)',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ..._videoControllers.asMap().entries.map((entry) {
                    final i = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _videoControllers[i],
                              onChanged: (val) => _validarVideo(i, val),
                              decoration: InputDecoration(
                                labelText: 'Link de YouTube ${i + 1}',
                                hintText: 'https://youtube.com/watch?v=...',
                                prefixIcon: const Icon(Icons.play_circle_outline),
                                suffixIcon: _videosValidos[i]
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                                border: const OutlineInputBorder(),
                                errorText: _videoControllers[i].text.isNotEmpty && !_videosValidos[i]
                                    ? 'Link inválido'
                                    : null,
                              ),
                            ),
                          ),
                          if (_videoControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _eliminarVideo(i),
                            ),
                        ],
                      ),
                    );
                  }),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await launchUrl(
                            Uri.parse('https://www.youtube.com'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        icon: const Icon(Icons.open_in_new, color: Colors.red),
                        label: const Text('Abrir YouTube'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _agregarVideo,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar video'),
                      ),
                    ],
                  ),
                ],
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