import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/fechas.dart';
import '../../../data/models/cliente.dart';
import '../../../data/models/frecuencia.dart';
import '../../shared/widgets/async_body.dart';
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
      await ref.read(adminRepositoryProvider).guardarCliente(Cliente(
            id: widget.cliente?.id,
            nombre: _nombre.text.trim(),
            email: _email.text.trim(),
            telefono: _telefono.text.trim(),
            planId: _planId,
            frecuencia: _frecuencia,
            diasPersonalizados: _diasPersonalizados,
            fechaInicio: _inicio,
            activo: widget.cliente?.activo ?? true,
          ));
      if (mounted) Navigator.pop(context);
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
        content: Text('${widget.cliente!.nombre}\nTambién se borrará su historial de pagos.'),
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
    final planes = ref.watch(planesProvider).value ?? [];
    final disponibles = planes.where((p) => p.activo || p.id == _planId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar cliente' : 'Nuevo cliente'),
        actions: [if (_editando) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _eliminar)],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Correo de Google', helperText: 'Con este correo el cliente entrará a la app'),
              validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              value: disponibles.any((p) => p.id == _planId) ? _planId : null,
              decoration: const InputDecoration(labelText: 'Plan'),
              items: disponibles
                  .map((p) =>
                      DropdownMenuItem(value: p.id, child: Text('${p.nombre} · \$${p.precio.toStringAsFixed(0)}')))
                  .toList(),
              onChanged: (id) => setState(() {
                _planId = id;
                if (!_editando) _frecuencia = disponibles.firstWhere((e) => e.id == id).frecuenciaSugerida;
              }),
              validator: (v) => v == null ? 'Selecciona un plan' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Frecuencia>(
              value: _frecuencia,
              decoration: const InputDecoration(labelText: 'Frecuencia de pago / recordatorio'),
              items: Frecuencia.values.map((f) => DropdownMenuItem(value: f, child: Text(f.etiqueta))).toList(),
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
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('Fecha de inscripción / último pago'),
              subtitle: Text(Fechas.formato(_inicio)),
              onTap: () async {
                final d = await showDatePicker(
                    context: context, initialDate: _inicio, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (d != null) setState(() => _inicio = Fechas.soloFecha(d));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy),
              title: const Text('Vence (último día cubierto)'),
              subtitle: Text(Fechas.formato(_finCalculado)),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: _guardando ? null : _guardar,
              child: Text(_guardando ? 'Guardando…' : 'Guardar'),
            ),
            if (_editando) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: const Icon(Icons.payments),
                label: const Text('Registrar pago'),
                onPressed: () async {
                  final pagado = await mostrarRegistrarPago(context, widget.cliente!);
                  if (pagado && context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
