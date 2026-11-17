import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../core/utils/periodo.dart';
import '../../../data/models/cliente.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/estado_chip.dart';
import '../../shared/widgets/filtro_periodo.dart';
import '../../shared/widgets/ui.dart';
import 'cliente_form_screen.dart';
import '../solicitudes/solicitudes_screen.dart';
import 'registrar_pago_sheet.dart';

class ClientesListScreen extends ConsumerStatefulWidget {
  const ClientesListScreen({super.key});
  @override
  ConsumerState<ClientesListScreen> createState() => _ClientesListScreenState();
}

enum _Filtro { todos, sinPlan, activos, porVencer, expirados }

class _ClientesListScreenState extends ConsumerState<ClientesListScreen> {
  String _busqueda = '';
  _Filtro _filtro = _Filtro.todos;
  Periodo _alta = Periodo.de(TipoPeriodo.todos); // filtro por fecha de registro

  Future<void> _abrirForm([Cliente? c]) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClienteFormScreen(cliente: c)));
    refrescarAdmin(ref);
  }

  static bool _pasa(Cliente c, _Filtro f) => switch (f) {
        _Filtro.todos => true,
        _Filtro.sinPlan => c.estado == EstadoPlan.sinPlan,
        _Filtro.activos => c.estado == EstadoPlan.activo,
        _Filtro.porVencer => c.estado == EstadoPlan.porVencer || c.estado == EstadoPlan.ultimoDia,
        _Filtro.expirados => c.estado == EstadoPlan.expirado,
      };

  @override
  Widget build(BuildContext context) {
    final clientes = ref.watch(clientesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-clientes',
        onPressed: _abrirForm,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo'),
      ),
      body: AsyncBody(
        value: clientes,
        onRetry: () => ref.invalidate(clientesProvider),
        data: (lista) {
          final q = _busqueda.toLowerCase();
          final filtrados = lista
              .where((c) =>
                  _pasa(c, _filtro) &&
                  (c.creadoEn == null || _alta.incluye(c.creadoEn!)) &&
                  (c.nombre.toLowerCase().contains(q) || c.email.contains(q)))
              .toList();
          // Los contadores de estado respetan el filtro de fecha de registro
          int contar(_Filtro f) =>
              lista.where((c) => _pasa(c, f) && (c.creadoEn == null || _alta.incluye(c.creadoEn!))).length;

          final sinPlan = contar(_Filtro.sinPlan);
          final apartados = ref.watch(solicitudesProvider).value?.length ?? 0;

          return RefreshIndicator(
            onRefresh: () => ref.refresh(clientesProvider.future),
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por nombre o correo'),
                    onChanged: (v) => setState(() => _busqueda = v),
                  ),
                ),
              ),
              if (apartados > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Material(
                      color: AppColors.porVencer.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radio),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.radio),
                        onTap: () async {
                          await Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const SolicitudesScreen()));
                          refrescarAdmin(ref);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            const Icon(Icons.event_seat_outlined, color: AppColors.porVencer),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$apartados apartado${apartados == 1 ? '' : 's'} de plan por confirmar',
                                style: const TextStyle(color: AppColors.porVencer, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.porVencer),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              if (sinPlan > 0 && _filtro != _Filtro.sinPlan)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Material(
                      color: AppColors.primario.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radio),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppTheme.radio),
                        onTap: () => setState(() => _filtro = _Filtro.sinPlan),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            const Icon(Icons.how_to_reg, color: AppColors.primario),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$sinPlan cliente${sinPlan == 1 ? '' : 's'} esperando que actives su plan',
                                style: const TextStyle(color: AppColors.primario, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.primario),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    children: [
                      for (final (f, etiqueta) in [
                        (_Filtro.todos, 'Todos'),
                        (_Filtro.sinPlan, 'Sin plan'),
                        (_Filtro.activos, 'Activos'),
                        (_Filtro.porVencer, 'Por vencer'),
                        (_Filtro.expirados, 'Expirados'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$etiqueta (${contar(f)})'),
                            selected: _filtro == f,
                            onSelected: (_) => setState(() => _filtro = f),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Text('Registrados',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textoSuave)),
                ),
              ),
              SliverToBoxAdapter(
                child: FiltroPeriodo(valor: _alta, conTodos: true, onCambio: (p) => setState(() => _alta = p)),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Text('${filtrados.length} cliente${filtrados.length == 1 ? '' : 's'} · más recientes primero',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textoSuave)),
                ),
              ),
              if (filtrados.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(icono: Icons.people_outline, titulo: 'Sin clientes', mensaje: 'Nada por aquí con ese filtro.'),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(top: 4, bottom: 100),
                  sliver: SliverList.builder(
                    itemCount: filtrados.length,
                    itemBuilder: (_, i) => _ClienteCard(
                      cliente: filtrados[i],
                      onTap: () => _abrirForm(filtrados[i]),
                      onLongPress: filtrados[i].planId == null
                          ? null
                          : () async {
                              await mostrarRegistrarPago(context, filtrados[i]);
                              refrescarAdmin(ref);
                            },
                    ),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}

class _ClienteCard extends StatelessWidget {
  const _ClienteCard({required this.cliente, required this.onTap, this.onLongPress});
  final Cliente cliente;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = cliente;
    final detalle = c.planId == null
        ? (c.vinculado ? 'Registrado · sin plan' : 'Sin plan · aún no entra a la app')
        : '${c.planNombre} · ${c.frecuencia.etiqueta}';
    final horarios = c.horarios.map((h) => h.horaInicio).join(' · ');
    final alta = c.creadoEn == null ? null : 'Alta: ${Fechas.relativa(c.creadoEn!).toLowerCase()}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Avatar(fotoUrl: c.fotoUrl, iniciales: c.iniciales),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(c.nombre, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                  if (c.bloqueado || c.historial.sospechoso) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: c.bloqueado
                          ? 'Bloqueado por seguridad'
                          : '${c.historial.sinConcretar} apartados sin pagar',
                      child: Icon(c.bloqueado ? Icons.block : Icons.warning_amber_rounded,
                          size: 16, color: AppColors.expirado),
                    ),
                  ],
                ]),
                Text(alta == null ? detalle : '$detalle · $alta', style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
                if (horarios.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(children: [
                      const Icon(Icons.schedule, size: 14, color: AppColors.textoSuave),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(horarios,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
                      ),
                    ]),
                  ),
              ]),
            ),
            EstadoChip(c.estado),
          ]),
        ),
      ),
    );
  }
}
