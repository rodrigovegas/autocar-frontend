import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

enum _SplashEstado { verificando, errorRed }

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  _SplashEstado _estado = _SplashEstado.verificando;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    if (mounted) setState(() => _estado = _SplashEstado.verificando);
    debugPrint('Splash: verificando sesión...'); // TODO: remover en producción

    try {
      // El delay mínimo arranca en paralelo con la lógica de verificación
      final delayMinimo = Future<void>.delayed(const Duration(milliseconds: 800));

      // Cargar el token en los headers de Dio para que las llamadas siguientes lo incluyan
      await _apiService.loadTokenFromStorage();

      // Comprobar si existe un token guardado
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        debugPrint('Splash: sin token guardado, navegando a bienvenida...'); // TODO: remover en producción
        await delayMinimo;
        _navegarA('/bienvenida');
        return;
      }

      // Obtener el rol guardado en sesión
      final userData = await _apiService.getUserData();
      final rol = userData['role'] ?? '';

      // Datos de sesión corruptos o rol desconocido → limpiar y empezar de nuevo
      if (rol.isEmpty || !_esRolConocido(rol)) {
        debugPrint('Splash: rol desconocido ("$rol"), limpiando sesión...'); // TODO: remover en producción
        await ref.read(authProvider.notifier).cerrarSesion();
        await delayMinimo;
        _navegarA('/bienvenida');
        return;
      }

      debugPrint('Splash: token encontrado, validando con backend (rol: $rol)...'); // TODO: remover en producción

      // Validar token contra el backend y obtener la ruta de destino.
      // Esperamos tanto el resultado de la validación como el delay mínimo.
      final rutaDestino = await _validarTokenConBackend(rol);
      await delayMinimo;

      debugPrint('Splash: navegando a $rutaDestino...'); // TODO: remover en producción
      _navegarA(rutaDestino);

    } on DioException catch (e) {
      if (_esErrorDeRed(e)) {
        debugPrint('Splash: error de red, mostrando reintentar...'); // TODO: remover en producción
        if (mounted) setState(() => _estado = _SplashEstado.errorRed);
      } else {
        // Error HTTP inesperado fuera del switch de roles
        debugPrint('Splash: error HTTP inesperado (${e.response?.statusCode}), limpiando sesión...'); // TODO: remover en producción
        await ref.read(authProvider.notifier).cerrarSesion();
        _navegarA('/bienvenida');
      }
    } catch (e) {
      debugPrint('Splash: error inesperado ($e), limpiando sesión...'); // TODO: remover en producción
      await ref.read(authProvider.notifier).cerrarSesion();
      _navegarA('/bienvenida');
    }
  }

  /// Llama al endpoint de validación correspondiente al rol.
  /// Devuelve la ruta de destino si el token es válido.
  /// Devuelve '/bienvenida' si el backend rechaza el token (401 / 403).
  /// Relanza DioException si es un error de red para que el caller lo maneje.
  Future<String> _validarTokenConBackend(String rol) async {
    try {
      switch (rol) {
        case 'usuario':
          await _apiService.dio.get('/usuarios/estadisticas');
          debugPrint('Splash: token válido, navegando a home_usuario...'); // TODO: remover en producción
          return '/home-usuario';

        case 'taller':
          await _apiService.dio.get('/talleres/perfil');
          debugPrint('Splash: token válido, navegando a home_taller...'); // TODO: remover en producción
          return '/home-taller';

        case 'administrador':
          await _apiService.dio.get('/admin/estadisticas');
          debugPrint('Splash: token válido, navegando a home_admin...'); // TODO: remover en producción
          return '/home-admin';

        default:
          return '/bienvenida';
      }
    } on DioException catch (e) {
      // Error de red: relanzar para que _verificarSesion muestre el botón de reintentar
      if (_esErrorDeRed(e)) rethrow;

      // Error HTTP (401 token expirado, 403 cuenta no activa, etc.) → sesión inválida
      debugPrint('Splash: token inválido (${e.response?.statusCode}), limpiando sesión...'); // TODO: remover en producción
      await ref.read(authProvider.notifier).cerrarSesion();
      return '/bienvenida';
    }
  }

  bool _esRolConocido(String rol) =>
      rol == 'usuario' || rol == 'taller' || rol == 'administrador';

  // Un error "de red" es cualquier error sin respuesta HTTP del servidor
  bool _esErrorDeRed(DioException e) => e.response == null;

  void _navegarA(String ruta) {
    if (mounted) Navigator.pushReplacementNamed(context, ruta);
  }

  @override
  Widget build(BuildContext context) {
    // Durante la verificación no permitir cerrar accidentalmente con el botón atrás.
    // En estado de error de red sí se permite salir de la app.
    return PopScope(
      canPop: _estado == _SplashEstado.errorRed,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _estado == _SplashEstado.verificando
                  ? _buildVerificando()
                  : _buildErrorRed(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificando() {
    return Column(
      key: const ValueKey('verificando'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // TODO: reemplazar con el logo real de AutoCar cuando esté disponible
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_car_filled,
            size: 64,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'AutoCar',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 32),
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
            strokeWidth: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorRed() {
    return Padding(
      key: const ValueKey('errorRed'),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off,
              size: 64,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Sin conexión a internet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Verifica tu conexión y vuelve a intentar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _verificarSesion,
              child: const Text(
                'Reintentar',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
