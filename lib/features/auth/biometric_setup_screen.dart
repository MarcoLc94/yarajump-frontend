import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Se muestra una sola vez, después del primer login.
class BiometricSetupScreen extends ConsumerWidget {
  const BiometricSetupScreen({super.key});

  Future<void> _decidir(WidgetRef ref, BuildContext context, bool activar) async {
    final bio = ref.read(biometricServiceProvider);
    if (activar) {
      final ok = await bio.autenticar(motivo: 'Confirma tu huella para activarla');
      if (!ok) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No se pudo verificar la huella')));
        }
        return;
      }
    }
    await bio.guardarPreferencia(habilitada: activar);
    ref.read(biometricUnlockedProvider.notifier).state = true;
    ref.invalidate(biometricStateProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.fingerprint, size: 96, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text('¿Entrar con tu huella?',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              const Text('La próxima vez solo pon tu huella para entrar, sin escribir nada.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () => _decidir(ref, context, true),
                child: const Text('Activar huella'),
              ),
              TextButton(onPressed: () => _decidir(ref, context, false), child: const Text('Ahora no')),
            ],
          ),
        ),
      ),
    );
  }
}
