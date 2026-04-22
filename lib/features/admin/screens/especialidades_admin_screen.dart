import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/api_service.dart';

class EspecialidadesAdminScreen extends StatefulWidget {
  const EspecialidadesAdminScreen({super.key});

  @override
  State<EspecialidadesAdminScreen> createState() =>
      _EspecialidadesAdminScreenState();
}

class _EspecialidadesAdminScreenState
    extends State<EspecialidadesAdminScreen> {
  static const morado = Color(0xFF7C3AED);

  List<Map<String, dynamic>> _especialidades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final res =
          await ApiService().dio.get('/admin/especialidades');
      setState(() {
        _especialidades =
            (res.data as List).map<Map<String, dynamic>>((e) => e).toList();
      });
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar especialidades')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> esp) async {
    final esActivo = esp['activo'] as bool;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(esActivo ? 'Desactivar especialidad' : 'Activar especialidad'),
        content: Text(
          esActivo
              ? '¿Desactivar "${esp['nombre']}"? No aparecerá en el registro de nuevos talleres.'
              : '¿Activar "${esp['nombre']}"? Volverá a aparecer en el registro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: esActivo ? Colors.red : morado,
            ),
            child: Text(
              esActivo ? 'Desactivar' : 'Activar',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService()
          .dio
          .patch('/admin/especialidades/${esp['id']}/toggle');
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esActivo
                ? 'Especialidad desactivada'
                : 'Especialidad activada'),
            backgroundColor: esActivo ? Colors.orange : Colors.green,
          ),
        );
      }
    } on DioException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cambiar estado')),
        );
      }
    }
  }

  void _abrirFormularioNueva() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nueva especialidad',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nombre de la especialidad',
                  hintText: 'Ej: Mecánica general',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final nombre = ctrl.text.trim();
                    if (nombre.isEmpty) return;
                    Navigator.pop(context);
                    try {
                      await ApiService().dio.post(
                        '/admin/especialidades',
                        data: {'nombre': nombre},
                      );
                      await _cargar();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Especialidad creada'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } on DioException catch (e) {
                      if (mounted) {
                        final msg =
                            e.response?.data?['detail'] ?? 'Error al crear';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(msg),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: morado,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Crear especialidad',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activas =
        _especialidades.where((e) => e['activo'] == true).toList();
    final inactivas =
        _especialidades.where((e) => e['activo'] == false).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Especialidades'),
        backgroundColor: morado,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Activas ───────────────────────────────
                  if (activas.isNotEmpty) ...[
                    const Text('Activas',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.green)),
                    const SizedBox(height: 8),
                    ...activas.map((e) => _EspecialidadCard(
                          esp: e,
                          onToggle: () => _toggle(e),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // ── Inactivas ─────────────────────────────
                  if (inactivas.isNotEmpty) ...[
                    const Text('Inactivas',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.red)),
                    const SizedBox(height: 8),
                    ...inactivas.map((e) => _EspecialidadCard(
                          esp: e,
                          onToggle: () => _toggle(e),
                        )),
                  ],

                  if (_especialidades.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No hay especialidades aún'),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormularioNueva,
        backgroundColor: morado,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _EspecialidadCard extends StatelessWidget {
  final Map<String, dynamic> esp;
  final VoidCallback onToggle;

  const _EspecialidadCard({required this.esp, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final esActivo = esp['activo'] as bool;
    final color = esActivo ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.build, color: color, size: 18),
        ),
        title: Text(esp['nombre'],
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: OutlinedButton(
          onPressed: onToggle,
          style: OutlinedButton.styleFrom(
            foregroundColor: esActivo ? Colors.red : Colors.green,
            side: BorderSide(color: esActivo ? Colors.red : Colors.green),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: Text(esActivo ? 'Desactivar' : 'Activar',
              style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}