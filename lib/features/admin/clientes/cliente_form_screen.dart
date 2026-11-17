import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/fechas.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/frecuencia.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/estado_chip.dart';
import '../../shared/widgets/horario_tile.dart';
import '../../shared/widgets/ui.dart';
import 'cliente_progreso_screen.dart';
import 'registrar_pago_sheet.dart';

class ClienteFormScreen extends ConsumerStatefulWidget {
  const ClienteFormScreen({super.key, this.cliente});
  final Cliente? cliente;
  @override
  ConsumerState<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends ConsumerState<ClienteFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.cliente?.nombre);
  late final _email = TextEditingController(text: widget.cliente?.email);
  late final _telefono = TextEditingController(text: widget.cliente?.telefono);
  late final _diasLibres = TextEditingController(text: widget.cliente?.diasPersonalizados?.toString() ?? '');

  late int? _planId = widget.cliente?.planId;
  late Frecuencia _frecuencia = widget.cliente?.frecuencia ?? Frecuencia.mensual;
  late DateTime _inicio = widget.cliente?.fechaInicio ?? Fechas.hoy();
  late final Set<int> _horarioIds = {...?widget.cliente?.horarios.map((h) => h.id!)};
  bool _guardando = false;

  bool get _editando => widget.cliente != null;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _telefono.dispose();
    _diasLibres.dispose();
    super.dispose();
  }

  int? get _diasPersonalizados => int.tryParse(_diasLibres.text);

  /// Vista previa; el valor definitivo lo calcula el servidor.
  DateTime get _finCalculado => _frecuencia.calcularFechaFin(_inicio, diasPersonalizados: _diasPersonalizados);

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await ref.read(adminRepositoryProvider).guardarCliente(
            Cliente(
              id: widget.cliente?.id,
              nombre: _nombre.text.trim(),
              email: _email.text.trim(),
              telefono: _telefono.text.trim(),
              planId: _planId,
              frecuencia: _frecuencia,
              diasPersonalizados: _diasPersonalizados,
              fechaInicio: _inicio,
              activo: widget.cliente?.activo ?? true,
            ),
            horarioIds: _horarioIds.toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_planId != null && widget.cliente?.planId == null ? 'Plan activado ✅' : 'Guardado ✅')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar cliente?'),
        content: Text('${widget.cliente!.nombre}\nTambién se borrará su historial de pagos y su progreso.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminRepositoryProvider).eliminarCliente(widget.cliente!.id!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final planes = ref.watch(planesProvider).value ?? [];
    final disponibles = planes.where((p) => p.activo || p.id == _planId).toList();
    final horarios = (ref.watch(horariosProvider).value ?? [])
        .where((h) => h.activo || _horarioIds.contains(h.id))
        .toList();
    final c = widget.cliente;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Cliente' : 'Nuevo cliente'),
        actions: [
          if (_editando) IconButton(tooltip: 'Eliminar', icon: const Icon(Icons.delete_outline), onPressed: _eliminar),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (c != null) _Cabecera(cliente: c),
            if (c != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Pago'),
                      onPressed: c.planId == null
                          ? null
                          : () async {
                              final pagado = await mostrarRegistrarPago(context, c);
                              if (pagado && context.mounted) Navigator.pop(context);
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.insights_outlined),
                      label: const Text('Progreso'),
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => ClienteProgresoScreen(cliente: c))),
                    ),
                  ),
                ]),
              ),
            const SectionTitle('Datos'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Correo', helperText: 'Con este correo el cliente entra a la app'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
              ]),
            ),
            const SectionTitle('Plan'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                DropdownButtonFormField<int?>(
                  initialValue: disponibles.any((p) => p.id == _planId) ? _planId : null,
                  decoration: const InputDecoration(labelText: 'Plan'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Sin plan')),
                    ...disponibles.map((p) => DropdownMenuItem<int?>(
                        value: p.id, child: Text('${p.nombre} · \$${p.precio.toStringAsFixed(0)}'))),
                  ],
                  onChanged: (id) => setState(() {
                    final antes = _planId;
                    _planId = id;
                    if (id != null && antes == null) {
                      _frecuencia = disponibles.firstWhere((e) => e.id == id).frecuenciaSugerida;
                      if (c?.fechaInicio == null) _inicio = Fechas.hoy();
                    }
                  }),
                ),
                if (_planId != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Frecuencia>(
                    initialValue: _frecuencia,
                    decoration: const InputDecoration(labelText: 'Frecuencia de pago'),
                    items:
                        Frecuencia.values.map((f) => DropdownMenuItem(value: f, child: Text(f.etiqueta))).toList(),
                    onChanged: (f) => setState(() => _frecuencia = f!),
                  ),
                  if (_frecuencia == Frecuencia.libre) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _diasLibres,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cada cuántos días'),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Ingresa un número de días' : null,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(children: [
                      ListTile(
                        leading: const Icon(Icons.event, color: AppColors.primario),
                        title: const Text('Inicio / último pago'),
                        subtitle: Text(Fechas.formato(_inicio)),
                        trailing: const Icon(Icons.edit_calendar_outlined),
                        onTap: () async {
                          final d = await showDatePicker(
                              context: context, initialDate: _inicio, firstDate: DateTime(2020), lastDate: DateTime(2100));
                          if (d != null) setState(() => _inicio = Fechas.soloFecha(d));
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.event_busy, color: AppColors.textoSuave),
                        title: const Text('Vence (último día cubierto)'),
                        subtitle: Text(Fechas.formato(_finCalculado)),
                      ),
                    ]),
                  ),
                ],
              ]),
            ),
            SectionTitle('Horarios',
                trailing: Text('${_horarioIds.length} elegido${_horarioIds.length == 1 ? '' : 's'}',
                    style: t.bodySmall?.copyWith(color: AppColors.textoSuave))),
            if (horarios.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Aún no hay horarios. Créalos en la pestaña "Horarios".',
                    style: TextStyle(color: AppColors.textoSuave)),
              )
            else
              for (final h in horarios)
                HorarioTile(
                  horario: h,
                  onTap: () => setState(() => _horarioIds.contains(h.id) ? _horarioIds.remove(h.id) : _horarioIds.add(h.id!)),
                  trailing: Checkbox(
                    value: _horarioIds.contains(h.id),
                    onChanged: (v) => setState(() => v == true ? _horarioIds.add(h.id!) : _horarioIds.remove(h.id)),
                  ),
                ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: Text(_guardando
                    ? 'Guardando…'
                    : (_planId != null && c != null && c.planId == null ? 'Activar plan' : 'Guardar')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.cliente});
  final Cliente cliente;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = cliente;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Avatar(fotoUrl: c.fotoUrl, iniciales: c.iniciales, radio: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.nombre, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(c.email, style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
              if (c.fechaFin != null && c.planId != null)
                Text('Vence: ${Fechas.corta(c.fechaFin!)}', style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
            ]),
          ),
          EstadoChip(c.estado),
        ]),
      ),
    );
  }
}
