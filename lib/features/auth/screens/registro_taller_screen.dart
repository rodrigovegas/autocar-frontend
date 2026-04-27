import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/google_auth_service.dart';

class RegistroTallerScreen extends ConsumerStatefulWidget {
  const RegistroTallerScreen({super.key});

  @override
  ConsumerState<RegistroTallerScreen> createState() =>
      _RegistroTallerScreenState();
}

class _RegistroTallerScreenState extends ConsumerState<RegistroTallerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();

  // Especialidades
  List<Map<String, String>> _especialidades = [];
  String? _especialidadSeleccionadaId;
  String? _especialidadSeleccionadaNombre;
  bool _loadingEspecialidades = true;
  String? _errorEspecialidades;

  bool _googleLoading = false;
  bool _argsLeidos = false;

  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLeidos) {
      _argsLeidos = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final datosGoogle = args?['datosGoogle'] as Map<String, dynamic>?;
      final idTokenPrevio = args?['idToken'] as String?;

      // Si viene con token previo y datos de Google, ir directo a completar perfil
      if (datosGoogle != null && idTokenPrevio != null) {
        debugPrint('Registro Taller: redirigiendo a completar-perfil (idToken previo)'); // TODO: remover en producción
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/completar-perfil-taller-google',
              arguments: args,
            );
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarEspecialidades();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 4)),
    );
  }

  Future<void> _cargarEspecialidades() async {
    setState(() {
      _loadingEspecialidades = true;
      _errorEspecialidades = null;
    });
    try {
      final res = await ApiService().dio.get('/especialidades');
      setState(() {
        _especialidades = (res.data as List)
            .map<Map<String, String>>(
              (e) => {'id': e['id'].toString(), 'nombre': e['nombre'].toString()},
            )
            .toList();
        if (_especialidades.isNotEmpty) {
          _especialidadSeleccionadaId = _especialidades.first['id'];
          _especialidadSeleccionadaNombre = _especialidades.first['nombre'];
        }
      });
    } on DioException catch (_) {
      setState(() =>
          _errorEspecialidades = 'No se pudieron cargar las especialidades');
    } finally {
      if (mounted) setState(() => _loadingEspecialidades = false);
    }
  }

  // ── Flujo tradicional ──────────────────────────────────────────────────────

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_especialidadSeleccionadaNombre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una especialidad')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).registrarTaller(
          _nombreController.text.trim(),
          _especialidadSeleccionadaNombre!,
          _direccionController.text.trim(),
          _telefonoController.text.trim(),
          _correoController.text.trim(),
          _contrasenaController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitud enviada. Su cuenta será revisada por el administrador.',
          ),
          backgroundColor: AppTheme.secondaryColor,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // ── Flujo Google ───────────────────────────────────────────────────────────

  Future<void> _onGoogleRegistroPressed() async {
    debugPrint('Registro Taller Google: usuario presionó el botón'); // TODO: remover en producción
    setState(() => _googleLoading = true);

    try {
      final idToken = await _googleAuthService.obtenerIdTokenGoogle();
      if (!mounted) return;
      if (idToken == null) return; // cancelado por usuario

      final datosUsuario = _googleAuthService.obtenerDatosUsuarioActual();
      debugPrint('Registro Taller Google: navegando a completar-perfil'); // TODO: remover en producción

      Navigator.pushNamed(
        context,
        '/completar-perfil-taller-google',
        arguments: {
          'idToken': idToken,
          'datosGoogle': {
            'correo': datosUsuario['correo'] ?? '',
            'nombre': datosUsuario['nombre'] ?? '',
          },
        },
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('Registro Taller Google: error = $e'); // TODO: remover en producción
      _mostrarSnackBar(
          'Hubo un problema al iniciar sesión con Google. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bool ocupado = authState.isLoading || _googleLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro de taller')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registra tu taller',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Una vez registrado el administrador verificará '
                'tu cuenta antes de que puedas acceder.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // ── Botón Google + separador ──────────────────────────────────
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
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFDADADA))),
                ],
              ),
              const SizedBox(height: 20),

              // ── Nombre ────────────────────────────────────────────────────
              TextFormField(
                controller: _nombreController,
                enabled: !ocupado,
                decoration: const InputDecoration(
                  labelText: 'Nombre del taller',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingrese el nombre del taller' : null,
              ),
              const SizedBox(height: 16),

              // ── Especialidad (dropdown) ───────────────────────────────────
              if (_loadingEspecialidades)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorEspecialidades != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorEspecialidades!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13)),
                      ),
                      TextButton(
                        onPressed: _cargarEspecialidades,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _especialidadSeleccionadaId,
                  decoration: const InputDecoration(
                    labelText: 'Especialidad',
                    prefixIcon: Icon(Icons.build_outlined),
                  ),
                  items: _especialidades
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e['id'],
                          child: Text(e['nombre']!),
                        ),
                      )
                      .toList(),
                  onChanged: ocupado
                      ? null
                      : (id) {
                          setState(() {
                            _especialidadSeleccionadaId = id;
                            _especialidadSeleccionadaNombre = _especialidades
                                .firstWhere((e) => e['id'] == id)['nombre'];
                          });
                        },
                  validator: (v) =>
                      v == null ? 'Selecciona una especialidad' : null,
                ),
              const SizedBox(height: 16),

              // ── Dirección ─────────────────────────────────────────────────
              TextFormField(
                controller: _direccionController,
                enabled: !ocupado,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: 'Ej: Av. Las Américas 123, Tarija',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingrese la dirección' : null,
              ),
              const SizedBox(height: 16),

              // ── Teléfono ──────────────────────────────────────────────────
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                enabled: !ocupado,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Ingrese el teléfono' : null,
              ),
              const SizedBox(height: 16),

              // ── Correo ────────────────────────────────────────────────────
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                enabled: !ocupado,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese su correo';
                  if (!v.contains('@')) return 'Ingrese un correo válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Contraseña ────────────────────────────────────────────────
              TextFormField(
                controller: _contrasenaController,
                obscureText: true,
                enabled: !ocupado,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Error de auth ─────────────────────────────────────────────
              if (authState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                ),
              const SizedBox(height: 24),

              // ── Botón registrar ───────────────────────────────────────────
              authState.isLoading && !_googleLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: ocupado ? null : _registrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                      child: const Text('Enviar solicitud de registro'),
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
