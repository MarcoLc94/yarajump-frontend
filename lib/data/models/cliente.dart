import '../../core/utils/fechas.dart';
import 'frecuencia.dart';

/// Estado calculado por la API con la fecha de hoy (zona horaria del negocio).
enum EstadoPlan { sinPlan, activo, porVencer, ultimoDia, expirado }

extension EstadoPlanX on EstadoPlan {
  String get etiqueta => switch (this) {
        EstadoPlan.sinPlan => 'Sin plan',
        EstadoPlan.activo => 'Activo',
        EstadoPlan.porVencer => 'Por vencer',
        EstadoPlan.ultimoDia => 'Último día',
        EstadoPlan.expirado => 'Expirado',
      };

  /// Valor que usa la API (?estado=por_vencer)
  String get api => switch (this) {
        EstadoPlan.sinPlan => 'sin_plan',
        EstadoPlan.activo => 'activo',
        EstadoPlan.porVencer => 'por_vencer',
        EstadoPlan.ultimoDia => 'ultimo_dia',
        EstadoPlan.expirado => 'expirado',
      };

  static EstadoPlan fromApi(String? s) =>
      EstadoPlan.values.firstWhere((e) => e.api == s, orElse: () => EstadoPlan.sinPlan);
}

class Cliente {
  const Cliente({
    this.id,
    required this.nombre,
    required this.email,
    this.telefono = '',
    this.fechaNacimiento,
    this.contactoEmergencia = '',
    this.fotoUrl,
    this.planId,
    this.planNombre,
    this.precio,
    this.frecuencia = Frecuencia.mensual,
    this.diasPersonalizados,
    this.fechaInicio,
    this.fechaFin,
    this.activo = true,
    this.vinculado = false,
    this.diasRestantes,
    this.estado = EstadoPlan.sinPlan,
  });

  final int? id;
  final String nombre;
  final String email;
  final String telefono;
  final DateTime? fechaNacimiento;
  final String contactoEmergencia;
  final String? fotoUrl;

  final int? planId;
  final String? planNombre;
  final double? precio;
  final Frecuencia frecuencia;
  final int? diasPersonalizados;
  final DateTime? fechaInicio;
  final DateTime? fechaFin; // último día cubierto
  final bool activo;
  final bool vinculado; // ya entró a la app con su cuenta de Google

  final int? diasRestantes;
  final EstadoPlan estado;

  factory Cliente.fromJson(Map<String, dynamic> j) => Cliente(
        id: j['id'] as int,
        nombre: j['nombre'] as String? ?? '',
        email: j['email'] as String? ?? '',
        telefono: j['telefono'] as String? ?? '',
        fechaNacimiento: Fechas.parse(j['fechaNacimiento']),
        contactoEmergencia: j['contactoEmergencia'] as String? ?? '',
        fotoUrl: j['fotoUrl'] as String?,
        planId: j['planId'] as int?,
        planNombre: j['planNombre'] as String?,
        precio: (j['precio'] as num?)?.toDouble(),
        frecuencia: Frecuencia.fromName(j['frecuencia'] as String?),
        diasPersonalizados: j['diasPersonalizados'] as int?,
        fechaInicio: Fechas.parse(j['fechaInicio']),
        fechaFin: Fechas.parse(j['fechaFin']),
        activo: j['activo'] as bool? ?? true,
        vinculado: j['vinculado'] as bool? ?? false,
        diasRestantes: j['diasRestantes'] as int?,
        estado: EstadoPlanX.fromApi(j['estado'] as String?),
      );

  /// Cuerpo para POST/PUT /admin/clientes (fechaFin la calcula el servidor).
  Map<String, dynamic> toInputJson() => {
        'nombre': nombre,
        'email': email.trim().toLowerCase(),
        'telefono': telefono,
        'planId': planId,
        'frecuencia': frecuencia.name,
        'diasPersonalizados': frecuencia == Frecuencia.libre ? diasPersonalizados : null,
        'fechaInicio': fechaInicio == null ? null : Fechas.api(fechaInicio!),
        'activo': activo,
      };
}

class Pago {
  const Pago({
    required this.id,
    required this.monto,
    required this.fechaPago,
    required this.periodoInicio,
    required this.periodoFin,
    this.planNombre,
  });

  final int id;
  final double monto;
  final DateTime fechaPago;
  final DateTime periodoInicio;
  final DateTime periodoFin;
  final String? planNombre;

  factory Pago.fromJson(Map<String, dynamic> j) => Pago(
        id: j['id'] as int,
        monto: (j['monto'] as num).toDouble(),
        fechaPago: Fechas.parse(j['fechaPago'])!,
        periodoInicio: Fechas.parse(j['periodoInicio'])!,
        periodoFin: Fechas.parse(j['periodoFin'])!,
        planNombre: j['planNombre'] as String?,
      );
}
