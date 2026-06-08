import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../reservas/screens/reservas_taller_screen.dart';
import '../../educativo/screens/mis_contenidos_screen.dart';
import '../../talleres/screens/disponibilidad_taller_screen.dart';
import '../../mantenimiento/screens/historial_taller_screen.dart';
import '../../talleres/screens/servicios_taller_screen.dart';

// ─────────────────────────────────────────────
// MODELO ESTADÍSTICAS
// ─────────────────────────────────────────────

class _Stats {
  final int pendientes;
  final int confirmadas;
  final int rechazadas;
  final int mantenimientos;
  final int clientes;

  const _Stats({
    required this.pendientes,
    required this.confirmadas,
    required this.rechazadas,
    required this.mantenimientos,
    required this.clientes,
  });

  factory _Stats.fromJson(Map<String, dynamic> j) => _Stats(
        pendientes: j['reservas_pendientes'] ?? 0,
        confirmadas: j['reservas_confirmadas'] ?? 0,
        rechazadas: j['reservas_rechazadas'] ?? 0,
        mantenimientos: j['mantenimientos_completados'] ?? 0,
        clientes: j['clientes_atendidos'] ?? 0,
      );
}

// ─────────────────────────────────────────────
// SHELL PRINCIPAL
// ─────────────────────────────────────────────

class HomeTallerScreen extends ConsumerStatefulWidget {
  const HomeTallerScreen({super.key});

  @override
  ConsumerState<HomeTallerScreen> createState() => _HomeTallerScreenState();
}

class _HomeTallerScreenState extends ConsumerState<HomeTallerScreen> {
  int _currentIndex = 0;

  final List<Widget> _pantallas = [
    const _HomeTab(),
    const ReservasTallerScreen(),
    const DisponibilidadTallerScreen(),
    const ServiciosTallerScreen(),
    const HistorialTallerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF15803D),
        unselectedItemColor: AppTheme.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: 'Horarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined),
            activeIcon: Icon(Icons.build),
            label: 'Servicios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HOME TAB CON ESTADÍSTICAS Y DRAWER
// ─────────────────────────────────────────────

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  static const verde = Color(0xFF15803D);

  _Stats? _stats;
  double? _calificacionPromedio;
  int _totalCalificaciones = 0;
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
      final api = ApiService();
      final results = await Future.wait([
        api.dio.get('/talleres/estadisticas'),
        api.dio.get('/talleres/mi-calificacion'),
      ]);
      setState(() {
        _stats = _Stats.fromJson(results[0].data);
        final cal = results[1].data;
        _calificacionPromedio = cal['promedio'] != null
            ? double.parse(cal['promedio'].toString())
            : null;
        _totalCalificaciones = cal['total_calificaciones'] ?? 0;
      });
    } on DioException catch (_) {
      setState(() => _errorStats = 'No se pudieron cargar las estadísticas');
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  void _navegar(Widget pantalla) {
    Navigator.pop(context); // cierra drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(authProvider).usuario;

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
                  colors: [verde, Color(0xFF166534)],
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
                    child: const Icon(Icons.store,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    usuario?.nombre ?? 'Taller',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Panel del taller',
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
                    icono: Icons.article,
                    titulo: 'Mis contenidos',
                    subtitulo: 'Ver mis publicaciones',
                    color: const Color(0xFFD97706),
                    onTap: () => _navegar(const MisContenidosScreen()),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Cerrar sesión',
                        style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      Navigator.pop(context);
                      await ref
                          .read(authProvider.notifier)
                          .cerrarSesion();
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
        title: const Text('AutoCar — Taller'),
        backgroundColor: verde,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ── Body ────────────────────────────────────────────────
      body: RefreshIndicator(
        onRefresh: _cargarEstadisticas,
        color: verde,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header con nombre del taller
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [verde, Color(0xFF166534)],
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
                      child: const Icon(Icons.store,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bienvenido',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          Text(
                            usuario?.nombre ?? 'Taller',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Estadísticas
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Resumen del taller',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        if (!_loadingStats)
                          GestureDetector(
                            onTap: _cargarEstadisticas,
                            child: const Icon(Icons.refresh,
                                size: 20, color: verde),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_loadingStats)
                      const SizedBox(
                        height: 200,
                        child: Center(
                            child: CircularProgressIndicator(
                                color: verde)),
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
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorStats!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 13)),
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
                          // Fila 1: reservas
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icono: Icons.hourglass_empty,
                                  valor: '${_stats!.pendientes}',
                                  etiqueta: 'Reservas\npendientes',
                                  color: const Color(0xFFD97706),
                                  fondo: const Color(0xFFFFFBEB),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icono: Icons.check_circle,
                                  valor: '${_stats!.confirmadas}',
                                  etiqueta: 'Reservas\nconfirmadas',
                                  color: const Color(0xFF15803D),
                                  fondo: const Color(0xFFF0FDF4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Fila 2
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icono: Icons.cancel,
                                  valor: '${_stats!.rechazadas}',
                                  etiqueta: 'Reservas\nrechazadas',
                                  color: const Color(0xFFDC2626),
                                  fondo: const Color(0xFFFEF2F2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icono: Icons.build_circle,
                                  valor: '${_stats!.mantenimientos}',
                                  etiqueta: 'Mantenimientos\ncompletados',
                                  color: const Color(0xFF0369A1),
                                  fondo: const Color(0xFFF0F9FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Fila 3: clientes (centrada)
                          _StatCard(
                            icono: Icons.people,
                            valor: '${_stats!.clientes}',
                            etiqueta: 'Clientes atendidos',
                            color: const Color(0xFF7C3AED),
                            fondo: const Color(0xFFF5F3FF),
                            ancha: true,
                          ),
                          const SizedBox(height: 12),
                          // Fila 4: calificación promedio
                          _StatCard(
                            icono: Icons.star,
                            valor: _calificacionPromedio != null
                                ? _calificacionPromedio!.toStringAsFixed(1)
                                : '—',
                            etiqueta: _calificacionPromedio != null
                                ? 'Calificación promedio · $_totalCalificaciones reseñas'
                                : 'Sin calificaciones aún',
                            color: const Color(0xFFB45309),
                            fondo: const Color(0xFFFFFBEB),
                            ancha: true,
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

class _StatCard extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;
  final Color fondo;
  final bool ancha;

  const _StatCard({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
    required this.fondo,
    this.ancha = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: ancha ? double.infinity : null,
      padding: EdgeInsets.all(ancha ? 16 : 16),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ancha
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(valor,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 1,
                        )),
                    const SizedBox(height: 2),
                    Text(etiqueta,
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withValues(alpha: 0.75),
                        )),
                  ],
                ),
              ],
            )
          : Column(
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
                Text(valor,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1,
                    )),
                const SizedBox(height: 4),
                Text(etiqueta,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.75),
                      height: 1.3,
                    )),
              ],
            ),
    );
    return content;
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
      title: Text(titulo,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitulo,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      onTap: onTap,
    );
  }
}