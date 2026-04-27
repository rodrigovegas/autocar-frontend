import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SeleccionRolScreen extends StatelessWidget {
  const SeleccionRolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              const Text(
                '¿Cómo deseas registrarte?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona el tipo de cuenta que mejor se adapte a ti.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 36),

              // Tarjeta: Propietario de vehículo
              _buildTarjeta(
                context: context,
                icono: Icons.directions_car_filled,
                titulo: 'Soy propietario de un vehículo',
                descripcion:
                    'Quiero registrar mi vehículo, agendar mantenimientos '
                    'y llevar el control de mi auto.',
                ruta: '/registro-usuario',
              ),
              const SizedBox(height: 16),

              // Tarjeta: Taller mecánico
              _buildTarjeta(
                context: context,
                icono: Icons.car_repair,
                titulo: 'Soy un taller mecánico',
                descripcion:
                    'Quiero ofrecer mis servicios, gestionar reservas y '
                    'conectar con propietarios de vehículos.',
                ruta: '/registro-taller',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTarjeta({
    required BuildContext context,
    required IconData icono,
    required String titulo,
    required String descripcion,
    required String ruta,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      color: AppTheme.surfaceColor,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          ruta,
          arguments: ModalRoute.of(context)?.settings.arguments,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Row(
            children: [
              // Ícono en círculo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icono,
                  size: 30,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),

              // Título y descripción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Chevron
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
