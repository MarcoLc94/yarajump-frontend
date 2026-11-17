import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/comunicado.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/compartir_comprobante.dart';
import '../../shared/widgets/cuenta_pago_visual.dart';
import '../../shared/widgets/estado_chip.dart';
import '../../shared/widgets/horario_tile.dart';
import '../../shared/widgets/ui.dart';
import '../../shared/widgets/whatsapp_button.dart';

class MiPlanScreen extends ConsumerWidget {
  const MiPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(sessionProvider).value?.user.nombre ?? '';
    return Scaffold(
      body: AsyncBody(
        value: ref.watch(miClienteProvider),
        onRetry: () => ref.invalidate(miClienteProvider),
        data: (c) => RefreshIndicator(
          onRefresh: () {
            ref.invalidate(misComunicadosProvider);
            ref.invalidate(misCuentasPagoProvider);
            return ref.refresh(miClienteProvider.future);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Saludo(nombre: c?.nombre ?? nombre, fotoUrl: c?.fotoUrl, iniciales: c?.iniciales ?? '?'),
              const _AvisosYara(),
              if (c == null || c.estado == EstadoPlan.sinPlan)
                _SinPlan(nombre: c?.nombre ?? nombre)
              else
                _DetallePlan(cliente: c),
              if (c != null)
                _DatosDePago(
                  nombreCliente: c.nombre,
                  // Sin plan ya tiene su botón "Activar mi plan por WhatsApp"
                  conWhatsapp: c.estado != EstadoPlan.sinPlan,
                ),
              if (c != null) _MisHorarios(cliente: c),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Saludo extends StatelessWidget {
  const _Saludo({required this.nombre, this.fotoUrl, required this.iniciales});
  final String nombre;
  final String? fotoUrl;
  final String iniciales;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final primerNombre = nombre.trim().split(' ').first;
    return GradientHeader(
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hola${primerNombre.isEmpty ? '' : ', $primerNombre'} 👋',
                style: t.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
            Text('¡A brincar se ha dicho!', style: t.bodyMedium?.copyWith(color: Colors.white70)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Avatar(fotoUrl: fotoUrl, iniciales: iniciales, radio: 26),
        ),
      ]),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(AppTheme.radio),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tu plan', style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
                  Text(cliente.planNombre ?? 'Plan', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ]),
              ),
              EstadoChip(estado),
            ]),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (expirado)
                Text('Expirado', style: t.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w800))
              else ...[
                Text('$dias', style: t.displayMedium?.copyWith(color: color, fontWeight: FontWeight.w800, height: 1)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(dias == 1 ? 'día restante' : 'días restantes', style: t.titleMedium),
                ),
              ],
            ]),
            const SizedBox(height: 16),
            if (!expirado && cliente.fechaInicio != null && cliente.fechaFin != null)
              _BarraVigencia(inicio: cliente.fechaInicio!, fin: cliente.fechaFin!, color: color),
            const SizedBox(height: 12),
            Text(
              expirado
                  ? 'Venció el ${Fechas.formato(cliente.fechaFin!)}'
                  : 'Vigente hasta el ${Fechas.formato(cliente.fechaFin!)}',
              style: t.bodyMedium?.copyWith(color: AppColors.textoSuave),
            ),
            if (cliente.precio != null)
              Text('\$${cliente.precio!.toStringAsFixed(0)} · ${cliente.frecuencia.etiqueta}',
                  style: t.bodyMedium?.copyWith(color: AppColors.textoSuave)),
          ]),
        ),
        const SizedBox(height: 12),
        if (estado == EstadoPlan.porVencer)
          const _Aviso(
            color: AppColors.porVencer,
            icono: Icons.warning_amber,
            texto: 'Tu plan está por vencer. Realiza tu pago para seguir disfrutando de tus clases.',
          ),
        if (estado == EstadoPlan.ultimoDia)
          const _Aviso(
            color: AppColors.porVencer,
            icono: Icons.alarm,
            texto: 'Hoy es tu último día. Realiza tu pago para continuar mañana.',
          ),
        if (expirado)
          const _Aviso(
            color: AppColors.expirado,
            icono: Icons.error_outline,
            texto: 'Tu plan expiró. Regulariza tu pago con los datos de abajo o escríbele a Yara Jump.',
          ),
      ]),
    );
  }
}

