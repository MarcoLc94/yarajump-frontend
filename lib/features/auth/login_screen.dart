import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../shared/widgets/async_body.dart';
import '../shared/widgets/ui.dart';
import 'google_web/google_web_button.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _cargando = false;
  bool _verPassword = false;

  // Solo web: el botón de Google avisa por authenticationEvents en vez de devolver la cuenta.
  Future<void>? _googleWebListo;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleWebSub;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && AuthRepository.googleWebDisponible) {
      _googleWebListo = ref.read(authRepositoryProvider).initGoogle().then((_) {
        _googleWebSub = GoogleSignIn.instance.authenticationEvents.listen(_onGoogleWeb, onError: _onGoogleWebError);
      });
    }
  }

  @override
  void dispose() {
    _googleWebSub?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onGoogleWeb(GoogleSignInAuthenticationEvent e) {
    if (e is! GoogleSignInAuthenticationEventSignIn || _cargando || !mounted) return;
    _entrar(() => ref.read(sessionProvider.notifier).loginGoogleCuenta(e.user));
  }

  void _onGoogleWebError(Object e) {
    if (!mounted) return;
    if (e is GoogleSignInException) {
      if (e.code != GoogleSignInExceptionCode.canceled) mostrarError(context, e.description ?? e.code.name);
    } else {
      mostrarError(context, e);
    }
  }

  Future<void> _entrar(Future<void> Function() login) async {
    FocusScope.of(context).unfocus();
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

  void _entrarConCorreo() {
    if (!_form.currentState!.validate()) return;
    _entrar(() => ref.read(sessionProvider.notifier).login(_email.text, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final session = ref.read(sessionProvider.notifier);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          GradientHeader(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
                child: const AppLogo(size: 96),
              ),
              const SizedBox(height: 16),
              Text(AppConstants.nombreNegocio,
                  style: t.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Tu plan, tus horarios y tu progreso',
                  style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Iniciar sesión', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline)),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Escribe tu correo' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: !_verPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _entrarConCorreo(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _verPassword = !_verPassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Escribe tu contraseña' : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _cargando ? null : _entrarConCorreo,
                    child: _cargando
                        ? const SizedBox(
                            width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Entrar'),
                  ),
                  if (!kIsWeb || AuthRepository.googleWebDisponible) ...[
                    const SizedBox(height: 20),
                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o', style: t.bodyMedium?.copyWith(color: AppColors.textoSuave)),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 20),
                    if (kIsWeb)
                      _botonGoogleWeb(t)
                    else
                      OutlinedButton.icon(
                        onPressed: _cargando ? null : () => _entrar(session.loginGoogle),
                        icon: const _GoogleG(),
                        label: const Text('Continuar con Google'),
                      ),
                  ],
                  const SizedBox(height: 28),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('¿No tienes cuenta?', style: t.bodyMedium),
                    TextButton(
                      onPressed: _cargando
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('Regístrate', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  /// En web Google exige su propio botón (no se puede abrir el login desde uno nuestro).
  Widget _botonGoogleWeb(TextTheme t) => FutureBuilder<void>(
        future: _googleWebListo,
        builder: (context, snap) {
          if (snap.hasError) {
            return Text('No se pudo cargar el acceso con Google',
                textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: AppColors.textoSuave));
          }
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(
                height: 44, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
          }
          return LayoutBuilder(
            builder: (context, c) => Center(
              child: IgnorePointer(
                ignoring: _cargando,
                child: Opacity(opacity: _cargando ? 0.5 : 1, child: googleWebButton(width: c.maxWidth)),
              ),
            ),
          );
        },
      );
}

/// "G" de Google sin depender de un asset.
class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (r) => const SweepGradient(
          colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335), Color(0xFF4285F4)],
        ).createShader(r),
        child: const Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
      );
}
