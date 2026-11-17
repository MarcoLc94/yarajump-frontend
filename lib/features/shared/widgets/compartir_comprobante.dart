import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/whatsapp_service.dart';

/// Botón "Compartir comprobante": el cliente elige la foto/captura de su pago y la
/// comparte (WhatsApp con Yara). Funciona en Android y en la app web.
class CompartirComprobanteButton extends ConsumerWidget {
  const CompartirComprobanteButton({super.key, this.nombreCliente});
  final String? nombreCliente;

  @override
  Widget build(BuildContext context, WidgetRef ref) => OutlinedButton.icon(
        onPressed: () => _elegir(context, ref),
        icon: const Icon(Icons.ios_share),
        label: const Text('Compartir comprobante'),
      );

  Future<void> _elegir(BuildContext context, WidgetRef ref) async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir captura o foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tomar foto del ticket'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ]),
      ),
    );
    if (origen == null) return;
    final img = await ImagePicker().pickImage(source: origen, maxWidth: 1600, imageQuality: 85);
    if (img == null) return;

    // Se leen los bytes antes de mostrar la vista previa: en Safari compartir solo
    // funciona justo después de un toque, así que al tocar "Compartir" ya no hay que esperar nada.
    final bytes = await img.readAsBytes();
    final nombre = img.name.isNotEmpty ? img.name : 'comprobante.jpg';
    final archivo = XFile.fromData(bytes, name: nombre, mimeType: img.mimeType ?? 'image/jpeg');
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VistaPrevia(bytes: bytes, archivo: archivo, nombreCliente: nombreCliente),
    );
  }
}

class _VistaPrevia extends ConsumerWidget {
  const _VistaPrevia({required this.bytes, required this.archivo, this.nombreCliente});
  final Uint8List bytes;
  final XFile archivo;
  final String? nombreCliente;

  Future<void> _compartir(BuildContext context, WidgetRef ref) async {
    final quien = (nombreCliente == null || nombreCliente!.isEmpty) ? '' : ' – $nombreCliente';
    try {
      final r = await SharePlus.instance.share(ShareParams(
        files: [archivo],
        text: 'Comprobante de pago$quien',
        downloadFallbackEnabled: false, // en web: mejor abrir WhatsApp que descargar el archivo
      ));
      if (r.status != ShareResultStatus.dismissed && context.mounted) Navigator.pop(context);
    } catch (_) {
      // El navegador no permite compartir imágenes (p. ej. Chrome de escritorio).
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tu navegador no permite compartir imágenes. Te abrimos WhatsApp: adjunta ahí tu comprobante.'),
        duration: Duration(seconds: 6),
      ));
      await ref
          .read(whatsappServiceProvider)
          .abrirChatAdmin(nombreCliente: nombreCliente, motivo: MotivoWhatsapp.comprobante);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Tu comprobante', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 12),
          Text('Toca Compartir, elige WhatsApp y el chat de Yara Jump.',
              textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: AppColors.textoSuave)),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.whatsapp),
            onPressed: () => _compartir(context, ref),
            icon: const Icon(Icons.share),
            label: const Text('Compartir'),
          ),
        ]),
      ),
    );
  }
}
