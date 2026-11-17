import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../shared/widgets/ui.dart';
import 'clientes/clientes_list_screen.dart';
import 'horarios/horarios_screen.dart';
import 'planes/planes_screen.dart';
import 'avisos/avisos_screen.dart';
import 'pagos/cuentas_pago_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _tab = 0;
  static const _titulos = ['Clientes', 'Horarios', 'Planes', 'Avisos'];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Column(children: [
        GradientHeader(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: const AppLogo(size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppConstants.nombreNegocio, style: t.bodySmall?.copyWith(color: Colors.white70)),
                Text(_titulos[_tab], style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              ]),
            ),
            IconButton(
              tooltip: 'Datos de pago',
              color: Colors.white,
              icon: const Icon(Icons.credit_card),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CuentasPagoScreen())),
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              color: Colors.white,
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(sessionProvider.notifier).logout(),
            ),
          ]),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: const [ClientesListScreen(), HorariosScreen(), PlanesScreen(), AvisosScreen()],
          ),
        ),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          refrescarAdmin(ref); // datos frescos al cambiar de pestaña
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Horarios'),
          NavigationDestination(
              icon: Icon(Icons.card_membership_outlined), selectedIcon: Icon(Icons.card_membership), label: 'Planes'),
          NavigationDestination(
              icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Avisos'),
        ],
      ),
    );
  }
}
