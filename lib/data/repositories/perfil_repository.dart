import '../../core/api/api_client.dart';
import '../../core/utils/fechas.dart';
import '../models/cliente.dart';
import '../models/comunicado.dart';
import '../models/cuenta_pago.dart';
import '../models/medicion.dart';
import '../models/plan.dart';
import '../models/solicitud.dart';

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

  Future<String> subirFoto(List<int> bytes, String nombreArchivo) async {
    final r = await _api.upload('/me/foto', 'foto', bytes, nombreArchivo) as Map<String, dynamic>;
    return r['fotoUrl'] as String;
  }

  Future<List<Medicion>> miProgreso() async => ((await _api.get('/me/progreso')) as List)
      .map((e) => Medicion.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<void> registrarMedicion(Medicion m) => _api.post('/me/progreso', m.toJson());

  Future<void> eliminarMedicion(int id) => _api.delete('/me/progreso/$id');

  Future<void> registrarTokenPush(String? token) => _api.put('/me/fcm-token', {'token': token});

  /// Tarjetas/CLABE activas donde se puede pagar.
  Future<List<CuentaPago>> misCuentasPago() async => ((await _api.get('/me/cuentas-pago')) as List)
      .map((e) => CuentaPago.fromJson(e as Map<String, dynamic>))
      .toList();

  /// Avisos de Yara de los últimos 60 días que me tocan (por turno/horario o para todos).
  Future<List<Comunicado>> misComunicados() async => ((await _api.get('/me/comunicados')) as List)
      .map((e) => Comunicado.fromJson(e as Map<String, dynamic>))
      .toList();

  /// Planes activos con sus turnos y lugares libres.
  Future<List<PlanOfertado>> planesOfertados() async => ((await _api.get('/me/planes')) as List)
      .map((e) => PlanOfertado.fromJson(e as Map<String, dynamic>))
      .toList();

  /// Mi solicitud pendiente (null si no hay).
  Future<Solicitud?> miSolicitud() async {
    final r = await _api.get('/me/solicitud');
    return r == null ? null : Solicitud.fromJson(r as Map<String, dynamic>);
  }

  Future<Solicitud> solicitarPlan(int planId, List<int> horarioIds) async =>
      Solicitud.fromJson(await _api.post('/me/solicitud', {'planId': planId, 'horarioIds': horarioIds}) as Map<String, dynamic>);

  Future<void> cancelarSolicitud() => _api.delete('/me/solicitud');

  Future<Map<String, dynamic>> config() async => await _api.get('/config') as Map<String, dynamic>;
}
