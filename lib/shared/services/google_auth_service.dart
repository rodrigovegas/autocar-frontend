import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Inicia el flujo OAuth de Google y retorna el Firebase ID Token.
  /// Retorna null si el usuario cancela sin seleccionar cuenta.
  /// Lanza excepción en caso de error de red o configuración.
  ///
  /// Llama a signOut() antes de signIn() para forzar siempre el selector
  /// de cuentas y evitar silent sign-in con la última cuenta guardada.
  Future<String?> obtenerIdTokenGoogle() async {
    debugPrint('Google Sign-In: iniciando flujo...'); // TODO: remover en producción
    try {
      // Limpiar sesión previa de Google para forzar el selector de cuentas.
      // El token de sesión de la app se gestiona por SharedPreferences, no por aquí.
      await _googleSignIn.signOut();

      final GoogleSignInAccount? cuenta = await _googleSignIn.signIn();
      if (cuenta == null) {
        debugPrint('Google Sign-In: cancelado por usuario'); // TODO: remover en producción
        return null;
      }

      final GoogleSignInAuthentication auth = await cuenta.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final String? token = await userCredential.user?.getIdToken();
      debugPrint('Google Sign-In: token obtenido, enviando al backend...'); // TODO: remover en producción
      return token;
    } catch (e) {
      debugPrint('Google Sign-In: error = $e'); // TODO: remover en producción
      rethrow;
    }
  }

  /// Cierra la sesión de Google y de Firebase.
  /// Llama a disconnect() además de signOut() para revocar el acceso
  /// completamente y que el sistema olvide la cuenta.
  Future<void> cerrarSesionGoogle() async {
    try {
      await _googleSignIn.signOut();
      // disconnect() revoca el token y olvida la cuenta — más completo que signOut().
      // Puede lanzar excepción si no hay sesión activa; se ignora.
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Google Sign-In: error al desconectar (no crítico): $e'); // TODO: remover en producción
    }
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Google Sign-In: error al cerrar sesión Firebase: $e'); // TODO: remover en producción
    }
  }

  /// Verifica si hay una sesión de Google activa (silent sign-in).
  Future<bool> tieneSesionGoogleActiva() async {
    return _googleSignIn.isSignedIn();
  }

  /// Devuelve el correo y nombre del usuario de Firebase actualmente autenticado.
  /// Disponible justo después de obtenerIdTokenGoogle() — usar en el mismo frame.
  Map<String, String?> obtenerDatosUsuarioActual() {
    final user = _firebaseAuth.currentUser;
    return {'correo': user?.email, 'nombre': user?.displayName};
  }
}
