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
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.mantenimientos.length,
                  itemBuilder: (context, index) {
                    return _TarjetaMantenimiento(
                      mantenimiento: state.mantenimientos[index],
                      vehiculoId: widget.vehiculoId,
                    );
                  },
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

class _TarjetaMantenimiento extends ConsumerWidget {
  final MantenimientoModel mantenimiento;
  final String vehiculoId;

  const _TarjetaMantenimiento({
    required this.mantenimiento,
    required this.vehiculoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.build,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo #${mantenimiento.tipoMantenimientoId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        mantenimiento.fecha,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Eliminar registro'),
                        content: const Text(
                            '¿Estás seguro de eliminar este registro?'),
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
                    }
                  },
                ),
              ],
            ),
            if (mantenimiento.kilometraje != null) ...[
              const SizedBox(height: 8),
              _InfoFila(icono: Icons.speed, texto: '${mantenimiento.kilometraje} km'),
            ],
            if (mantenimiento.tallerNombre != null) ...[
              const SizedBox(height: 4),
              _InfoFila(icono: Icons.store, texto: mantenimiento.tallerNombre!),
            ],
            if (mantenimiento.costo != null) ...[
              const SizedBox(height: 4),
              _InfoFila(
                  icono: Icons.attach_money,
                  texto: 'Bs. ${mantenimiento.costo!.toStringAsFixed(2)}'),
            ],
            if (mantenimiento.descripcion != null) ...[
              const SizedBox(height: 4),
              _InfoFila(icono: Icons.notes, texto: mantenimiento.descripcion!),
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
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}