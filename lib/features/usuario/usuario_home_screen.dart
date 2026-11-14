import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../services/notification_service.dart';
import 'mi_perfil/mi_perfil_screen.dart';
import 'mi_plan/mi_plan_screen.dart';

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
      body: IndexedStack(index: _tab, children: const [MiPlanScreen(), MiPerfilScreen()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.card_membership), label: 'Mi plan'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Mi perfil'),
        ],
      ),
    );
  }
}
