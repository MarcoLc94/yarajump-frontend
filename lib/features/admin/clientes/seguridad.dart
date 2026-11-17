import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cliente.dart';
import '../../shared/widgets/async_body.dart';

/// Chips con apartados, cancelados, rechazados y pagos del cliente.
/// Se resaltan cuando el patrón parece abuso (muchos apartados sin pagar).
class HistorialChips extends StatelessWidget {
  const HistorialChips({super.key, required this.historial, this.bloqueado = false});
  final Historial historial;
  final bool bloqueado;

  @override
  Widget build(BuildContext context) {
    final h = historial;
    final alerta = h.sospechoso;
    Widget chip(IconData i, String texto, {Color? color}) {
      final c = color ?? AppColors.textoSuave;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 15, color: c),
          const SizedBox(width: 5),
          Text(texto, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    String n(int x, String s, String p) => '$x ${x == 1 ? s : p}';
    return Wrap(spacing: 6, runSpacing: 6, children: [
      if (bloqueado) chip(Icons.block, 'Bloqueado', color: AppColors.expirado),
      if (alerta && !bloqueado) chip(Icons.warning_amber_rounded, 'Revisar', color: AppColors.expirado),
      chip(Icons.event_seat_outlined, n(h.apartados, 'apartado', 'apartados'), color: alerta ? AppColors.porVencer : null),
      if (h.cancelados > 0)
        chip(Icons.cancel_outlined, n(h.cancelados, 'cancelado', 'cancelados'), color: alerta ? AppColors.expirado : null),
      if (h.rechazados > 0)
        chip(Icons.thumb_down_alt_outlined, n(h.rechazados, 'rechazado', 'rechazados'), color: alerta ? AppColors.expirado : null),
      chip(Icons.payments_outlined, n(h.pagos, 'pago', 'pagos'), color: h.pagos > 0 ? AppColors.activo : null),
    ]);
  }
}

/// Pide confirmación y bloquea/desbloquea el acceso del cliente. Devuelve true si cambió.
Future<bool> cambiarBloqueo(
  BuildContext context,
  WidgetRef ref, {
  required int clienteId,
  required String nombre,
  required bool bloquear,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(bloquear ? Icons.gpp_bad_outlined : Icons.lock_open, color: bloquear ? AppColors.expirado : null),
      title: Text(bloquear ? '¿Bloquear a $nombre?' : '¿Devolver el acceso a $nombre?'),
      content: Text(bloquear
          ? 'Ya no podrá ver su plan, planes, avisos ni datos de pago, ni apartar lugares. '
              'Sus apartados pendientes se cancelan y los lugares se liberan ahora mismo.\n\n'
              'Verá un mensaje de seguridad con un botón para escribirte por WhatsApp. Puedes desbloquearlo cuando quieras.'
          : 'Podrá volver a usar la app normalmente.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: bloquear ? FilledButton.styleFrom(backgroundColor: AppColors.expirado) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(bloquear ? 'Bloquear acceso' : 'Desbloquear'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  try {
    await ref.read(adminRepositoryProvider).bloquearCliente(clienteId, bloquear: bloquear);
    refrescarAdmin(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(bloquear ? '$nombre fue bloqueado' : '$nombre puede volver a usar la app'),
      ));
    }
    return true;
  } catch (e) {
    if (context.mounted) mostrarError(context, e);
    return false;
  }
}
