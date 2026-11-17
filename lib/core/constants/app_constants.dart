class AppConstants {
  AppConstants._();

  static const nombreNegocio = 'Yara Jump';

  /// URL de la API en Go. Se pasa con --dart-define-from-file=env/dev.json
  /// - Emulador Android → http://10.0.2.2:8080 (es el localhost de tu PC)
  /// - Celular físico   → http://<IP-de-tu-PC>:8080  o la URL de Railway
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

  /// "Web client ID" de Google Cloud. Es necesario para que Google Sign-In devuelva un ID token.
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Valor de respaldo si la API no devuelve el número (GET /config).
  static const whatsappAdminDefault = '52XXXXXXXXXX';

  // Llaves de SharedPreferences
  static const prefBiometriaHabilitada = 'biometria_habilitada';
  static const prefBiometriaPreguntada = 'biometria_preguntada';
}
