enum TipoCuenta {
  tarjeta('Tarjeta', 16),
  clabe('CLABE', 18);

  const TipoCuenta(this.etiqueta, this.digitos);
  final String etiqueta;
  final int digitos;

  static TipoCuenta fromName(String? n) => TipoCuenta.values.firstWhere((t) => t.name == n, orElse: () => TipoCuenta.tarjeta);
}

/// Tarjeta o CLABE donde los clientes pagan (la configura la admin).
class CuentaPago {
  const CuentaPago({
    this.id,
    required this.tipo,
    required this.numero,
    this.banco = '',
    this.titular = '',
    this.activo = true,
  });

  final int? id;
  final TipoCuenta tipo;
  final String numero; // solo dígitos
  final String banco; // banco o app (opcional)
  final String titular; // opcional
  final bool activo;

  /// Tarjeta: "4111 1111 1111 1111" · CLABE: "032 180 00011835971 9" (banco, plaza, cuenta, verificador).
  String get numeroFormateado => formatear(tipo, numero);

  static String formatear(TipoCuenta tipo, String digitos) {
    final d = digitos.replaceAll(RegExp(r'\D'), '');
    final cortes = tipo == TipoCuenta.tarjeta ? const [4, 8, 12] : const [3, 6, 17];
    final b = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (cortes.contains(i)) b.write(' ');
      b.write(d[i]);
    }
    return b.toString();
  }

  /// Red de la tarjeta según su primer dígito (solo para el dibujo).
  String? get red {
    if (tipo != TipoCuenta.tarjeta || numero.isEmpty) return null;
    if (numero.startsWith('4')) return 'VISA';
    if (RegExp(r'^(5[1-5]|2[2-7])').hasMatch(numero)) return 'MASTERCARD';
    if (RegExp(r'^3[47]').hasMatch(numero)) return 'AMEX';
    return null;
  }

  /// Mismo criterio que la API: longitud + dígito verificador. Devuelve el error o null.
  static String? validar(TipoCuenta tipo, String digitos) {
    if (digitos.length != tipo.digitos) {
      return tipo == TipoCuenta.tarjeta ? 'La tarjeta debe tener 16 dígitos' : 'La CLABE debe tener 18 dígitos';
    }
    final ok = tipo == TipoCuenta.tarjeta ? _luhn(digitos) : _clabe(digitos);
    if (!ok) return tipo == TipoCuenta.tarjeta ? 'El número de tarjeta no es válido' : 'La CLABE no es válida';
    return null;
  }

  static bool _luhn(String n) {
    var suma = 0;
    for (var i = 0; i < n.length; i++) {
      var d = int.parse(n[n.length - 1 - i]);
      if (i.isOdd) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      suma += d;
    }
    return suma % 10 == 0;
  }

  static bool _clabe(String n) {
    const pesos = [3, 7, 1];
    var suma = 0;
    for (var i = 0; i < 17; i++) {
      suma += (int.parse(n[i]) * pesos[i % 3]) % 10;
    }
    return (10 - suma % 10) % 10 == int.parse(n[17]);
  }

  factory CuentaPago.fromJson(Map<String, dynamic> j) => CuentaPago(
        id: j['id'] as int?,
        tipo: TipoCuenta.fromName(j['tipo'] as String?),
        numero: j['numero'] as String? ?? '',
        banco: j['banco'] as String? ?? '',
        titular: j['titular'] as String? ?? '',
        activo: j['activo'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'tipo': tipo.name,
        'numero': numero,
        'banco': banco,
        'titular': titular,
        'activo': activo,
      };
}
