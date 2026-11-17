import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/frecuencia.dart';
import '../../../data/models/horario.dart';
import '../../../data/models/plan.dart';
import '../../shared/widgets/async_body.dart';

String _turnos(int n) => n == 0 ? 'sin turnos' : '$n turno${n == 1 ? '' : 's'}';

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
                                ' · ${_turnos(p.horarioIds?.length ?? 0)}'
                                '${p.descripcion.isNotEmpty ? '\n${p.descripcion}' : ''}'),
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
    final elegidos = <int>{...?plan?.horarioIds};
    final horarios = (ref.read(horariosProvider).value ?? const <Horario>[])
        .where((h) => h.activo || elegidos.contains(h.id))
        .toList();

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
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Turnos que ofrece (${elegidos.length})',
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Los clientes solo pueden apartar estos turnos al elegir el plan.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppColors.textoSuave)),
              ),
              const SizedBox(height: 8),
              if (horarios.isEmpty)
                const Text('Primero crea horarios en la pestaña "Horarios".')
              else
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final h in horarios)
                    FilterChip(
                      avatar: Icon(h.turno.icono, size: 18),
                      label: Text('${h.titulo} · ${h.diasTexto}'
                          '${h.cupo == null ? '' : ' · ${h.cupo} lugares'}'),
                      selected: elegidos.contains(h.id),
                      onSelected: (v) => setState(() => v ? elegidos.add(h.id!) : elegidos.remove(h.id)),
                    ),
                ]),
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
          horarioIds: elegidos.toList(),
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
