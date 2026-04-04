import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class HomeTallerScreen extends ConsumerWidget {
  const HomeTallerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authProvider).usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoCar — Taller'),
        backgroundColor: const Color(0xFF15803D),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).cerrarSesion();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build, size: 80, color: Color(0xFF15803D)),
            const SizedBox(height: 16),
            Text(
              'Bienvenido, ${usuario?.nombre ?? "Taller"}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Panel del taller en construcción...'),
          ],
        ),
      ),
    );
  }
}