import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

/// Widget base reutilizable para pantallas de estado de cuenta bloqueada.
/// Se usa para los tres estados especiales: pendiente, rechazada, desactivada.
class EstadoCuentaWidget extends StatelessWidget {
  final IconData icono;
  final Color colorIcono;
  final String titulo;
  final String mensaje;
  final String textoBoton;
  final VoidCallback onPressed;

  const EstadoCuentaWidget({
    super.key,
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    required this.mensaje,
    required this.onPressed,
    this.textoBoton = 'Cerrar sesión',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Círculo de fondo con ícono
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorIcono.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icono,
                    size: 64,
                    color: colorIcono,
                  ),
                ),
                const SizedBox(height: 32),

                // Título
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Mensaje descriptivo
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Botón de acción
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    child: Text(
                      textoBoton,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
