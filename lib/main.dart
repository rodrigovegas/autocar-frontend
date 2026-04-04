import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/registro_usuario_screen.dart';
import 'features/auth/screens/registro_taller_screen.dart';
import 'features/auth/screens/home_usuario_screen.dart';
import 'features/auth/screens/home_taller_screen.dart';
import 'features/auth/screens/home_admin_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    const ProviderScope(
      child: AutoCarApp(),
    ),
  );
}

class AutoCarApp extends StatelessWidget {
  const AutoCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoCar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registro-usuario': (context) => const RegistroUsuarioScreen(),
        '/registro-taller': (context) => const RegistroTallerScreen(),
        '/home-usuario': (context) => const HomeUsuarioScreen(),
        '/home-taller': (context) => const HomeTallerScreen(),
        '/home-admin': (context) => const HomeAdminScreen(),
      },
    );
  }
}