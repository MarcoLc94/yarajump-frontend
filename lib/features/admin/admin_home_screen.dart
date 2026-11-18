import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../shared/widgets/ui.dart';
import 'clientes/clientes_list_screen.dart';
import 'horarios/horarios_screen.dart';
import 'planes/planes_screen.dart';
import 'avisos/avisos_screen.dart';
import 'pagos/pagos_screen.dart';
import 'pagos/cuentas_pago_screen.dart';
import '../support/backoffice_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _tab = 0;
  static const _titulos = ['Clientes', 'Pagos', 'Horarios', 'Planes', 'Avisos', 'Backoffice'];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // Support ve lo mismo que admin más el backoffice.
    final support = ref.watch(sessionProvider).value?.user.esSupport ?? false;
    final tab = support ? _tab : _tab.clamp(0, 4);
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
                Text(_titulos[tab], style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
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
            index: tab,
            children: [
              const ClientesListScreen(),
              const PagosScreen(),
              const HorariosScreen(),
              const PlanesScreen(),
              const AvisosScreen(),
              if (support) const BackofficeScreen(),
            ],
          ),
        ),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        // Con 6 pestañas no caben todas las etiquetas en el teléfono
        labelBehavior: support ? NavigationDestinationLabelBehavior.onlyShowSelected : null,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          refrescarAdmin(ref); // datos frescos al cambiar de pestaña
        },
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clientes'),
          const NavigationDestination(
              icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Pagos'),
          const NavigationDestination(
              icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Horarios'),
          const NavigationDestination(
              icon: Icon(Icons.card_membership_outlined), selectedIcon: Icon(Icons.card_membership), label: 'Planes'),
          const NavigationDestination(
              icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Avisos'),
          if (support)
            const NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings),
                label: 'Backoffice'),
        ],
      ),
    );
  }
}
