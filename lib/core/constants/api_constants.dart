class ApiConstants {
  static const String baseUrl = 'http://192.168.0.5:8000';
  // 10.0.2.2 es la IP del localhost desde el emulador Android
  // Si usas dispositivo físico reemplaza con la IP de tu computadora
  // Por ejemplo: 'http://192.168.1.X:8000'

  static const String authRegistroUsuario = '/auth/registro/usuario';
  static const String authRegistroTaller = '/auth/registro/taller';
  static const String authLogin = '/auth/login';
  static const String vehiculos = '/vehiculos';
  static const String talleres = '/talleres';
  static const String disponibilidad = '/disponibilidad';
  static const String reservas = '/reservas';
  static const String mantenimientos = '/mantenimientos';
  static const String recordatorios = '/recordatorios';
  static const String educativo = '/educativo';
  static const String asistente = '/asistente/consulta';
  static const String notificaciones = '/notificaciones';
  static const String admin = '/admin';
}
