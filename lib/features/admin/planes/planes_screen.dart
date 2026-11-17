import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/frecuencia.dart';
import '../../../data/models/plan.dart';
import '../../shared/widgets/async_body.dart';

class PlanesScreen extends ConsumerWidget {
  const PlanesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-planes',
        onPressed: () => _editar(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo plan'),
      ),
      body: AsyncBody(
        value: ref.watch(planesProvider),
        onRetry: () => ref.invalidate(planesProvider),
        data: (lista) => lista.isEmpty
            ? const Center(child: Text('Aún no hay planes'))
            : ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 96),
                children: lista
                    .map((p) => Card(
                          child: ListTile(
                            title: Text(p.nombre),
                            subtitle: Text('${p.frecuenciaSugerida.etiqueta}'
                                '${p.descripcion.isNotEmpty ? ' · ${p.descripcion}' : ''}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('\$${p.precio.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium),
                                if (!p.activo) const Text('Inactivo', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                            onTap: () => _editar(context, ref, p),
                          ),
                        ))
                    .toList(),
              ),
      ),
    );
  }

  Future<void> _editar(BuildContext context, WidgetRef ref, [Plan? plan]) async {
    final nombre = TextEditingController(text: plan?.nombre);
    final precio = TextEditingController(text: plan?.precio.toStringAsFixed(0));
    final desc = TextEditingController(text: plan?.descripcion);
    var frecuencia = plan?.frecuenciaSugerida ?? Frecuencia.mensual;
    var activo = plan?.activo ?? true;

    final accion = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(plan == null ? 'Nuevo plan' : 'Editar plan'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 12),
              TextField(
                controller: precio,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Costo', prefixText: '\$ '),
              ),
              const SizedBox(height: 12),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'Descripción')),
              const SizedBox(height: 12),
              DropdownButtonFormField<Frecuencia>(
                initialValue: frecuencia,
                decoration: const InputDecoration(labelText: 'Frecuencia sugerida'),
                items: Frecuencia.values.map((f) => DropdownMenuItem(value: f, child: Text(f.etiqueta))).toList(),
                onChanged: (f) => setState(() => frecuencia = f!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activo'),
                value: activo,
                onChanged: (v) => setState(() => activo = v),
              ),
            ]),
          ),
          actions: [
            if (plan != null)
              TextButton(onPressed: () => Navigator.pop(ctx, 'eliminar'), child: const Text('Eliminar')),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, 'guardar'), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    final repo = ref.read(adminRepositoryProvider);
    try {
      if (accion == 'guardar' && nombre.text.trim().isNotEmpty) {
        await repo.guardarPlan(Plan(
          id: plan?.id,
          nombre: nombre.text.trim(),
          precio: double.tryParse(precio.text) ?? 0,
          descripcion: desc.text.trim(),
          frecuenciaSugerida: frecuencia,
          activo: activo,
        ));
      } else if (accion == 'eliminar') {
        await repo.eliminarPlan(plan!.id!);
      } else {
        return;
      }
      refrescarAdmin(ref);
    } catch (e) {
      if (context.mounted) mostrarError(context, e); // p. ej. "Hay clientes con este plan..."
    }
  }
}
