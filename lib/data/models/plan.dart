import 'frecuencia.dart';

class Plan {
  const Plan({
    this.id,
    required this.nombre,
    required this.precio,
    this.descripcion = '',
    this.frecuenciaSugerida = Frecuencia.mensual,
    this.activo = true,
  });

  final int? id;
  final String nombre;
  final double precio;
  final String descripcion;
  final Frecuencia frecuenciaSugerida;
  final bool activo;

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        id: j['id'] as int,
        nombre: j['nombre'] as String? ?? '',
        precio: (j['precio'] as num?)?.toDouble() ?? 0,
        descripcion: j['descripcion'] as String? ?? '',
        frecuenciaSugerida: Frecuencia.fromName(j['frecuenciaSugerida'] as String?),
        activo: j['activo'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'precio': precio,
        'descripcion': descripcion,
        'frecuenciaSugerida': frecuenciaSugerida.name,
        'activo': activo,
      };
}
