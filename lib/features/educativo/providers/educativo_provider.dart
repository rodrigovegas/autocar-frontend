import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/educativo_model.dart';

class EducativoState {
  final bool isLoading;
  final List<ContenidoEducativoModel> contenidos;
  final String? error;

  const EducativoState({
    this.isLoading = false,
    this.contenidos = const [],
    this.error,
  });

  EducativoState copyWith({
    bool? isLoading,
    List<ContenidoEducativoModel>? contenidos,
    String? error,
  }) {
    return EducativoState(
      isLoading: isLoading ?? this.isLoading,
      contenidos: contenidos ?? this.contenidos,
      error: error,
    );
  }
}

class EducativoNotifier extends StateNotifier<EducativoState> {
  final ApiService _apiService = ApiService();

  EducativoNotifier() : super(const EducativoState());

  Future<void> cargarContenidos() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.dio.get('${ApiConstants.educativo}/');
      final lista = (response.data as List)
          .map((e) => ContenidoEducativoModel.fromJson(e))
          .toList();
      state = state.copyWith(isLoading: false, contenidos: lista);
    } on DioException catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar el contenido educativo',
      );
    }
  }
}

final educativoProvider =
    StateNotifierProvider<EducativoNotifier, EducativoState>((ref) {
      return EducativoNotifier();
    });
