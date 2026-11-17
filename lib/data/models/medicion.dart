import '../../core/utils/fechas.dart';

/// Campos medibles del módulo de progreso.
enum CampoMedicion {
  peso('Peso', 'kg'),
  estatura('Estatura', 'cm'),
  grasa('Grasa corporal', '%'),
  musculo('Masa muscular', '%'),
  cintura('Cintura', 'cm'),
  cadera('Cadera', 'cm'),
  pecho('Pecho', 'cm'),
  brazo('Brazo', 'cm'),
  pierna('Pierna', 'cm');

  const CampoMedicion(this.etiqueta, this.unidad);
  final String etiqueta;
  final String unidad;

  /// Bajar es "bueno" en estos campos (se pinta en verde).
  bool get menosEsMejor => this == peso || this == grasa || this == cintura || this == cadera;
}

class Medicion {
  const Medicion({this.id, required this.fecha, this.valores = const {}, this.notas = '', this.registradoPor});

  final int? id;
  final DateTime fecha;
  final Map<CampoMedicion, double> valores;
  final String notas;
  final String? registradoPor;

  double? operator [](CampoMedicion c) => valores[c];
  double? get peso => valores[CampoMedicion.peso];
  double? get estatura => valores[CampoMedicion.estatura];

  /// IMC = kg / m². Usa la estatura de este registro o la [estaturaRef].
  double? imc({double? estaturaRef}) {
    final p = valores[CampoMedicion.peso];
    final e = valores[CampoMedicion.estatura] ?? estaturaRef;
    if (p == null || e == null || e <= 0) return null;
    final m = e / 100;
    return p / (m * m);
  }

  factory Medicion.fromJson(Map<String, dynamic> j) => Medicion(
        id: j['id'] as int,
        fecha: Fechas.parse(j['fecha'])!,
        valores: {
          for (final c in CampoMedicion.values)
            if (j[c.name] != null) c: (j[c.name] as num).toDouble(),
        },
        notas: j['notas'] as String? ?? '',
        registradoPor: j['registradoPor'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'fecha': Fechas.api(fecha),
        for (final c in CampoMedicion.values) c.name: valores[c],
        'notas': notas,
      };
}

String imcCategoria(double imc) => switch (imc) {
      < 18.5 => 'Bajo peso',
      < 25 => 'Normal',
      < 30 => 'Sobrepeso',
      _ => 'Obesidad',
    };

String numFmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
