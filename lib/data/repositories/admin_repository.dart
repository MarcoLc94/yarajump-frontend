import '../../core/api/api_client.dart';
import '../../core/utils/fechas.dart';
import '../../core/utils/periodo.dart';
import '../models/cliente.dart';
import '../models/comunicado.dart';
import '../models/cuenta_pago.dart';
import '../models/horario.dart';
import '../models/medicion.dart';
import '../models/plan.dart';
import '../models/reporte_pagos.dart';
import '../models/solicitud.dart';
import '../models/usuario_bo.dart';

/// Endpoints /admin/* (solo rol administrador).
class AdminRepository {
  AdminRepository(this._api);
  final ApiClient _api;

  // ---------- Planes ----------
  Future<List<Plan>> planes() async => ((await _api.get('/admin/planes')) as List)
      .map((e) => Plan.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<void> guardarPlan(Plan p) =>
      p.id == null ? _api.post('/admin/planes', p.toJson()) : _api.put('/admin/planes/${p.id}', p.toJson());

  Future<void> eliminarPlan(int id) => _api.delete('/admin/planes/$id');

  // ---------- Clientes ----------
  Future<List<Cliente>> clientes({String? q}) async =>
      ((await _api.get('/admin/clientes', query: q == null || q.isEmpty ? null : {'q': q})) as List)
          .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<Cliente> guardarCliente(Cliente c, {List<int>? horarioIds}) async {
    final body = c.toInputJson(horarioIds: horarioIds);
    final r = c.id == null
        ? await _api.post('/admin/clientes', body)
        : await _api.put('/admin/clientes/${c.id}', body);
    return Cliente.fromJson(r as Map<String, dynamic>);
  }

  Future<void> eliminarCliente(int id) => _api.delete('/admin/clientes/$id');

  /// Bloquea (o desbloquea) el acceso del cliente por seguridad. Al bloquear se liberan sus apartados.
  Future<Cliente> bloquearCliente(int id, {required bool bloquear}) async => Cliente.fromJson(
      await _api.post('/admin/clientes/$id/${bloquear ? 'bloquear' : 'desbloquear'}') as Map<String, dynamic>);

  // ---------- Pagos ----------
  Future<List<Pago>> pagos(int clienteId) async => ((await _api.get('/admin/clientes/$clienteId/pagos')) as List)
      .map((e) => Pago.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<Cliente> registrarPago(int clienteId, {required double monto, DateTime? fechaPago}) async {
    final r = await _api.post('/admin/clientes/$clienteId/pagos', {
      'monto': monto,
      if (fechaPago != null) 'fechaPago': Fechas.api(fechaPago),
    }) as Map<String, dynamic>;
    return Cliente.fromJson(r['cliente'] as Map<String, dynamic>);
  }

  /// Todos los pagos recibidos en el periodo, con total y comparativo.
  Future<ReportePagos> reportePagos(Periodo p) async {
    final r = p.rango!, c = p.comparativo!;
    final j = await _api.get('/admin/pagos', query: {
      'desde': Fechas.api(r.desde),
      'hasta': Fechas.api(r.hasta),
      'compDesde': Fechas.api(c.desde),
      'compHasta': Fechas.api(c.hasta),
    });
    return ReportePagos.fromJson(j as Map<String, dynamic>);
  }

  // ---------- Horarios ----------
  Future<List<Horario>> horarios() async => ((await _api.get('/admin/horarios')) as List)
      .map((e) => Horario.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<void> guardarHorario(Horario h) =>
      h.id == null ? _api.post('/admin/horarios', h.toJson()) : _api.put('/admin/horarios/${h.id}', h.toJson());

  Future<void> eliminarHorario(int id) => _api.delete('/admin/horarios/$id');

  // ---------- Progreso ----------
  Future<List<Medicion>> progreso(int clienteId) async =>
      ((await _api.get('/admin/clientes/$clienteId/progreso')) as List)
          .map((e) => Medicion.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<void> registrarMedicion(int clienteId, Medicion m) =>
      _api.post('/admin/clientes/$clienteId/progreso', m.toJson());

  Future<void> eliminarMedicion(int id) => _api.delete('/admin/progreso/$id');

  // ---------- Datos de pago ----------
  Future<List<CuentaPago>> cuentasPago() async => ((await _api.get('/admin/cuentas-pago')) as List)
      .map((e) => CuentaPago.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<void> guardarCuentaPago(CuentaPago c) => c.id == null
      ? _api.post('/admin/cuentas-pago', c.toJson())
      : _api.put('/admin/cuentas-pago/${c.id}', c.toJson());

  Future<void> eliminarCuentaPago(int id) => _api.delete('/admin/cuentas-pago/$id');

  // ---------- Avisos (comunicados) ----------
  Future<List<Comunicado>> comunicados() async => ((await _api.get('/admin/comunicados')) as List)
      .map((e) => Comunicado.fromJson(e as Map<String, dynamic>))
      .toList();

  static Map<String, String> _audiencia(Audiencia a, Turno? turno, int? horarioId) => {
        'audiencia': a.name,
        if (a == Audiencia.turno && turno != null) 'turno': turno.name,
        if (a == Audiencia.horario && horarioId != null) 'horarioId': '$horarioId',
      };

  /// Cuántos clientes verían un aviso con esa audiencia.
  Future<int> alcance(Audiencia a, {Turno? turno, int? horarioId}) async {
    final r = await _api.get('/admin/comunicados/alcance', query: _audiencia(a, turno, horarioId));
    return (r as Map<String, dynamic>)['clientes'] as int;
  }

  Future<Comunicado> crearComunicado({
    required String titulo,
    required String cuerpo,
    required Audiencia audiencia,
    Turno? turno,
    int? horarioId,
  }) async {
    final r = await _api.post('/admin/comunicados', {
      'titulo': titulo,
      'cuerpo': cuerpo,
      'audiencia': audiencia.name,
      if (audiencia == Audiencia.turno) 'turno': turno?.name,
      if (audiencia == Audiencia.horario) 'horarioId': horarioId,
    });
    return Comunicado.fromJson(r as Map<String, dynamic>);
  }

  Future<void> eliminarComunicado(int id) => _api.delete('/admin/comunicados/$id');

  // ---------- Solicitudes de plan ----------
  Future<List<Solicitud>> solicitudes({String estado = 'pendiente'}) async =>
      ((await _api.get('/admin/solicitudes', query: {'estado': estado})) as List)
          .map((e) => Solicitud.fromJson(e as Map<String, dynamic>))
          .toList();

  /// Activa el plan con los turnos pedidos y registra el pago (por defecto, el total).
  Future<void> aprobarSolicitud(int id, {double? monto}) =>
      _api.post('/admin/solicitudes/$id/aprobar', monto == null ? null : {'monto': monto});

  Future<void> rechazarSolicitud(int id) => _api.post('/admin/solicitudes/$id/rechazar');

  // ---------- Recordatorios ----------
  Future<List<Cliente>> recordatorios() async => ((await _api.get('/admin/recordatorios')) as List)
      .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
      .toList();

  // ---------- Backoffice (solo support) ----------
  Future<List<UsuarioBO>> usuariosBO() async => ((await _api.get('/support/usuarios')) as List)
      .map((e) => UsuarioBO.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<List<Acceso>> accesosBO(int userId) async => ((await _api.get('/support/usuarios/$userId/accesos')) as List)
      .map((e) => Acceso.fromJson(e as Map<String, dynamic>))
      .toList();

  /// Solo se mandan los campos que cambian.
  Future<UsuarioBO> editarUsuarioBO(int userId, Map<String, dynamic> cambios) async =>
      UsuarioBO.fromJson(await _api.patch('/support/usuarios/$userId', cambios) as Map<String, dynamic>);

  Future<void> eliminarUsuarioBO(int userId, {required bool conCliente}) =>
      _api.delete('/support/usuarios/$userId${conCliente ? '?cliente=true' : ''}');
}
