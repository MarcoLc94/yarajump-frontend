import 'cliente.dart';
import 'horario.dart';

/// Un cliente pide un plan con 1 o más turnos; aparta los lugares hasta que Yara la aprueba o rechaza.
class Solicitud {
  const Solicitud({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.planId,
    required this.planNombre,
    required this.precio,
    required this.total,
    required this.estado,
    required this.fecha,
    required this.horarios,
    this.clienteBloqueado = false,
    this.clienteHistorial = const Historial(),
  });

  final int id;
  final int clienteId;
  final String clienteNombre;
  final String clienteEmail;
  final int planId;
  final String planNombre;
  final double precio; // precio del plan por turno
  final double total; // precio × turnos
  final String estado; // pendiente | aprobada | rechazada | cancelada
  final DateTime fecha;
  final List<Horario> horarios;
  final bool clienteBloqueado;
  final Historial clienteHistorial;

  factory Solicitud.fromJson(Map<String, dynamic> j) => Solicitud(
        id: j['id'] as int,
        clienteId: j['clienteId'] as int,
        clienteNombre: j['clienteNombre'] as String? ?? '',
        clienteEmail: j['clienteEmail'] as String? ?? '',
        planId: j['planId'] as int,
        planNombre: j['planNombre'] as String? ?? '',
        precio: (j['precio'] as num?)?.toDouble() ?? 0,
        total: (j['total'] as num?)?.toDouble() ?? 0,
        estado: j['estado'] as String? ?? 'pendiente',
        fecha: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        horarios: ((j['horarios'] as List?) ?? const [])
            .map((e) => Horario.fromJson(e as Map<String, dynamic>))
            .toList(),
        clienteBloqueado: j['clienteBloqueado'] as bool? ?? false,
        clienteHistorial: Historial.fromJson(j['clienteHistorial'] as Map<String, dynamic>?),
      );
}
