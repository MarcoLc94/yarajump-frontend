import 'package:flutter_test/flutter_test.dart';
import 'package:yara_jumping/data/models/cuenta_pago.dart';

void main() {
  group('CuentaPago.validar', () {
    test('tarjeta válida (Luhn)', () => expect(CuentaPago.validar(TipoCuenta.tarjeta, '4111111111111111'), isNull));
    test('tarjeta con dígito mal', () => expect(CuentaPago.validar(TipoCuenta.tarjeta, '4111111111111112'), isNotNull));
    test('tarjeta corta', () => expect(CuentaPago.validar(TipoCuenta.tarjeta, '411111'), isNotNull));
    test('CLABE válida', () => expect(CuentaPago.validar(TipoCuenta.clabe, '032180000118359719'), isNull));
    test('CLABE con verificador mal', () => expect(CuentaPago.validar(TipoCuenta.clabe, '032180000118359718'), isNotNull));
  });

  test('formato agrupado', () {
    expect(CuentaPago.formatear(TipoCuenta.tarjeta, '4111111111111111'), '4111 1111 1111 1111');
    expect(CuentaPago.formatear(TipoCuenta.clabe, '032180000118359719'), '032 180 00011835971 9');
    expect(CuentaPago.formatear(TipoCuenta.tarjeta, '41111'), '4111 1');
  });

  test('red de la tarjeta', () {
    CuentaPago t(String n) => CuentaPago(tipo: TipoCuenta.tarjeta, numero: n);
    expect(t('4111111111111111').red, 'VISA');
    expect(t('5500000000000004').red, 'MASTERCARD');
    expect(t('6011000000000004').red, isNull);
    expect(const CuentaPago(tipo: TipoCuenta.clabe, numero: '032180000118359719').red, isNull);
  });
}
