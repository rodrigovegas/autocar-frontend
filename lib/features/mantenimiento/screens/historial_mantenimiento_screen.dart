import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mantenimiento_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/mantenimiento_model.dart';
import 'registro_mantenimiento_screen.dart';

class HistorialMantenimientoScreen extends ConsumerStatefulWidget {
  final String vehiculoId;
  final String vehiculoNombre;

  const HistorialMantenimientoScreen({
    super.key,
    required this.vehiculoId,
    required this.vehiculoNombre,
  });

  @override
  ConsumerState<HistorialMantenimientoScreen> createState() =>
      _HistorialMantenimientoScreenState();
}

class _HistorialMantenimientoScreenState
    extends ConsumerState<HistorialMantenimientoScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(mantenimientoProvider.notifier)
          .cargarPorVehiculo(widget.vehiculoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mantenimientoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historial de mantenimiento',
                style: TextStyle(fontSize: 14)),
            Text(
              widget.vehiculoNombre,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegistroMantenimientoScreen(
                vehiculoId: widget.vehiculoId,
              ),
            ),
          );
          if (context.mounted) {
            ref
                .read(mantenimientoProvider.notifier)
                .cargarPorVehiculo(widget.vehiculoId);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.mantenimientos.isEmpty
              ? _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.mantenimientos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final m = state.mantenimientos[index];
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
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _DetalleMantenimientoScreen(
                              mantenimiento: m,
                              vehiculoId: widget.vehiculoId,
                            ),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.build_circle_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tipo #${m.tipoMantenimientoId}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      m.fecha,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.green
                                          .withValues(alpha: 0.4)),
                                ),
                                child: const Text(
                                  'COMPLETADO',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 13,
                                  color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── PANTALLA DE DETALLE ──────────────────────────────────────

class _DetalleMantenimientoScreen extends ConsumerWidget {
  final MantenimientoModel mantenimiento;
  final String vehiculoId;

  const _DetalleMantenimientoScreen({
    required this.mantenimiento,
    required this.vehiculoId,
  });

  Future<void> _eliminar(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar registro'),
        content:
            const Text('¿Estás seguro de eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      ref.read(mantenimientoProvider.notifier).eliminar(
            mantenimiento.id,
            vehiculoId,
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = mantenimiento;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Detalle del mantenimiento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.build_circle_outlined,
                            color: AppTheme.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipo #${m.tipoMantenimientoId}',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Registro de mantenimiento',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  _CampoDetalle(
                    icono: Icons.calendar_today,
                    label: 'Fecha',
                    valor: m.fecha,
                  ),
                  if (m.kilometraje != null) ...[
                    const SizedBox(height: 14),
                    _CampoDetalle(
                      icono: Icons.speed,
                      label: 'Kilometraje',
                      valor: '${m.kilometraje} km',
                    ),
                  ],
                  if (m.costo != null) ...[
                    const SizedBox(height: 14),
                    _CampoDetalle(
                      icono: Icons.attach_money,
                      label: 'Costo',
                      valor: 'Bs. ${m.costo!.toStringAsFixed(2)}',
                    ),
                  ],
                  if (m.tallerNombre != null) ...[
                    const SizedBox(height: 14),
                    _CampoDetalle(
                      icono: Icons.store_outlined,
                      label: 'Taller',
                      valor: m.tallerNombre!,
                    ),
                  ],
                  if (m.descripcion != null &&
                      m.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _CampoDetalle(
                      icono: Icons.notes,
                      label: 'Descripción',
                      valor: m.descripcion!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _eliminar(context, ref),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Eliminar registro',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGETS COMPARTIDOS ──────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Sin registros de mantenimiento',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca el botón para registrar el primer mantenimiento',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CampoDetalle extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _CampoDetalle({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
