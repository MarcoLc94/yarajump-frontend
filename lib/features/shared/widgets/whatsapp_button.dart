import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';

class WhatsappButton extends ConsumerWidget {
  const WhatsappButton({super.key, this.nombreCliente, this.texto = 'Comunicarme con Yara Jumping'});
  final String? nombreCliente;
  final String texto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.whatsapp,
        minimumSize: const Size.fromHeight(52),
      ),
      icon: const Icon(Icons.chat),
      label: Text(texto),
      onPressed: () async {
        final ok = await ref.read(whatsappServiceProvider).abrirChatAdmin(nombreCliente: nombreCliente);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
        }
      },
    );
  }
}
