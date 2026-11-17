import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/whatsapp_service.dart';

export '../../../services/whatsapp_service.dart' show MotivoWhatsapp;

class WhatsappButton extends ConsumerWidget {
  const WhatsappButton({
    super.key,
    this.nombreCliente,
    this.texto = 'Comunicarme con Yara Jump',
    this.motivo = MotivoWhatsapp.pago,
  });
  final String? nombreCliente;
  final String texto;
  final MotivoWhatsapp motivo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(backgroundColor: AppColors.whatsapp),
      icon: const Icon(Icons.chat),
      label: Text(texto),
      onPressed: () async {
        final ok =
            await ref.read(whatsappServiceProvider).abrirChatAdmin(nombreCliente: nombreCliente, motivo: motivo);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
        }
      },
    );
  }
}
