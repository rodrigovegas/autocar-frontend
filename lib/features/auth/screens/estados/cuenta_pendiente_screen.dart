import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'widgets/estado_cuenta_widget.dart';

class CuentaPendienteScreen extends ConsumerWidget {
  const CuentaPendienteScreen({super.key});

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
        icono: Icons.hourglass_top,
        colorIcono: Colors.amber,
        titulo: 'Cuenta pendiente de aprobación',
        mensaje:
            'Tu solicitud fue enviada correctamente. El administrador '
            'revisará tu cuenta y recibirás una notificación cuando sea '
            'activada. Gracias por tu paciencia.',
        onPressed: () => _cerrarSesion(context, ref),
      ),
    );
  }
}
