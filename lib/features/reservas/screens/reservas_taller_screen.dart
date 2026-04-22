import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reserva_taller_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/reserva_model.dart';
import '../../mantenimiento/screens/registrar_mantenimiento_screen.dart';

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

    final pendientes =
        state.reservas.where((r) => r.estado == 'pendiente').toList();
    final confirmadas =
        state.reservas.where((r) => r.estado == 'confirmada').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reservas del taller'),
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
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pendientes.length}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white),
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
            Icon(Icons.calendar_today_outlined,
                size: 64, color: Colors.black12),
            SizedBox(height: 16),
            Text(
              'Sin reservas en esta categoría',
              style:
                  TextStyle(fontSize: 16, color: AppTheme.textSecondary),
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

  void _mostrarDialogoRechazo(
      BuildContext context, WidgetRef ref, String reservaId) {
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
                  .actualizarEstado(
                      reservaId, 'rechazada', controller.text);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _colorEstado(reserva.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    reserva.estado.toUpperCase(),
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${reserva.fecha} — ${reserva.horaInicio.substring(0, 5)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
            if (reserva.servicios.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.build,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reserva.servicios.map((s) => s.nombre).join(', '),
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
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
                            borderRadius: BorderRadius.circular(8)),
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
                            .actualizarEstado(
                                reserva.id, 'confirmada', null);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Confirmar',
                          style: TextStyle(color: Colors.white)),
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
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegistrarMantenimientoScreen(
                          reservaId: reserva.id,
                          servicioNombre: reserva.servicios
                              .map((s) => s.nombre)
                              .join(', '),
                          vehiculoInfo: reserva.vehiculo,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 18),
                  label: const Text('Registrar mantenimiento completado',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
