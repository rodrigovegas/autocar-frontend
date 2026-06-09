import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/asistente_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/mensaje_model.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/vehiculo_model.dart';

class AsistenteScreen extends ConsumerStatefulWidget {
  const AsistenteScreen({super.key});

  @override
  ConsumerState<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends ConsumerState<AsistenteScreen> {
  final _mensajeController = TextEditingController();
  final _scrollController = ScrollController();
  List<VehiculoModel> _vehiculos = [];
  VehiculoModel? _vehiculoSeleccionado;
  bool _cargandoVehiculos = true;

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollAlFinal() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _cargarVehiculos() async {
    try {
      final response = await ApiService().dio.get(ApiConstants.vehiculos);
      setState(() {
        _vehiculos = (response.data as List)
            .map((e) => VehiculoModel.fromJson(e))
            .where((v) => v.activo)
            .toList();
        if (_vehiculos.length == 1) {
          _vehiculoSeleccionado = _vehiculos.first;
        }
        _cargandoVehiculos = false;
      });
    } catch (_) {
      setState(() => _cargandoVehiculos = false);
    }
  }

  Future<void> _enviarMensaje() async {
    final mensaje = _mensajeController.text.trim();
    if (mensaje.isEmpty) return;
    _mensajeController.clear();
    await ref.read(asistenteProvider.notifier).enviarMensaje(
      mensaje,
      vehiculoId: _vehiculoSeleccionado?.id,
    );
    _scrollAlFinal();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(asistenteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Icon(
                Icons.smart_toy_outlined,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Asistente AutoCar', style: TextStyle(fontSize: 14)),
                Text(
                  'Especialista en mantenimiento vehicular',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Limpiar conversación',
            onPressed: () {
              ref.read(asistenteProvider.notifier).limpiarChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Mensaje de bienvenida si no hay mensajes
          if (state.mensajes.isEmpty)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Asistente de mantenimiento vehicular',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedo ayudarte con preguntas sobre el cuidado '
                      'y mantenimiento preventivo de tu vehículo.',
                      style: TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Preguntas frecuentes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._preguntasSugeridas.map(
                      (pregunta) => _PreguntaSugerida(
                        pregunta: pregunta,
                        onTap: () {
                          _mensajeController.text = pregunta;
                          _enviarMensaje();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.mensajes.length + (state.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.mensajes.length && state.isLoading) {
                    return const _BurbujaCargando();
                  }
                  final mensaje = state.mensajes[index];
                  return _BurbujaMensaje(mensaje: mensaje);
                },
              ),
            ),

          if (_cargandoVehiculos)
            const LinearProgressIndicator()
          else if (_vehiculos.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.directions_car, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<VehiculoModel>(
                        value: _vehiculoSeleccionado,
                        hint: const Text('Seleccioná tu vehículo', style: TextStyle(fontSize: 13)),
                        isExpanded: true,
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                        items: _vehiculos.map((v) => DropdownMenuItem(
                          value: v,
                          child: Text('${v.marca} ${v.modelo} ${v.anio}'),
                        )).toList(),
                        onChanged: (v) => setState(() => _vehiculoSeleccionado = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Campo de entrada
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu pregunta...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    enabled: _vehiculos.isEmpty || _vehiculoSeleccionado != null,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviarMensaje(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: state.isLoading
                      ? AppTheme.textSecondary
                      : AppTheme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: state.isLoading ? null : _enviarMensaje,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Preguntas sugeridas
const List<String> _preguntasSugeridas = [
  '¿Cada cuánto debo cambiar el aceite?',
  '¿Cómo sé si mis frenos necesitan revisión?',
  '¿Qué es el mantenimiento preventivo?',
  '¿Cada cuánto debo revisar los neumáticos?',
];

class _PreguntaSugerida extends StatelessWidget {
  final String pregunta;
  final VoidCallback onTap;

  const _PreguntaSugerida({required this.pregunta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pregunta,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _BurbujaMensaje extends StatelessWidget {
  final MensajeModel mensaje;

  const _BurbujaMensaje({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: mensaje.esUsuario
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mensaje.esUsuario) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: mensaje.esUsuario ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: mensaje.esUsuario
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: mensaje.esUsuario
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: mensaje.esUsuario
                  ? Text(
                      mensaje.contenido,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    )
                  : MarkdownBody(
                      data: mensaje.contenido,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        strong: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
            ),
          ),
          if (mensaje.esUsuario) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.backgroundColor,
              child: Icon(
                Icons.person_outline,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BurbujaCargando extends StatelessWidget {
  const _BurbujaCargando();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor,
            child: Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'El asistente está escribiendo...',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
