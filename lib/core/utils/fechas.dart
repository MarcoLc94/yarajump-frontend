import 'package:intl/intl.dart';

/// Utilidades de fechas.
/// Convención: las fechas de plan son días de calendario (medianoche UTC) y viajan
/// a la API como "AAAA-MM-DD".
class Fechas {
  Fechas._();

  /// Quita la hora y lo deja en medianoche UTC del mismo día de calendario (local).
  static DateTime soloFecha(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static DateTime hoy() => soloFecha(DateTime.now());

  /// `fechaFin` es el último día cubierto (inclusive).
  /// Devuelve 1 el último día, 0 el día siguiente (expirado) y negativos después.
  static int diasRestantes(DateTime fechaFin, {DateTime? ahora}) {
    final h = ahora != null ? soloFecha(ahora) : hoy();
    return soloFecha(fechaFin).difference(h).inDays + 1;
  }

  /// Suma meses respetando fin de mes (31 ene + 1 mes = 28/29 feb).
  static DateTime sumarMeses(DateTime d, int meses) {
    final totalMes = d.month - 1 + meses;
    final y = d.year + totalMes ~/ 12;
    final m = totalMes % 12 + 1;
    final ultimoDia = DateTime.utc(y, m + 1, 0).day;
    return DateTime.utc(y, m, d.day > ultimoDia ? ultimoDia : d.day);
  }

  /// "2026-11-15" → DateTime.utc(2026, 11, 15)
  static DateTime? parse(Object? s) {
    if (s is! String || s.length < 10) return null;
    final p = s.substring(0, 10).split('-').map(int.parse).toList();
    return DateTime.utc(p[0], p[1], p[2]);
  }

  /// DateTime → "2026-11-15" (para la API)
  static String api(DateTime d) => DateFormat('yyyy-MM-dd').format(soloFecha(d));

  static String formato(DateTime d) => DateFormat("d 'de' MMMM yyyy", 'es_MX').format(d);
  static String corta(DateTime d) => DateFormat('dd/MM/yyyy', 'es_MX').format(d);

  /// "Hoy", "Ayer", "Hace 3 días" o la fecha corta (para avisos).
  static String relativa(DateTime d) {
    final dias = hoy().difference(soloFecha(d)).inDays;
    if (dias <= 0) return 'Hoy';
    if (dias == 1) return 'Ayer';
    if (dias < 7) return 'Hace $dias días';
    return DateFormat("d 'de' MMM", 'es_MX').format(d);
  }
}
