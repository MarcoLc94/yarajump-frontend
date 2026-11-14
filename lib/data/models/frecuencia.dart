import '../../core/utils/fechas.dart';

/// Frecuencia de pago / recordatorio de un cliente.
enum Frecuencia {
  semanal('Semanal', dias: 7),
  quincenal('Quincenal', dias: 15),
  mensual('Mensual', meses: 1),
  bimestral('Bimestral', meses: 2),
  semestral('Semestral', meses: 6),
  anual('Anual', meses: 12),
  libre('Libre (días personalizados)');

  const Frecuencia(this.etiqueta, {this.dias, this.meses});

  final String etiqueta;
  final int? dias;
  final int? meses;

  /// Primer día del SIGUIENTE periodo a partir de [inicio].
  DateTime siguienteInicio(DateTime inicio, {int? diasPersonalizados}) {
    final i = Fechas.soloFecha(inicio);
    if (meses != null) return Fechas.sumarMeses(i, meses!);
    final n = dias ?? (diasPersonalizados ?? 30);
    return i.add(Duration(days: n));
  }

  /// Último día cubierto de un periodo que empieza en [inicio].
  DateTime calcularFechaFin(DateTime inicio, {int? diasPersonalizados}) =>
      siguienteInicio(inicio, diasPersonalizados: diasPersonalizados)
          .subtract(const Duration(days: 1));

  static Frecuencia fromName(String? name) =>
      Frecuencia.values.firstWhere((f) => f.name == name, orElse: () => Frecuencia.mensual);
}
