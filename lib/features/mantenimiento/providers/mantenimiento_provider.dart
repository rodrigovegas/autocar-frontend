import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/mantenimiento_model.dart';

class MantenimientoState {
  final bool isLoading;
  final List<MantenimientoModel> mantenimientos;
  final List<TipoMantenimientoModel> tipos;
  final String? error;
  final bool guardadoExitoso;

  const MantenimientoState({
    this.isLoading = false,
    this.mantenimientos = const [],
    this.tipos = const [],
    this.error,
    this.guardadoExitoso = false,
  });

  MantenimientoState copyWith({
    bool? isLoading,
    List<MantenimientoModel>? mantenimientos,
    List<TipoMantenimientoModel>? tipos,
    String? error,
    bool? guardadoExitoso,
  }) {
    return MantenimientoState(
      isLoading: isLoading ?? this.isLoading,
      mantenimientos: mantenimientos ?? this.mantenimientos,
      tipos: tipos ?? this.tipos,
      error: error,
      guardadoExitoso: guardadoExitoso ?? this.guardadoExitoso,
    );
  }
}

class MantenimientoNotifier extends StateNotifier<MantenimientoState> {
  final ApiService _apiService = ApiService();

  MantenimientoNotifier() : super(const MantenimientoState());

  Future<void> cargarTipos() async {
    try {
      final response = await _apiService.dio.get(
        '${ApiConstants.mantenimientos}/tipos',
      );
      final tipos = (response.data as List)
          .map((e) => TipoMantenimientoModel.fromJson(e))
          .toList();
      state = state.copyWith(tipos: tipos);
    } on DioException catch (_) {
      state = state.copyWith(error: 'Error al cargar tipos de mantenimiento');
    }
  }

  Future<void> cargarPorVehiculo(String vehiculoId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.dio.get(
        '${ApiConstants.mantenimientos}/vehiculo/$vehiculoId',
      );
      final lista = (response.data as List)
          .map((e) => MantenimientoModel.fromJson(e))
          .toList();
      state = state.copyWith(isLoading: false, mantenimientos: lista);
    } on DioException catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar el historial',
      );
    }
  }

  Future<void> registrar({
    required String vehiculoId,
    required String tipoMantenimientoId,
    required String fecha,
    int? kilometraje,
    double? costo,
    String? descripcion,
    String? tallerNombre,
  }) async {
    state = state.copyWith(isLoading: true, error: null, guardadoExitoso: false);
    try {
      await _apiService.dio.post(
        '${ApiConstants.mantenimientos}/',
        data: {
          'vehiculo_id': vehiculoId,
          'tipo_mantenimiento_id': tipoMantenimientoId,
          'fecha': fecha,
          'kilometraje': ?kilometraje,
          'costo': ?costo,
          if (descripcion != null && descripcion.isNotEmpty)
            'descripcion': descripcion,
          if (tallerNombre != null && tallerNombre.isNotEmpty)
            'taller_nombre': tallerNombre,
        },
      );
      state = state.copyWith(isLoading: false, guardadoExitoso: true);
      await cargarPorVehiculo(vehiculoId);
    } on DioException catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al registrar el mantenimiento',
      );
    }
  }

  Future<void> eliminar(int mantenimientoId, String vehiculoId) async {
    try {
      await _apiService.dio.delete(
        '${ApiConstants.mantenimientos}/$mantenimientoId',
      );
      await cargarPorVehiculo(vehiculoId);
    } on DioException catch (_) {
      state = state.copyWith(error: 'Error al eliminar el registro');
    }
  }
}

final mantenimientoProvider =
    StateNotifierProvider<MantenimientoNotifier, MantenimientoState>((ref) {
  return MantenimientoNotifier();
});