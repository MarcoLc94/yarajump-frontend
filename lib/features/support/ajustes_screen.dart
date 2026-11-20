import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../shared/widgets/async_body.dart';

String soloDigitos(String s) => s.replaceAll(RegExp(r'\D'), '');

/// "5215512345678" → "+52 1 55 1234 5678" (solo para mostrar).
String formatoWhatsapp(String n) {
  final d = soloDigitos(n);
  if (d.isEmpty) return 'Sin configurar';
  if (d.length == 12 && d.startsWith('52')) {
    return '+52 ${d.substring(2, 4)} ${d.substring(4, 8)} ${d.substring(8)}';
  }
  if (d.length == 13 && d.startsWith('521')) {
    return '+52 1 ${d.substring(3, 5)} ${d.substring(5, 9)} ${d.substring(9)}';
  }
  return '+$d';
}

/// Tarjeta del Backoffice que lleva a los ajustes de la app.
class AjustesCard extends ConsumerWidget {
  const AjustesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wa = ref.watch(ajustesProvider).value?['whatsappAdmin'] ?? '';
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ListTile(
        leading: const Icon(Icons.tune, color: AppColors.secundario),
        title: const Text('Ajustes de la app', style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(wa.isEmpty ? 'WhatsApp sin configurar' : 'WhatsApp ${formatoWhatsapp(wa)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AjustesScreen())),
      ),
    );
  }
}

/// WhatsApp al que escriben los clientes (pagar, comprobante, bloqueo) y correo de contacto.
class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Ajustes de la app')),
        body: AsyncBody(
          value: ref.watch(ajustesProvider),
          onRetry: () => ref.invalidate(ajustesProvider),
          data: (a) => _Formulario(key: ValueKey(a), ajustes: a),
        ),
      );
}

class _Formulario extends ConsumerStatefulWidget {
  const _Formulario({super.key, required this.ajustes});
  final Map<String, String> ajustes;
  @override
  ConsumerState<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends ConsumerState<_Formulario> {
  late final _wa = TextEditingController(text: widget.ajustes['whatsappAdmin'] ?? '');
  late final _email = TextEditingController(text: widget.ajustes['contactoEmail'] ?? '');
  bool _guardando = false;

  bool get _cambio =>
      soloDigitos(_wa.text) != soloDigitos(widget.ajustes['whatsappAdmin'] ?? '') ||
      _email.text.trim().toLowerCase() != (widget.ajustes['contactoEmail'] ?? '');

  @override
  void dispose() {
    _wa.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminRepositoryProvider).guardarAjustes({
        'whatsappAdmin': soloDigitos(_wa.text),
        'contactoEmail': _email.text.trim(),
      });
      ref.invalidate(ajustesProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Ajustes guardados. Ya se usan en toda la app.')));
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final digitos = soloDigitos(_wa.text);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('WhatsApp de Yara', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(
        'Aquí llegan los mensajes de los clientes: pagar su plan, mandar comprobante, '
        'activar su plan y los avisos de bloqueo.',
        style: t.bodySmall?.copyWith(color: AppColors.textoSuave),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _wa,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'Número con código de país',
          hintText: '52 55 1234 5678',
          prefixIcon: const Icon(Icons.chat_outlined, color: AppColors.whatsapp),
          helperText: digitos.isEmpty ? 'México: 52 + 10 dígitos' : 'Se verá como ${formatoWhatsapp(digitos)}',
        ),
        onChanged: (_) => setState(() {}),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: digitos.length < 10
              ? null
              : () => launchUrl(Uri.parse('https://api.whatsapp.com/send?phone=$digitos'),
                  mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Probar número'),
        ),
      ),
      const SizedBox(height: 20),
      Text('Correo de contacto', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('Aparece en la política de privacidad y los términos.',
          style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
      const SizedBox(height: 12),
      TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.alternate_email)),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: !_cambio || _guardando ? null : _guardar,
        child: Text(_guardando ? 'Guardando…' : 'Guardar'),
      ),
    ]);
  }
}
