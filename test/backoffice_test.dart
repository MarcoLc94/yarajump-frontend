import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yara_jumping/data/models/app_user.dart';
import 'package:yara_jumping/data/models/usuario_bo.dart';
import 'package:yara_jumping/features/support/backoffice_screen.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  test('roles: support tiene acceso de admin y backoffice', () {
    AppUser u(String rol) => AppUser.fromJson({'id': 1, 'email': 'a@b.co', 'rol': rol});
    expect(u('support').esAdmin, isTrue);
    expect(u('support').esSupport, isTrue);
    expect(u('admin').esAdmin, isTrue);
    expect(u('admin').esSupport, isFalse);
    expect(u('usuario').esAdmin, isFalse);
    expect(u('raro').rol, Rol.usuario);
  });

  test('tiempo relativo de actividad', () {
    final ahora = DateTime(2026, 11, 18, 12, 0);
    expect(haceTiempo(null, ahora: ahora), 'Nunca');
    expect(haceTiempo(ahora.subtract(const Duration(seconds: 20)), ahora: ahora), 'Hace un momento');
    expect(haceTiempo(ahora.subtract(const Duration(minutes: 7)), ahora: ahora), 'Hace 7 min');
    expect(haceTiempo(DateTime(2026, 11, 18, 9, 0), ahora: ahora), 'Hace 3 h');
    expect(haceTiempo(DateTime(2026, 11, 17, 18, 20), ahora: ahora), 'Ayer 18:20');
    expect(haceTiempo(DateTime(2025, 3, 2), ahora: ahora), '2 mar 2025');
  });

  test('usuario de backoffice desde JSON', () {
    final u = UsuarioBO.fromJson({
      'id': 3, 'email': 'ana@x.co', 'nombre': '', 'rol': 'usuario', 'clienteId': 9,
      'creadoEn': '2026-11-01T10:00:00Z', 'ultimaActividad': null, 'logins': 2, 'rolFijo': false,
    });
    expect(u.nombreVisible, 'ana');
    expect(u.esCliente, isTrue);
    expect(u.ultimaActividad, isNull);
  });
}
