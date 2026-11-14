import 'dart:io';

import '../../core/api/api_client.dart';
import '../../core/utils/fechas.dart';
import '../models/cliente.dart';

/// Endpoints /me/* que usa el rol USUARIO.
class PerfilRepository {
  PerfilRepository(this._api);
  final ApiClient _api;

  /// Mi plan. null si la cuenta aún no está vinculada a un cliente.
  Future<Cliente?> miCliente() async {
    try {
      return Cliente.fromJson(await _api.get('/me/cliente') as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  Future<List<Pago>> misPagos() async => ((await _api.get('/me/pagos')) as List)
      .map((e) => Pago.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<void> actualizarDatos({String? telefono, String? contactoEmergencia, DateTime? fechaNacimiento}) =>
      _api.patch('/me/perfil', {
        if (telefono != null) 'telefono': telefono,
        if (contactoEmergencia != null) 'contactoEmergencia': contactoEmergencia,
        if (fechaNacimiento != null) 'fechaNacimiento': Fechas.api(fechaNacimiento),
      });

  Future<String> subirFoto(File archivo) async {
    final r = await _api.upload('/me/foto', 'foto', archivo) as Map<String, dynamic>;
    return r['fotoUrl'] as String;
  }

  Future<void> registrarTokenPush(String? token) => _api.put('/me/fcm-token', {'token': token});

  Future<Map<String, dynamic>> config() async => await _api.get('/config') as Map<String, dynamic>;
}
