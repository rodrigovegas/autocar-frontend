import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reserva_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/reserva_model.dart';

class MisReservasScreen extends ConsumerStatefulWidget {
  const MisReservasScreen({super.key});

  @override
  ConsumerState<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends ConsumerState<MisReservasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reservaProvider.notifier).cargarReservasUsuario();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis reservas'),
        automaticallyImplyLeading: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.reservas.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(reservaProvider.notifier)
                      .cargarReservasUsuario(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.reservas.length,
                    itemBuilder: (context, index) {
                      return _TarjetaReserva(
                        reserva: state.reservas[index],
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No tienes reservas activas',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ve al mapa de talleres para hacer una reserva',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TarjetaReserva extends ConsumerWidget {
  final ReservaModel reserva;

  const _TarjetaReserva({required this.reserva});

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'rechazada':
        return Colors.red;
      case 'cancelada':
        return Colors.grey;
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
                    reserva.tallerNombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
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
            _InfoFila(
              icono: Icons.directions_car,
              texto: reserva.vehiculo,
            ),
            const SizedBox(height: 4),
            _InfoFila(
              icono: Icons.calendar_today,
              texto:
                  '${reserva.fecha} — ${reserva.horaInicio.substring(0, 5)}',
            ),
            if (reserva.servicios.isNotEmpty) ...[
              const SizedBox(height: 4),
              _InfoFila(
                icono: Icons.build,
                texto: reserva.servicios.map((s) => s.nombre).join(', '),
              ),
            ],
            if (reserva.motivoRechazo != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reserva.motivoRechazo!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (reserva.estado == 'pendiente') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Cancelar reserva'),
                        content: const Text(
                            '¿Estás seguro de cancelar esta reserva?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sí, cancelar',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirmar == true && context.mounted) {
                      await ref
                          .read(reservaProvider.notifier)
                          .cancelarReserva(reserva.id);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancelar reserva'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoFila extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _InfoFila({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}