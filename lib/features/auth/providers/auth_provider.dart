import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/usuario_model.dart';

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

  Future<void> cerrarSesion() async {
    await _apiService.clearToken();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});