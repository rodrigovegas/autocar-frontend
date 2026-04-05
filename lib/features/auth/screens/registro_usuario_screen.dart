import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class RegistroUsuarioScreen extends ConsumerStatefulWidget {
  const RegistroUsuarioScreen({super.key});

  @override
  ConsumerState<RegistroUsuarioScreen> createState() =>
      _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState extends ConsumerState<RegistroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authProvider.notifier)
        .registrarUsuario(
          _nombreController.text.trim(),
          _correoController.text.trim(),
          _contrasenaController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada exitosamente. Inicia sesión.'),
          backgroundColor: AppTheme.secondaryColor,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registro de usuario',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea tu cuenta para gestionar el mantenimiento de tu vehículo.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese su nombre completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese su correo';
                  }
                  if (!value.contains('@')) {
                    return 'Ingrese un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contrasenaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (authState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(color: AppTheme.errorColor),
                  ),
                ),
              const SizedBox(height: 24),

              authState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registrar,
                      child: const Text('Crear cuenta'),
                    ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
