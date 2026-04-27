import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';
import '../providers/google_auth_result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/google_auth_service.dart';

class CompletarPerfilTallerGoogleScreen extends ConsumerStatefulWidget {
  const CompletarPerfilTallerGoogleScreen({super.key});

  @override
  ConsumerState<CompletarPerfilTallerGoogleScreen> createState() =>
      _CompletarPerfilTallerGoogleScreenState();
}

class _CompletarPerfilTallerGoogleScreenState
    extends ConsumerState<CompletarPerfilTallerGoogleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreTallerController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();

  // Datos de Google recibidos por args
  String _correoGoogle = '';
  String _nombreGoogle = '';
  bool _argsLeidos = false;
  bool _argsValidos = true;

  // Especialidades
  List<Map<String, String>> _especialidades = [];
  String? _especialidadSeleccionadaId;
  String? _especialidadSeleccionadaNombre;
  bool _loadingEspecialidades = true;
  String? _errorEspecialidades;

  bool _loading = false;

  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLeidos) {
      _argsLeidos = true;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final datosGoogle = args?['datosGoogle'] as Map<String, dynamic>?;

      if (datosGoogle == null) {
        debugPrint('CompletarPerfilTallerGoogle: args inválidos'); // TODO: remover en producción
        setState(() => _argsValidos = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Error de sesión. Por favor inicia el registro nuevamente.'),
              ),
            );
            Navigator.pushReplacementNamed(context, '/seleccion-rol');
          }
        });
        return;
      }

      setState(() {
        _correoGoogle = datosGoogle['correo'] ?? '';
        _nombreGoogle = datosGoogle['nombre'] ?? '';
      });
      debugPrint('CompletarPerfilTallerGoogle: args ok, correo=$_correoGoogle'); // TODO: remover en producción
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarEspecialidades();
  }

  @override
  void dispose() {
    _nombreTallerController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
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
              (e) => {
                'id': e['id'].toString(),
                'nombre': e['nombre'].toString()
              },
            )
            .toList();
        if (_especialidades.isNotEmpty) {
          _especialidadSeleccionadaId = _especialidades.first['id'];
          _especialidadSeleccionadaNombre = _especialidades.first['nombre'];
        }
      });
    } on DioException catch (_) {
      setState(
          () => _errorEspecialidades = 'No se pudieron cargar las especialidades');
    } finally {
      if (mounted) setState(() => _loadingEspecialidades = false);
    }
  }

  Future<void> _onRegistrarPressed() async {
    if (!_formKey.currentState!.validate()) return;
    if (_especialidadSeleccionadaNombre == null) {
      _mostrarSnackBar('Selecciona una especialidad');
      return;
    }

    setState(() => _loading = true);

    // Regenerar token — puede haber expirado mientras el usuario llenaba el formulario
    final idTokenFresco = await _googleAuthService.obtenerIdTokenGoogle();
    if (!mounted) return;
    if (idTokenFresco == null) {
      setState(() => _loading = false);
      return;
    }

    final result = await ref.read(authProvider.notifier).registrarTallerConGoogle(
          nombre: _nombreTallerController.text.trim(),
          especialidad: _especialidadSeleccionadaNombre!,
          direccion: _direccionController.text.trim(),
          telefono: _telefonoController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _loading = false);

    _manejarResultado(result);
  }

  void _manejarResultado(GoogleAuthResult result) {
    debugPrint('CompletarPerfilTallerGoogle: resultado = ${result.tipo}'); // TODO: remover en producción

    switch (result.tipo) {
      case GoogleAuthTipo.exito:
        // Taller queda en "pendiente" — limpiar pila y mostrar pantalla de estado
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/cuenta-pendiente',
          (route) => false,
        );

      case GoogleAuthTipo.canceladoPorUsuario:
        break;

      case GoogleAuthTipo.alreadyRegistered:
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ya tienes una cuenta'),
            content: const Text(
              'Ya tienes una cuenta de taller registrada con esta cuenta de Google. '
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

      case GoogleAuthTipo.especialidadInvalida:
        _mostrarSnackBar(
            'La especialidad seleccionada no es válida. Selecciona otra.');

      case GoogleAuthTipo.emailExiste:
        _mostrarSnackBar(
          'Ya existe una cuenta con este correo. Inicia sesión con tu correo y contraseña.',
        );

      case GoogleAuthTipo.adminNoPermitido:
        _mostrarSnackBar(
          'Este correo está asociado a una cuenta administrativa. Usa otra cuenta de Google.',
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
          result.mensaje ?? 'Hubo un problema al registrar. Intenta de nuevo.',
        );

      default:
        _mostrarSnackBar(
            'Hubo un problema. Intenta de nuevo o usa el formulario manual.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_argsValidos) return const SizedBox.shrink();

    final bool ocupado = _loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Completar registro de taller')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos del taller',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Completa la información de tu taller para enviar la solicitud.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              // ── Cuenta de Google (informativo) ────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBDEFB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.g_mobiledata, // TODO: reemplazar por logo oficial de Google
                        size: 28, color: Color(0xFF4285F4)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estás registrando tu taller con:',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _correoGoogle.isNotEmpty
                                ? _correoGoogle
                                : 'Cuenta de Google',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (_nombreGoogle.isNotEmpty)
                            Text(
                              _nombreGoogle,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.lock_outline,
                        size: 16, color: AppTheme.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Nombre del taller ─────────────────────────────────────────
              TextFormField(
                controller: _nombreTallerController,
                enabled: !ocupado,
                decoration: const InputDecoration(
                  labelText: 'Nombre del taller',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Ingrese el nombre del taller'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Especialidad ──────────────────────────────────────────────
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
              const SizedBox(height: 28),

              // ── Botón registrar ───────────────────────────────────────────
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: ocupado ? null : _onRegistrarPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                      child: const Text('Registrar taller'),
                    ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: ocupado
                      ? null
                      : () => Navigator.pushReplacementNamed(
                            context, '/seleccion-rol'),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
