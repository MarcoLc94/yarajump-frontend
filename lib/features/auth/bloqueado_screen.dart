import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../services/whatsapp_service.dart';

/// Se muestra cuando la admin bloqueó el acceso de esta cuenta por seguridad.
/// La API ya le niega todos los datos; aquí solo puede pedir ayuda o cerrar sesión.
class BloqueadoScreen extends ConsumerWidget {
  const BloqueadoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final user = ref.watch(sessionProvider).value?.user;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(
                  'Por razones de seguridad se te ha denegado el acceso a esta información.',
                  textAlign: TextAlign.center,
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.3),
                ),
                const SizedBox(height: 28),
                const Center(child: _IlustracionError()),
                const SizedBox(height: 28),
                Text(
                  'Para más información o ayuda contacta con Yara Jump.',
                  textAlign: TextAlign.center,
                  style: t.bodyLarge?.copyWith(color: AppColors.textoSuave),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.whatsapp),
                  icon: const Icon(Icons.chat),
                  label: const Text('Contactar a Yara Jump por WhatsApp'),
                  onPressed: () async {
                    final ok = await ref.read(whatsappServiceProvider).abrirChatAdmin(
                          nombreCliente: user?.nombre,
                          email: user?.email,
                          motivo: MotivoWhatsapp.bloqueado,
                        );
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.read(sessionProvider.notifier).logout(),
                  child: const Text('Cerrar sesión'),
                ),
                if (user != null)
                  Text(user.email, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Escudo con una X sobre círculos rojos (la "imagen de error").
class _IlustracionError extends StatelessWidget {
  const _IlustracionError();

  @override
  Widget build(BuildContext context) {
    Widget anillo(double d, double alpha) => Container(
          width: d,
          height: d,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.expirado.withValues(alpha: alpha)),
        );
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(alignment: Alignment.center, children: [
        anillo(200, 0.06),
        anillo(150, 0.10),
        anillo(104, 0.16),
        const Icon(Icons.shield_rounded, size: 84, color: AppColors.expirado),
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Icon(Icons.close_rounded, size: 40, color: Colors.white),
        ),
        Positioned(
          right: 34,
          top: 30,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.lock_rounded, size: 22, color: AppColors.expirado),
          ),
        ),
      ]),
    );
  }
}
