import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../services/notification_service.dart';
import 'mi_perfil/mi_perfil_screen.dart';
import 'mi_plan/mi_plan_screen.dart';
import 'mi_progreso/mi_progreso_screen.dart';

class UsuarioHomeScreen extends ConsumerStatefulWidget {
  const UsuarioHomeScreen({super.key});
  @override
  ConsumerState<UsuarioHomeScreen> createState() => _UsuarioHomeScreenState();
}

class _UsuarioHomeScreenState extends ConsumerState<UsuarioHomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Manda el token de push a la API para recibir los avisos de vencimiento.
    final perfil = ref.read(perfilRepositoryProvider);
    NotificationService.instance.registrarToken(perfil.registrarTokenPush);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: const [MiPlanScreen(), MiProgresoScreen(), MiPerfilScreen()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          // Datos frescos al cambiar de pestaña (la admin pudo activar el plan o registrar medidas)
          ref.invalidate(miClienteProvider);
          ref.invalidate(misComunicadosProvider);
          ref.invalidate(misCuentasPagoProvider);
          ref.invalidate(miProgresoProvider);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.card_membership_outlined), selectedIcon: Icon(Icons.card_membership), label: 'Mi plan'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progreso'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
