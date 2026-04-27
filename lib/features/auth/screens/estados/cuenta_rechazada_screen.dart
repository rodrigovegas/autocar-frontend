import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'widgets/estado_cuenta_widget.dart';

class CuentaRechazadaScreen extends ConsumerWidget {
  const CuentaRechazadaScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).cerrarSesion();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/bienvenida',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _cerrarSesion(context, ref);
      },
      child: EstadoCuentaWidget(
        icono: Icons.cancel,
        colorIcono: AppTheme.errorColor,
        titulo: 'Solicitud rechazada',
        mensaje:
            'Tu solicitud de registro no fue aprobada. Si crees que '
            'esto es un error o necesitas más información, por favor contacta '
            'al administrador del sistema.',
        onPressed: () => _cerrarSesion(context, ref),
      ),
    );
  }
}
