import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/mensaje_model.dart';

class AsistenteState {
  final bool isLoading;
  final List<MensajeModel> mensajes;
  final String? error;

  const AsistenteState({
    this.isLoading = false,
    this.mensajes = const [],
    this.error,
  });

  AsistenteState copyWith({
    bool? isLoading,
    List<MensajeModel>? mensajes,
    String? error,
  }) {
    return AsistenteState(
      isLoading: isLoading ?? this.isLoading,
      mensajes: mensajes ?? this.mensajes,
      error: error,
    );
  }
}

class AsistenteNotifier extends StateNotifier<AsistenteState> {
  final ApiService _apiService = ApiService();

  AsistenteNotifier() : super(const AsistenteState());

  Future<void> enviarMensaje(String mensaje) async {
    // Agregar mensaje del usuario a la lista
    final mensajeUsuario = MensajeModel(
      contenido: mensaje,
      esUsuario: true,
      fecha: DateTime.now(),
    );

    state = state.copyWith(
      isLoading: true,
      error: null,
      mensajes: [...state.mensajes, mensajeUsuario],
    );

    try {
      // Construir historial para enviar al backend
      final historial = state.mensajes
          .where((m) => !m.esUsuario || m != mensajeUsuario)
          .map((m) => {
                'rol': m.esUsuario ? 'user' : 'model',
                'contenido': m.contenido,
              })
          .toList();

      final response = await _apiService.dio.post(
        ApiConstants.asistente,
        data: {
          'mensaje': mensaje,
          'historial': historial,
        },
      );

      final respuestaIA = MensajeModel(
        contenido: response.data['respuesta'],
        esUsuario: false,
        fecha: DateTime.now(),
      );

      state = state.copyWith(
        isLoading: false,
        mensajes: [...state.mensajes, respuestaIA],
      );
    } on DioException catch (_) {
      final mensajeError = MensajeModel(
        contenido:
            'El asistente no está disponible en este momento. Intenta más tarde.',
        esUsuario: false,
        fecha: DateTime.now(),
      );
      state = state.copyWith(
        isLoading: false,
        mensajes: [...state.mensajes, mensajeError],
      );
    }
  }

  void limpiarChat() {
    state = const AsistenteState();
  }
}

final asistenteProvider =
    StateNotifierProvider<AsistenteNotifier, AsistenteState>((ref) {
  return AsistenteNotifier();
});