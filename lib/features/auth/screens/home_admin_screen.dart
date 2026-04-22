import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../admin/screens/talleres_admin_screen.dart';
import '../../admin/screens/usuarios_admin_screen.dart';
import '../../admin/screens/contenidos_admin_screen.dart';
import '../../admin/screens/especialidades_admin_screen.dart';
import '../../admin/screens/tipos_mantenimiento_admin_screen.dart';

// ─────────────────────────────────────────────
// MODELO DE ESTADÍSTICAS
// ─────────────────────────────────────────────

class _EstadisticasModel {
  final int totalUsuarios;
  final int talleresActivos;
  final int reservasMes;
  final int mantenimientosCompletados;

  const _EstadisticasModel({
    required this.totalUsuarios,
    required this.talleresActivos,
    required this.reservasMes,
    required this.mantenimientosCompletados,
  });

  factory _EstadisticasModel.fromJson(Map<String, dynamic> json) {
    return _EstadisticasModel(
      totalUsuarios: json['total_usuarios'] ?? 0,
      talleresActivos: json['talleres_activos'] ?? 0,
      reservasMes: json['reservas_mes'] ?? 0,
      mantenimientosCompletados: json['mantenimientos_completados'] ?? 0,
    );
  }
}

// ─────────────────────────────────────────────
// SHELL PRINCIPAL (navbar)
// ─────────────────────────────────────────────

class HomeAdminScreen extends ConsumerStatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  ConsumerState<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends ConsumerState<HomeAdminScreen> {
  int _currentIndex = 0;

  final List<Widget> _pantallas = [
    const _HomeTab(),
    const TalleresAdminScreen(),
    const UsuariosAdminScreen(),
    const ContenidosAdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF7C3AED),
        unselectedItemColor: AppTheme.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Talleres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'Contenidos',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB HOME CON ESTADÍSTICAS Y DRAWER
// ─────────────────────────────────────────────

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  static const morado = Color(0xFF7C3AED);

  _EstadisticasModel? _stats;
  bool _loadingStats = true;
  String? _errorStats;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() {
      _loadingStats = true;
      _errorStats = null;
    });
    try {
      final response = await ApiService().dio.get('/admin/estadisticas');
      setState(() {
        _stats = _EstadisticasModel.fromJson(response.data);
      });
    } on DioException catch (_) {
      setState(() => _errorStats = 'No se pudieron cargar las estadísticas');
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  String _nombreMes(int mes) {
    const meses = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return meses[mes];
  }

  void _navegar(Widget pantalla) {
    Navigator.pop(context); // cierra drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final mesActual = _nombreMes(DateTime.now().month);

    return Scaffold(
      // ── Drawer ─────────────────────────────────────────────
      drawer: Drawer(
        child: Column(
          children: [
            // Header del drawer
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 20,
                20,
                24,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [morado, Color(0xFF6D28D9)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Administrador',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Panel de control',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Items del drawer
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icono: Icons.build,
                    titulo: 'Especialidades',
                    subtitulo: 'Gestionar especialidades de talleres',
                    color: const Color(0xFF0369A1),
                    onTap: () => _navegar(const EspecialidadesAdminScreen()),
                  ),
                  _DrawerItem(
                    icono: Icons.pending_actions,
                    titulo: 'Propuestas de tipos',
                    subtitulo: 'Revisar tipos de mantenimiento propuestos',
                    color: const Color(0xFF15803D),
                    onTap: () =>
                        _navegar(const TiposMantenimientoAdminScreen()),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(authProvider.notifier).cerrarSesion();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── AppBar ──────────────────────────────────────────────
      appBar: AppBar(
        title: const Text('AutoCar — Admin'),
        backgroundColor: morado,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).cerrarSesion();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),

      // ── Body ────────────────────────────────────────────────
      body: RefreshIndicator(
        onRefresh: _cargarEstadisticas,
        color: morado,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [morado, Color(0xFF6D28D9)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panel de administración',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          'AutoCar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Resumen del sistema',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_loadingStats)
                          GestureDetector(
                            onTap: _cargarEstadisticas,
                            child: const Icon(
                              Icons.refresh,
                              size: 20,
                              color: morado,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_loadingStats)
                      const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorStats != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorStats!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _cargarEstadisticas,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _TarjetaStat(
                                  icono: Icons.people,
                                  valor: '${_stats!.totalUsuarios}',
                                  etiqueta: 'Usuarios\nregistrados',
                                  color: const Color(0xFF7C3AED),
                                  fondo: const Color(0xFFF5F3FF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TarjetaStat(
                                  icono: Icons.store,
                                  valor: '${_stats!.talleresActivos}',
                                  etiqueta: 'Talleres\nactivos',
                                  color: const Color(0xFF15803D),
                                  fondo: const Color(0xFFF0FDF4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _TarjetaStat(
                                  icono: Icons.calendar_month,
                                  valor: '${_stats!.reservasMes}',
                                  etiqueta: 'Reservas en\n$mesActual',
                                  color: const Color(0xFF0369A1),
                                  fondo: const Color(0xFFF0F9FF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TarjetaStat(
                                  icono: Icons.build_circle,
                                  valor: '${_stats!.mantenimientosCompletados}',
                                  etiqueta: 'Mantenimientos\ncompletados',
                                  color: const Color(0xFFB45309),
                                  fondo: const Color(0xFFFFFBEB),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TARJETA DE ESTADÍSTICA
// ─────────────────────────────────────────────

class _TarjetaStat extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;
  final Color fondo;

  const _TarjetaStat({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
    required this.fondo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ITEM DEL DRAWER
// ─────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, color: color, size: 20),
      ),
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitulo,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      onTap: onTap,
    );
  }
}
