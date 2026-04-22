import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../providers/reserva_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/reserva_model.dart';
import '../../../shared/services/api_service.dart';

class MisReservasScreen extends ConsumerStatefulWidget {
  const MisReservasScreen({super.key});

  @override
  ConsumerState<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends ConsumerState<MisReservasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(() {
      ref.read(reservaProvider.notifier).cargarReservasUsuario();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ReservaModel> _filtrar(List<ReservaModel> reservas, String tab) {
    final filtradas = reservas.where((r) {
      switch (tab) {
        case 'pendiente':
          return r.estado == 'pendiente';
        case 'confirmada':
          return r.estado == 'confirmada';
        case 'completada':
          return r.estado == 'completada';
        case 'rechazada':
          return r.estado == 'rechazada' || r.estado == 'cancelada';
        default:
          return false;
      }
    }).toList()
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    return filtradas;
  }

  Future<void> _recargar() =>
      ref.read(reservaProvider.notifier).cargarReservasUsuario();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservaProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Mis reservas'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Confirmadas'),
            Tab(text: 'Completadas'),
            Tab(text: 'Rechazadas'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _TabVista(
                  reservas: _filtrar(state.reservas, 'pendiente'),
                  emptyIcon: Icons.pending_outlined,
                  emptyMensaje: 'No tienes reservas pendientes',
                  onRefresh: _recargar,
                ),
                _TabVista(
                  reservas: _filtrar(state.reservas, 'confirmada'),
                  emptyIcon: Icons.check_circle_outline,
                  emptyMensaje: 'No tienes reservas confirmadas',
                  onRefresh: _recargar,
                ),
                _TabVista(
                  reservas: _filtrar(state.reservas, 'completada'),
                  emptyIcon: Icons.task_alt,
                  emptyMensaje: 'No tienes reservas completadas',
                  onRefresh: _recargar,
                ),
                _TabVista(
                  reservas: _filtrar(state.reservas, 'rechazada'),
                  emptyIcon: Icons.cancel_outlined,
                  emptyMensaje: 'No tienes reservas rechazadas ni canceladas',
                  onRefresh: _recargar,
                ),
              ],
            ),
    );
  }
}

class _TabVista extends StatelessWidget {
  final List<ReservaModel> reservas;
  final IconData emptyIcon;
  final String emptyMensaje;
  final Future<void> Function() onRefresh;

  const _TabVista({
    required this.reservas,
    required this.emptyIcon,
    required this.emptyMensaje,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (reservas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              emptyMensaje,
              style: const TextStyle(
                  fontSize: 16, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reservas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _TarjetaReserva(reserva: reservas[index]),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
            if (reserva.estado == 'completada') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              if (reserva.calificacion == null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => _CalificarBottomSheet(
                        reservaId: reserva.id,
                        tallerNombre: reserva.tallerNombre,
                        onCalificado: () => ref
                            .read(reservaProvider.notifier)
                            .cargarReservasUsuario(),
                      ),
                    ),
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: const Text('Calificar taller'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                )
              else ...[
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < reserva.calificacion! ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                ),
                if (reserva.comentarioCalificacion != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    reserva.comentarioCalificacion!,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CalificarBottomSheet extends StatefulWidget {
  final String reservaId;
  final String tallerNombre;
  final Future<void> Function() onCalificado;

  const _CalificarBottomSheet({
    required this.reservaId,
    required this.tallerNombre,
    required this.onCalificado,
  });

  @override
  State<_CalificarBottomSheet> createState() => _CalificarBottomSheetState();
}

class _CalificarBottomSheetState extends State<_CalificarBottomSheet> {
  int _estrellas = 0;
  final _comentarioController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_estrellas == 0) return;
    setState(() => _isLoading = true);
    try {
      await ApiService().dio.patch(
        '/reservas/${widget.reservaId}/calificar',
        data: {
          'calificacion': _estrellas,
          'comentario': _comentarioController.text.trim().isEmpty
              ? null
              : _comentarioController.text.trim(),
        },
      );
      await widget.onCalificado();
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.response?.data['detail'] ?? 'Error al enviar calificación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '¿Cómo fue tu experiencia en ${widget.tallerNombre}?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Estrellas
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => _estrellas = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _estrellas ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _comentarioController,
            decoration: InputDecoration(
              hintText: 'Agrega un comentario (opcional)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _estrellas == 0 || _isLoading ? null : _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Enviar calificación',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
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