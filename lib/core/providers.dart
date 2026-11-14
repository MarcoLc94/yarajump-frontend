import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/cliente.dart';
import '../data/models/plan.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/perfil_repository.dart';
import '../services/biometric_service.dart';
import '../services/whatsapp_service.dart';
import 'api/api_client.dart';
import 'constants/app_constants.dart';

// ---------------- API y repositorios ----------------
final apiClientProvider = Provider((_) => ApiClient(baseUrl: AppConstants.apiUrl));
final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
final adminRepositoryProvider = Provider((ref) => AdminRepository(ref.watch(apiClientProvider)));
final perfilRepositoryProvider = Provider((ref) => PerfilRepository(ref.watch(apiClientProvider)));

// ---------------- Servicios ----------------
final biometricServiceProvider = Provider((_) => BiometricService());
final whatsappServiceProvider = Provider((ref) => WhatsappService(ref.watch(perfilRepositoryProvider)));

// ---------------- Sesión ----------------
class SessionNotifier extends AsyncNotifier<Session?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<Session?> build() {
    // Si la API responde 401 en cualquier pantalla, se cierra la sesión.
    ref.read(apiClientProvider).onUnauthorized = () => state = const AsyncData(null);
    return _repo.restaurar();
  }

  Future<void> loginGoogle() async => state = AsyncData(await _repo.loginGoogle());
  Future<void> loginDev(String email) async => state = AsyncData(await _repo.loginDev(email));

  Future<void> refrescar() async {
    final s = await _repo.me();
    state = AsyncData(s);
  }

  Future<void> logout() async {
    await ref.read(biometricServiceProvider).reset();
    await _repo.logout();
    ref.read(biometricUnlockedProvider.notifier).state = false;
    ref.invalidate(biometricStateProvider);
    state = const AsyncData(null);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);

/// Estado de la huella en este dispositivo.
final biometricStateProvider = FutureProvider<BiometricState>(
  (ref) => ref.watch(biometricServiceProvider).estado(),
);

/// Pasa a true cuando el usuario se autentica (huella o login) en esta sesión de la app.
final biometricUnlockedProvider = StateProvider<bool>((_) => false);

// ---------------- Datos (se recargan con ref.invalidate / ref.refresh) ----------------
final planesProvider = FutureProvider<List<Plan>>((ref) => ref.watch(adminRepositoryProvider).planes());

final clientesProvider = FutureProvider<List<Cliente>>((ref) => ref.watch(adminRepositoryProvider).clientes());

final recordatoriosProvider =
    FutureProvider<List<Cliente>>((ref) => ref.watch(adminRepositoryProvider).recordatorios());

/// Mi plan (rol usuario).
final miClienteProvider = FutureProvider<Cliente?>((ref) => ref.watch(perfilRepositoryProvider).miCliente());

/// Invalida todo lo que muestra la admin (después de crear/editar/pagar).
void refrescarAdmin(WidgetRef ref) {
  ref.invalidate(clientesProvider);
  ref.invalidate(recordatoriosProvider);
  ref.invalidate(planesProvider);
}
