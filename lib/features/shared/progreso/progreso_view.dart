import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../data/models/medicion.dart';
import '../widgets/ui.dart';

/// Progreso de un cliente: resumen (inicio vs. ahora), gráfica e historial.
/// [mediciones] viene ordenado del más antiguo al más reciente.
class ProgresoView extends StatefulWidget {
  const ProgresoView({
    super.key,
    required this.mediciones,
    required this.onAgregar,
    required this.onEliminar,
    required this.onRefresh,
  });

  final List<Medicion> mediciones;
  final VoidCallback onAgregar;
  final Future<void> Function(Medicion m) onEliminar;
  final Future<void> Function() onRefresh;

  @override
  State<ProgresoView> createState() => _ProgresoViewState();
}

class _ProgresoViewState extends State<ProgresoView> {
  CampoMedicion _campo = CampoMedicion.peso;

  List<CampoMedicion> get _camposConDatos =>
      CampoMedicion.values.where((c) => widget.mediciones.any((m) => m[c] != null)).toList();

  @override
  Widget build(BuildContext context) {
    final ms = widget.mediciones;
    if (ms.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(children: [
          const SizedBox(height: 60),
          EmptyState(
            icono: Icons.monitor_weight_outlined,
            titulo: 'Aún no hay mediciones',
            mensaje: 'Registra el peso y las medidas iniciales para empezar a ver el progreso.',
            accion: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(220, 52)),
              onPressed: widget.onAgregar,
              icon: const Icon(Icons.add),
              label: const Text('Primera medición'),
            ),
          ),
        ]),
      );
    }

    final campos = _camposConDatos;
    if (!campos.contains(_campo) && campos.isNotEmpty) _campo = campos.first;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _Resumen(mediciones: ms),
          if (campos.isNotEmpty) ...[
            const SectionTitle('Evolución'),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final c in campos)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.etiqueta),
                        selected: c == _campo,
                        onSelected: (_) => setState(() => _campo = c),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _Grafica(mediciones: ms, campo: _campo),
          ],
          SectionTitle('Historial (${ms.length})'),
          for (final m in ms.reversed)
            _MedicionCard(
              medicion: m,
              esInicial: identical(m, ms.first),
              onEliminar: () => _confirmarEliminar(m),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(Medicion m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar medición?'),
        content: Text('Registro del ${Fechas.formato(m.fecha)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) await widget.onEliminar(m);
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.mediciones});
  final List<Medicion> mediciones;

  @override
  Widget build(BuildContext context) {
    final conPeso = mediciones.where((m) => m.peso != null).toList();
    final inicial = conPeso.isEmpty ? null : conPeso.first.peso;
    final actual = conPeso.isEmpty ? null : conPeso.last.peso;
    final diff = (inicial != null && actual != null) ? actual - inicial : null;

    final estatura = mediciones.lastWhere((m) => m.estatura != null, orElse: () => mediciones.last).estatura;
    final imc = conPeso.isEmpty ? null : conPeso.last.imc(estaturaRef: estatura);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: AppColors.gradiente, borderRadius: BorderRadius.circular(AppTheme.radio)),
          child: Row(children: [
            Expanded(child: _PesoCol(titulo: 'Peso inicial', valor: inicial, fecha: conPeso.firstOrNull?.fecha)),
            Container(width: 1, height: 56, color: Colors.white24),
            Expanded(child: _PesoCol(titulo: 'Peso actual', valor: actual, fecha: conPeso.lastOrNull?.fecha)),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: StatTile(
              icono: diff == null || diff.abs() < 0.05
                  ? Icons.trending_flat
                  : (diff < 0 ? Icons.trending_down : Icons.trending_up),
              color: diff == null || diff.abs() < 0.05
                  ? AppColors.textoSuave
                  : (diff < 0 ? AppColors.activo : AppColors.porVencer),
              valor: diff == null ? '—' : '${diff > 0 ? '+' : ''}${numFmt(diff)} kg',
              etiqueta: 'Cambio de peso',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatTile(
              icono: Icons.speed,
              valor: imc == null ? '—' : imc.toStringAsFixed(1),
              etiqueta: imc == null ? 'IMC (falta estatura)' : 'IMC · ${imcCategoria(imc)}',
            ),
          ),
        ]),
      ]),
    );
  }
}

class _PesoCol extends StatelessWidget {
  const _PesoCol({required this.titulo, this.valor, this.fecha});
  final String titulo;
  final double? valor;
  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(children: [
      Text(titulo, style: t.bodySmall?.copyWith(color: Colors.white70)),
      const SizedBox(height: 4),
      Text(valor == null ? '—' : '${numFmt(valor!)} kg',
          style: t.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
      if (fecha != null) Text(Fechas.corta(fecha!), style: t.bodySmall?.copyWith(color: Colors.white70)),
    ]);
  }
}

class _Grafica extends StatelessWidget {
  const _Grafica({required this.mediciones, required this.campo});
  final List<Medicion> mediciones;
  final CampoMedicion campo;

