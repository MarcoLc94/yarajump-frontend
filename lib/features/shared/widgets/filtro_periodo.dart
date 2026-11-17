import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/utils/periodo.dart';

/// Chips "Hoy · Esta semana · Este mes · Personalizado" (y "Todos" si [conTodos]).
/// Personalizado abre un calendario para elegir de qué día a qué día.
class FiltroPeriodo extends StatelessWidget {
  const FiltroPeriodo({super.key, required this.valor, required this.onCambio, this.conTodos = false});
  final Periodo valor;
  final ValueChanged<Periodo> onCambio;
  final bool conTodos;

  Future<void> _personalizado(BuildContext context) async {
    final hoy = Fechas.hoy();
    final actual = valor.rango;
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime.utc(hoy.year - 3),
      lastDate: hoy,
      initialDateRange: actual == null ? null : DateTimeRange(start: actual.desde, end: actual.hasta),
      helpText: 'Elige de qué día a qué día',
      saveText: 'Aplicar',
    );
    if (r == null) return;
    onCambio(Periodo.de(TipoPeriodo.personalizado,
        personalizado: Rango(Fechas.soloFecha(r.start), Fechas.soloFecha(r.end))));
  }

  @override
  Widget build(BuildContext context) {
    final tipos = [if (conTodos) TipoPeriodo.todos, TipoPeriodo.hoy, TipoPeriodo.semana, TipoPeriodo.mes];
    final esPers = valor.tipo == TipoPeriodo.personalizado;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          for (final t in tipos)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(t.etiqueta),
                selected: valor.tipo == t,
                onSelected: (_) => onCambio(Periodo.de(t)),
              ),
            ),
          ChoiceChip(
            avatar: Icon(Icons.date_range, size: 18, color: esPers ? AppColors.primario : AppColors.textoSuave),
            label: Text(esPers ? valor.rango!.texto : TipoPeriodo.personalizado.etiqueta),
            selected: esPers,
            onSelected: (_) => _personalizado(context),
          ),
        ],
      ),
    );
  }
}
