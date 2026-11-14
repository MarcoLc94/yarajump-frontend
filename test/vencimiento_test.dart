import 'package:flutter_test/flutter_test.dart';
import 'package:yara_jumping/core/utils/fechas.dart';
import 'package:yara_jumping/data/models/frecuencia.dart';

void main() {
  group('diasRestantes', () {
    final fin = DateTime.utc(2026, 11, 20); // último día cubierto

    test('3 días antes', () => expect(Fechas.diasRestantes(fin, ahora: DateTime(2026, 11, 18)), 3));
    test('último día = 1', () => expect(Fechas.diasRestantes(fin, ahora: DateTime(2026, 11, 20)), 1));
    test('día siguiente = 0 (expirado)',
        () => expect(Fechas.diasRestantes(fin, ahora: DateTime(2026, 11, 21)), 0));
  });

  group('Frecuencia.calcularFechaFin', () {
    final inicio = DateTime.utc(2026, 1, 15);

    test('semanal', () => expect(Frecuencia.semanal.calcularFechaFin(inicio), DateTime.utc(2026, 1, 21)));
    test('quincenal', () => expect(Frecuencia.quincenal.calcularFechaFin(inicio), DateTime.utc(2026, 1, 29)));
    test('mensual', () => expect(Frecuencia.mensual.calcularFechaFin(inicio), DateTime.utc(2026, 2, 14)));
    test('anual', () => expect(Frecuencia.anual.calcularFechaFin(inicio), DateTime.utc(2027, 1, 14)));
    test('libre 10 días',
        () => expect(Frecuencia.libre.calcularFechaFin(inicio, diasPersonalizados: 10), DateTime.utc(2026, 1, 24)));
    test('mensual desde el 31 de enero', () {
      expect(Frecuencia.mensual.calcularFechaFin(DateTime.utc(2026, 1, 31)), DateTime.utc(2026, 2, 27));
    });
  });
}
