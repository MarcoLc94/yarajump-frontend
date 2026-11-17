import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

class BiometricState {
  const BiometricState({required this.disponible, required this.habilitada, required this.preguntada});
  final bool disponible; // el dispositivo tiene huella o Face ID configurado
  final bool habilitada; // el usuario la activó en la app
  final bool preguntada; // ya se le mostró la pantalla para activarla
}

class BiometricService {
  final _auth = LocalAuthentication();

  Future<bool> disponible() async {
    if (kIsWeb) return false; // local_auth no tiene implementación web
    try {
      final soporta = await _auth.isDeviceSupported();
      final puede = await _auth.canCheckBiometrics;
      final lista = await _auth.getAvailableBiometrics();
      return soporta && puede && lista.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<BiometricState> estado() async {
    final prefs = await SharedPreferences.getInstance();
    return BiometricState(
      disponible: await disponible(),
      habilitada: prefs.getBool(AppConstants.prefBiometriaHabilitada) ?? false,
      preguntada: prefs.getBool(AppConstants.prefBiometriaPreguntada) ?? false,
    );
  }

  Future<bool> autenticar({String motivo = 'Usa tu huella para entrar a Yara Jump'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> guardarPreferencia({required bool habilitada}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefBiometriaHabilitada, habilitada);
    await prefs.setBool(AppConstants.prefBiometriaPreguntada, true);
  }

  /// Se usa al cerrar sesión, para que el siguiente usuario vea de nuevo la pregunta.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefBiometriaHabilitada);
    await prefs.remove(AppConstants.prefBiometriaPreguntada);
  }
}
