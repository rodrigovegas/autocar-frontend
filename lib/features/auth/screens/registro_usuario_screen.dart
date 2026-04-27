import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/google_auth_result.dart';
import '../../../core/theme/app_theme.dart';

class RegistroUsuarioScreen extends ConsumerStatefulWidget {
  const RegistroUsuarioScreen({super.key});

  @override
  ConsumerState<RegistroUsuarioScreen> createState() =>
      _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState extends ConsumerState<RegistroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _googleLoading = false;
  bool _vienesDeGoogle = false;
  bool _argsLeidos = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLeidos) {
      _argsLeidos = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final datosGoogle = args?['datosGoogle'] as Map<String, dynamic>?;
      if (datosGoogle != null) {
        debugPrint(
            'Registro Usuario: pantalla iniciada con datosGoogle = true'); // TODO: remover en producción
        setState(() {
          _nombreController.text = datosGoogle['nombre'] ?? '';
          _correoController.text = datosGoogle['correo'] ?? '';
          _vienesDeGoogle = true;
        });
      } else {
        debugPrint(
            'Registro Usuario: pantalla iniciada con datosGoogle = false'); // TODO: remover en producción
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 4)),
    );
  }

  // ── Flujo tradicional ──────────────────────────────────────────────────────

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).registrarUsuario(
          _nombreController.text.trim(),
          _correoController.text.trim(),
          _contrasenaController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada exitosamente. Inicia sesión.'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ── Flujo Google ───────────────────────────────────────────────────────────

  Future<void> _onGoogleRegistroPressed() async {
    debugPrint('Registro Usuario Google: usuario presionó el botón'); // TODO: remover en producción
    setState(() => _googleLoading = true);

    // Si viene de Google, pasar el nombre pre-llenado como override
    final String? nombreOverride = _vienesDeGoogle
        ? (_nombreController.text.trim().isNotEmpty
            ? _nombreController.text.trim()
            : null)
        : null;

    final result = await ref
        .read(authProvider.notifier)
        .registrarUsuarioConGoogle(nombreOverride: nombreOverride);

    if (!mounted) return;
    setState(() => _googleLoading = false);

    await _manejarResultadoGoogle(result);
  }

  Future<void> _manejarResultadoGoogle(GoogleAuthResult result) async {
    if (!mounted) return;
    debugPrint('Registro Usuario Google: resultado = ${result.tipo}'); // TODO: remover en producción

    switch (result.tipo) {
      case GoogleAuthTipo.exito:
        Navigator.pushReplacementNamed(context, '/home-usuario');

      case GoogleAuthTipo.canceladoPorUsuario:
        break;

      case GoogleAuthTipo.alreadyRegistered:
        _mostrarDialogoYaRegistrado();

      case GoogleAuthTipo.emailExiste:
        _mostrarSnackBar(
          'Ya existe una cuenta con este correo. Inicia sesión con tu correo y contraseña.',
        );

      case GoogleAuthTipo.adminNoPermitido:
        _mostrarSnackBar(
          'Este correo está asociado a una cuenta administrativa. Usa otra cuenta de Google.',
        );

      case GoogleAuthTipo.nombreRequerido:
        await _pedirNombreYReintentarRegistro();

      case GoogleAuthTipo.emailNoVerificado:
        _mostrarSnackBar(
          'Tu correo de Google no está verificado. Verifícalo y vuelve a intentar.',
        );

      case GoogleAuthTipo.sinConexion:
        _mostrarSnackBar('No se pudo conectar. Verifica tu conexión a internet.');

      case GoogleAuthTipo.tokenInvalido:
      case GoogleAuthTipo.errorGenerico:
        _mostrarSnackBar(
          result.mensaje ?? 'Hubo un problema al registrar. Intenta de nuevo.',
        );

      default:
        _mostrarSnackBar(
          'Hubo un problema. Intenta de nuevo o usa el formulario manual.',
        );
    }
  }

  void _mostrarDialogoYaRegistrado() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ya tienes una cuenta'),
        content: const Text(
          'Ya tienes una cuenta de usuario registrada con esta cuenta de Google. '
          '¿Quieres iniciar sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _pedirNombreYReintentarRegistro() async {
    final nombreController = TextEditingController();

    final nombre = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Necesitamos tu nombre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu cuenta de Google no incluye tu nombre. '
              'Por favor ingrésalo para continuar.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final texto = nombreController.text.trim();
              if (texto.isEmpty) return;
              Navigator.pop(ctx, texto);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    nombreController.dispose();

    if (nombre == null || !mounted) return;

    setState(() => _googleLoading = true);
    final result = await ref
        .read(authProvider.notifier)
        .registrarUsuarioConGoogle(nombreOverride: nombre);
    if (!mounted) return;
    setState(() => _googleLoading = false);

    await _manejarResultadoGoogle(result);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bool ocupado = authState.isLoading || _googleLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registro de usuario',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea tu cuenta para gestionar el mantenimiento de tu vehículo.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // ── Botón Google + separador (solo si no viene de Google) ──────
              if (!_vienesDeGoogle) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: ocupado ? null : _onGoogleRegistroPressed,
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
                      'Registrarse con Google',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF3C4043),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFFDADADA))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o regístrate manualmente',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFDADADA))),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // ── Nombre ────────────────────────────────────────────────────
              TextFormField(
                controller: _nombreController,
                enabled: !ocupado,
                readOnly: _vienesDeGoogle,
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: const Icon(Icons.person_outlined),
                  suffixIcon: _vienesDeGoogle
                      ? const Icon(Icons.lock_outline,
                          size: 18, color: AppTheme.textSecondary)
                      : null,
                  helperText:
                      _vienesDeGoogle ? 'Desde tu cuenta de Google' : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese su nombre completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Correo ────────────────────────────────────────────────────
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                enabled: !ocupado,
                readOnly: _vienesDeGoogle,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  suffixIcon: _vienesDeGoogle
                      ? const Icon(Icons.lock_outline,
                          size: 18, color: AppTheme.textSecondary)
                      : null,
                  helperText:
                      _vienesDeGoogle ? 'Desde tu cuenta de Google' : null,
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

              // ── Contraseña (oculta cuando viene de Google) ────────────────
              if (!_vienesDeGoogle) ...[
                TextFormField(
                  controller: _contrasenaController,
                  obscureText: true,
                  enabled: !ocupado,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // ── Error ─────────────────────────────────────────────────────
              if (authState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                ),
              const SizedBox(height: 24),

              // ── Botón principal ───────────────────────────────────────────
              authState.isLoading && !_googleLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: ocupado
                          ? null
                          : (_vienesDeGoogle
                              ? _onGoogleRegistroPressed
                              : _registrar),
                      child: Text(
                        _vienesDeGoogle ? 'Completar registro' : 'Crear cuenta',
                      ),
                    ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: ocupado
                      ? null
                      : () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
