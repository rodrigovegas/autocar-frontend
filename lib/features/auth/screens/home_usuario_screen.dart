import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../vehiculos/screens/vehiculos_screen.dart';
import '../../talleres/screens/mapa_talleres_screen.dart';
import '../../asistente/screens/asistente_screen.dart';
import '../../reservas/screens/mis_reservas_screen.dart';
import '../../educativo/screens/educativo_screen.dart';
import '../../mantenimiento/screens/historial_completado_screen.dart';

// ─────────────────────────────────────────────
// MODELO ESTADÍSTICAS USUARIO
// ─────────────────────────────────────────────

class _StatsUsuario {
  final int vehiculosRegistrados;
  final int reservasActivas;
  final int mantenimientosCompletados;
  final String? proximoMantenimiento;

  const _StatsUsuario({
    required this.vehiculosRegistrados,
    required this.reservasActivas,
    required this.mantenimientosCompletados,
    this.proximoMantenimiento,
  });

  factory _StatsUsuario.fromJson(Map<String, dynamic> j) => _StatsUsuario(
        vehiculosRegistrados: j['vehiculos_registrados'] ?? 0,
        reservasActivas: j['reservas_activas'] ?? 0,
        mantenimientosCompletados: j['mantenimientos_completados'] ?? 0,
        proximoMantenimiento: j['proximo_mantenimiento'],
      );
}

// ─────────────────────────────────────────────
// SHELL PRINCIPAL (BottomNavigationBar)
// ─────────────────────────────────────────────

class HomeUsuarioScreen extends ConsumerStatefulWidget {
  const HomeUsuarioScreen({super.key});

  @override
  ConsumerState<HomeUsuarioScreen> createState() => _HomeUsuarioScreenState();
}

class _HomeUsuarioScreenState extends ConsumerState<HomeUsuarioScreen> {
  int _currentIndex = 0;

  final List<Widget> _pantallas = [
    const _HomeTab(),
    const MisReservasScreen(),
    const MapaTalleresScreen(),
    const EducativoScreen(),
    const AsistenteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.primaryColor,
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
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Talleres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Educativo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'Asistente',
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
  _StatsUsuario? _stats;
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
      final response = await ApiService().dio.get('/usuarios/estadisticas');
      setState(() => _stats = _StatsUsuario.fromJson(response.data));
    } on DioException catch (_) {
      setState(() => _errorStats = 'No se pudieron cargar las estadísticas');
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  void _navegar(Widget pantalla) {
    Navigator.pop(context); // cierra drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(authProvider).usuario;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                  ],
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
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    usuario?.nombre ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Mi cuenta',
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
                    icono: Icons.directions_car,
                    titulo: 'Mis vehículos',
                    subtitulo: 'Gestiona tus vehículos registrados',
                    color: AppTheme.primaryColor,
                    onTap: () => _navegar(const VehiculosScreen()),
                  ),
                  _DrawerItem(
                    icono: Icons.history,
                    titulo: 'Historial de mantenimiento',
                    subtitulo: 'Ver mantenimientos completados',
                    color: const Color(0xFF0369A1),
                    onTap: () =>
                        _navegar(const HistorialCompletadoScreen()),
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
        title: const Text('AutoCar'),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ── Body ────────────────────────────────────────────────
      body: RefreshIndicator(
        onRefresh: _cargarEstadisticas,
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header gradiente ──────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
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
                      child: const Icon(Icons.person,
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
                            usuario?.nombre ?? 'Usuario',
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

              // ── Estadísticas ──────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mi resumen',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        if (!_loadingStats)
                          GestureDetector(
                            onTap: _cargarEstadisticas,
                            child: Icon(Icons.refresh,
                                size: 20,
                                color: AppTheme.primaryColor),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_loadingStats)
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryColor),
                        ),
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
                          // Fila 1
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icono: Icons.directions_car,
                                  valor:
                                      '${_stats!.vehiculosRegistrados}',
                                  etiqueta: 'Vehículos\nregistrados',
                                  color: AppTheme.primaryColor,
                                  fondo: const Color(0xFFEFF6FF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icono: Icons.calendar_today,
                                  valor: '${_stats!.reservasActivas}',
                                  etiqueta: 'Reservas\nactivas',
                                  color: const Color(0xFF0369A1),
                                  fondo: const Color(0xFFF0F9FF),
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
                                  icono: Icons.build_circle,
                                  valor:
                                      '${_stats!.mantenimientosCompletados}',
                                  etiqueta: 'Mantenimientos\ncompletados',
                                  color: const Color(0xFF15803D),
                                  fondo: const Color(0xFFF0FDF4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icono: Icons.event,
                                  valor: _stats!.proximoMantenimiento ??
                                      'Sin recordatorios',
                                  etiqueta: 'Próximo\nmantenimiento',
                                  color: const Color(0xFFB45309),
                                  fondo: const Color(0xFFFFFBEB),
                                  valorPequeno:
                                      _stats!.proximoMantenimiento !=
                                          null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),
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
  final bool valorPequeno;

  const _StatCard({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
    required this.fondo,
    this.valorPequeno = false,
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
              fontSize: valorPequeno ? 13 : 28,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
      title: Text(titulo,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitulo,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      onTap: onTap,
    );
  }
}
