import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
// Flujo inicial
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/bienvenida_screen.dart';
// Autenticación
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/seleccion_rol_screen.dart';
import 'features/auth/screens/registro_usuario_screen.dart';
import 'features/auth/screens/registro_taller_screen.dart';
import 'features/auth/screens/completar_perfil_taller_google_screen.dart';
// Estados especiales de cuenta
import 'features/auth/screens/estados/cuenta_pendiente_screen.dart';
import 'features/auth/screens/estados/cuenta_rechazada_screen.dart';
import 'features/auth/screens/estados/cuenta_desactivada_screen.dart';
// Pantallas principales por rol
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'BO'),
        Locale('es'),
        Locale('en'),
      ],
      initialRoute: '/splash',
      routes: {
        // Flujo inicial
        '/splash': (context) => const SplashScreen(),
        '/bienvenida': (context) => const BienvenidaScreen(),
        // Autenticación
        '/login': (context) => const LoginScreen(),
        '/seleccion-rol': (context) => const SeleccionRolScreen(),
        '/registro-usuario': (context) => const RegistroUsuarioScreen(),
        '/registro-taller': (context) => const RegistroTallerScreen(),
        '/completar-perfil-taller-google': (context) =>
            const CompletarPerfilTallerGoogleScreen(),
        // Estados especiales de cuenta
        '/cuenta-pendiente': (context) => const CuentaPendienteScreen(),
        '/cuenta-rechazada': (context) => const CuentaRechazadaScreen(),
        '/cuenta-desactivada': (context) => const CuentaDesactivadaScreen(),
        // Pantallas principales por rol
        '/home-usuario': (context) => const HomeUsuarioScreen(),
        '/home-taller': (context) => const HomeTallerScreen(),
        '/home-admin': (context) => const HomeAdminScreen(),
      },
    );
  }
}