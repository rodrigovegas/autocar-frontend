import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
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
                p: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    height: 1.6),
                strong: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
                h2: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                h3: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (contenido.urlVideo != null) ...[
              const SizedBox(height: 24),
              _VideoWidget(url: contenido.urlVideo!),
            ],
            if (contenido.urlImagen != null) ...[
              const SizedBox(height: 12),
              _MediaCard(
                icon: contenido.urlImagen!.toLowerCase().contains('pdf')
                    ? Icons.picture_as_pdf
                    : Icons.image,
                iconColor: contenido.urlImagen!.toLowerCase().contains('pdf')
                    ? Colors.orange
                    : Colors.blue,
                label: 'Ver archivo adjunto',
                url: contenido.urlImagen!,
              ),
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

    return _MediaCard(
      icon: Icons.play_circle,
      iconColor: Colors.red,
      label: 'Ver video',
      url: url,
    );
  }
}

class _MediaCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String url;

  const _MediaCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _abrirUrl(url),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      url,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 16, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}