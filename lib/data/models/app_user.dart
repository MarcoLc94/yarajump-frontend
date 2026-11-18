/// usuario = cliente; admin = Yara; support = admin + backoffice.
enum Rol {
  usuario('Cliente'),
  admin('Admin'),
  support('Support');

  const Rol(this.etiqueta);
  final String etiqueta;

  static Rol desde(Object? s) => Rol.values.firstWhere((r) => r.name == s, orElse: () => Rol.usuario);
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.rol,
    this.nombre = '',
    this.fotoUrl,
    this.clienteId,
    this.bloqueado = false,
  });

  final int id;
  final String email;
  final Rol rol;
  final String nombre;
  final String? fotoUrl;
  final int? clienteId;
  final bool bloqueado; // acceso denegado por seguridad

  /// Acceso de administrador (admin o support).
  bool get esAdmin => rol == Rol.admin || rol == Rol.support;
  bool get esSupport => rol == Rol.support;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        email: j['email'] as String? ?? '',
        rol: Rol.desde(j['rol']),
        nombre: j['nombre'] as String? ?? '',
        fotoUrl: j['fotoUrl'] as String?,
        clienteId: j['clienteId'] as int?,
        bloqueado: j['bloqueado'] as bool? ?? false,
      );
}
