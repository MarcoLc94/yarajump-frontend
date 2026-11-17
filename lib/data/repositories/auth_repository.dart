import 'package:google_sign_in/google_sign_in.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/cliente.dart';

class Session {
  const Session({required this.user, this.cliente});
  final AppUser user;
  final Cliente? cliente;
}

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  bool _googleIniciado = false;

  Future<void> _initGoogle() async {
    if (_googleIniciado) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConstants.googleServerClientId.isEmpty ? null : AppConstants.googleServerClientId,
    );
    _googleIniciado = true;
  }

  /// Login con Google en un clic: obtiene el ID token y lo cambia por el JWT de la API.
  Future<Session> loginGoogle() async {
    await _initGoogle();
    final cuenta = await GoogleSignIn.instance.authenticate();
    final idToken = cuenta.authentication.idToken;
    if (idToken == null) {
      throw ApiException(null, 'Google no devolvió el token. Revisa GOOGLE_SERVER_CLIENT_ID.');
    }
    final r = await _api.post('/auth/google', {'idToken': idToken}) as Map<String, dynamic>;
    await _api.saveToken(r['token'] as String);
    return me();
  }

  /// Entra con correo y contraseña.
  Future<Session> login(String email, String password) async {
    final r = await _api.post('/auth/login', {'email': email.trim().toLowerCase(), 'password': password});
    await _api.saveToken((r as Map<String, dynamic>)['token'] as String);
    return me();
  }

  /// Crea una cuenta nueva (rol usuario, sin plan) y entra.
  Future<Session> registrar({required String nombre, required String email, required String password}) async {
    final r = await _api.post('/auth/register', {
      'nombre': nombre.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });
    await _api.saveToken((r as Map<String, dynamic>)['token'] as String);
    return me();
  }

  /// Restaura la sesión guardada; null si no hay token.
  Future<Session?> restaurar() async {
    if (await _api.loadToken() == null) return null;
    try {
      return await me();
    } on ApiException catch (e) {
      if (e.status == 401) return null;
      rethrow;
    }
  }

  Future<Session> me() async {
    final r = await _api.get('/me') as Map<String, dynamic>;
    final c = r['cliente'];
    return Session(
      user: AppUser.fromJson(r['user'] as Map<String, dynamic>),
      cliente: c == null ? null : Cliente.fromJson(c as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    try {
      await _api.put('/me/fcm-token', {'token': null}); // deja de recibir push en este equipo
    } catch (_) {}
    await _api.clearToken();
    if (_googleIniciado) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }
}
