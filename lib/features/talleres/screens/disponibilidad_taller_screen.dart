import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class DisponibilidadModel {
  final String id;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final int cuposTotales;
  final int cuposOcupados;
  final bool activo;

  DisponibilidadModel({
    required this.id,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.cuposTotales,
    required this.cuposOcupados,
    required this.activo,
  });

  factory DisponibilidadModel.fromJson(Map<String, dynamic> json) {
    return DisponibilidadModel(
      id: json['id'].toString(),
      fecha: json['fecha'],
      horaInicio: json['hora_inicio'],
      horaFin: json['hora_fin'],
      cuposTotales: json['cupos_totales'],
      cuposOcupados: json['cupos_ocupados'],
      activo: json['activo'],
    );
  }
}

class DisponibilidadTallerScreen extends StatefulWidget {
  const DisponibilidadTallerScreen({super.key});

  @override
  State<DisponibilidadTallerScreen> createState() =>
      _DisponibilidadTallerScreenState();
}

class _DisponibilidadTallerScreenState
    extends State<DisponibilidadTallerScreen> {
  bool _isLoading = false;
  Map<String, List<DisponibilidadModel>> _agrupadas = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().dio.get(
        '${ApiConstants.disponibilidad}/taller',
      );
      final lista = (response.data as List)
          .map((e) => DisponibilidadModel.fromJson(e))
          .toList();

      final Map<String, List<DisponibilidadModel>> agrupadas = {};
      for (final d in lista) {
        agrupadas.putIfAbsent(d.fecha, () => []).add(d);
      }

      final fechasOrdenadas = agrupadas.keys.toList()..sort();
      final Map<String, List<DisponibilidadModel>> ordenadas = {};
      for (final f in fechasOrdenadas) {
        ordenadas[f] = agrupadas[f]!
          ..sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
      }

      setState(() => _agrupadas = ordenadas);
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar la disponibilidad')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActivo(DisponibilidadModel d) async {
    try {
      await ApiService().dio.patch(
        '${ApiConstants.disponibilidad}/${d.id}',
        data: {'activo': !d.activo},
      );
      await _cargar();
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar')),
        );
      }
    }
  }

  String _formatearFecha(String fechaStr) {
    try {
      final fecha = DateTime.parse(fechaStr);
      const dias = [
        'Lunes', 'Martes', 'Miércoles', 'Jueves',
        'Viernes', 'Sábado', 'Domingo'
      ];
      const meses = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      final dia = dias[fecha.weekday - 1];
      final mes = meses[fecha.month - 1];
      final hoy = DateTime.now();
      final manana = hoy.add(const Duration(days: 1));

      if (fecha.year == hoy.year &&
          fecha.month == hoy.month &&
          fecha.day == hoy.day) {
        return 'Hoy — ${fecha.day} $mes';
      } else if (fecha.year == manana.year &&
          fecha.month == manana.month &&
          fecha.day == manana.day) {
        return 'Mañana — ${fecha.day} $mes';
      }
      return '$dia ${fecha.day} $mes';
    } catch (_) {
      return fechaStr;
    }
  }

  Future<void> _mostrarFormularioNuevo() async {
    DateTime fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
    TimeOfDay horaInicio = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay horaFin = const TimeOfDay(hour: 9, minute: 0);
    int cupos = 3;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nueva franja horaria',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: fechaSeleccionada,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (fecha != null) {
                    setModalState(() => fechaSeleccionada = fecha);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF15803D)),
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
              GestureDetector(
                onTap: () async {
                  final hora = await showTimePicker(
                    context: context,
                    initialTime: horaInicio,
                  );
                  if (hora != null) setModalState(() => horaInicio = hora);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Color(0xFF15803D)),
                      const SizedBox(width: 12),
                      Text(
                        'Hora inicio: ${horaInicio.format(context)}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final hora = await showTimePicker(
                    context: context,
                    initialTime: horaFin,
                  );
                  if (hora != null) setModalState(() => horaFin = hora);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled,
                          color: Color(0xFF15803D)),
                      const SizedBox(width: 12),
                      Text(
                        'Hora fin: ${horaFin.format(context)}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Cupos:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      if (cupos > 1) setModalState(() => cupos--);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: const Color(0xFF15803D),
                  ),
                  Text('$cupos',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () {
                      if (cupos < 10) setModalState(() => cupos++);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFF15803D),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _crearDisponibilidad(
                        fechaSeleccionada, horaInicio, horaFin, cupos);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Crear franja horaria',
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
      ),
    );
  }

  Future<void> _crearDisponibilidad(
    DateTime fecha,
    TimeOfDay horaInicio,
    TimeOfDay horaFin,
    int cupos,
  ) async {
    try {
      final fechaStr =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      final inicioStr =
          '${horaInicio.hour.toString().padLeft(2, '0')}:${horaInicio.minute.toString().padLeft(2, '0')}';
      final finStr =
          '${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}';

      await ApiService().dio.post(
        ApiConstants.disponibilidad,
        data: {
          'fecha': fechaStr,
          'hora_inicio': inicioStr,
          'hora_fin': finStr,
          'cupos_totales': cupos,
        },
      );
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Franja creada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.response?.data['detail'] ?? 'Error al crear la franja'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLista(
    Map<String, List<DisponibilidadModel>> agrupadas, {
    required bool esProxima,
  }) {
    if (agrupadas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              esProxima ? Icons.schedule_outlined : Icons.history_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              esProxima
                  ? 'No hay franjas próximas'
                  : 'No hay franjas pasadas',
              style: const TextStyle(
                  fontSize: 16, color: AppTheme.textSecondary),
            ),
            if (esProxima) ...[
              const SizedBox(height: 8),
              const Text(
                'Toca el botón para crear una nueva franja',
                style:
                    TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: agrupadas.keys.length,
        itemBuilder: (context, index) {
          final fecha = agrupadas.keys.elementAt(index);
          final franjas = agrupadas[fecha]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: esProxima
                      ? const Color(0xFF15803D).withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: esProxima
                        ? const Color(0xFF15803D).withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: esProxima
                          ? const Color(0xFF15803D)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatearFecha(fecha),
                      style: TextStyle(
                        color: esProxima
                            ? const Color(0xFF15803D)
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${franjas.length} franja${franjas.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: esProxima
                            ? const Color(0xFF15803D)
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ...franjas.map((d) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: d.activo
                                  ? const Color(0xFF15803D)
                                      .withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.access_time,
                              color: d.activo
                                  ? const Color(0xFF15803D)
                                  : Colors.grey,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${d.horaInicio.substring(0, 5)} — ${d.horaFin.substring(0, 5)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 12,
                                      color: d.cuposOcupados >= d.cuposTotales
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${d.cuposTotales - d.cuposOcupados} cupos libres de ${d.cuposTotales}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: d.cuposOcupados >=
                                                d.cuposTotales
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (esProxima)
                            Switch(
                              value: d.activo,
                              onChanged: (_) => _toggleActivo(d),
                              activeThumbColor: const Color(0xFF15803D),
                            )
                          else
                            Icon(
                              Icons.lock_outline,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 4),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();

    final proximas = Map.fromEntries(
      _agrupadas.entries.where((e) {
        final fecha = DateTime.tryParse(e.key);
        return fecha != null &&
            !fecha.isBefore(DateTime(hoy.year, hoy.month, hoy.day));
      }),
    );

    final pasadas = Map.fromEntries(
      _agrupadas.entries.where((e) {
        final fecha = DateTime.tryParse(e.key);
        return fecha != null &&
            fecha.isBefore(DateTime(hoy.year, hoy.month, hoy.day));
      }),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi disponibilidad'),
          backgroundColor: const Color(0xFF15803D),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Próximas'),
              Tab(text: 'Pasadas'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _mostrarFormularioNuevo,
          backgroundColor: const Color(0xFF15803D),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nueva franja',
              style: TextStyle(color: Colors.white)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildLista(proximas, esProxima: true),
                  _buildLista(pasadas, esProxima: false),
                ],
              ),
      ),
    );
  }
}