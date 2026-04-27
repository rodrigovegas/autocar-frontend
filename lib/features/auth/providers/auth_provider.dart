import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/google_auth_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/usuario_model.dart';
import 'google_auth_result.dart';

// Estado de autenticación
class AuthState {
  final bool isLoading;
  final UsuarioModel? usuario;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.usuario,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    UsuarioModel? usuario,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      usuario: usuario ?? this.usuario,
      error: error,
    );
  }
}

// Notifier de autenticación — Patrón Service Layer en Flutter
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  AuthNotifier() : super(const AuthState()) {
    _cargarSesion();
  }

  Future<void> _cargarSesion() async {
    await _apiService.loadTokenFromStorage();
    final userData = await _apiService.getUserData();
    if (userData['role'] != null) {
      state = state.copyWith(
        usuario: UsuarioModel(
          id: userData['id'] ?? '',
          nombre: userData['name'] ?? '',
          correo: '',
          rol: userData['role'] ?? '',
          token: '',
        ),
      );
    }
  }

  Future<bool> login(String correo, String contrasena) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.dio.post(
        ApiConstants.authLogin,
        data: {'correo': correo, 'contrasena': contrasena},
      );

      final usuario = UsuarioModel.fromJson(response.data);
      await _apiService.setAuthToken(usuario.token);
      await _apiService.saveUserData(usuario.rol, usuario.id, usuario.nombre);

      state = state.copyWith(isLoading: false, usuario: usuario);
      return true;
    } on DioException catch (e) {
      final mensaje = e.response?.data['detail'] ?? 'Error al iniciar sesión';
      state = state.copyWith(isLoading: false, error: mensaje);
      return false;
    }
  }

  Future<bool> registrarUsuario(
      String nombre, String correo, String contrasena) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.dio.post(
        ApiConstants.authRegistroUsuario,
        data: {
          'nombre_completo': nombre,
          'correo': correo,
          'contrasena': contrasena,
        },
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      final mensaje = e.response?.data['detail'] ?? 'Error al registrarse';
      state = state.copyWith(isLoading: false, error: mensaje);
      return false;
    }
  }

  Future<bool> registrarTaller(String nombre, String especialidad,
      String direccion, String telefono,
      String correo, String contrasena) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.dio.post(
        ApiConstants.authRegistroTaller,
        data: {
          'nombre': nombre,
          'especialidad': especialidad,
          'direccion_texto': direccion,
          'telefono': telefono,
          'correo': correo,
          'contrasena': contrasena,
        },
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      final mensaje = e.response?.data['detail'] ?? 'Error al registrar taller';
      state = state.copyWith(isLoading: false, error: mensaje);
      return false;
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  Future<GoogleAuthResult> loginConGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final idToken = await _googleAuthService.obtenerIdTokenGoogle();
      if (idToken == null) {
        state = state.copyWith(isLoading: false);
        return const GoogleAuthResult(tipo: GoogleAuthTipo.canceladoPorUsuario);
      }

      debugPrint('Google Sign-In: token obtenido, enviando al backend...'); // TODO: remover en producción
      final response = await _apiService.dio.post(
        ApiConstants.googleLogin,
        data: {'id_token': idToken},
      );

      final usuario = UsuarioModel.fromJson(response.data);
      await _apiService.setAuthToken(usuario.token);
      await _apiService.saveUserData(usuario.rol, usuario.id, usuario.nombre);
      state = state.copyWith(isLoading: false, usuario: usuario);
      debugPrint('Google Sign-In: respuesta del backend = éxito, rol=${usuario.rol}'); // TODO: remover en producción
      return GoogleAuthResult(tipo: GoogleAuthTipo.exito, usuario: usuario);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      return _mapearErrorGoogle(e);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint('Google Sign-In: error = $e'); // TODO: remover en producción
      return GoogleAuthResult(
        tipo: GoogleAuthTipo.errorGenerico,
        mensaje: 'Error al iniciar sesión con Google.',
      );
    }
  }

  Future<GoogleAuthResult> registrarUsuarioConGoogle({
    String? nombreOverride,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final idToken = await _googleAuthService.obtenerIdTokenGoogle();
      if (idToken == null) {
        state = state.copyWith(isLoading: false);
        return const GoogleAuthResult(tipo: GoogleAuthTipo.canceladoPorUsuario);
      }

      debugPrint('Google Sign-In: token obtenido, enviando al backend...'); // TODO: remover en producción
      final body = <String, dynamic>{'id_token': idToken};
      if (nombreOverride != null && nombreOverride.isNotEmpty) {
        body['nombre'] = nombreOverride;
      }

      final response = await _apiService.dio.post(
        ApiConstants.googleRegistroUsuario,
        data: body,
      );

      final usuario = UsuarioModel.fromJson(response.data);
      await _apiService.setAuthToken(usuario.token);
      await _apiService.saveUserData(usuario.rol, usuario.id, usuario.nombre);
      state = state.copyWith(isLoading: false, usuario: usuario);
      debugPrint('Google Sign-In: respuesta del backend = registro usuario ok'); // TODO: remover en producción
      return GoogleAuthResult(tipo: GoogleAuthTipo.exito, usuario: usuario);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      return _mapearErrorGoogle(e);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint('Google Sign-In: error = $e'); // TODO: remover en producción
      return GoogleAuthResult(
        tipo: GoogleAuthTipo.errorGenerico,
        mensaje: 'Error al registrarse con Google.',
      );
    }
  }

  Future<GoogleAuthResult> registrarTallerConGoogle({
    required String nombre,
    required String especialidad,
    required String direccion,
    required String telefono,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final idToken = await _googleAuthService.obtenerIdTokenGoogle();
      if (idToken == null) {
        state = state.copyWith(isLoading: false);
        return const GoogleAuthResult(tipo: GoogleAuthTipo.canceladoPorUsuario);
      }

      debugPrint('Google Sign-In: token obtenido, enviando al backend...'); // TODO: remover en producción
      await _apiService.dio.post(
        ApiConstants.googleRegistroTaller,
        data: {
          'id_token': idToken,
          'nombre': nombre,
          'especialidad': especialidad,
          'direccion_texto': direccion,
          'telefono': telefono,
        },
      );

      state = state.copyWith(isLoading: false);
      debugPrint('Google Sign-In: respuesta del backend = registro taller ok (pendiente)'); // TODO: remover en producción
      // No guardamos sesión — el taller queda en estado "pendiente"
      return const GoogleAuthResult(tipo: GoogleAuthTipo.exito);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      return _mapearErrorGoogle(e);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint('Google Sign-In: error = $e'); // TODO: remover en producción
      return GoogleAuthResult(
        tipo: GoogleAuthTipo.errorGenerico,
        mensaje: 'Error al registrar taller con Google.',
      );
    }
  }

  GoogleAuthResult _mapearErrorGoogle(DioException e) {
    if (e.response == null) {
      return const GoogleAuthResult(tipo: GoogleAuthTipo.sinConexion);
    }
    final detail = e.response?.data['detail'];
    final code = detail is Map ? detail['code'] as String? : null;
    final mensaje = detail is Map ? detail['message'] as String? : detail?.toString();
    debugPrint('Google Sign-In: respuesta del backend = $code'); // TODO: remover en producción

    return switch (code) {
      'INVALID_TOKEN'       => GoogleAuthResult(tipo: GoogleAuthTipo.tokenInvalido, mensaje: mensaje),
      'EMAIL_NOT_VERIFIED'  => GoogleAuthResult(tipo: GoogleAuthTipo.emailNoVerificado, mensaje: mensaje),
      'ADMIN_NOT_ALLOWED'   => GoogleAuthResult(tipo: GoogleAuthTipo.adminNoPermitido, mensaje: mensaje),
      'CUENTA_PENDIENTE'    => GoogleAuthResult(tipo: GoogleAuthTipo.cuentaPendiente, mensaje: mensaje),
      'CUENTA_RECHAZADA'    => GoogleAuthResult(tipo: GoogleAuthTipo.cuentaRechazada, mensaje: mensaje),
      'CUENTA_DESACTIVADA'  => GoogleAuthResult(tipo: GoogleAuthTipo.cuentaDesactivada, mensaje: mensaje),
      'EMAIL_EXISTS'        => GoogleAuthResult(tipo: GoogleAuthTipo.emailExiste, mensaje: mensaje),
      'NOT_REGISTERED'      => GoogleAuthResult(tipo: GoogleAuthTipo.noRegistrado, mensaje: mensaje),
      'ALREADY_REGISTERED'  => GoogleAuthResult(tipo: GoogleAuthTipo.alreadyRegistered, mensaje: mensaje),
      'NOMBRE_REQUERIDO'    => GoogleAuthResult(tipo: GoogleAuthTipo.nombreRequerido, mensaje: mensaje),
      'ESPECIALIDAD_INVALIDA' => GoogleAuthResult(tipo: GoogleAuthTipo.especialidadInvalida, mensaje: mensaje),
      _                     => GoogleAuthResult(tipo: GoogleAuthTipo.errorGenerico, mensaje: mensaje),
    };
  }

  // ── Sesión ────────────────────────────────────────────────────────────────

  Future<void> cerrarSesion() async {
    await _apiService.clearToken();
    await _googleAuthService.cerrarSesionGoogle();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});