class _BarraVigencia extends StatelessWidget {
  const _BarraVigencia({required this.inicio, required this.fin, required this.color});
  final DateTime inicio;
  final DateTime fin;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final total = fin.difference(inicio).inDays + 1;
    final usados = Fechas.hoy().difference(inicio).inDays + 1;
    final p = total <= 0 ? 1.0 : (usados / total).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: 1 - p,
        minHeight: 10,
        color: color,
        backgroundColor: color.withValues(alpha: 0.12),
      ),
    );
  }
}

class _MisHorarios extends StatelessWidget {
  const _MisHorarios({required this.cliente});
  final Cliente cliente;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionTitle('Mis horarios'),
      if (cliente.horarios.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.schedule, color: AppColors.textoSuave),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cliente.estado == EstadoPlan.sinPlan
                      ? 'Yara te asignará tu horario al activar tu plan.'
                      : 'Aún no tienes horario asignado.',
                  style: const TextStyle(color: AppColors.textoSuave),
                ),
              ),
            ]),
          ),
        )
      else
        for (final h in cliente.horarios) HorarioTile(horario: h),
    ]);
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
          borderRadius: BorderRadius.circular(AppTheme.radio),
        ),
        child: Row(children: [
          Icon(icono, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ]),
      );
}

class _SinPlan extends StatelessWidget {
  const _SinPlan({required this.nombre});
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(AppTheme.radio),
          border: Border.all(color: AppColors.borde),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.primario.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.hourglass_top, color: AppColors.primario),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('Tu cuenta está lista', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            'Aún no tienes un plan activo. Escríbele a Yara para elegir tu plan y tu horario; '
            'en cuanto lo active lo verás aquí.',
            style: t.bodyMedium?.copyWith(color: AppColors.textoSuave),
          ),
          const SizedBox(height: 16),
          WhatsappButton(nombreCliente: nombre, texto: 'Activar mi plan por WhatsApp', motivo: MotivoWhatsapp.activar),
        ]),
      ),
    );
  }
}

/// Avisos que Yara mandó a todos, al turno o al horario del cliente.
class _AvisosYara extends ConsumerWidget {
  const _AvisosYara();
  static const _visibles = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avisos = ref.watch(misComunicadosProvider).value ?? const <Comunicado>[];
    if (avisos.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(
        'Avisos de Yara',
        trailing: avisos.length > _visibles
            ? TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Avisos de Yara')),
                    body: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [for (final a in avisos) ComunicadoCard(aviso: a)],
                    ),
                  ),
                )),
                child: Text('Ver todos (${avisos.length})'),
              )
            : null,
      ),
      for (final a in avisos.take(_visibles)) ComunicadoCard(aviso: a),
    ]);
  }
}

class ComunicadoCard extends StatelessWidget {
  const ComunicadoCard({super.key, required this.aviso});
  final Comunicado aviso;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primario.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign_outlined, color: AppColors.primario),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(aviso.titulo, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
                Text(Fechas.relativa(aviso.fecha), style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
              ]),
              const SizedBox(height: 4),
              Text(aviso.cuerpo, style: t.bodyMedium),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Dónde pagar (tarjeta/CLABE dibujadas), pagar por WhatsApp y compartir comprobante.
class _DatosDePago extends ConsumerWidget {
  const _DatosDePago({required this.nombreCliente, required this.conWhatsapp});
  final String nombreCliente;
  final bool conWhatsapp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentas = ref.watch(misCuentasPagoProvider).value ?? const [];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionTitle(cuentas.isEmpty ? 'Pagos' : 'Datos para pagar'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final c in cuentas) ...[CuentaPagoVisual(cuenta: c), const SizedBox(height: 8)],
          if (conWhatsapp) ...[
            WhatsappButton(nombreCliente: nombreCliente, texto: 'Pagar por WhatsApp'),
            const SizedBox(height: 10),
          ],
          CompartirComprobanteButton(nombreCliente: nombreCliente),
        ]),
      ),
    ]);
  }
}
