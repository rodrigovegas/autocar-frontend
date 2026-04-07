import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/reserva_taller_provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/reserva_model.dart';

class ReservasTallerScreen extends ConsumerStatefulWidget {
  const ReservasTallerScreen({super.key});

  @override
  ConsumerState<ReservasTallerScreen> createState() =>
      _ReservasTallerScreenState();
}

class _ReservasTallerScreenState extends ConsumerState<ReservasTallerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reservaTallerProvider.notifier).cargarReservas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservaTallerProvider);

    final pendientes = state.reservas
        .where((r) => r.estado == 'pendiente')
        .toList();
    final confirmadas = state.reservas
        .where((r) => r.estado == 'confirmada')
        .toList();
    final completadas = state.reservas
        .where((r) => r.estado == 'completada')
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reservas del taller'),
          backgroundColor: const Color(0xFF15803D),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pendientes'),
                    if (pendientes.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pendientes.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Confirmadas'),
            ],
          ),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildLista(pendientes, ref),
                  _buildLista(confirmadas, ref),
                ],
              ),
      ),
    );
  }

  Widget _buildLista(List<ReservaModel> reservas, WidgetRef ref) {
    if (reservas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.black12,
            ),
            SizedBox(height: 16),
            Text(
              'Sin reservas en esta categoría',
              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(reservaTallerProvider.notifier).cargarReservas(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservas.length,
        itemBuilder: (context, index) {
          return _TarjetaReservaTaller(reserva: reservas[index]);
        },
      ),
    );
  }
}

class _TarjetaReservaTaller extends ConsumerWidget {
  final ReservaModel reserva;

