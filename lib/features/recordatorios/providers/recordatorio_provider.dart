import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/recordatorio_model.dart';

class RecordatorioState {
  final bool isLoading;
  final List<RecordatorioModel> recordatorios;
  final String? error;

  const RecordatorioState({
    this.isLoading = false,
    this.recordatorios = const [],
    this.error,
  });

  RecordatorioState copyWith({
    bool? isLoading,
    List<RecordatorioModel>? recordatorios,
    String? error,
  }) {
    return RecordatorioState(
      isLoading: isLoading ?? this.isLoading,
      recordatorios: recordatorios ?? this.recordatorios,
      error: error,
    );
  }
}

class RecordatorioNotifier extends StateNotifier<RecordatorioState> {
  final ApiService _apiService = ApiService();

  RecordatorioNotifier() : super(const RecordatorioState());

  Future<void> cargarRecordatorios() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.dio.get(ApiConstants.recordatorios);
      final recordatorios = (response.data as List)
          .map((r) => RecordatorioModel.fromJson(r))
          .toList();
      state = state.copyWith(isLoading: false, recordatorios: recordatorios);
    } on DioException catch (e) {
      final mensaje =
          e.response?.data['detail'] ?? 'Error al cargar recordatorios';
      state = state.copyWith(isLoading: false, error: mensaje);
    }
  }

  Future<bool> crearRecordatorio({
    required String vehiculoId,
    required String tipoMantenimientoId,
    DateTime? fechaProgramada,
    int? kilometrajeProgramado,
    String? textoPersonalizado,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.dio.post(
        ApiConstants.recordatorios,
        data: {
          'vehiculo_id': vehiculoId,
          'tipo_mantenimiento_id': tipoMantenimientoId,
          if (fechaProgramada != null)
            'fecha_programada':
                '${fechaProgramada.year}-${fechaProgramada.month.toString().padLeft(2, '0')}-${fechaProgramada.day.toString().padLeft(2, '0')}',
          if (kilometrajeProgramado != null)
            'kilometraje_programado': kilometrajeProgramado,
          if (textoPersonalizado != null && textoPersonalizado.isNotEmpty)
            'texto_personalizado': textoPersonalizado,
        },
      );
      await cargarRecordatorios();
      return true;
    } on DioException catch (e) {
      final mensaje =
          e.response?.data['detail'] ?? 'Error al crear recordatorio';
      state = state.copyWith(isLoading: false, error: mensaje);
      return false;
    }
  }

  Future<bool> eliminarRecordatorio(String recordatorioId) async {
    try {
      await _apiService.dio
          .delete('${ApiConstants.recordatorios}/$recordatorioId');
      await cargarRecordatorios();
      return true;
    } on DioException catch (e) {
      final mensaje =
          e.response?.data['detail'] ?? 'Error al eliminar recordatorio';
      state = state.copyWith(error: mensaje);
      return false;
    }
  }
}

final recordatorioProvider =
    StateNotifierProvider<RecordatorioNotifier, RecordatorioState>(
  (ref) => RecordatorioNotifier(),
);
