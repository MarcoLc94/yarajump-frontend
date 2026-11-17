import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dinero.dart';
import '../../../core/utils/fechas.dart';
import '../../../data/models/solicitud.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/ui.dart';
import '../clientes/seguridad.dart';

/// Apartados de plan por confirmar: aprobar (activa plan + registra pago), rechazar o bloquear.
class SolicitudesScreen extends ConsumerWidget {
  const SolicitudesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apartados por confirmar')),
      body: AsyncBody(
        value: ref.watch(solicitudesProvider),
        onRetry: () => ref.invalidate(solicitudesProvider),
        data: (lista) => RefreshIndicator(
          onRefresh: () => ref.refresh(solicitudesProvider.future),
          child: lista.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 60),
                  EmptyState(
                    icono: Icons.event_available_outlined,
                    titulo: 'No hay apartados pendientes',
                    mensaje: 'Cuando un cliente aparte un plan desde la app aparecerá aquí.',
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: lista.length,
                  itemBuilder: (_, i) => _SolicitudCard(solicitud: lista[i]),
                ),
        ),
      ),
    );
  }
}

class _SolicitudCard extends ConsumerWidget {
  const _SolicitudCard({required this.solicitud});
  final Solicitud solicitud;

  Future<void> _aprobar(BuildContext context, WidgetRef ref) async {
    final so = solicitud;
    final monto = TextEditingController(text: so.total.toStringAsFixed(0));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprobar y registrar pago'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Se activará el plan ${so.planNombre} de ${so.clienteNombre} con '
              '${so.horarios.length} turno${so.horarios.length == 1 ? '' : 's'} y se registrará el pago con fecha de hoy.'),
          const SizedBox(height: 16),
          TextField(
            controller: monto,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: const InputDecoration(labelText: 'Monto recibido', prefixText: r'$ '),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aprobar')),
        ],
      ),
    );
    final valor = double.tryParse(monto.text);
    monto.dispose();
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).aprobarSolicitud(so.id, monto: valor);
      refrescarAdmin(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Plan de ${so.clienteNombre} activado')));
      }
    } catch (e) {
      if (context.mounted) mostrarError(context, e);
    }
  }

  Future<void> _rechazar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Rechazar este apartado?'),
        content: Text('Se liberan los lugares de ${solicitud.clienteNombre} y se le avisa que no fue aprobado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rechazar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).rechazarSolicitud(solicitud.id);
      refrescarAdmin(ref);
    } catch (e) {
      if (context.mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final so = solicitud;
    final suave = t.bodySmall?.copyWith(color: AppColors.textoSuave);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(so.clienteNombre, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text(so.clienteEmail, style: suave),
              ]),
            ),
            Text(Fechas.relativa(so.fecha), style: suave),
          ]),
          const SizedBox(height: 10),
          HistorialChips(historial: so.clienteHistorial, bloqueado: so.clienteBloqueado),
          const Divider(height: 24),
          Text(so.planNombre, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          for (final h in so.horarios)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(children: [
                Icon(h.turno.icono, size: 18, color: AppColors.textoSuave),
                const SizedBox(width: 8),
                Expanded(child: Text('${h.titulo} · ${h.diasTexto}')),
                if (h.cupo != null) Text('${h.ocupados}/${h.cupo}', style: suave),
              ]),
            ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Text('${so.horarios.length} × ${dinero(so.precio)}', style: suave),
            ),
            Text('Total ${dinero(so.total)}',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primario)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(onPressed: () => _rechazar(context, ref), child: const Text('Rechazar')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(onPressed: () => _aprobar(context, ref), child: const Text('Aprobar')),
            ),
          ]),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.expirado),
              onPressed: () => cambiarBloqueo(context, ref,
                  clienteId: so.clienteId, nombre: so.clienteNombre, bloquear: true),
              icon: const Icon(Icons.gpp_bad_outlined, size: 18),
              label: const Text('Bloquear acceso'),
            ),
          ),
        ]),
      ),
    );
  }
}
