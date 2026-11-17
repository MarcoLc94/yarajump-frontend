import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../data/models/comunicado.dart';
import '../../../data/models/horario.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/ui.dart';
import '../recordatorios/recordatorios_screen.dart';

/// Pestaña "Avisos" de la admin: avisos a clientes + vencimientos de planes.
class AvisosScreen extends StatelessWidget {
  const AvisosScreen({super.key});

  @override
  Widget build(BuildContext context) => const DefaultTabController(
        length: 2,
        child: Column(children: [
          TabBar(tabs: [
            Tab(icon: Icon(Icons.campaign_outlined), text: 'Avisos'),
            Tab(icon: Icon(Icons.event_busy_outlined), text: 'Vencimientos'),
          ]),
          Expanded(child: TabBarView(children: [_Comunicados(), RecordatoriosScreen()])),
        ]),
      );
}

class _Comunicados extends ConsumerWidget {
  const _Comunicados();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horarios = ref.watch(horariosProvider).value ?? const <Horario>[];
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-avisos',
        onPressed: () => nuevoAviso(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo aviso'),
      ),
      body: AsyncBody(
        value: ref.watch(comunicadosProvider),
        onRetry: () => ref.invalidate(comunicadosProvider),
        data: (lista) => RefreshIndicator(
          onRefresh: () => ref.refresh(comunicadosProvider.future),
          child: lista.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 40),
                  EmptyState(
                    icono: Icons.campaign_outlined,
                    titulo: 'Sin avisos todavía',
                    mensaje: 'Manda un aviso a todos tus clientes, a un turno o a un horario. '
                        'Lo verán en la app y les llega notificación en Android.',
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: lista.length,
                  itemBuilder: (_, i) => _ComunicadoTile(aviso: lista[i], horarios: horarios),
                ),
        ),
      ),
    );
  }
}

class _ComunicadoTile extends ConsumerWidget {
  const _ComunicadoTile({required this.aviso, required this.horarios});
  final Comunicado aviso;
  final List<Horario> horarios;

  Future<void> _eliminar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar este aviso?'),
        content: const Text('Tus clientes dejarán de verlo en la app. Las notificaciones que ya llegaron no se pueden quitar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).eliminarComunicado(aviso.id);
      ref.invalidate(comunicadosProvider);
    } catch (e) {
      if (context.mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final suave = t.bodySmall?.copyWith(color: AppColors.textoSuave);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(aviso.titulo, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
            Text(Fechas.relativa(aviso.fecha), style: suave),
            IconButton(
              tooltip: 'Borrar aviso',
              icon: const Icon(Icons.delete_outline, color: AppColors.textoSuave),
              onPressed: () => _eliminar(context, ref),
            ),
          ]),
          Padding(padding: const EdgeInsets.only(right: 12), child: Text(aviso.cuerpo, style: t.bodyMedium)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Chip(
              visualDensity: VisualDensity.compact,
              avatar: const Icon(Icons.groups_outlined, size: 18),
              label: Text(aviso.descripcionAudiencia(horarios)),
            ),
            Text(
              '${aviso.destinatarios} cliente${aviso.destinatarios == 1 ? '' : 's'}'
              ' · ${aviso.notificados} notificación${aviso.notificados == 1 ? '' : 'es'}',
              style: suave,
            ),
          ]),
        ]),
      ),
    );
  }
}

Future<void> nuevoAviso(BuildContext context, WidgetRef ref) async {
  final creado = await showModalBottomSheet<Comunicado>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _NuevoAvisoSheet(),
  );
  if (creado == null) return;
  ref.invalidate(comunicadosProvider);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Aviso enviado a ${creado.destinatarios} cliente${creado.destinatarios == 1 ? '' : 's'}'),
    ));
  }
  // El conteo de notificaciones se completa en segundo plano: recarga en un momento.
  await Future<void>.delayed(const Duration(seconds: 3));
  ref.invalidate(comunicadosProvider);
}

class _NuevoAvisoSheet extends ConsumerStatefulWidget {
  const _NuevoAvisoSheet();
  @override
  ConsumerState<_NuevoAvisoSheet> createState() => _NuevoAvisoSheetState();
}

