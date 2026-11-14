import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/models/cliente.dart';
import '../../shared/widgets/async_body.dart';
import '../../shared/widgets/estado_chip.dart';
import 'cliente_form_screen.dart';
import 'registrar_pago_sheet.dart';

class ClientesListScreen extends ConsumerStatefulWidget {
  const ClientesListScreen({super.key});
  @override
  ConsumerState<ClientesListScreen> createState() => _ClientesListScreenState();
}

class _ClientesListScreenState extends ConsumerState<ClientesListScreen> {
  String _filtro = '';

  Future<void> _abrirForm([Cliente? c]) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClienteFormScreen(cliente: c)));
    refrescarAdmin(ref);
  }

  @override
  Widget build(BuildContext context) {
    final clientes = ref.watch(clientesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirForm,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo cliente'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar cliente'),
              onChanged: (v) => setState(() => _filtro = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: AsyncBody(
              value: clientes,
              onRetry: () => ref.invalidate(clientesProvider),
              data: (lista) {
                final filtrados = lista
                    .where((c) => c.nombre.toLowerCase().contains(_filtro) || c.email.contains(_filtro))
                    .toList();
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(clientesProvider.future),
                  child: filtrados.isEmpty
                      ? ListView(children: const [SizedBox(height: 120), Center(child: Text('Sin clientes'))])
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: filtrados.length,
                          itemBuilder: (_, i) {
                            final c = filtrados[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: c.fotoUrl != null ? NetworkImage(c.fotoUrl!) : null,
                                  child: c.fotoUrl == null ? Text(c.nombre.isEmpty ? '?' : c.nombre[0]) : null,
                                ),
                                title: Text(c.nombre),
                                subtitle: Text('${c.planNombre ?? 'Sin plan'} · ${c.frecuencia.etiqueta}'
                                    '${c.vinculado ? '' : '\nAún no entra a la app'}'),
                                isThreeLine: !c.vinculado,
                                trailing: EstadoChip(c.estado),
                                onTap: () => _abrirForm(c),
                                onLongPress: () async {
                                  await mostrarRegistrarPago(context, c);
                                  refrescarAdmin(ref);
                                },
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
