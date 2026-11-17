import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dinero.dart';
import '../../../data/models/horario.dart';
import '../../../data/models/plan.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/horario_tile.dart';
import '../../shared/widgets/ui.dart';

/// "Ver planes": los planes que configuró Yara con su costo.
class PlanesDisponiblesScreen extends ConsumerWidget {
  const PlanesDisponiblesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Planes')),
      body: AsyncBody(
        value: ref.watch(planesOfertadosProvider),
        onRetry: () => ref.invalidate(planesOfertadosProvider),
        data: (planes) => RefreshIndicator(
          onRefresh: () => ref.refresh(planesOfertadosProvider.future),
          child: planes.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 60),
                  EmptyState(
                    icono: Icons.card_membership_outlined,
                    titulo: 'Aún no hay planes disponibles',
                    mensaje: 'Escríbele a Yara por WhatsApp para conocer las opciones.',
                  ),
                ])
              : ListView(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Text('Elige un plan para ver sus turnos y lugares disponibles.',
                          style: t.bodyMedium?.copyWith(color: AppColors.textoSuave)),
                    ),
                    for (final o in planes) _PlanCard(oferta: o),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.oferta});
  final PlanOfertado oferta;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = oferta.plan;
    final disponibles = oferta.horarios.where((h) => !h.lleno).length;
    final sinTurnos = oferta.horarios.isEmpty;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: sinTurnos
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ElegirTurnosScreen(planId: p.id!))),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(gradient: AppColors.gradiente, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.sports_gymnastics, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.nombre, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                if (p.descripcion.isNotEmpty)
                  Text(p.descripcion, style: t.bodyMedium?.copyWith(color: AppColors.textoSuave)),
                const SizedBox(height: 6),
                Text(
                  sinTurnos
                      ? 'Sin turnos por ahora'
                      : disponibles == 0
                          ? 'Todos los turnos están llenos'
                          : '$disponibles turno${disponibles == 1 ? '' : 's'} con lugar',
                  style: t.bodySmall?.copyWith(
                    color: sinTurnos || disponibles == 0 ? AppColors.expirado : AppColors.activo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(dinero(p.precio), style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primario)),
              Text('${p.frecuenciaSugerida.etiqueta.toLowerCase()} · por turno',
                  style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
            ]),
            if (!sinTurnos) const Icon(Icons.chevron_right, color: AppColors.textoSuave),
          ]),
        ),
      ),
    );
  }
}

/// Turnos del plan con sus lugares libres; el cliente elige 1 o más y ve el total abajo.
class ElegirTurnosScreen extends ConsumerStatefulWidget {
  const ElegirTurnosScreen({super.key, required this.planId});
  final int planId;
  @override
  ConsumerState<ElegirTurnosScreen> createState() => _ElegirTurnosScreenState();
}

class _ElegirTurnosScreenState extends ConsumerState<ElegirTurnosScreen> {
  final Set<int> _elegidos = {};
  bool _enviando = false;

