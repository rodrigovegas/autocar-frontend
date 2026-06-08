import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../providers/educativo_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/educativo_model.dart';

Future<void> _abrirUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class EducativoScreen extends ConsumerStatefulWidget {
  const EducativoScreen({super.key});

  @override
  ConsumerState<EducativoScreen> createState() => _EducativoScreenState();
}

class _EducativoScreenState extends ConsumerState<EducativoScreen> {
  String _categoriaSeleccionada = 'Todos';

  final List<String> _categorias = [
    'Todos',
    'Aceite',
    'Frenos',
    'Neumáticos',
    'Batería',
    'Motor',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(educativoProvider.notifier).cargarContenidos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(educativoProvider);

    final contenidosFiltrados = _categoriaSeleccionada == 'Todos'
        ? state.contenidos
        : state.contenidos
            .where((c) => c.categoria
                .toLowerCase()
                .contains(_categoriaSeleccionada.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Contenido educativo'),
        automaticallyImplyLeading: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtros de categoría
                Container(
                  color: Colors.white,
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _categorias.length,
                    itemBuilder: (context, index) {
                      final cat = _categorias[index];
                      final seleccionada = cat == _categoriaSeleccionada;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _categoriaSeleccionada = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: seleccionada
                                ? AppTheme.primaryColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: seleccionada
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: seleccionada
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Lista de contenidos
                Expanded(
                  child: contenidosFiltrados.isEmpty
                      ? _EmptyState()
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(educativoProvider.notifier)
                              .cargarContenidos(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: contenidosFiltrados.length,
                            itemBuilder: (context, index) {
                              return _TarjetaContenido(
                                contenido: contenidosFiltrados[index],
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No hay contenido disponible',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los talleres publicarán contenido educativo próximamente',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TarjetaContenido extends StatelessWidget {
  final ContenidoEducativoModel contenido;

  const _TarjetaContenido({required this.contenido});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _DetalleContenidoScreen(contenido: contenido),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      contenido.categoria,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                contenido.titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                contenido.cuerpo.length > 100
                    ? '${contenido.cuerpo.substring(0, 100)}...'
                    : contenido.cuerpo,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalleContenidoScreen extends StatelessWidget {
  final ContenidoEducativoModel contenido;

  const _DetalleContenidoScreen({required this.contenido});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          contenido.categoria,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                contenido.categoria,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              contenido.titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            MarkdownBody(
              data: contenido.cuerpo,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 15, height: 1.6),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                listBullet: const TextStyle(fontSize: 15),
              ),
            ),
            if (contenido.urlVideo != null && contenido.urlVideo!.isNotEmpty) ...[
              const SizedBox(height: 24),
              ...contenido.urlVideo!.split(',').map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VideoWidget(url: url.trim()),
              )),
            ],
            if (contenido.urlImagen != null && contenido.urlImagen!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...contenido.urlImagen!.split(',').map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MediaCard(url: url.trim()),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoWidget extends StatelessWidget {
  final String url;
  const _VideoWidget({required this.url});

  String? _youtubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
    if (uri.host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ytId = _youtubeId(url);

    if (ytId != null) {
      final thumbUrl = 'https://img.youtube.com/vi/$ytId/hqdefault.jpg';
      return GestureDetector(
        onTap: () => _abrirUrl(url),
        child: SizedBox(
          width: double.infinity,
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: Image.network(
                    thumbUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.black87),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'YouTube',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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

    if (url.contains('res.cloudinary.com')) {
      return _VideoCloudinary(url: url);
    }
    return _MediaCard(url: url);
  }
}

class _VideoCloudinary extends StatefulWidget {
  final String url;
  const _VideoCloudinary({required this.url});

  @override
  State<_VideoCloudinary> createState() => _VideoCloudinaryState();
}

class _VideoCloudinaryState extends State<_VideoCloudinary> {
  late VideoPlayerController _controller;
  bool _iniciado = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _iniciado = true);
      }).catchError((_) {
        if (mounted) setState(() => _error = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return _MediaCard(url: widget.url);
    }
    if (!_iniciado) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          VideoProgressIndicator(_controller, allowScrubbing: true),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final String url;
  const _MediaCard({required this.url});

  bool get esPDF =>
      url.contains('.pdf') ||
      url.contains('/raw/upload/') ||
      url.contains('application/pdf');

  bool get esCloudinaryImagen =>
      url.contains('res.cloudinary.com') &&
      !esPDF &&
      (url.contains('/image/upload/') ||
       url.endsWith('.jpg') ||
       url.endsWith('.jpeg') ||
       url.endsWith('.png') ||
       url.endsWith('.webp'));

  @override
  Widget build(BuildContext context) {
    if (esCloudinaryImagen) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        final urlFinal = esPDF && url.contains('res.cloudinary.com')
            ? 'https://docs.google.com/viewer?url=${Uri.encodeComponent(url)}'
            : url;
        launchUrl(
          Uri.parse(urlFinal),
          mode: LaunchMode.externalApplication,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: esPDF ? Colors.orange[50] : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: esPDF ? Colors.orange[200]! : Colors.blue[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              esPDF ? Icons.picture_as_pdf : Icons.image,
              color: esPDF ? Colors.orange[700] : Colors.blue[700],
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    esPDF ? 'Ver PDF' : 'Ver imagen',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Toca para abrir',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}