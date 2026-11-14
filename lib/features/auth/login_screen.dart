import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../shared/widgets/async_body.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _cargando = false;
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _entrar(Future<void> Function() login) async {
    setState(() => _cargando = true);
    try {
      await login();
      // Acaba de iniciar sesión: no hace falta pedirle la huella ahora.
      ref.read(biometricUnlockedProvider.notifier).state = true;
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) mostrarError(context, e.description ?? e.code.name);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final session = ref.read(sessionProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TODO: reemplazar por el logo (assets/images/logo.png)
                Icon(Icons.sports_gymnastics, size: 96, color: t.colorScheme.primary),
                const SizedBox(height: 16),
                Text(AppConstants.nombreNegocio, textAlign: TextAlign.center, style: t.textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Consulta tu plan y recibe avisos de pago', textAlign: TextAlign.center),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: _cargando ? null : () => _entrar(session.loginGoogle),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: _cargando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.login),
                  label: const Text('Continuar con Google'),
                ),
                if (AppConstants.devAuth) ...[
                  const SizedBox(height: 40),
                  const Divider(),
                  Text('Modo pruebas (DEV_AUTH)', style: t.textTheme.labelMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _cargando ? null : () => _entrar(() => session.loginDev(_email.text.trim())),
                    child: const Text('Entrar con correo (pruebas)'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
