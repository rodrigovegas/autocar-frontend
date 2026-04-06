import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/taller_model.dart';

// ─── Provider de LISTA de talleres (para el mapa) ───────────────────────────

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
      final lista = (response.data as List)
          .map((e) => TallerModel.fromJson(e))
          .toList();
      state = state.copyWith(isLoading: false, talleres: lista);
    } on DioException catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar los talleres',
      );
    }
  }
}

final tallerProvider =
    StateNotifierProvider<TallerNotifier, TallerState>((ref) {
  return TallerNotifier();
});

// ─── Provider de DETALLE de un taller (para reservas) ───────────────────────

class TallerDetalleState {
  final bool isLoading;
  final TallerModel? taller;
  final String? error;

  const TallerDetalleState({
    this.isLoading = false,
    this.taller,
    this.error,
  });

  TallerDetalleState copyWith({
    bool? isLoading,
    TallerModel? taller,
    String? error,
  }) {
    return TallerDetalleState(
      isLoading: isLoading ?? this.isLoading,
      taller: taller ?? this.taller,
      error: error,
    );
  }
}

class TallerDetalleNotifier extends StateNotifier<TallerDetalleState> {
  final ApiService _apiService = ApiService();

  TallerDetalleNotifier() : super(const TallerDetalleState());

  Future<TallerModel?> cargarDetalle(String tallerId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.dio.get(
        '${ApiConstants.talleres}/$tallerId',
      );
      final taller = TallerModel.fromJson(response.data);
      state = state.copyWith(isLoading: false, taller: taller);
      return taller;
    } on DioException catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar el detalle del taller',
      );
      return null;
    }
  }
}

final tallerDetalleProvider =
    StateNotifierProvider<TallerDetalleNotifier, TallerDetalleState>((ref) {
  return TallerDetalleNotifier();
});