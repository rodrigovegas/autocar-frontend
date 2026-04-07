import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/vehiculo_model.dart';

class VehiculoState {
  final bool isLoading;
  final List<VehiculoModel> vehiculos;
  final String? error;

  const VehiculoState({
    this.isLoading = false,
    this.vehiculos = const [],
    this.error,
  });

  VehiculoState copyWith({
    bool? isLoading,
    List<VehiculoModel>? vehiculos,
    String? error,
  }) {
    return VehiculoState(
      isLoading: isLoading ?? this.isLoading,
      vehiculos: vehiculos ?? this.vehiculos,
      error: error,
    );
  }
}

class VehiculoNotifier extends StateNotifier<VehiculoState> {
  final ApiService _apiService = ApiService();

  VehiculoNotifier() : super(const VehiculoState());

  Future<void> cargarVehiculos() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.dio.get(ApiConstants.vehiculos);
      final vehiculos = (response.data as List)
          .map((v) => VehiculoModel.fromJson(v))
          .toList();
      state = state.copyWith(isLoading: false, vehiculos: vehiculos);
    } on DioException catch (e) {
      final mensaje = e.response?.data['detail'] ?? 'Error al cargar vehículos';
      state = state.copyWith(isLoading: false, error: mensaje);
    }
  }

  Future<bool> registrarVehiculo(
    String marca,
    String modelo,
    int anio,
    int kilometraje, {
    String? placa,
    String? color,
    String? tipoCombustible,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.dio.post(
        ApiConstants.vehiculos,
        data: {
          'marca': marca,
          'modelo': modelo,
          'anio': anio,
          'kilometraje_actual': kilometraje,
          if (placa != null) 'placa': placa,
          if (color != null) 'color': color,
          if (tipoCombustible != null) 'tipo_combustible': tipoCombustible,
        },
      );
      await cargarVehiculos();
      return true;
    } on DioException catch (e) {
      final mensaje =
          e.response?.data['detail'] ?? 'Error al registrar vehículo';
      state = state.copyWith(isLoading: false, error: mensaje);
      return false;
    }
  }

  Future<bool> eliminarVehiculo(String vehiculoId) async {
    try {
      await _apiService.dio.delete('${ApiConstants.vehiculos}/$vehiculoId');
      await cargarVehiculos();
      return true;
    } on DioException catch (e) {
      final mensaje =
          e.response?.data['detail'] ?? 'Error al eliminar vehículo';
      state = state.copyWith(error: mensaje);
      return false;
    }
  }

  Future<void> actualizarVehiculo(
    String vehiculoId, {
    int? kilometraje,
    String? color,
    String? tipoCombustible,
  }) async {
    try {
      await _apiService.dio.put(
        '${ApiConstants.vehiculos}/$vehiculoId',
        data: {
          if (kilometraje != null) 'kilometraje_actual': kilometraje,
          if (color != null) 'color': color,
          if (tipoCombustible != null) 'tipo_combustible': tipoCombustible,
        },
      );
      await cargarVehiculos();
    } on DioException catch (e) {
      final mensaje =
          e.response?.data['detail'] ?? 'Error al actualizar vehículo';
      state = state.copyWith(error: mensaje);
    }
  }
}

final vehiculoProvider = StateNotifierProvider<VehiculoNotifier, VehiculoState>(
  (ref) {
    return VehiculoNotifier();
  },
);
