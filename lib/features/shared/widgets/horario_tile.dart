import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/horario.dart';
import 'ui.dart';

Color colorTurno(Turno t) => switch (t) {
      Turno.manana => const Color(0xFFF2A100),
      Turno.tarde => AppColors.primario,
      Turno.noche => AppColors.secundario,
    };

/// Tarjeta de un horario: turno, rango de horas y días.
class HorarioTile extends StatelessWidget {
  const HorarioTile({super.key, required this.horario, this.trailing, this.onTap, this.subtitulo});
  final Horario horario;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = colorTurno(horario.turno);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
              child: Icon(horario.turno.icono, color: c),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(horario.nombre.isNotEmpty ? horario.nombre : horario.turno.etiqueta,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(horario.rango, style: t.bodyMedium?.copyWith(color: AppColors.textoSuave)),
                const SizedBox(height: 6),
                DiasSemana(dias: horario.dias),
                if (subtitulo != null) ...[
                  const SizedBox(height: 6),
                  Text(subtitulo!, style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
                ],
              ]),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
      ),
    );
  }
}
