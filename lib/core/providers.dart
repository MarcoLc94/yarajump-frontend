import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/models/usuario_bo.dart';
import '../data/models/cliente.dart';
import '../data/models/comunicado.dart';
import '../data/models/cuenta_pago.dart';
import '../data/models/horario.dart';
import '../data/models/medicion.dart';
import '../data/models/plan.dart';
import '../data/models/reporte_pagos.dart';
import 'utils/periodo.dart';
import '../data/models/solicitud.dart';
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
    final api = ref.read(apiClientProvider);
    api.onUnauthorized = () => state = const AsyncData(null);
    // Si la bloquean a mitad de sesión, recarga /me para mostrar la pantalla de bloqueo.
    api.onBloqueado = () => refrescar().ignore();
    // Si le cambiaron el rol, recarga /me para mostrar la pantalla que le toca.
    api.onSinPermiso = () => refrescarSiCambio().ignore();
    return _repo.restaurar();
  }

  Future<void> loginGoogle() async => state = AsyncData(await _repo.loginGoogle());
  Future<void> loginGoogleCuenta(GoogleSignInAccount cuenta) async =>
      state = AsyncData(await _repo.loginGoogleCuenta(cuenta));
  Future<void> login(String email, String password) async => state = AsyncData(await _repo.login(email, password));

  Future<void> registrar({required String nombre, required String email, required String password}) async =>
      state = AsyncData(await _repo.registrar(nombre: nombre, email: email, password: password));

  Future<void> refrescar() async {
    final s = await _repo.me();
    state = AsyncData(s);
  }

  bool _revisando = false;

  /// Vuelve a pedir /me y solo cambia la sesión si cambió el rol, el bloqueo o su ficha de
  /// cliente (así la app pasa sola a la pantalla de admin cuando soporte le cambia el rol).
  Future<void> refrescarSiCambio() async {
    final actual = state.value;
    if (actual == null || _revisando) return;
    _revisando = true;
    try {
      final s = await _repo.me();
      final a = actual.user, b = s.user;
      if (state.value != null && (a.rol != b.rol || a.bloqueado != b.bloqueado || a.clienteId != b.clienteId)) {
        state = AsyncData(s);
      }
    } catch (_) {
      // Sin red o sesión vencida (el 401 ya cierra la sesión por su lado).
    } finally {
      _revisando = false;
    }
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

final horariosProvider = FutureProvider<List<Horario>>((ref) => ref.watch(adminRepositoryProvider).horarios());

/// Progreso de un cliente (vista de admin).
final progresoClienteProvider = FutureProvider.family<List<Medicion>, int>(
  (ref, clienteId) => ref.watch(adminRepositoryProvider).progreso(clienteId),
);

/// Mi progreso (rol usuario).
final miProgresoProvider = FutureProvider<List<Medicion>>((ref) => ref.watch(perfilRepositoryProvider).miProgreso());

final recordatoriosProvider =
    FutureProvider<List<Cliente>>((ref) => ref.watch(adminRepositoryProvider).recordatorios());

final cuentasPagoProvider =
    FutureProvider<List<CuentaPago>>((ref) => ref.watch(adminRepositoryProvider).cuentasPago());

final comunicadosProvider =
    FutureProvider<List<Comunicado>>((ref) => ref.watch(adminRepositoryProvider).comunicados());

/// Datos para pagar (rol usuario).
final misCuentasPagoProvider =
    FutureProvider<List<CuentaPago>>((ref) => ref.watch(perfilRepositoryProvider).misCuentasPago());

/// Avisos de Yara para mí (rol usuario).
final misComunicadosProvider =
    FutureProvider<List<Comunicado>>((ref) => ref.watch(perfilRepositoryProvider).misComunicados());

/// Filtro del módulo de Pagos (por defecto: esta semana).
final periodoPagosProvider = StateProvider<Periodo>((_) => Periodo.de(TipoPeriodo.semana));

final reportePagosProvider = FutureProvider<ReportePagos>(
  (ref) => ref.watch(adminRepositoryProvider).reportePagos(ref.watch(periodoPagosProvider)),
);

/// Solicitudes de plan por confirmar (admin).
final solicitudesProvider =
    FutureProvider<List<Solicitud>>((ref) => ref.watch(adminRepositoryProvider).solicitudes());

/// Planes con turnos y lugares libres (rol usuario, "Ver planes").
final planesOfertadosProvider =
    FutureProvider<List<PlanOfertado>>((ref) => ref.watch(perfilRepositoryProvider).planesOfertados());

/// Mi solicitud de plan pendiente (rol usuario).
final miSolicitudProvider = FutureProvider<Solicitud?>((ref) => ref.watch(perfilRepositoryProvider).miSolicitud());

/// Mi plan (rol usuario).
final miClienteProvider = FutureProvider<Cliente?>((ref) => ref.watch(perfilRepositoryProvider).miCliente());

/// Invalida todo lo que muestra la admin (después de crear/editar/pagar).
// ---------- Backoffice (support) ----------
final usuariosBOProvider = FutureProvider<List<UsuarioBO>>((ref) => ref.watch(adminRepositoryProvider).usuariosBO());
final ajustesProvider = FutureProvider<Map<String, String>>((ref) => ref.watch(adminRepositoryProvider).ajustes());
final accesosBOProvider =
    FutureProvider.family<List<Acceso>, int>((ref, id) => ref.watch(adminRepositoryProvider).accesosBO(id));

void refrescarAdmin(WidgetRef ref) {
  ref.invalidate(clientesProvider);
  ref.invalidate(recordatoriosProvider);
  ref.invalidate(planesProvider);
  ref.invalidate(horariosProvider);
  ref.invalidate(cuentasPagoProvider);
  ref.invalidate(comunicadosProvider);
  ref.invalidate(solicitudesProvider);
  ref.invalidate(reportePagosProvider);
  ref.invalidate(usuariosBOProvider);
}
