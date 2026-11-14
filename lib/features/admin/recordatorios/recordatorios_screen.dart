import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/fechas.dart';
import '../../../data/models/cliente.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/estado_chip.dart';
import '../clientes/cliente_form_screen.dart';
import '../clientes/registrar_pago_sheet.dart';

/// Vencimientos: clientes ordenados por días restantes, con filtro por estado.
/// La frecuencia de cada cliente se configura desde su formulario.
class RecordatoriosScreen extends ConsumerStatefulWidget {
  const RecordatoriosScreen({super.key});
  @override
  ConsumerState<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends ConsumerState<RecordatoriosScreen> {
  EstadoPlan? _filtro;

  @override
  Widget build(BuildContext context) {
    return AsyncBody(
      value: ref.watch(recordatoriosProvider),
      onRetry: () => ref.invalidate(recordatoriosProvider),
      data: (lista) {
        final filtrados = _filtro == null ? lista : lista.where((c) => c.estado == _filtro).toList();
        int contar(EstadoPlan e) => lista.where((c) => c.estado == e).length;

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Wrap(spacing: 8, children: [
                ChoiceChip(
                  label: Text('Todos (${lista.length})'),
                  selected: _filtro == null,
                  onSelected: (_) => setState(() => _filtro = null),
                ),
                for (final e in [EstadoPlan.expirado, EstadoPlan.ultimoDia, EstadoPlan.porVencer, EstadoPlan.activo])
                  ChoiceChip(
                    label: Text('${e.etiqueta} (${contar(e)})'),
                    selected: _filtro == e,
                    selectedColor: colorEstado(e).withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _filtro = e),
                  ),
              ]),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(recordatoriosProvider.future),
                child: ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (_, i) {
                    final c = filtrados[i];
                    final d = c.diasRestantes ?? 0;
                    return Card(
                      child: ListTile(
                        title: Text(c.nombre),
                        subtitle: Text('${c.frecuencia.etiqueta}'
                            '${c.diasPersonalizados != null ? ' (${c.diasPersonalizados} días)' : ''}'
                            ' · Vence ${Fechas.corta(c.fechaFin!)}\n'
                            '${d > 0 ? 'Le quedan $d día(s)' : 'Venció hace ${-d + 1} día(s)'}'),
                        isThreeLine: true,
                        trailing: EstadoChip(c.estado),
                        onTap: () async {
                          await Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => ClienteFormScreen(cliente: c)));
                          refrescarAdmin(ref);
                        },
                        onLongPress: () async {
                          await mostrarRegistrarPago(context, c);
                          refrescarAdmin(ref);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