class _NuevoAvisoSheetState extends ConsumerState<_NuevoAvisoSheet> {
  final _titulo = TextEditingController();
  final _cuerpo = TextEditingController();
  Audiencia _audiencia = Audiencia.todos;
  Turno _turno = Turno.manana;
  int? _horarioId;
  Future<int>? _alcance;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _calcularAlcance();
  }

  @override
  void dispose() {
    _titulo.dispose();
    _cuerpo.dispose();
    super.dispose();
  }

  bool get _audienciaCompleta => _audiencia != Audiencia.horario || _horarioId != null;

  void _calcularAlcance() {
    _alcance = _audienciaCompleta
        ? ref.read(adminRepositoryProvider).alcance(_audiencia, turno: _turno, horarioId: _horarioId)
        : null;
  }

  void _cambiar(VoidCallback f) => setState(() {
        f();
        _calcularAlcance();
      });

  Future<void> _enviar() async {
    final titulo = _titulo.text.trim(), cuerpo = _cuerpo.text.trim();
    String? error;
    if (titulo.isEmpty || cuerpo.isEmpty) error = 'Escribe el título y el mensaje';
    if (!_audienciaCompleta) error = 'Elige el horario';
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final n = await _alcance ?? 0;
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Enviar aviso?'),
        content: Text(n == 0
            ? 'Ningún cliente está en esta audiencia todavía. Se guardará, pero nadie lo verá por ahora.'
            : 'Lo verán $n cliente${n == 1 ? '' : 's'} en la app y les llegará notificación a quienes tengan Android.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enviar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _enviando = true);
    try {
      final c = await ref.read(adminRepositoryProvider).crearComunicado(
            titulo: titulo,
            cuerpo: cuerpo,
            audiencia: _audiencia,
            turno: _turno,
            horarioId: _horarioId,
          );
      if (mounted) Navigator.pop(context, c);
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final horarios = (ref.watch(horariosProvider).value ?? const <Horario>[]).where((h) => h.activo).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Nuevo aviso', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _titulo,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Título', hintText: 'Ej. No hay clase el lunes'),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _cuerpo,
            maxLength: 1000,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Mensaje', alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          Text('¿Para quién?', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<Audiencia>(
            segments: const [
              ButtonSegment(value: Audiencia.todos, label: Text('Todos'), icon: Icon(Icons.groups_outlined)),
              ButtonSegment(value: Audiencia.turno, label: Text('Turno'), icon: Icon(Icons.wb_twilight)),
              ButtonSegment(value: Audiencia.horario, label: Text('Horario'), icon: Icon(Icons.schedule)),
            ],
            selected: {_audiencia},
            onSelectionChanged: (s) => _cambiar(() => _audiencia = s.first),
          ),
          if (_audiencia == Audiencia.turno) ...[
            const SizedBox(height: 12),
            SegmentedButton<Turno>(
              segments: [
                for (final tu in Turno.values) ButtonSegment(value: tu, label: Text(tu.etiqueta), icon: Icon(tu.icono)),
              ],
              selected: {_turno},
              onSelectionChanged: (s) => _cambiar(() => _turno = s.first),
            ),
          ],
          if (_audiencia == Audiencia.horario) ...[
            const SizedBox(height: 12),
            if (horarios.isEmpty)
              Text('Aún no tienes horarios activos.', style: t.bodyMedium?.copyWith(color: AppColors.textoSuave))
            else
              DropdownButtonFormField<int>(
                initialValue: _horarioId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Horario', prefixIcon: Icon(Icons.schedule)),
                items: [
                  for (final h in horarios)
                    DropdownMenuItem(
                      value: h.id,
                      child: Text('${h.titulo} · ${h.diasTexto}', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => _cambiar(() => _horarioId = v),
              ),
          ],
          const SizedBox(height: 14),
          _Alcance(futuro: _alcance),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _enviando ? null : _enviar,
            icon: _enviando
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.send),
            label: const Text('Enviar aviso'),
          ),
        ]),
      ),
    );
  }
}

class _Alcance extends StatelessWidget {
  const _Alcance({required this.futuro});
  final Future<int>? futuro;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textoSuave);
    if (futuro == null) return Text('Elige un horario para ver a cuántos clientes llega.', style: estilo);
    return FutureBuilder<int>(
      future: futuro,
      builder: (_, s) {
        final texto = s.hasError
            ? 'No se pudo calcular el alcance'
            : !s.hasData
                ? 'Calculando…'
                : 'Lo verán ${s.data} cliente${s.data == 1 ? '' : 's'}';
        return Row(children: [
          const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textoSuave),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: estilo)),
        ]);
      },
    );
  }
}
