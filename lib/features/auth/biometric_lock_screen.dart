import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';

/// Pide la huella al abrir la app cuando ya hay una sesión guardada.
class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});
  @override
  ConsumerState<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  int _intentos = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _desbloquear());
  }

  Future<void> _desbloquear() async {
    final ok = await ref.read(biometricServiceProvider).autenticar();
    if (ok) {
      ref.read(biometricUnlockedProvider.notifier).state = true;
    } else if (mounted) {
      setState(() => _intentos++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppConstants.nombreNegocio, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 32),
              IconButton(
                iconSize: 96,
                icon: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary),
                onPressed: _desbloquear,
              ),
              const Text('Toca para usar tu huella'),
              if (_intentos >= 3) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => ref.read(sessionProvider.notifier).logout(),
                  child: const Text('Entrar con Google de nuevo'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
