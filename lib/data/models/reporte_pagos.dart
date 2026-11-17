import '../../core/utils/fechas.dart';
import '../../core/utils/periodo.dart';

/// Un pago recibido con los datos del cliente (módulo de Pagos de la admin).
class PagoRecibido {
  const PagoRecibido({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteEmail,
    this.planNombre,
    required this.monto,
    required this.fecha,
  });

  final int id;
  final int clienteId;
  final String clienteNombre;
  final String clienteEmail;
  final String? planNombre;
  final double monto;
  final DateTime fecha;

  factory PagoRecibido.fromJson(Map<String, dynamic> j) => PagoRecibido(
        id: j['id'] as int,
        clienteId: j['clienteId'] as int,
        clienteNombre: j['clienteNombre'] as String? ?? '',
        clienteEmail: j['clienteEmail'] as String? ?? '',
        planNombre: j['planNombre'] as String?,
        monto: (j['monto'] as num).toDouble(),
        fecha: Fechas.parse(j['fechaPago'])!,
      );
}

class TotalPlan {
  const TotalPlan({required this.plan, required this.total, required this.cantidad});
  final String plan;
  final double total;
  final int cantidad;
}

class ResumenPeriodo {
  const ResumenPeriodo({required this.rango, required this.total, required this.cantidad});
  final Rango rango;
  final double total;
  final int cantidad;

  factory ResumenPeriodo.fromJson(Map<String, dynamic> j) => ResumenPeriodo(
        rango: Rango(Fechas.parse(j['desde'])!, Fechas.parse(j['hasta'])!),
        total: (j['total'] as num).toDouble(),
        cantidad: j['cantidad'] as int,
      );
}

/// Pagos de un periodo con su total, desglose por plan y el periodo anterior para comparar.
class ReportePagos {
  const ReportePagos({required this.periodo, required this.anterior, required this.porPlan, required this.pagos});
  final ResumenPeriodo periodo;
  final ResumenPeriodo anterior;
  final List<TotalPlan> porPlan;
  final List<PagoRecibido> pagos;

  /// Cambio porcentual vs el periodo anterior (null si antes fue 0).
  double? get cambio => anterior.total == 0 ? null : (periodo.total - anterior.total) / anterior.total * 100;

  factory ReportePagos.fromJson(Map<String, dynamic> j) => ReportePagos(
        periodo: ResumenPeriodo.fromJson(j['periodo'] as Map<String, dynamic>),
        anterior: ResumenPeriodo.fromJson(j['anterior'] as Map<String, dynamic>),
        porPlan: ((j['porPlan'] as List?) ?? const [])
            .map((e) => e as Map<String, dynamic>)
            .map((e) => TotalPlan(
                plan: e['plan'] as String, total: (e['total'] as num).toDouble(), cantidad: e['cantidad'] as int))
            .toList(),
        pagos: ((j['pagos'] as List?) ?? const [])
            .map((e) => PagoRecibido.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