  Future<void> _solicitar(PlanOfertado o) async {
    final turnos = o.horarios.where((h) => _elegidos.contains(h.id)).toList();
    final total = o.plan.precio * turnos.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Apartar tu lugar?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${o.plan.nombre} · ${turnos.length} turno${turnos.length == 1 ? '' : 's'}'),
          for (final h in turnos) Text('• ${h.titulo} (${h.diasTexto})'),
          const SizedBox(height: 12),
          Text('Total: ${dinero(total)}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text('Tu lugar queda apartado. Yara activará tu plan cuando confirme tu pago.'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apartar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _enviando = true);
    try {
      await ref.read(perfilRepositoryProvider).solicitarPlan(o.plan.id!, _elegidos.toList());
      ref.invalidate(miSolicitudProvider);
      ref.invalidate(planesOfertadosProvider);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('¡Lugar apartado! Realiza tu pago con los datos de "Mi plan" y comparte tu comprobante.'),
        duration: Duration(seconds: 6),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarError(context, e);
      if (e.status == 409) {
        // Alguien tomó el lugar mientras elegía: recarga y quita los turnos que se llenaron.
        final nuevas = await ref.refresh(planesOfertadosProvider.future);
        final actual = nuevas.where((x) => x.plan.id == widget.planId).firstOrNull;
        if (mounted && actual != null) {
          setState(() => _elegidos.removeWhere((id) => actual.horarios.any((h) => h.id == id && h.lleno)));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ofertas = ref.watch(planesOfertadosProvider);
    final o = ofertas.value?.where((x) => x.plan.id == widget.planId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(o?.plan.nombre ?? 'Turnos')),
      body: AsyncBody(
        value: ofertas,
        onRetry: () => ref.invalidate(planesOfertadosProvider),
        data: (_) {
          if (o == null) return const Center(child: Text('Este plan ya no está disponible'));
          final total = o.plan.precio * _elegidos.length;
          return Stack(children: [
            RefreshIndicator(
              onRefresh: () => ref.refresh(planesOfertadosProvider.future),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 130),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Text('${dinero(o.plan.precio)} por turno · elige uno o más',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textoSuave)),
                  ),
                  for (final turno in Turno.values)
                    if (o.horarios.any((h) => h.turno == turno)) ...[
                      SectionTitle(turno.etiqueta),
                      for (final h in o.horarios.where((h) => h.turno == turno))
                        _TurnoElegible(
                          horario: h,
                          elegido: _elegidos.contains(h.id),
                          onTap: h.lleno
                              ? null
                              : () => setState(() => _elegidos.contains(h.id) ? _elegidos.remove(h.id) : _elegidos.add(h.id!)),
                        ),
                    ],
                ],
              ),
            ),
            // "Toast" con el total, abajo
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: SafeArea(
                top: false,
                child: AnimatedSlide(
                  offset: _elegidos.isEmpty ? const Offset(0, 1.6) : Offset.zero,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: _BarraTotal(
                    turnos: _elegidos.length,
                    precio: o.plan.precio,
                    total: total,
                    enviando: _enviando,
                    onSolicitar: _elegidos.isEmpty || _enviando ? null : () => _solicitar(o),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _TurnoElegible extends StatelessWidget {
  const _TurnoElegible({required this.horario, required this.elegido, this.onTap});
  final Horario horario;
  final bool elegido;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lleno = horario.lleno;
    final color = lleno
        ? AppColors.expirado
        : (horario.libres != null && horario.libres! <= 3 ? AppColors.porVencer : AppColors.activo);
    return Opacity(
      opacity: lleno ? 0.55 : 1,
      child: HorarioTile(
        horario: horario,
        onTap: onTap,
        subtitulo: null,
        trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(horario.lugaresTexto,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(height: 6),
          if (!lleno)
            Icon(elegido ? Icons.check_circle : Icons.radio_button_unchecked,
                color: elegido ? AppColors.primario : AppColors.textoSuave, size: 28),
        ]),
      ),
    );
  }
}

class _BarraTotal extends StatelessWidget {
  const _BarraTotal({
    required this.turnos,
    required this.precio,
    required this.total,
    required this.enviando,
    required this.onSolicitar,
  });
  final int turnos;
  final double precio;
  final double total;
  final bool enviando;
  final VoidCallback? onSolicitar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      elevation: 10,
      shadowColor: AppColors.secundario.withValues(alpha: 0.4),
      color: AppColors.texto,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
        child: Row(children: [
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$turnos turno${turnos == 1 ? '' : 's'} × ${dinero(precio)}',
                  style: t.bodySmall?.copyWith(color: Colors.white70)),
              Text('Total ${dinero(total)}',
                  style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
            ]),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(130, 50)),
            onPressed: onSolicitar,
            child: enviando
                ? const SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Apartar'),
          ),
        ]),
      ),
    );
  }
}
