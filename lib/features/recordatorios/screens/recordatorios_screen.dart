import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recordatorio_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/recordatorio_model.dart';
import 'registro_recordatorio_screen.dart';

class RecordatoriosScreen extends ConsumerStatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  ConsumerState<RecordatoriosScreen> createState() =>
      _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends ConsumerState<RecordatoriosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(recordatorioProvider.notifier).cargarRecordatorios(),
    );
  }

  String _formatearFecha(DateTime fecha) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }

  Future<void> _confirmarEliminar(
      BuildContext context, RecordatorioModel recordatorio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar recordatorio'),
        content: Text(
          '¿Eliminar el recordatorio de "${recordatorio.tipoMantenimientoNombre}" '
          'para ${recordatorio.vehiculoMarca} ${recordatorio.vehiculoModelo}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      final exito = await ref
          .read(recordatorioProvider.notifier)
          .eliminarRecordatorio(recordatorio.id);
      if (!exito && context.mounted) {
        final error = ref.read(recordatorioProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Error al eliminar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordatorioProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Mis recordatorios'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.recordatorios.isEmpty
              ? _EstadoVacio(
                  onCrear: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegistroRecordatorioScreen(),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.recordatorios.length,
                  itemBuilder: (context, index) {
                    final r = state.recordatorios[index];
                    return _TarjetaRecordatorio(
                      recordatorio: r,
                      formatearFecha: _formatearFecha,
                      onEliminar: () => _confirmarEliminar(context, r),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RegistroRecordatorioScreen(),
            ),
          );
          if (context.mounted) {
            ref.read(recordatorioProvider.notifier).cargarRecordatorios();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── ESTADO VACÍO ────────────────────────────────────────────

class _EstadoVacio extends StatelessWidget {
  final VoidCallback onCrear;

  const _EstadoVacio({required this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes recordatorios',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCrear,
            icon: const Icon(Icons.add),
            label: const Text('Crear recordatorio'),
          ),
        ],
      ),
    );
  }
}

// ─── TARJETA DE RECORDATORIO ─────────────────────────────────

class _TarjetaRecordatorio extends StatelessWidget {
  final RecordatorioModel recordatorio;
  final String Function(DateTime) formatearFecha;
  final VoidCallback onEliminar;

  const _TarjetaRecordatorio({
    required this.recordatorio,
    required this.formatearFecha,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final fechaVencida = recordatorio.fechaProgramada != null &&
        recordatorio.fechaProgramada!.isBefore(
          DateTime(hoy.year, hoy.month, hoy.day),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado: título + badge origen + botón eliminar ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recordatorio.tipoMantenimientoNombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${recordatorio.vehiculoMarca} ${recordatorio.vehiculoModelo}'
                        '${recordatorio.vehiculoPlaca != null ? ' • ${recordatorio.vehiculoPlaca}' : ''}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Badge de origen — preparado para fase 2
                _BadgeOrigen(origen: recordatorio.origen),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onEliminar,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Info de fecha y/o km ──────────────────────────────
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (recordatorio.fechaProgramada != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        fechaVencida
                            ? Icons.warning_amber_rounded
                            : Icons.calendar_today_outlined,
                        size: 14,
                        color: fechaVencida
                            ? Colors.red
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatearFecha(recordatorio.fechaProgramada!),
                        style: TextStyle(
                          fontSize: 13,
                          color: fechaVencida
                              ? Colors.red
                              : AppTheme.textSecondary,
                          fontWeight: fechaVencida
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                if (recordatorio.kilometrajeProgramado != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.speed_outlined,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recordatorio.kilometrajeProgramado} km',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // ── Notas ─────────────────────────────────────────────
            if (recordatorio.textoPersonalizado != null &&
                recordatorio.textoPersonalizado!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                recordatorio.textoPersonalizado!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── BADGE DE ORIGEN ─────────────────────────────────────────

class _BadgeOrigen extends StatelessWidget {
  final String origen;

  const _BadgeOrigen({required this.origen});

  @override
  Widget build(BuildContext context) {
    final esAuto = origen == 'automatico';
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: esAuto
            ? AppTheme.primaryColor.withValues(alpha: 0.15)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: esAuto
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 11,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 3),
                Text(
                  'Auto',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            )
          : Text(
              'Manual',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
    );
  }
}
