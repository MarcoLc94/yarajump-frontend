import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../data/repositories/perfil_repository.dart';

enum MotivoWhatsapp { pago, activar, comprobante, bloqueado }

class WhatsappService {
  WhatsappService(this._perfil);
  final PerfilRepository _perfil;
  String? _numero;

  Future<String> _numeroAdmin() async {
    if (_numero != null) return _numero!;
    try {
      final n = (await _perfil.config())['whatsappAdmin'] as String?;
      if (n != null && n.isNotEmpty) return _numero = n;
    } catch (_) {}
    return AppConstants.whatsappAdminDefault;
  }

  /// Abre WhatsApp con el chat de la admin y un mensaje ya escrito.
  Future<bool> abrirChatAdmin({
    String? nombreCliente,
    MotivoWhatsapp motivo = MotivoWhatsapp.pago,
    String? email,
  }) async {
    final numero = await _numeroAdmin();
    final quien = (nombreCliente == null || nombreCliente.isEmpty) ? 'cliente' : nombreCliente;
    final texto = switch (motivo) {
      MotivoWhatsapp.pago => 'Hola Yara Jump 👋, soy $quien. Quiero regularizar el pago de mi plan.',
      MotivoWhatsapp.activar => 'Hola Yara Jump 👋, soy $quien. Ya me registré en la app y quiero activar mi plan.',
      MotivoWhatsapp.comprobante => 'Hola Yara Jump 👋, soy $quien. Te envío mi comprobante de pago.',
      MotivoWhatsapp.bloqueado => 'Hola Yara Jump 👋, soy $quien${email == null ? '' : ' ($email)'}. '
          'No puedo ver la información de mi app porque me aparece que mi acceso fue bloqueado '
          'por razones de seguridad. ¿Me podrías ayudar?',
    };
    // api.whatsapp.com directo: la redirección de wa.me rompe los emojis (👋 llegaba como "�").
    final uri = Uri.https('api.whatsapp.com', '/send', {'phone': numero, 'text': texto});
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
