import 'app_user.dart';

/// Una cuenta vista desde el backoffice (rol support).
class UsuarioBO {
  const UsuarioBO({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.creadoEn,
    this.fotoUrl,
    this.clienteId,
    this.telefono = '',
    this.bloqueado = false,
    this.metodo = 'google',
    this.ultimoLogin,
    this.ultimaActividad,
    this.logins = 0,
    this.ultimaPlataforma = '',
    this.pushActivo = false,
    this.rolFijo = false,
  });

  final int id;
  final String email;
  final String nombre;
  final Rol rol;
  final DateTime creadoEn;
  final String? fotoUrl;
  final int? clienteId;
  final String telefono;
  final bool bloqueado;
  final String metodo; // google | password
  final DateTime? ultimoLogin;
  final DateTime? ultimaActividad;
  final int logins;
  final String ultimaPlataforma; // web | android | ios | ''
  final bool pushActivo;

  /// Su rol lo fija la configuración del servidor (ADMIN_EMAILS / SUPPORT_EMAILS).
  final bool rolFijo;

  bool get esCliente => clienteId != null;
  String get nombreVisible => nombre.trim().isEmpty ? email.split('@').first : nombre;
  String get iniciales =>
      nombreVisible.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join().toUpperCase();

  factory UsuarioBO.fromJson(Map<String, dynamic> j) {
    DateTime? f(Object? v) => v == null ? null : DateTime.parse(v as String).toLocal();
    return UsuarioBO(
      id: j['id'] as int,
      email: j['email'] as String,
      nombre: j['nombre'] as String? ?? '',
      rol: Rol.desde(j['rol']),
      creadoEn: f(j['creadoEn'])!,
      fotoUrl: j['fotoUrl'] as String?,
      clienteId: j['clienteId'] as int?,
      telefono: j['telefono'] as String? ?? '',
      bloqueado: j['bloqueado'] as bool? ?? false,
      metodo: j['metodo'] as String? ?? 'google',
      ultimoLogin: f(j['ultimoLogin']),
      ultimaActividad: f(j['ultimaActividad']),
      logins: j['logins'] as int? ?? 0,
      ultimaPlataforma: j['ultimaPlataforma'] as String? ?? '',
      pushActivo: j['pushActivo'] as bool? ?? false,
      rolFijo: j['rolFijo'] as bool? ?? false,
    );
  }
}

class Acceso {
  const Acceso({required this.fecha, required this.metodo, required this.plataforma});
  final DateTime fecha;
  final String metodo;
  final String plataforma;

  factory Acceso.fromJson(Map<String, dynamic> j) => Acceso(
        fecha: DateTime.parse(j['fecha'] as String).toLocal(),
        metodo: j['metodo'] as String? ?? '',
        plataforma: j['plataforma'] as String? ?? '',
      );
}
