import 'package:flutter_test/flutter_test.dart';
import 'package:yara_jumping/data/models/cliente.dart';
import 'package:yara_jumping/data/models/horario.dart';

Horario h({int? cupo, int? libres}) => Horario(
      turno: Turno.manana,
      horaInicio: '07:00',
      horaFin: '08:00',
      dias: const [1],
      cupo: cupo,
      libres: libres,
    );

void main() {
  test('texto de lugares libres', () {
    expect(h().lugaresTexto, 'Lugares disponibles');
    expect(h(cupo: 10, libres: 4).lugaresTexto, 'Quedan 4 lugares');
    expect(h(cupo: 10, libres: 1).lugaresTexto, 'Último lugar');
    expect(h(cupo: 10, libres: 0).lugaresTexto, 'Lleno');
    expect(h(cupo: 10, libres: 0).lleno, isTrue);
    expect(h().lleno, isFalse); // sin límite nunca se llena
  });

  test('historial sospechoso: 3+ apartados sin pagar y más que pagos', () {
    expect(const Historial(apartados: 4, cancelados: 3).sospechoso, isTrue);
    expect(const Historial(apartados: 3, cancelados: 2, rechazados: 1).sospechoso, isTrue);
    expect(const Historial(apartados: 2, cancelados: 2).sospechoso, isFalse);
    expect(const Historial(apartados: 8, cancelados: 3, pagos: 5).sospechoso, isFalse); // cliente fiel que a veces cambia
  });
}
