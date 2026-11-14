import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../data/models/cliente.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/estado_chip.dart';
import '../../shared/widgets/whatsapp_button.dart';

class MiPlanScreen extends ConsumerWidget {
  const MiPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi plan')),
      body: AsyncBody(
        value: ref.watch(miClienteProvider),
        onRetry: () => ref.invalidate(miClienteProvider),
        data: (c) => RefreshIndicator(
          onRefresh: () => ref.refresh(miClienteProvider.future),
          child: c == null || c.estado == EstadoPlan.sinPlan ? const _SinPlan() : _DetallePlan(cliente: c),
        ),
      ),
    );
  }
}

class _DetallePlan extends StatelessWidget {
  const _DetallePlan({required this.cliente});
  final Cliente cliente;

  @override
  Widget build(BuildContext context) {
    final estado = cliente.estado;
    final dias = cliente.diasRestantes ?? 0;
    final color = colorEstado(estado);
    final t = Theme.of(context).textTheme;
    final expirado = estado == EstadoPlan.expirado;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color, width: 2)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Text(cliente.planNombre ?? 'Plan', style: t.headlineSmall),
              const SizedBox(height: 8),
              EstadoChip(estado),
              const SizedBox(height: 24),
              if (expirado)
                Text('PLAN EXPIRADO',
                    style: t.headlineMedium?.copyWith(color: AppColors.expirado, fontWeight: FontWeight.bold))
              else ...[
                Text('$dias', style: t.displayLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
                Text(dias == 1 ? 'día restante' : 'días restantes', style: t.titleMedium),
              ],
              const SizedBox(height: 16),
              Text(expirado
                  ? 'Venció el ${Fechas.formato(cliente.fechaFin!)}'
                  : 'Vigente hasta el ${Fechas.formato(cliente.fechaFin!)}'),
              if (cliente.precio != null)
                Text('Costo: \$${cliente.precio!.toStringAsFixed(0)} · ${cliente.frecuencia.etiqueta}'),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        if (estado == EstadoPlan.porVencer)
          const _Aviso(
            color: AppColors.porVencer,
            icono: Icons.warning_amber,
            texto: 'Tu plan está por expirar. Realiza tu pago para seguir disfrutando de tus clases.',
          ),
        if (estado == EstadoPlan.ultimoDia)
          const _Aviso(
            color: AppColors.porVencer,
            icono: Icons.alarm,
            texto: 'Hoy es tu último día. Debes realizar tu pago para continuar mañana.',
          ),
        if (expirado) ...[
          const _Aviso(
            color: AppColors.expirado,
            icono: Icons.error_outline,
            texto: 'Tu plan expiró. Regulariza tu pago comunicándote con Yara Jumping.',
          ),
          const SizedBox(height: 16),
          WhatsappButton(nombreCliente: cliente.nombre, texto: 'Regularizar pago por WhatsApp'),
        ],
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.color, required this.icono, required this.texto});
  final Color color;
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Row(children: [
          Icon(icono, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ]),
      );
}

class _SinPlan extends StatelessWidget {
  const _SinPlan();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(32),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.card_membership, size: 72),
          SizedBox(height: 16),
          Text('Aún no tienes un plan asignado', textAlign: TextAlign.center),
          SizedBox(height: 24),
          WhatsappButton(),
        ],
      );
}
