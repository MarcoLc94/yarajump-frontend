import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/cliente.dart';
import '../../shared/progreso/progreso_view.dart';
import '../../shared/widgets/async_body.dart';

class ClienteProgresoScreen extends ConsumerWidget {
  const ClienteProgresoScreen({super.key, required this.cliente});
  final Cliente cliente;

  Future<void> _agregar(BuildContext context, WidgetRef ref) async {
    final previas = ref.read(progresoClienteProvider(cliente.id!)).value ?? [];
    final m = await mostrarNuevaMedicion(context, anterior: previas.isEmpty ? null : previas.last);
    if (m == null) return;
    try {
      await ref.read(adminRepositoryProvider).registrarMedicion(cliente.id!, m);
      ref.invalidate(progresoClienteProvider(cliente.id!));
    } catch (e) {
      if (context.mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = progresoClienteProvider(cliente.id!);
    final progreso = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(title: Text('Progreso · ${cliente.nombre.split(' ').first}')),
      floatingActionButton: (progreso.value?.isNotEmpty ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => _agregar(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Medición'),
            )
          : null,
      body: AsyncBody(
        value: progreso,
        onRetry: () => ref.invalidate(provider),
        data: (lista) => ProgresoView(
          mediciones: lista,
          onAgregar: () => _agregar(context, ref),
          onRefresh: () => ref.refresh(provider.future),
          onEliminar: (m) async {
            try {
              await ref.read(adminRepositoryProvider).eliminarMedicion(m.id!);
              ref.invalidate(provider);
            } catch (e) {
              if (context.mounted) mostrarError(context, e);
            }
          },
        ),
      ),
    );
  }
}
