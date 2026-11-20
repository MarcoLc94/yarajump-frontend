import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/admin_home_screen.dart';
import 'features/auth/biometric_lock_screen.dart';
import 'features/auth/biometric_setup_screen.dart';
import 'features/auth/bloqueado_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/no_registrado_screen.dart';
import 'features/usuario/usuario_home_screen.dart';

class YaraJumpingApp extends StatelessWidget {
  const YaraJumpingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.nombreNegocio,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

/// Decide qué pantalla mostrar según la sesión, la huella y el rol.
/// Revisa el rol al volver a la app y cada 30 s: si soporte la hace admin, cambia sola.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});
  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _revisar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _revisar();
  }

  void _revisar() => ref.read(sessionProvider.notifier).refrescarSiCambio();

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final bio = ref.watch(biometricStateProvider);

    if (session.isLoading || bio.isLoading) return const _Cargando();
    if (session.hasError) {
      return _Error(session.error!, onRetry: () => ref.invalidate(sessionProvider));
    }

    final s = session.value;
    if (s == null) return const LoginScreen();

    // Bloqueado por seguridad: no ve nada más, ni siquiera se le pide la huella.
    if (s.user.bloqueado) return const BloqueadoScreen();

    final bioState = bio.value!;
    // 1) Sesión guardada + huella activada → pedir huella
    if (bioState.habilitada && !ref.watch(biometricUnlockedProvider)) {
      return const BiometricLockScreen();
    }
    // 2) Primera vez: preguntar si quiere activar la huella
    if (!bioState.preguntada && bioState.disponible) {
      return const BiometricSetupScreen();
    }
    // 3) Home según el rol
    if (s.user.esAdmin) return const AdminHomeScreen();
    if (s.user.clienteId == null) return const NoRegistradoScreen();
    return const UsuarioHomeScreen();
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _Error extends StatelessWidget {
  const _Error(this.error, {required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off, size: 64),
              const SizedBox(height: 16),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            ]),
          ),
        ),
      );
}