  const _TarjetaReservaTaller({required this.reserva});

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'completada':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _colorEstado(reserva.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reserva.vehiculo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    reserva.estado.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${reserva.fecha} — ${reserva.horaInicio.substring(0, 5)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (reserva.servicios.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.build,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reserva.servicios.map((s) => s.nombre).join(', '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Botones según estado
            if (reserva.estado == 'pendiente') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _mostrarDialogoRechazo(context, ref, reserva.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(reservaTallerProvider.notifier)
                            .actualizarEstado(reserva.id, 'confirmada', null);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (reserva.estado == 'confirmada') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _mostrarFormularioCompletar(context, ref, reserva),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Registrar mantenimiento completado',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoRechazo(
    BuildContext context,
    WidgetRef ref,
    String reservaId,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rechazar reserva'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Motivo del rechazo...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(reservaTallerProvider.notifier)
                  .actualizarEstado(reservaId, 'rechazada', controller.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Rechazar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioCompletar(
    BuildContext context,
    WidgetRef ref,
    ReservaModel reserva,
  ) {
    final kmController = TextEditingController();
    final costoController = TextEditingController();
    final detalleTecnicoController = TextEditingController(
      text: _generarTemplate(reserva),
    );
    final recomendacionesController = TextEditingController();
    final kmProximoController = TextEditingController();

    DateTime fechaSeleccionada = DateTime.now();
    DateTime? fechaProximo;
    String? gravedad;
    final problemasSeleccionados = <String>{};

    const problemas = [
      'Fuga de aceite',
      'Pastillas de freno desgastadas',
      'Batería débil',
      'Sobrecalentamiento',
      'Ruido extraño',
      'Fuga de refrigerante',
      'Otro',
    ];

    const gravedades = ['Baja', 'Media', 'Alta'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Título
                    Text(
                      'Registrar mantenimiento',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${reserva.vehiculo} — ${reserva.servicios.map((s) => s.nombre).join(", ")}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── A. INFORMACIÓN GENERAL ───
                    _SeccionFormulario(titulo: 'A. Información general'),
                    const SizedBox(height: 12),

                    // Fecha
                    GestureDetector(
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaSeleccionada,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (fecha != null) {
                          setModalState(() => fechaSeleccionada = fecha);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF15803D),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Fecha: ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Kilometraje
                    TextField(
                      controller: kmController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Kilometraje actual *',
                        prefixIcon: const Icon(Icons.speed),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Costo
                    TextField(
                      controller: costoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Costo en Bs. (opcional)',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── B. DETALLE TÉCNICO ───
                    _SeccionFormulario(titulo: 'B. Detalle técnico'),
                    const SizedBox(height: 4),
                    const Text(
                      'Template generado según los servicios de la reserva. Puedes editarlo libremente.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detalleTecnicoController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),
                    const SizedBox(height: 24),

                    // ─── C. PROBLEMAS DETECTADOS ───
                    _SeccionFormulario(titulo: 'C. Problemas detectados'),
                    const SizedBox(height: 12),
                    ...problemas.map(
                      (p) => CheckboxListTile(
                        value: problemasSeleccionados.contains(p),
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              problemasSeleccionados.add(p);
                            } else {
                              problemasSeleccionados.remove(p);
                            }
                          });
                        },
                        title: Text(p, style: const TextStyle(fontSize: 14)),
                        activeColor: const Color(0xFF15803D),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Gravedad
                    if (problemasSeleccionados.isNotEmpty) ...[
                      const Text(
                        'Gravedad de los problemas:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: gravedades.map((g) {
                          final seleccionada = gravedad == g;
                          Color color;
                          switch (g) {
                            case 'Alta':
                              color = Colors.red;
                              break;
                            case 'Media':
                              color = Colors.orange;
                              break;
                            default:
                              color = Colors.green;
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setModalState(() => gravedad = g),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: seleccionada
                                      ? color
                                      : color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: color),
                                ),
                                child: Text(
                                  g,
                                  style: TextStyle(
                                    color: seleccionada ? Colors.white : color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ─── D. RECOMENDACIONES FUTURAS ───
                    _SeccionFormulario(titulo: 'D. Recomendaciones futuras'),
                    const SizedBox(height: 12),

                    // Km próximo mantenimiento
                    TextField(
                      controller: kmProximoController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Km para próximo mantenimiento',
                        prefixIcon: const Icon(Icons.speed_outlined),
                        hintText: 'Ej: 50000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Fecha próximo mantenimiento
                    GestureDetector(
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 180),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 1095),
                          ),
                        );
                        if (fecha != null) {
                          setModalState(() => fechaProximo = fecha);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_outlined,
                              color: Color(0xFF15803D),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              fechaProximo != null
                                  ? 'Próximo: ${fechaProximo!.day}/${fechaProximo!.month}/${fechaProximo!.year}'
                                  : 'Fecha estimada próximo mantenimiento',
                              style: TextStyle(
                                fontSize: 14,
                                color: fechaProximo != null
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Recomendaciones
                    TextField(
                      controller: recomendacionesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notas del mecánico (opcional)',
                        hintText:
                            'Ej: Revisar frenos en 2 meses, cambiar batería pronto...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón guardar
                    ElevatedButton(
                      onPressed: () async {
                        if (kmController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ingresa el kilometraje'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        try {
                          final fecha =
                              '${fechaSeleccionada.year}-${fechaSeleccionada.month.toString().padLeft(2, '0')}-${fechaSeleccionada.day.toString().padLeft(2, '0')}';

                          final data = {
                            'reserva_id': reserva.id,
                            'kilometraje_registro': int.parse(
                              kmController.text,
                            ),
                            'fecha_realizado': fecha,
                            if (costoController.text.isNotEmpty)
                              'costo': double.tryParse(costoController.text),
                            if (detalleTecnicoController.text.isNotEmpty)
                              'detalle_tecnico': detalleTecnicoController.text,
                            if (problemasSeleccionados.isNotEmpty)
                              'problemas_detectados': problemasSeleccionados
                                  .join(', '),
                            if (gravedad != null)
                              'gravedad_problemas': gravedad,
                            if (kmProximoController.text.isNotEmpty)
                              'km_proximo_mantenimiento': int.tryParse(
                                kmProximoController.text,
                              ),
                            if (fechaProximo != null)
                              'fecha_proximo_mantenimiento':
                                  '${fechaProximo!.year}-${fechaProximo!.month.toString().padLeft(2, '0')}-${fechaProximo!.day.toString().padLeft(2, '0')}',
                            if (recomendacionesController.text.isNotEmpty)
                              'recomendaciones': recomendacionesController.text,
                          };

                          await ApiService().dio.post(
                            '${ApiConstants.mantenimientos}/',
                            data: data,
                          );
                          await ref
                              .read(reservaTallerProvider.notifier)
                              .cargarReservas();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Mantenimiento registrado correctamente',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } on DioException catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.response?.data['detail'] ??
                                      'Error al registrar',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Guardar mantenimiento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  

  String _generarTemplate(ReservaModel reserva) {
    final servicios = reserva.servicios
        .map((s) => s.nombre.toLowerCase())
        .toList();
    final buffer = StringBuffer();

    if (servicios.any((s) => s.contains('aceite'))) {
      buffer.writeln('CAMBIO DE ACEITE:');
      buffer.writeln('- Aceite cambiado: Sí / No');
      buffer.writeln('- Tipo de aceite: ');
      buffer.writeln('- Filtro reemplazado: Sí / No');
      buffer.writeln('- Estado general del motor: Bueno / Regular / Malo');
      buffer.writeln();
    }

    if (servicios.any((s) => s.contains('freno'))) {
      buffer.writeln('REVISIÓN DE FRENOS:');
      buffer.writeln(
        '- Pastillas delanteras: Buenas / Desgastadas / Reemplazadas / No revisado',
      );
      buffer.writeln(
        '- Pastillas traseras: Buenas / Desgastadas / Reemplazadas / No revisado',
      );
      buffer.writeln(
        '- Líquido de frenos: Normal / Bajo / Reemplazado / No revisado',
      );
      buffer.writeln('- Discos: Buen estado / Desgastados / No revisado');
      buffer.writeln();
    }

    if (servicios.any(
      (s) => s.contains('neumático') || s.contains('neumatico'),
    )) {
      buffer.writeln('REVISIÓN DE NEUMÁTICOS:');
      buffer.writeln(
        '- Estado general: Buen estado / Desgaste medio / Desgastado / No revisado',
      );
      buffer.writeln('- Presión verificada: Sí / No');
      buffer.writeln('- Alineación recomendada: Sí / No / No revisado');
      buffer.writeln();
    }

    if (servicios.any((s) => s.contains('batería') || s.contains('bateria'))) {
      buffer.writeln('REVISIÓN DE BATERÍA:');
      buffer.writeln('- Estado: Buena / Débil / Requiere cambio / No revisado');
      buffer.writeln('- Terminales limpios: Sí / No / No revisado');
      buffer.writeln();
    }

    if (servicios.any((s) => s.contains('general'))) {
      buffer.writeln('REVISIÓN GENERAL:');
      buffer.writeln('- Motor: Bueno / Regular / Malo / No revisado');
      buffer.writeln(
        '- Frenos: Bueno / Desgastado / Requiere cambio / No revisado',
      );
      buffer.writeln(
        '- Batería: Buena / Débil / Requiere cambio / No revisado',
      );
      buffer.writeln(
        '- Neumáticos: Buen estado / Desgaste medio / Desgastado / No revisado',
      );
      buffer.writeln('- Luces: Funcionando / Con fallas / No revisado');
      buffer.writeln('- Refrigerante: Normal / Bajo / No revisado');
      buffer.writeln(
        '- Suspensión: Buena / Regular / Requiere revisión / No revisado',
      );
      buffer.writeln();
    }

    if (servicios.any((s) => s.contains('filtro'))) {
      buffer.writeln('CAMBIO DE FILTRO DE AIRE:');
      buffer.writeln('- Filtro reemplazado: Sí / No');
      buffer.writeln(
        '- Estado anterior: Sucio / Muy sucio / Dañado / No revisado',
      );
      buffer.writeln();
    }

    if (servicios.any((s) => s.contains('refrigerante'))) {
      buffer.writeln('REVISIÓN DE REFRIGERANTE:');
      buffer.writeln('- Nivel: Normal / Bajo / No revisado');
      buffer.writeln('- Líquido reemplazado: Sí / No');
      buffer.writeln('- Estado del sistema: Bueno / Con fugas / No revisado');
      buffer.writeln();
    }

    buffer.writeln('OBSERVACIONES ADICIONALES:');
    buffer.writeln('');

    return buffer.toString().trim();
  }
}

class _SeccionFormulario extends StatelessWidget {
  final String titulo;

  const _SeccionFormulario({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
