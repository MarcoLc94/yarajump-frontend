import 'horario.dart';

enum Audiencia {
  todos('Todos'),
  turno('Un turno'),
  horario('Un horario');

  const Audiencia(this.etiqueta);
  final String etiqueta;

  static Audiencia fromName(String? n) => Audiencia.values.firstWhere((a) => a.name == n, orElse: () => Audiencia.todos);
}

/// Aviso de la admin para todos sus clientes, un turno o un horario.
class Comunicado {
  const Comunicado({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.audiencia,
    this.turno,
    this.horarioId,
    this.destinatarios = 0,
    this.notificados = 0,
    required this.fecha,
  });

  final int id;
  final String titulo;
  final String cuerpo;
  final Audiencia audiencia;
  final Turno? turno;
  final int? horarioId;
  final int destinatarios; // clientes que lo ven
  final int notificados; // push enviados
  final DateTime fecha;

  /// "Todos los clientes" · "Turno tarde" · "Horario Jumping 7am"
  String descripcionAudiencia(List<Horario> horarios) => switch (audiencia) {
        Audiencia.todos => 'Todos los clientes',
        Audiencia.turno => 'Turno ${turno?.etiqueta.toLowerCase() ?? ''}',
        Audiencia.horario => () {
            final h = horarios.where((h) => h.id == horarioId).firstOrNull;
            return h == null ? 'Un horario' : 'Horario ${h.titulo}';
          }(),
      };

  factory Comunicado.fromJson(Map<String, dynamic> j) => Comunicado(
        id: j['id'] as int,
        titulo: j['titulo'] as String? ?? '',
        cuerpo: j['cuerpo'] as String? ?? '',
        audiencia: Audiencia.fromName(j['audiencia'] as String?),
        turno: j['turno'] == null ? null : Turno.fromName(j['turno'] as String),
        horarioId: j['horarioId'] as int?,
        destinatarios: j['destinatarios'] as int? ?? 0,
        notificados: j['notificados'] as int? ?? 0,
        fecha: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      );
}
