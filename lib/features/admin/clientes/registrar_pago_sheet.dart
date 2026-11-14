import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/fechas.dart';
import '../../../data/models/cliente.dart';
import '../../shared/widgets/async_body.dart';

/// Devuelve true si se registró el pago.
Future<bool> mostrarRegistrarPago(BuildContext context, Cliente cliente) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RegistrarPagoSheet(cliente: cliente),
    ) ??
    false;

class _RegistrarPagoSheet extends ConsumerStatefulWidget {
  const _RegistrarPagoSheet({required this.cliente});
  final Cliente cliente;
  @override
  ConsumerState<_RegistrarPagoSheet> createState() => _RegistrarPagoSheetState();
}

class _RegistrarPagoSheetState extends ConsumerState<_RegistrarPagoSheet> {
  late final _monto = TextEditingController(text: widget.cliente.precio?.toStringAsFixed(0) ?? '');
  DateTime _fecha = Fechas.hoy();
  bool _guardando = false;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final monto = double.tryParse(_monto.text);
    if (monto == null) return;
    setState(() => _guardando = true);
    try {
      final c = await ref
          .read(adminRepositoryProvider)
          .registrarPago(widget.cliente.id!, monto: monto, fechaPago: _fecha);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(SnackBar(content: Text('Pago registrado ✅ Vigente hasta ${Fechas.formato(c.fechaFin!)}')));
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        mostrarError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cliente;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Registrar pago · ${c.nombre}', style: Theme.of(context).textTheme.titleMedium),
          if (c.fechaFin != null) Text('Vence actualmente: ${Fechas.formato(c.fechaFin!)}'),
          const SizedBox(height: 16),
          TextField(
            controller: _monto,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: const Text('Fecha de pago'),
            subtitle: Text(Fechas.formato(_fecha)),
            onTap: () async {
              final d = await showDatePicker(
                  context: context, initialDate: _fecha, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) setState(() => _fecha = Fechas.soloFecha(d));
            },
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: Text(_guardando ? 'Guardando…' : 'Confirmar pago'),
          ),
        ],
      ),
    );
  }
}
