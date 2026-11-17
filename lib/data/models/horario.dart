import 'package:flutter/material.dart';

enum Turno {
  manana('Mañana', Icons.wb_sunny_outlined),
  tarde('Tarde', Icons.wb_twilight),
  noche('Noche', Icons.nights_stay_outlined);

  const Turno(this.etiqueta, this.icono);
  final String etiqueta;
  final IconData icono;

  static Turno fromName(String? n) => Turno.values.firstWhere((t) => t.name == n, orElse: () => Turno.manana);
}

/// Días de la semana como los maneja la API: 1 = lunes … 7 = domingo.
const diasCortos = {1: 'L', 2: 'M', 3: 'X', 4: 'J', 5: 'V', 6: 'S', 7: 'D'};
const diasNombre = {1: 'Lun', 2: 'Mar', 3: 'Mié', 4: 'Jue', 5: 'Vie', 6: 'Sáb', 7: 'Dom'};

class Horario {
  const Horario({
    this.id,
    this.nombre = '',
    required this.turno,
    required this.horaInicio,
    required this.horaFin,
    required this.dias,
    this.activo = true,
    this.inscritos = 0,
  });

  final int? id;
  final String nombre;
  final Turno turno;
  final String horaInicio; // "HH:MM"
  final String horaFin;
  final List<int> dias;
  final bool activo;
  final int inscritos;

  String get rango => '$horaInicio – $horaFin';

  /// "Lun, Mié, Vie" o "Lun a Vie" si son consecutivos.
  String get diasTexto {
    if (dias.isEmpty) return '';
    final ord = [...dias]..sort();
    final consecutivos = ord.length > 2 && ord.last - ord.first == ord.length - 1;
    if (consecutivos) return '${diasNombre[ord.first]} a ${diasNombre[ord.last]}';
    return ord.map((d) => diasNombre[d]).join(', ');
  }

  String get titulo => nombre.isNotEmpty ? nombre : '${turno.etiqueta} · $rango';

  factory Horario.fromJson(Map<String, dynamic> j) => Horario(
        id: j['id'] as int,
        nombre: j['nombre'] as String? ?? '',
        turno: Turno.fromName(j['turno'] as String?),
        horaInicio: j['horaInicio'] as String? ?? '',
        horaFin: j['horaFin'] as String? ?? '',
        dias: ((j['dias'] as List?) ?? []).map((e) => (e as num).toInt()).toList(),
        activo: j['activo'] as bool? ?? true,
        inscritos: j['inscritos'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'turno': turno.name,
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'dias': dias,
        'activo': activo,
      };
}
