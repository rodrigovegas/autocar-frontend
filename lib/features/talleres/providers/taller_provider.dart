import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/taller_model.dart';

class TallerState {
  final bool isLoading;
  final List<TallerModel> talleres;
  final String? error;

  const TallerState({
    this.isLoading = false,
    this.talleres = const [],
    this.error,
  });

  TallerState copyWith({
    bool? isLoading,
    List<TallerModel>? talleres,
    String? error,
  }) {
    return TallerState(
      isLoading: isLoading ?? this.isLoading,
      talleres: talleres ?? this.talleres,
      error: error,
    );
  }
}

class TallerNotifier extends StateNotifier<TallerState> {
  final ApiService _apiService = ApiService();

  TallerNotifier() : super(const TallerState());

  Future<void> cargarTalleres() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.dio.get(ApiConstants.talleres);
      final talleres = (response.data as List)
          .map((t) => TallerModel.fromJson(t))
          .toList();
      state = state.copyWith(isLoading: false, talleres: talleres);
    } on DioException catch (e) {
      final mensaje = e.response?.data['detail'] ?? 'Error al cargar talleres';
      state = state.copyWith(isLoading: false, error: mensaje);
    }
  }
}

final tallerProvider =
    StateNotifierProvider<TallerNotifier, TallerState>((ref) {
  return TallerNotifier();
});