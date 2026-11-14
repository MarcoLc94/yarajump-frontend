import '../../core/api/api_client.dart';
import '../../core/utils/fechas.dart';
import '../models/cliente.dart';
import '../models/plan.dart';

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

  Future<Cliente> guardarCliente(Cliente c) async {
    final r = c.id == null
        ? await _api.post('/admin/clientes', c.toInputJson())
        : await _api.put('/admin/clientes/${c.id}', c.toInputJson());
    return Cliente.fromJson(r as Map<String, dynamic>);
  }

  Future<void> eliminarCliente(int id) => _api.delete('/admin/clientes/$id');

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

  // ---------- Recordatorios ----------
  Future<List<Cliente>> recordatorios() async => ((await _api.get('/admin/recordatorios')) as List)
      .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
      .toList();
}
