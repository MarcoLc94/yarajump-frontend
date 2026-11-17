import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/horario.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/horario_tile.dart';
import '../../shared/widgets/ui.dart';

/// La admin crea los horarios (turno, horas y días) que luego asigna a cada cliente.
class HorariosScreen extends ConsumerWidget {
  const HorariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-horarios',
        onPressed: () => editarHorario(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo horario'),
      ),
      body: AsyncBody(
        value: ref.watch(horariosProvider),
        onRetry: () => ref.invalidate(horariosProvider),
        data: (lista) => RefreshIndicator(
          onRefresh: () => ref.refresh(horariosProvider.future),
          child: lista.isEmpty
              ? ListView(children: [
                  const SizedBox(height: 60),
                  EmptyState(
                    icono: Icons.schedule,
                    titulo: 'Aún no hay horarios',
                    mensaje: 'Crea los horarios de la mañana, tarde y noche para asignarlos a tus clientes.',
                    accion: FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size(220, 52)),
                      onPressed: () => editarHorario(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear horario'),
                    ),
                  ),
                ])
              : ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    for (final turno in Turno.values)
                      if (lista.any((h) => h.turno == turno)) ...[
                        SectionTitle(turno.etiqueta),
                        for (final h in lista.where((h) => h.turno == turno))
                          HorarioTile(
                            horario: h,
                            subtitulo: '${h.inscritos} cliente${h.inscritos == 1 ? '' : 's'}'
                                '${h.activo ? '' : ' · Inactivo'}',
                            trailing: const Icon(Icons.chevron_right, color: AppColors.textoSuave),
                            onTap: () => editarHorario(context, ref, h),
                          ),
                      ],
                  ],
                ),
        ),
      ),
    );
  }
}

Future<void> editarHorario(BuildContext context, WidgetRef ref, [Horario? horario]) async {
  final res = await showModalBottomSheet<_Resultado>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _HorarioSheet(horario: horario),
  );
  if (res == null) return;
  final repo = ref.read(adminRepositoryProvider);
  try {
    if (res.eliminar) {
      await repo.eliminarHorario(horario!.id!);
    } else {
      await repo.guardarHorario(res.horario!);
    }
    refrescarAdmin(ref);
  } catch (e) {
    if (context.mounted) mostrarError(context, e);
  }
}

class _Resultado {
  const _Resultado.guardar(Horario this.horario) : eliminar = false;
  const _Resultado.eliminar()
      : horario = null,
        eliminar = true;
  final Horario? horario;
  final bool eliminar;
}

class _HorarioSheet extends StatefulWidget {
  const _HorarioSheet({this.horario});
  final Horario? horario;
  @override
  State<_HorarioSheet> createState() => _HorarioSheetState();
}

class _HorarioSheetState extends State<_HorarioSheet> {
  late final _nombre = TextEditingController(text: widget.horario?.nombre);
  late Turno _turno = widget.horario?.turno ?? Turno.manana;
  late TimeOfDay _inicio = _parse(widget.horario?.horaInicio) ?? const TimeOfDay(hour: 7, minute: 0);
  late TimeOfDay _fin = _parse(widget.horario?.horaFin) ?? const TimeOfDay(hour: 8, minute: 0);
  late final Set<int> _dias = {...?widget.horario?.dias};
  late bool _activo = widget.horario?.activo ?? true;

  static TimeOfDay? _parse(String? s) {
    if (s == null || !s.contains(':')) return null;
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  static String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _min(TimeOfDay t) => t.hour * 60 + t.minute;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _elegirHora(bool inicio) async {
    final t = await showTimePicker(context: context, initialTime: inicio ? _inicio : _fin);
    if (t == null) return;
    setState(() {
      if (inicio) {
        _inicio = t;
        // Sugiere el turno según la hora de inicio
        _turno = t.hour < 12 ? Turno.manana : (t.hour < 18 ? Turno.tarde : Turno.noche);
        if (_min(_fin) <= _min(_inicio)) _fin = TimeOfDay(hour: (t.hour + 1) % 24, minute: t.minute);
      } else {
        _fin = t;
      }
    });
  }

  void _guardar() {
    String? error;
    if (_dias.isEmpty) error = 'Elige al menos un día';
    if (_min(_fin) <= _min(_inicio)) error = 'La hora de fin debe ser después del inicio';
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(
      context,
      _Resultado.guardar(Horario(
        id: widget.horario?.id,
        nombre: _nombre.text.trim(),
        turno: _turno,
        horaInicio: _fmt(_inicio),
        horaFin: _fmt(_fin),
        dias: (_dias.toList()..sort()),
        activo: _activo,
      )),
    );
  }

  Future<void> _eliminar() async {
    final n = widget.horario!.inscritos;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar horario?'),
        content: Text(n > 0
            ? 'Hay $n cliente${n == 1 ? '' : 's'} con este horario; se les quitará. '
                'Si solo quieres dejar de usarlo, mejor desactívalo.'
            : 'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context, const _Resultado.eliminar());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.horario == null ? 'Nuevo horario' : 'Editar horario',
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SegmentedButton<Turno>(
            segments: [
              for (final tu in Turno.values) ButtonSegment(value: tu, label: Text(tu.etiqueta), icon: Icon(tu.icono)),
            ],
            selected: {_turno},
            onSelectionChanged: (s) => setState(() => _turno = s.first),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _HoraBox(etiqueta: 'Inicio', hora: _fmt(_inicio), onTap: () => _elegirHora(true))),
            const SizedBox(width: 12),
            Expanded(child: _HoraBox(etiqueta: 'Fin', hora: _fmt(_fin), onTap: () => _elegirHora(false))),
          ]),
          const SizedBox(height: 16),
          Text('Días', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var d = 1; d <= 7; d++)
              _DiaToggle(
                letra: diasCortos[d]!,
                activo: _dias.contains(d),
                onTap: () => setState(() => _dias.contains(d) ? _dias.remove(d) : _dias.add(d)),
              ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ActionChip(label: const Text('Lun a Vie'), onPressed: () => setState(() => _dias..clear()..addAll([1, 2, 3, 4, 5]))),
            ActionChip(label: const Text('L · M · V'), onPressed: () => setState(() => _dias..clear()..addAll([1, 3, 5]))),
            ActionChip(label: const Text('M · J'), onPressed: () => setState(() => _dias..clear()..addAll([2, 4]))),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre (opcional)', hintText: 'Ej. Jumping principiantes'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activo'),
            subtitle: const Text('Los inactivos no se pueden asignar a clientes nuevos'),
            value: _activo,
            onChanged: (v) => setState(() => _activo = v),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _guardar, child: const Text('Guardar')),
          if (widget.horario != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.expirado),
              onPressed: _eliminar,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar horario'),
            ),
          ],
        ]),
      ),
    );
  }
}

class _HoraBox extends StatelessWidget {
  const _HoraBox({required this.etiqueta, required this.hora, required this.onTap});
  final String etiqueta;
  final String hora;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(etiqueta, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textoSuave)),
            Text(hora, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class _DiaToggle extends StatelessWidget {
  const _DiaToggle({required this.letra, required this.activo, required this.onTap});
  final String letra;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: activo ? AppColors.primario : Colors.transparent,
            border: Border.all(color: activo ? AppColors.primario : AppColors.borde, width: 1.5),
          ),
          child: Text(letra,
              style: TextStyle(fontWeight: FontWeight.w700, color: activo ? Colors.white : AppColors.texto)),
        ),
      );
}
