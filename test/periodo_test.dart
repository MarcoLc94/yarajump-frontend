import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yara_jumping/core/utils/periodo.dart';

DateTime d(int y, int m, int dd) => DateTime.utc(y, m, dd);

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));
  final martes = d(2026, 11, 17); // martes

  test('hoy y comparativo ayer', () {
    final p = Periodo.de(TipoPeriodo.hoy, hoy: martes);
    expect(p.rango, Rango(martes, martes));
    expect(p.comparativo, Rango(d(2026, 11, 16), d(2026, 11, 16)));
  });

  test('semana de lunes a hoy vs semana pasada al mismo día', () {
    final p = Periodo.de(TipoPeriodo.semana, hoy: martes);
    expect(p.rango, Rango(d(2026, 11, 16), martes));
    expect(p.comparativo, Rango(d(2026, 11, 9), d(2026, 11, 10)));
    // domingo: la semana va del lunes anterior al domingo
    expect(Periodo.de(TipoPeriodo.semana, hoy: d(2026, 11, 22)).rango, Rango(d(2026, 11, 16), d(2026, 11, 22)));
  });

  test('mes al día vs mes pasado al mismo día', () {
    final p = Periodo.de(TipoPeriodo.mes, hoy: martes);
    expect(p.rango, Rango(d(2026, 11, 1), martes));
    expect(p.comparativo, Rango(d(2026, 10, 1), d(2026, 10, 17)));
    // 31 de marzo vs febrero: se recorta al último día de febrero
    expect(Periodo.de(TipoPeriodo.mes, hoy: d(2027, 3, 31)).comparativo, Rango(d(2027, 2, 1), d(2027, 2, 28)));
    // enero vs diciembre del año anterior
    expect(Periodo.de(TipoPeriodo.mes, hoy: d(2027, 1, 10)).comparativo, Rango(d(2026, 12, 1), d(2026, 12, 10)));
  });

  test('personalizado vs mismos días justo antes', () {
    final p = Periodo.de(TipoPeriodo.personalizado, personalizado: Rango(d(2026, 11, 10), d(2026, 11, 16)));
    expect(p.comparativo, Rango(d(2026, 11, 3), d(2026, 11, 9)));
    expect(p.etiquetaComparativo, 'vs 7 días anteriores');
  });

  test('todos no filtra', () {
    final p = Periodo.de(TipoPeriodo.todos);
    expect(p.rango, isNull);
    expect(p.incluye(d(2001, 1, 1)), isTrue);
  });

  test('texto del rango', () {
    expect(Rango(d(2026, 11, 10), d(2026, 11, 17)).texto, '10 – 17 nov 2026');
    expect(Rango(d(2026, 10, 28), d(2026, 11, 3)).texto, '28 oct – 3 nov 2026');
  });
}
