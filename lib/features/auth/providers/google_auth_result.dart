import '../../../models/usuario_model.dart';

enum GoogleAuthTipo {
  // Éxito
  exito,

  // Sin acción necesaria (flujo cancelado por el usuario)
  canceladoPorUsuario,

  // Errores de conectividad
  sinConexion,

  // Errores del backend — token / validación
  tokenInvalido,       // INVALID_TOKEN
  emailNoVerificado,   // EMAIL_NOT_VERIFIED

  // Errores del backend — permisos de cuenta
  adminNoPermitido,    // ADMIN_NOT_ALLOWED
  cuentaPendiente,     // CUENTA_PENDIENTE  → navegar a /cuenta-pendiente
  cuentaRechazada,     // CUENTA_RECHAZADA  → navegar a /cuenta-rechazada
  cuentaDesactivada,   // CUENTA_DESACTIVADA → navegar a /cuenta-desactivada

  // Errores del backend — conflictos de registro
  emailExiste,         // EMAIL_EXISTS → usar correo+contraseña
  noRegistrado,        // NOT_REGISTERED → ir a /seleccion-rol
  alreadyRegistered,   // ALREADY_REGISTERED → llamar a loginConGoogle()
  nombreRequerido,     // NOMBRE_REQUERIDO → pedir nombre al usuario
  especialidadInvalida, // ESPECIALIDAD_INVALIDA

  // Error genérico
  errorGenerico,
}

class GoogleAuthResult {
  final GoogleAuthTipo tipo;
  final String? mensaje;
  final UsuarioModel? usuario;

  const GoogleAuthResult({
    required this.tipo,
    this.mensaje,
    this.usuario,
  });
}
