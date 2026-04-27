import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'widgets/estado_cuenta_widget.dart';

class CuentaDesactivadaScreen extends ConsumerWidget {
  const CuentaDesactivadaScreen({super.key});

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
        icono: Icons.no_accounts,
        colorIcono: Colors.grey,
        titulo: 'Cuenta desactivada',
        mensaje:
            'Tu cuenta se encuentra desactivada actualmente. Si crees '
            'que esto es un error, contacta al administrador del sistema '
            'para más información.',
        onPressed: () => _cerrarSesion(context, ref),
      ),
    );
  }
}
