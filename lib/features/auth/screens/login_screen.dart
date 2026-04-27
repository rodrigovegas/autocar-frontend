import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/google_auth_result.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _obscurePassword = true;
  bool _googleLoading = false;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 4)),
    );
  }

  void _redirigirSegunRol(String rol) {
    debugPrint('Login: navegando a rol = $rol'); // TODO: remover en producción
    switch (rol) {
      case 'usuario':
        Navigator.pushReplacementNamed(context, '/home-usuario');
        break;
      case 'taller':
        Navigator.pushReplacementNamed(context, '/home-taller');
        break;
      case 'administrador':
        Navigator.pushReplacementNamed(context, '/home-admin');
        break;
      default:
        debugPrint('Login: rol desconocido ("$rol")'); // TODO: remover en producción
        _mostrarSnackBar(
          'Hubo un problema al iniciar sesión. Intenta nuevamente o contacta al administrador.',
        );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
      _correoController.text.trim(),
      _contrasenaController.text,
    );

    if (!mounted) return;

    if (success) {
      final rol = ref.read(authProvider).usuario?.rol ?? '';
      debugPrint('Login: éxito, rol = $rol, navegando...'); // TODO: remover en producción
      _redirigirSegunRol(rol);
    } else {
      final authState = ref.read(authProvider);
      final rutaEspecial = _detectarRutaEstadoEspecial(authState.error);
      if (rutaEspecial != null) {
        debugPrint('Login: estado especial, redirigiendo a $rutaEspecial'); // TODO: remover en producción
        Navigator.pushReplacementNamed(context, rutaEspecial);
      } else {
        debugPrint('Login: error en formulario: ${authState.error}'); // TODO: remover en producción
      }
    }
  }

  Future<void> _onGoogleLoginPressed() async {
    debugPrint('Login Google: usuario presionó el botón'); // TODO: remover en producción
    setState(() => _googleLoading = true);

    final result = await ref.read(authProvider.notifier).loginConGoogle();

    if (!mounted) return;
    setState(() => _googleLoading = false);

    debugPrint('Login Google: resultado = ${result.tipo}'); // TODO: remover en producción

    switch (result.tipo) {
      case GoogleAuthTipo.exito:
        _redirigirSegunRol(result.usuario!.rol);

      case GoogleAuthTipo.canceladoPorUsuario:
        break;

      case GoogleAuthTipo.cuentaPendiente:
        debugPrint('Login Google: navegando a /cuenta-pendiente'); // TODO: remover en producción
        Navigator.pushReplacementNamed(context, '/cuenta-pendiente');

      case GoogleAuthTipo.cuentaRechazada:
        debugPrint('Login Google: navegando a /cuenta-rechazada'); // TODO: remover en producción
        Navigator.pushReplacementNamed(context, '/cuenta-rechazada');

      case GoogleAuthTipo.cuentaDesactivada:
        debugPrint('Login Google: navegando a /cuenta-desactivada'); // TODO: remover en producción
        Navigator.pushReplacementNamed(context, '/cuenta-desactivada');

      case GoogleAuthTipo.noRegistrado:
        _mostrarDialogoNoRegistrado();

      case GoogleAuthTipo.emailExiste:
        _mostrarSnackBar(
          'Ya existe una cuenta con este correo. Inicia sesión con tu correo y contraseña.',
        );

      case GoogleAuthTipo.adminNoPermitido:
        _mostrarSnackBar(
          'El acceso administrativo solo está disponible con correo y contraseña.',
        );

      case GoogleAuthTipo.emailNoVerificado:
        _mostrarSnackBar(
          'Tu correo de Google no está verificado. Verifícalo y vuelve a intentar.',
        );

      case GoogleAuthTipo.sinConexion:
        _mostrarSnackBar('No se pudo conectar. Verifica tu conexión a internet.');

      case GoogleAuthTipo.tokenInvalido:
      case GoogleAuthTipo.errorGenerico:
        _mostrarSnackBar(
          result.mensaje ??
              'Hubo un problema al iniciar sesión con Google. Intenta de nuevo.',
        );

      default:
        _mostrarSnackBar(
          'Hubo un problema. Intenta de nuevo o usa tu correo y contraseña.',
        );
    }
  }

  void _mostrarDialogoNoRegistrado() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No tienes cuenta registrada'),
        content: const Text(
          'No encontramos una cuenta con este correo de Google. ¿Quieres crear una?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              debugPrint('Login Google: navegando a /seleccion-rol'); // TODO: remover en producción
              // TODO (Fases 6/7): pasar datosGoogle {correo, nombre, idToken} para pre-llenar registro
              Navigator.pushReplacementNamed(context, '/seleccion-rol');
            },
            child: const Text('Crear cuenta'),
          ),
        ],
      ),
    );
  }

  String? _detectarRutaEstadoEspecial(String? mensajeError) {
    if (mensajeError == null) return null;
    final lower = mensajeError.toLowerCase();
    if (lower.contains('pendiente') ||
        lower.contains('verificación por el administrador')) {
      return '/cuenta-pendiente';
    }
    if (lower.contains('rechazada') || lower.contains('rechazado')) {
      return '/cuenta-rechazada';
    }
    if (lower.contains('desactivada') || lower.contains('desactivado')) {
      return '/cuenta-desactivada';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bool ocupado = authState.isLoading || _googleLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Logo y título
                  const Icon(
                    Icons.directions_car,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AutoCar',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Text(
                    'Gestión de mantenimiento vehicular',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Botón Google ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: ocupado ? null : _onGoogleLoginPressed,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDADADA)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _googleLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.g_mobiledata, // TODO: reemplazar por logo oficial de Google
                              size: 26,
                              color: Color(0xFF4285F4),
                            ),
                      label: const Text(
                        'Continuar con Google',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF3C4043),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Separador "o usa tu cuenta" ───────────────────────────
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: Color(0xFFDADADA)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'o usa tu cuenta',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: Color(0xFFDADADA)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Formulario tradicional ────────────────────────────────

                  TextFormField(
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !ocupado,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su correo';
                      }
                      if (!value.contains('@')) {
                        return 'Ingrese un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _contrasenaController,
                    obscureText: _obscurePassword,
                    enabled: !ocupado,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: ocupado
                            ? null
                            : () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Mensaje de error del formulario tradicional
                  if (authState.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.errorColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Botón login tradicional
                  authState.isLoading && !_googleLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: ocupado ? null : _login,
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                  const SizedBox(height: 16),

                  // Link ir a registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes cuenta? ',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      TextButton(
                        onPressed: ocupado
                            ? null
                            : () => Navigator.pushNamed(
                                  context, '/seleccion-rol'),
                        child: const Text('Crear cuenta'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
