import 'package:intl/intl.dart';

import 'fechas.dart';

enum TipoPeriodo {
  todos('Todos'),
  hoy('Hoy'),
  semana('Esta semana'),
  mes('Este mes'),
  personalizado('Personalizado');

  const TipoPeriodo(this.etiqueta);
  final String etiqueta;
}

/// Rango de días (inclusive), con fechas en medianoche UTC como el resto de la app.
class Rango {
  const Rango(this.desde, this.hasta);
  final DateTime desde;
  final DateTime hasta;

  int get dias => hasta.difference(desde).inDays + 1;

  bool contiene(DateTime d) {
    final f = Fechas.soloFecha(d);
    return !f.isBefore(desde) && !f.isAfter(hasta);
  }

  /// "17 nov 2026" · "10 – 17 nov 2026" · "28 oct – 3 nov 2026"
  String get texto {
    final dm = DateFormat('d MMM', 'es_MX');
    final dmy = DateFormat('d MMM yyyy', 'es_MX');
    if (desde == hasta) return dmy.format(desde);
    if (desde.year != hasta.year) return '${dmy.format(desde)} – ${dmy.format(hasta)}';
    if (desde.month == hasta.month) return '${desde.day} – ${dmy.format(hasta)}';
    return '${dm.format(desde)} – ${dmy.format(hasta)}';
  }

  @override
  bool operator ==(Object other) => other is Rango && other.desde == desde && other.hasta == hasta;
  @override
  int get hashCode => Object.hash(desde, hasta);
}

/// Filtro de fechas (pagos y clientes). [rango] es null en "Todos".
class Periodo {
  const Periodo._(this.tipo, this.rango);
  final TipoPeriodo tipo;
  final Rango? rango;

  factory Periodo.de(TipoPeriodo tipo, {DateTime? hoy, Rango? personalizado}) {
    final h = Fechas.soloFecha(hoy ?? DateTime.now());
    return switch (tipo) {
      TipoPeriodo.todos => const Periodo._(TipoPeriodo.todos, null),
      TipoPeriodo.hoy => Periodo._(tipo, Rango(h, h)),
      // Semana de lunes a hoy
      TipoPeriodo.semana => Periodo._(tipo, Rango(h.subtract(Duration(days: h.weekday - 1)), h)),
      TipoPeriodo.mes => Periodo._(tipo, Rango(DateTime.utc(h.year, h.month, 1), h)),
      TipoPeriodo.personalizado => Periodo._(tipo, personalizado ?? Rango(h, h)),
    };
  }

  /// Periodo con el que se compara: al mismo punto del periodo anterior,
  /// para no comparar medio mes contra un mes completo.
  Rango? get comparativo {
    final r = rango;
    if (r == null) return null;
    switch (tipo) {
      case TipoPeriodo.semana:
        return Rango(r.desde.subtract(const Duration(days: 7)), r.hasta.subtract(const Duration(days: 7)));
      case TipoPeriodo.mes:
        final d = r.desde;
        final ini = DateTime.utc(d.year, d.month - 1, 1);
        final ultimo = DateTime.utc(d.year, d.month, 0).day; // último día del mes anterior
        final dia = r.hasta.day > ultimo ? ultimo : r.hasta.day;
        return Rango(ini, DateTime.utc(ini.year, ini.month, dia));
      default: // hoy → ayer; personalizado → mismos días justo antes
        return Rango(r.desde.subtract(Duration(days: r.dias)), r.desde.subtract(const Duration(days: 1)));
    }
  }

  /// "vs ayer", "vs semana pasada", "vs mes pasado", "vs 7 días anteriores"
  String get etiquetaComparativo => switch (tipo) {
        TipoPeriodo.hoy => 'vs ayer',
        TipoPeriodo.semana => 'vs semana pasada',
        TipoPeriodo.mes => 'vs mes pasado',
        _ => 'vs ${rango?.dias ?? 0} día${rango?.dias == 1 ? '' : 's'} anteriores',
      };

  bool incluye(DateTime d) => rango?.contiene(d) ?? true;
}
