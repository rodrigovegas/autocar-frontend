import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/reserva_model.dart';

class ReservaState {
  final bool isLoading;
  final List<ReservaModel> reservas;
  final List<DisponibilidadModel> disponibilidades;
  final String? error;
  final bool exitoso;

  const ReservaState({
    this.isLoading = false,
    this.reservas = const [],
    this.disponibilidades = const [],
    this.error,
    this.exitoso = false,
  });

  ReservaState copyWith({
    bool? isLoading,
    List<ReservaModel>? reservas,
    List<DisponibilidadModel>? disponibilidades,
    String? error,
    bool? exitoso,
  }) {
    return ReservaState(
      isLoading: isLoading ?? this.isLoading,
      reservas: reservas ?? this.reservas,
      disponibilidades: disponibilidades ?? this.disponibilidades,
      error: error,
      exitoso: exitoso ?? this.exitoso,
    );
  }
}

class ReservaNotifier extends StateNotifier<ReservaState> {
  final ApiService _apiService = ApiService();

  ReservaNotifier() : super(const ReservaState());

  Future<void> cargarReservasUsuario() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.dio.get(
        '${ApiConstants.reservas}/usuario',
      );
      final lista = (response.data as List)
          .map((e) => ReservaModel.fromJson(e))
          .toList();
      state = state.copyWith(isLoading: false, reservas: lista);
    } on DioException catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar las reservas',
      );
    }
  }

  Future<void> cargarDisponibilidad(String tallerId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.dio.get(
        '${ApiConstants.disponibilidad}/$tallerId',
      );
      final lista = (response.data as List)
          .map((e) => DisponibilidadModel.fromJson(e))
          .toList();
      state = state.copyWith(isLoading: false, disponibilidades: lista);
    } on DioException catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar horarios disponibles',
      );
    }
  }

  Future<bool> crearReserva({
  required String tallerId,
  required String vehiculoId,
  required String disponibilidadId,
  required List<String> serviciosIds,
  String? descripcionOtro,
}) async {
  state = state.copyWith(isLoading: true, error: null, exitoso: false);
  try {
    await _apiService.dio.post(
      ApiConstants.reservas,
      data: {
        'taller_id': tallerId,
        'vehiculo_id': vehiculoId,
        'disponibilidad_id': disponibilidadId,
        'servicios_ids': serviciosIds,
        'descripcion_otro': ?descripcionOtro,
      },
    );
    state = state.copyWith(isLoading: false, exitoso: true);
    await cargarReservasUsuario();
    return true;
  } on DioException catch (e) {
    final mensaje = e.response?.data['detail'] ?? 'Error al crear la reserva';
    state = state.copyWith(
      isLoading: false,
      error: mensaje.toString(),
    );
    return false;
  }
}

  Future<bool> cancelarReserva(String reservaId) async {
    try {
      await _apiService.dio.patch(
        '${ApiConstants.reservas}/$reservaId/cancelar',
      );
      await cargarReservasUsuario();
      return true;
    } on DioException catch (_) {
      state = state.copyWith(error: 'Error al cancelar la reserva');
      return false;
    }
  }
}

final reservaProvider =
    StateNotifierProvider<ReservaNotifier, ReservaState>((ref) {
  return ReservaNotifier();
});