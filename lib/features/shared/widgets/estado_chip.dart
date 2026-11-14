import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/cliente.dart';

Color colorEstado(EstadoPlan e) => switch (e) {
      EstadoPlan.activo => AppColors.activo,
      EstadoPlan.porVencer => AppColors.porVencer,
      EstadoPlan.ultimoDia => AppColors.porVencer,
      EstadoPlan.expirado => AppColors.expirado,
      EstadoPlan.sinPlan => Colors.grey,
    };

class EstadoChip extends StatelessWidget {
  const EstadoChip(this.estado, {super.key});
  final EstadoPlan estado;

  @override
  Widget build(BuildContext context) {
    final c = colorEstado(estado);
    return Chip(
      label: Text(estado.etiqueta, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
      backgroundColor: c.withValues(alpha: 0.12),
      side: BorderSide(color: c),
      visualDensity: VisualDensity.compact,
    );
  }
}
