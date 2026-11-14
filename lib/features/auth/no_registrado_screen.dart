import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../shared/widgets/async_body.dart';
import '../shared/widgets/whatsapp_button.dart';

/// El usuario entró con Google, pero la admin no tiene un cliente registrado con ese correo.
class NoRegistradoScreen extends ConsumerWidget {
  const NoRegistradoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value?.user;
    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => ref.read(sessionProvider.notifier).logout(),
        ),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_search, size: 80),
            const SizedBox(height: 16),
            Text('Tu cuenta aún no está registrada',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Pide a Yara Jumping que te registre con el correo:\n${user?.email ?? ''}',
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            WhatsappButton(nombreCliente: user?.nombre, texto: 'Solicitar registro por WhatsApp'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Ya me registraron'),
              onPressed: () async {
                try {
                  await ref.read(sessionProvider.notifier).refrescar();
                } catch (e) {
                  if (context.mounted) mostrarError(context, e);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