  @override
  Widget build(BuildContext context) {
    final puntos = mediciones.where((m) => m[campo] != null).toList();
    final spots = [for (var i = 0; i < puntos.length; i++) FlSpot(i.toDouble(), puntos[i][campo]!)];
    final valores = spots.map((s) => s.y);
    final minY = valores.reduce((a, b) => a < b ? a : b);
    final maxY = valores.reduce((a, b) => a > b ? a : b);
    final margen = ((maxY - minY) * 0.2).clamp(1, double.infinity).toDouble();
    final fmt = DateFormat('d MMM', 'es_MX');

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
        child: SizedBox(
          height: 200,
          child: spots.length < 2
              ? Center(
                  child: Text(
                    '${numFmt(spots.first.y)} ${campo.unidad}\nRegistra otra medición para ver la gráfica',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textoSuave),
                  ),
                )
              : LineChart(LineChartData(
                  minY: minY - margen,
                  maxY: maxY + margen,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.borde, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (v, meta) => v == meta.max || v == meta.min
                            ? const SizedBox.shrink()
                            : Text(numFmt(v), style: const TextStyle(fontSize: 11, color: AppColors.textoSuave)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (v, meta) {
                          final i = v.toInt();
                          final paso = (puntos.length / 5).ceil();
                          if (i < 0 || i >= puntos.length || v != i.toDouble() || i % paso != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(fmt.format(puntos[i].fecha),
                                style: const TextStyle(fontSize: 11, color: AppColors.textoSuave)),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.texto,
                      getTooltipItems: (items) => items
                          .map((s) => LineTooltipItem(
                                '${numFmt(s.y)} ${campo.unidad}\n${Fechas.corta(puntos[s.x.toInt()].fecha)}',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ))
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: AppColors.primario,
                      barWidth: 3,
                      dotData: FlDotData(
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: AppColors.primario,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primario.withValues(alpha: 0.25), AppColors.primario.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ],
                )),
        ),
      ),
    );
  }
}

class _MedicionCard extends StatelessWidget {
  const _MedicionCard({required this.medicion, required this.esInicial, required this.onEliminar});
  final Medicion medicion;
  final bool esInicial;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = medicion;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.event, size: 18, color: AppColors.textoSuave),
            const SizedBox(width: 6),
            Text(Fechas.formato(m.fecha), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            if (esInicial) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.secundario.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text('Inicial',
                    style: t.labelSmall?.copyWith(color: AppColors.secundario, fontWeight: FontWeight.w700)),
              ),
            ],
            const Spacer(),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline, color: AppColors.textoSuave),
              onPressed: onEliminar,
            ),
          ]),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in m.valores.entries)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.fondo, borderRadius: BorderRadius.circular(10)),
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${e.key.etiqueta}  ', style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
                  TextSpan(
                      text: '${numFmt(e.value)} ${e.key.unidad}',
                      style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                ])),
              ),
          ]),
          if (m.notas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(m.notas, style: t.bodyMedium?.copyWith(color: AppColors.textoSuave)),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Hoja para registrar una medición. Devuelve la medición o null si se canceló.
Future<Medicion?> mostrarNuevaMedicion(BuildContext context, {Medicion? anterior}) => showModalBottomSheet<Medicion>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NuevaMedicionSheet(anterior: anterior),
    );

class _NuevaMedicionSheet extends StatefulWidget {
  const _NuevaMedicionSheet({this.anterior});
  final Medicion? anterior;
  @override
  State<_NuevaMedicionSheet> createState() => _NuevaMedicionSheetState();
}

class _NuevaMedicionSheetState extends State<_NuevaMedicionSheet> {
  final _form = GlobalKey<FormState>();
  late final _ctrls = {for (final c in CampoMedicion.values) c: TextEditingController()};
  final _notas = TextEditingController();
  DateTime _fecha = Fechas.hoy();

  @override
  void initState() {
    super.initState();
    // La estatura casi no cambia: se precarga la última registrada.
    final est = widget.anterior?.estatura;
    if (est != null) _ctrls[CampoMedicion.estatura]!.text = numFmt(est);
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _notas.dispose();
    super.dispose();
  }

  double? _valor(CampoMedicion c) => double.tryParse(_ctrls[c]!.text.replaceAll(',', '.'));

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final valores = {
      for (final c in CampoMedicion.values)
        if (_valor(c) != null) c: _valor(c)!,
    };
    if (valores.isEmpty && _notas.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registra al menos una medida')));
      return;
    }
    Navigator.pop(context, Medicion(fecha: _fecha, valores: valores, notas: _notas.text.trim()));
  }

  Widget _campo(CampoMedicion c) => TextFormField(
        controller: _ctrls[c],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: c.etiqueta, suffixText: c.unidad),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          final n = double.tryParse(v.replaceAll(',', '.'));
          return (n == null || n <= 0) ? 'Inválido' : null;
        },
      );

  Widget _fila(List<CampoMedicion> cs) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          for (var i = 0; i < cs.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: _campo(cs[i])),
          ],
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Nueva medición', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Fecha'),
              subtitle: Text(Fechas.formato(_fecha)),
              onTap: () async {
                final d = await showDatePicker(
                    context: context, initialDate: _fecha, firstDate: DateTime(2020), lastDate: DateTime.now());
                if (d != null) setState(() => _fecha = Fechas.soloFecha(d));
              },
            ),
            const SizedBox(height: 4),
            _fila([CampoMedicion.peso, CampoMedicion.estatura]),
            _fila([CampoMedicion.grasa, CampoMedicion.musculo]),
            Text('Medidas', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _fila([CampoMedicion.cintura, CampoMedicion.cadera]),
            _fila([CampoMedicion.pecho, CampoMedicion.brazo]),
            _fila([CampoMedicion.pierna]),
            TextField(
              controller: _notas,
              maxLines: 3,
              minLines: 1,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _guardar, child: const Text('Guardar medición')),
          ]),
        ),
      ),
    );
  }
}
