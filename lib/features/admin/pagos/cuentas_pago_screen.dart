import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cuenta_pago.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/cuenta_pago_visual.dart';
import '../../shared/widgets/ui.dart';

/// La admin configura las tarjetas/CLABE que ven sus clientes en "Datos para pagar".
class CuentasPagoScreen extends ConsumerWidget {
  const CuentasPagoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datos de pago')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-cuentas',
        onPressed: () => editarCuentaPago(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Agregar cuenta'),
      ),
      body: AsyncBody(
        value: ref.watch(cuentasPagoProvider),
        onRetry: () => ref.invalidate(cuentasPagoProvider),
        data: (lista) => lista.isEmpty
            ? EmptyState(
                icono: Icons.credit_card,
                titulo: 'Aún no hay datos de pago',
                mensaje: 'Agrega una tarjeta o CLABE y tus clientes la verán en "Mi plan" para pagarte.',
                accion: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(220, 52)),
                  onPressed: () => editarCuentaPago(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar cuenta'),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  Text('Toca una cuenta para editarla.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textoSuave)),
                  const SizedBox(height: 12),
                  for (final c in lista) ...[
                    GestureDetector(
                      onTap: () => editarCuentaPago(context, ref, c),
                      child: Opacity(opacity: c.activo ? 1 : 0.45, child: CuentaPagoVisual(cuenta: c, copiable: false)),
                    ),
                    if (!c.activo)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('Oculta para los clientes', style: TextStyle(color: AppColors.textoSuave)),
                      ),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
      ),
    );
  }
}

Future<void> editarCuentaPago(BuildContext context, WidgetRef ref, [CuentaPago? cuenta]) async {
  final res = await showModalBottomSheet<({CuentaPago? guardar, bool eliminar})>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CuentaSheet(cuenta: cuenta),
  );
  if (res == null) return;
  final repo = ref.read(adminRepositoryProvider);
  try {
    if (res.eliminar) {
      await repo.eliminarCuentaPago(cuenta!.id!);
    } else {
      await repo.guardarCuentaPago(res.guardar!);
    }
    ref.invalidate(cuentasPagoProvider);
  } catch (e) {
    if (context.mounted) mostrarError(context, e);
  }
}

class _CuentaSheet extends StatefulWidget {
  const _CuentaSheet({this.cuenta});
  final CuentaPago? cuenta;
  @override
  State<_CuentaSheet> createState() => _CuentaSheetState();
}

class _CuentaSheetState extends State<_CuentaSheet> {
  late TipoCuenta _tipo = widget.cuenta?.tipo ?? TipoCuenta.tarjeta;
  late final _numero = TextEditingController(text: widget.cuenta?.numeroFormateado);
  late final _banco = TextEditingController(text: widget.cuenta?.banco);
  late final _titular = TextEditingController(text: widget.cuenta?.titular);
  late bool _activo = widget.cuenta?.activo ?? true;
  String? _error;

  String get _digitos => _numero.text.replaceAll(RegExp(r'\D'), '');

  CuentaPago get _cuenta => CuentaPago(
        id: widget.cuenta?.id,
        tipo: _tipo,
        numero: _digitos,
        banco: _banco.text.trim(),
        titular: _titular.text.trim(),
        activo: _activo,
      );

  @override
  void initState() {
    super.initState();
    for (final c in [_numero, _banco, _titular]) {
      c.addListener(() => setState(() {})); // vista previa en vivo
    }
  }

  @override
  void dispose() {
    _numero.dispose();
    _banco.dispose();
    _titular.dispose();
    super.dispose();
  }

  void _cambiarTipo(TipoCuenta t) => setState(() {
        _tipo = t;
        _error = null;
        final d = _digitos.length > t.digitos ? _digitos.substring(0, t.digitos) : _digitos;
        _numero.text = CuentaPago.formatear(t, d);
      });

  void _guardar() {
    final error = CuentaPago.validar(_tipo, _digitos);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, (guardar: _cuenta, eliminar: false));
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar esta cuenta?'),
        content: const Text('Tus clientes dejarán de verla. Si solo quieres ocultarla un tiempo, desactívala.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context, (guardar: null, eliminar: true));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final esTarjeta = _tipo == TipoCuenta.tarjeta;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.cuenta == null ? 'Nueva cuenta' : 'Editar cuenta',
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SegmentedButton<TipoCuenta>(
            segments: const [
              ButtonSegment(value: TipoCuenta.tarjeta, label: Text('Tarjeta'), icon: Icon(Icons.credit_card)),
              ButtonSegment(value: TipoCuenta.clabe, label: Text('CLABE'), icon: Icon(Icons.account_balance)),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => _cambiarTipo(s.first),
          ),
          const SizedBox(height: 16),
          CuentaPagoVisual(cuenta: _cuenta, copiable: false), // así la verán los clientes
          const SizedBox(height: 16),
          TextField(
            controller: _numero,
            keyboardType: TextInputType.number,
            inputFormatters: [_FormatoNumero(_tipo)],
            decoration: InputDecoration(
              labelText: esTarjeta ? 'Número de tarjeta (16 dígitos)' : 'CLABE (18 dígitos)',
              prefixIcon: Icon(esTarjeta ? Icons.credit_card : Icons.account_balance),
              errorText: _error,
              counterText: '${_digitos.length}/${_tipo.digitos}',
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _banco,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Banco o app (opcional)',
              hintText: 'Ej. BBVA, Mercado Pago, Nu',
              prefixIcon: Icon(Icons.store_outlined),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titular,
            textCapitalization: TextCapitalization.words,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Nombre del titular (opcional)',
              prefixIcon: Icon(Icons.person_outline),
              counterText: '',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Visible para los clientes'),
            value: _activo,
            onChanged: (v) => setState(() => _activo = v),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _guardar, child: const Text('Guardar')),
          if (widget.cuenta != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.expirado),
              onPressed: _eliminar,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar cuenta'),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Deja solo dígitos (máximo 16 o 18) y los agrupa mientras se escribe.
class _FormatoNumero extends TextInputFormatter {
  _FormatoNumero(this.tipo);
  final TipoCuenta tipo;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > tipo.digitos) d = d.substring(0, tipo.digitos);
    final texto = CuentaPago.formatear(tipo, d);
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}
