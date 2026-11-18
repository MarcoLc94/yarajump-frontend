import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dinero.dart';
import '../../../core/utils/fechas.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/comunicado.dart';
import '../../../data/models/solicitud.dart';
import '../../../services/notification_service.dart';
import '../../../services/push_web/push_web.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/compartir_comprobante.dart';
import '../../shared/widgets/cuenta_pago_visual.dart';
import '../../shared/widgets/estado_chip.dart';
import '../../shared/widgets/horario_tile.dart';
import '../../shared/widgets/ui.dart';
import '../../shared/widgets/whatsapp_button.dart';
import '../planes/planes_screen.dart';

class MiPlanScreen extends ConsumerWidget {
  const MiPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(sessionProvider).value?.user.nombre ?? '';
    final solicitud = ref.watch(miSolicitudProvider).value;
    return Scaffold(
      body: AsyncBody(
        value: ref.watch(miClienteProvider),
        onRetry: () => ref.invalidate(miClienteProvider),
        data: (c) => RefreshIndicator(
          onRefresh: () {
            ref.invalidate(misComunicadosProvider);
            ref.invalidate(misCuentasPagoProvider);
            ref.invalidate(miSolicitudProvider);
            return ref.refresh(miClienteProvider.future);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Saludo(nombre: c?.nombre ?? nombre, fotoUrl: c?.fotoUrl, iniciales: c?.iniciales ?? '?'),
              const _ActivarNotificaciones(),
              const _AvisosYara(),
              if (solicitud != null)
                _SolicitudPendiente(solicitud: solicitud)
              else if (c == null || c.estado == EstadoPlan.sinPlan)
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

/// Solo PWA: invita a activar las notificaciones (o a instalar la app en iPhone, que es requisito).
class _ActivarNotificaciones extends StatefulWidget {
  const _ActivarNotificaciones();
  @override
  State<_ActivarNotificaciones> createState() => _ActivarNotificacionesState();
}

class _ActivarNotificacionesState extends State<_ActivarNotificaciones> {
  static bool _oculta = false; // "Ahora no": hasta que vuelva a abrir la app
  bool _cargando = false;

  void _activar() {
    setState(() => _cargando = true);
    // Sin await antes de activarWeb: el permiso debe pedirse dentro del toque.
    NotificationService.instance.activarWeb().then((ok) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Listo, te avisaremos aquí 🔔'
            : 'No se activaron. Puedes permitirlas en los ajustes del navegador.'),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ValueListenableBuilder(
      valueListenable: NotificationService.instance.estadoWeb,
      builder: (context, estado, _) {
        final iphone = estado == EstadoPushWeb.instalarEnIphone;
        if (_oculta || (estado != EstadoPushWeb.pendiente && !iphone)) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.notifications_active_outlined, color: AppColors.primario),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Recibe los avisos de Yara',
                        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      iphone
                          ? 'En iPhone primero instala la app: ábrela en Safari, toca Compartir '
                              '(el cuadro con flecha) y luego "Agregar a pantalla de inicio". '
                              'Entra desde el ícono y activa las notificaciones.'
                          : 'Te avisamos cuando se apruebe tu lugar, cuando tu plan esté por vencer '
                              'y cuando Yara publique algo.',
                      style: t.bodySmall?.copyWith(color: AppColors.textoSuave),
                    ),
                  ]),
                ),
              ]),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                  onPressed: () => setState(() => _oculta = true),
                  child: Text(iphone ? 'Entendido' : 'Ahora no'),
                ),
                if (!iphone)
                  FilledButton.icon(
                    // El tema hace los botones de ancho completo; aquí va junto a "Ahora no"
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
                    onPressed: _cargando ? null : _activar,
                    icon: _cargando
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.notifications_outlined, size: 18),
                    label: const Text('Activar'),
                  ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

class _SinPlan extends ConsumerWidget {
  const _SinPlan({required this.nombre});
  final String nombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            'Aún no tienes un plan activo. Elige tu plan y tus turnos para apartar tu lugar, '
            'o escríbele a Yara si tienes dudas.',
            style: t.bodyMedium?.copyWith(color: AppColors.textoSuave),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ref.invalidate(planesOfertadosProvider); // lugares al momento
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlanesDisponiblesScreen()));
            },
            icon: const Icon(Icons.view_list_rounded),
            label: const Text('Ver planes'),
          ),
          const SizedBox(height: 10),
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

/// El cliente apartó plan y turnos: espera a que Yara confirme su pago.
class _SolicitudPendiente extends ConsumerWidget {
  const _SolicitudPendiente({required this.solicitud});
  final Solicitud solicitud;

  Future<void> _cancelar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar tu apartado?'),
        content: const Text('Se liberarán tus lugares y otra persona podrá tomarlos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, cancelar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(perfilRepositoryProvider).cancelarSolicitud();
      ref.invalidate(miSolicitudProvider);
      ref.invalidate(planesOfertadosProvider);
    } catch (e) {
      if (context.mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final n = solicitud.horarios.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(AppTheme.radio),
          border: Border.all(color: AppColors.porVencer.withValues(alpha: 0.5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.porVencer.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.event_seat_outlined, color: AppColors.porVencer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Lugar apartado', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text('Esperando a que Yara confirme tu pago',
                    style: t.bodySmall?.copyWith(color: AppColors.porVencer, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Text(solicitud.planNombre, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          for (final h in solicitud.horarios)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(children: [
                Icon(h.turno.icono, size: 18, color: AppColors.textoSuave),
                const SizedBox(width: 8),
                Expanded(child: Text('${h.titulo} · ${h.diasTexto}', style: t.bodyMedium)),
              ]),
            ),
          const Divider(height: 28),
          Row(children: [
            Expanded(
              child: Text('$n turno${n == 1 ? '' : 's'} × ${dinero(solicitud.precio)}',
                  style: t.bodyMedium?.copyWith(color: AppColors.textoSuave)),
            ),
            Text('Total ${dinero(solicitud.total)}',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primario)),
          ]),
          const SizedBox(height: 12),
          Text('Paga con los datos de abajo y comparte tu comprobante para que Yara active tu plan.',
              style: t.bodyMedium?.copyWith(color: AppColors.textoSuave)),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.expirado),
              onPressed: () => _cancelar(context, ref),
              icon: const Icon(Icons.close),
              label: const Text('Cancelar apartado'),
            ),
          ),
        ]),
      ),
    );
  }
}
