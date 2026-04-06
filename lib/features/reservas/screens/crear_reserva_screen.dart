import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reserva_provider.dart';
import '../../vehiculos/providers/vehiculo_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/taller_model.dart';

class CrearReservaScreen extends ConsumerStatefulWidget {
  final TallerModel taller;

  const CrearReservaScreen({super.key, required this.taller});

  @override
  ConsumerState<CrearReservaScreen> createState() =>
      _CrearReservaScreenState();
}

class _CrearReservaScreenState extends ConsumerState<CrearReservaScreen> {
  String? _vehiculoSeleccionado;
  String? _disponibilidadSeleccionada;
  final Set<String> _serviciosSeleccionados = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(vehiculoProvider.notifier).cargarVehiculos();
      ref
          .read(reservaProvider.notifier)
          .cargarDisponibilidad(widget.taller.id);
    });
  }

  Future<void> _confirmarReserva() async {
    if (_vehiculoSeleccionado == null) {
      _mostrarError('Selecciona un vehículo');
      return;
    }
    if (_disponibilidadSeleccionada == null) {
      _mostrarError('Selecciona un horario disponible');
      return;
    }
    if (_serviciosSeleccionados.isEmpty) {
      _mostrarError('Selecciona al menos un servicio');
      return;
    }

    final exito = await ref.read(reservaProvider.notifier).crearReserva(
          tallerId: widget.taller.id,
          vehiculoId: _vehiculoSeleccionado!,
          disponibilidadId: _disponibilidadSeleccionada!,
          serviciosIds: _serviciosSeleccionados.toList(),
        );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      final error = ref.read(reservaProvider).error;
      _mostrarError(error ?? 'Error al crear la reserva');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservaState = ref.watch(reservaProvider);
    final vehiculoState = ref.watch(vehiculoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nueva reserva', style: TextStyle(fontSize: 14)),
            Text(
              widget.taller.nombre,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: reservaState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECCIÓN 1 — Vehículo
                  _SeccionTitulo(
                      numero: '1', titulo: 'Selecciona tu vehículo'),
                  const SizedBox(height: 8),
                  if (vehiculoState.vehiculos.isEmpty)
                    const Text(
                      'No tienes vehículos registrados.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _vehiculoSeleccionado,
                      hint: const Text('Selecciona un vehículo'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: vehiculoState.vehiculos
                          .map((v) => DropdownMenuItem(
                                value: v.id,
                                child: Text(
                                    '${v.marca} ${v.modelo} ${v.anio}'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _vehiculoSeleccionado = v),
                    ),

                  const SizedBox(height: 24),

                  // SECCIÓN 2 — Horario
                  _SeccionTitulo(
                      numero: '2', titulo: 'Selecciona un horario'),
                  const SizedBox(height: 8),
                  if (reservaState.disponibilidades.isEmpty)
                    const Text(
                      'No hay horarios disponibles para este taller.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _disponibilidadSeleccionada,
                      hint: const Text('Selecciona un horario'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: reservaState.disponibilidades
                          .map((d) => DropdownMenuItem(
                                value: d.id,
                                child: Text(
                                  '${d.etiqueta} (${d.cuposDisponibles} cupos)',
                                ),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _disponibilidadSeleccionada = v),
                    ),

                  const SizedBox(height: 24),

                  // SECCIÓN 3 — Servicios
                  _SeccionTitulo(
                      numero: '3', titulo: 'Selecciona los servicios'),
                  const SizedBox(height: 8),
                  if (widget.taller.servicios.isEmpty)
                    const Text(
                      'Este taller no tiene servicios configurados.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  else
                    ...widget.taller.servicios.map((servicio) {
                      final seleccionado =
                          _serviciosSeleccionados.contains(servicio.id);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: seleccionado
                                ? AppTheme.primaryColor
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: seleccionado,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _serviciosSeleccionados.add(servicio.id);
                              } else {
                                _serviciosSeleccionados.remove(servicio.id);
                              }
                            });
                          },
                          title: Text(servicio.nombre,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: servicio.precio != null
                              ? Text('Bs. ${servicio.precio}',
                                  style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 13))
                              : null,
                          activeColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          reservaState.isLoading ? null : _confirmarReserva,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: reservaState.isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              'Confirmar reserva',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  final String numero;
  final String titulo;

  const _SeccionTitulo({required this.numero, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            numero,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}