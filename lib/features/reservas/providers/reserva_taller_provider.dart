import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/reserva_model.dart';

class ReservaTallerState {
  final bool isLoading;
  final List<ReservaModel> reservas;
  final String? error;

  const ReservaTallerState({
    this.isLoading = false,
    this.reservas = const [],
    this.error,
  });

  ReservaTallerState copyWith({
    bool? isLoading,
    List<ReservaModel>? reservas,
    String? error,
  }) {
    return ReservaTallerState(
      isLoading: isLoading ?? this.isLoading,
      reservas: reservas ?? this.reservas,
      error: error,
    );
  }
}

class ReservaTallerNotifier extends StateNotifier<ReservaTallerState> {
  final ApiService _apiService = ApiService();

  ReservaTallerNotifier() : super(const ReservaTallerState());

  Future<void> cargarReservas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.dio.get(
        '${ApiConstants.reservas}/taller',
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

  Future<bool> actualizarEstado(
      String reservaId, String estado, String? motivoRechazo) async {
    try {
      await _apiService.dio.patch(
        '${ApiConstants.reservas}/$reservaId/estado',
        data: {
          'estado': estado,
          'motivo_rechazo': ?motivoRechazo,
        },
      );
      await cargarReservas();
      return true;
    } on DioException catch (_) {
      state = state.copyWith(error: 'Error al actualizar el estado');
      return false;
    }
  }
}

final reservaTallerProvider =
    StateNotifierProvider<ReservaTallerNotifier, ReservaTallerState>((ref) {
  return ReservaTallerNotifier();
});