import 'frecuencia.dart';
import 'horario.dart';

class Plan {
  const Plan({
    this.id,
    required this.nombre,
    required this.precio,
    this.descripcion = '',
    this.frecuenciaSugerida = Frecuencia.mensual,
    this.activo = true,
    this.horarioIds,
  });

  final int? id;
  final String nombre;
  final double precio;
  final String descripcion;
  final Frecuencia frecuenciaSugerida;
  final bool activo;
  final List<int>? horarioIds; // turnos que ofrece (null = no cambiarlos al guardar)

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        id: j['id'] as int,
        nombre: j['nombre'] as String? ?? '',
        precio: (j['precio'] as num?)?.toDouble() ?? 0,
        descripcion: j['descripcion'] as String? ?? '',
        frecuenciaSugerida: Frecuencia.fromName(j['frecuenciaSugerida'] as String?),
        activo: j['activo'] as bool? ?? true,
        horarioIds: ((j['horarioIds'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'precio': precio,
        'descripcion': descripcion,
        'frecuenciaSugerida': frecuenciaSugerida.name,
        'activo': activo,
        if (horarioIds != null) 'horarioIds': horarioIds,
      };
}

/// Plan activo con los turnos que ofrece y sus lugares libres (lo que ve el cliente en "Ver planes").
class PlanOfertado {
  const PlanOfertado({required this.plan, required this.horarios});
  final Plan plan;
  final List<Horario> horarios;

  factory PlanOfertado.fromJson(Map<String, dynamic> j) => PlanOfertado(
        plan: Plan.fromJson(j),
        horarios: ((j['horarios'] as List?) ?? const [])
            .map((e) => Horario.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
