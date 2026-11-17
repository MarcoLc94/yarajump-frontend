import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../shared/progreso/progreso_view.dart';
import '../../shared/widgets/async_body.dart';

class MiProgresoScreen extends ConsumerWidget {
  const MiProgresoScreen({super.key});

  Future<void> _agregar(BuildContext context, WidgetRef ref) async {
    final previas = ref.read(miProgresoProvider).value ?? [];
    final m = await mostrarNuevaMedicion(context, anterior: previas.isEmpty ? null : previas.last);
    if (m == null) return;
    try {
      await ref.read(perfilRepositoryProvider).registrarMedicion(m);
      ref.invalidate(miProgresoProvider);
    } catch (e) {
      if (context.mounted) mostrarError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progreso = ref.watch(miProgresoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi progreso')),
      floatingActionButton: (progreso.value?.isNotEmpty ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => _agregar(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Medición'),
            )
          : null,
      body: AsyncBody(
        value: progreso,
        onRetry: () => ref.invalidate(miProgresoProvider),
        data: (lista) => ProgresoView(
          mediciones: lista,
          onAgregar: () => _agregar(context, ref),
          onRefresh: () => ref.refresh(miProgresoProvider.future),
          onEliminar: (m) async {
            try {
              await ref.read(perfilRepositoryProvider).eliminarMedicion(m.id!);
              ref.invalidate(miProgresoProvider);
            } catch (e) {
              if (context.mounted) mostrarError(context, e);
            }
          },
        ),
      ),
    );
  }
}
