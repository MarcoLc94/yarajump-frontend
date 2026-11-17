import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dinero.dart';
import '../../../data/models/reporte_pagos.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/filtro_periodo.dart';
import '../../shared/widgets/ui.dart';

/// Módulo de pagos: todos los pagos recibidos en el periodo, comparativo y total abajo.
class PagosScreen extends ConsumerWidget {
  const PagosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodo = ref.watch(periodoPagosProvider);
    final reporte = ref.watch(reportePagosProvider);
    return Scaffold(
      body: Column(children: [
        FiltroPeriodo(
          valor: periodo,
          onCambio: (p) => ref.read(periodoPagosProvider.notifier).state = p,
        ),
        Expanded(
          child: AsyncBody(
            value: reporte,
            onRetry: () => ref.invalidate(reportePagosProvider),
            data: (r) => RefreshIndicator(
              onRefresh: () => ref.refresh(reportePagosProvider.future),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Text(r.periodo.rango.texto,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textoSuave)),
                  ),
                  _Comparativo(reporte: r, etiqueta: periodo.etiquetaComparativo),
                  if (r.porPlan.length > 1) _PorPlan(reporte: r),
                  SectionTitle('Pagos (${r.pagos.length})'),
                  if (r.pagos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: EmptyState(icono: Icons.payments_outlined, titulo: 'Sin pagos en este periodo'),
                    )
                  else
                    for (final p in r.pagos) _PagoTile(pago: p),
                ],
              ),
            ),
          ),
        ),
      ]),
      // Total de lo filtrado, siempre visible abajo
      bottomNavigationBar: reporte.whenOrNull(data: (r) => _BarraTotal(reporte: r)),
    );
  }
}

class _Comparativo extends StatelessWidget {
  const _Comparativo({required this.reporte, required this.etiqueta});
  final ReportePagos reporte;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final r = reporte;
    final cambio = r.cambio;
    final sube = (cambio ?? 0) >= 0;
    final color = cambio == null ? AppColors.textoSuave : (sube ? AppColors.activo : AppColors.expirado);
    final diferencia = r.periodo.total - r.anterior.total;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.gradiente,
        borderRadius: BorderRadius.circular(AppTheme.radio),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Recibido', style: t.bodyMedium?.copyWith(color: Colors.white70)),
        Text(dinero(r.periodo.total),
            style: t.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(
              cambio == null ? Icons.remove : (sube ? Icons.trending_up : Icons.trending_down),
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  cambio == null
                      ? (r.periodo.total > 0 ? 'Sin pagos para comparar' : 'Igual que antes')
                      : '${sube ? '+' : ''}${cambio.toStringAsFixed(0)}% $etiqueta',
                  style: t.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${r.anterior.rango.texto}: ${dinero(r.anterior.total)} '
                  '(${r.anterior.cantidad} pago${r.anterior.cantidad == 1 ? '' : 's'})',
                  style: t.bodySmall?.copyWith(color: AppColors.textoSuave),
                ),
              ]),
            ),
            if (diferencia != 0)
              Text('${diferencia > 0 ? '+' : '−'}${dinero(diferencia.abs())}',
                  style: t.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}

class _PorPlan extends StatelessWidget {
  const _PorPlan({required this.reporte});
  final ReportePagos reporte;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = reporte.periodo.total;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionTitle('Por plan'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            for (final p in reporte.porPlan) ...[
              Row(children: [
                Expanded(child: Text(p.plan, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                Text('${dinero(p.total)} · ${p.cantidad}', style: t.bodyMedium),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : p.total / total,
                  minHeight: 8,
                  color: AppColors.primario,
                  backgroundColor: AppColors.primario.withValues(alpha: 0.1),
                ),
              ),
              if (p != reporte.porPlan.last) const SizedBox(height: 12),
            ],
          ]),
        ),
      ),
    ]);
  }
}

class _PagoTile extends StatelessWidget {
  const _PagoTile({required this.pago});
  final PagoRecibido pago;

  static final _fecha = DateFormat('d MMM yyyy', 'es_MX');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = pago;
    final iniciales = p.clienteNombre.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Avatar(iniciales: iniciales.toUpperCase(), radio: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.clienteNombre, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(p.clienteEmail, style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
              const SizedBox(height: 2),
              Text('${p.planNombre ?? 'Sin plan'} · ${_fecha.format(p.fecha)}',
                  style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
            ]),
          ),
          Text(dinero(p.monto), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.activo)),
        ]),
      ),
    );
  }
}

class _BarraTotal extends StatelessWidget {
  const _BarraTotal({required this.reporte});
  final ReportePagos reporte;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final n = reporte.periodo.cantidad;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: AppColors.texto, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const Icon(Icons.payments_outlined, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$n pago${n == 1 ? '' : 's'}', style: t.bodyMedium?.copyWith(color: Colors.white70)),
          ),
          Text('Total ${dinero(reporte.periodo.total)}',
              style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
