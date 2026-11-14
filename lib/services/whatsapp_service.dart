import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../data/repositories/perfil_repository.dart';

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
  Future<bool> abrirChatAdmin({String? nombreCliente}) async {
    final numero = await _numeroAdmin();
    final texto = 'Hola Yara Jumping 👋, soy ${nombreCliente ?? 'cliente'}. '
        'Quiero regularizar el pago de mi plan.';
    final uri = Uri.parse('https://wa.me/$numero?text=${Uri.encodeComponent(texto)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
