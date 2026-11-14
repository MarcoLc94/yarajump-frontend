enum Rol { admin, usuario }

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.rol,
    this.nombre = '',
    this.fotoUrl,
    this.clienteId,
  });

  final int id;
  final String email;
  final Rol rol;
  final String nombre;
  final String? fotoUrl;
  final int? clienteId;

  bool get esAdmin => rol == Rol.admin;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        email: j['email'] as String? ?? '',
        rol: j['rol'] == 'admin' ? Rol.admin : Rol.usuario,
        nombre: j['nombre'] as String? ?? '',
        fotoUrl: j['fotoUrl'] as String?,
        clienteId: j['clienteId'] as int?,
      );
}
