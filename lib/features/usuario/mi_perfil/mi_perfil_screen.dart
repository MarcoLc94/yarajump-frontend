import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers.dart';
import '../../../core/utils/fechas.dart';
import '../../../data/models/cliente.dart';
import '../../shared/widgets/async_body.dart';

class MiPerfilScreen extends ConsumerWidget {
  const MiPerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
          ),
        ],
      ),
      body: AsyncBody(
        value: ref.watch(miClienteProvider),
        onRetry: () => ref.invalidate(miClienteProvider),
        data: (c) => c == null ? const SizedBox() : _PerfilForm(key: ValueKey(c.id), cliente: c),
      ),
    );
  }
}

class _PerfilForm extends ConsumerStatefulWidget {
  const _PerfilForm({super.key, required this.cliente});
  final Cliente cliente;
  @override
  ConsumerState<_PerfilForm> createState() => _PerfilFormState();
}

class _PerfilFormState extends ConsumerState<_PerfilForm> {
  late final _telefono = TextEditingController(text: widget.cliente.telefono);
  late final _emergencia = TextEditingController(text: widget.cliente.contactoEmergencia);
  late DateTime? _nacimiento = widget.cliente.fechaNacimiento;
  bool _subiendo = false;
  bool _guardando = false;

  @override
  void dispose() {
    _telefono.dispose();
    _emergencia.dispose();
    super.dispose();
  }

  Future<void> _cambiarFoto() async {
    final origen = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        ]),
      ),
    );
    if (origen == null) return;
    final img = await ImagePicker().pickImage(source: origen, maxWidth: 800, imageQuality: 80);
    if (img == null) return;

    setState(() => _subiendo = true);
    try {
      await ref.read(perfilRepositoryProvider).subirFoto(await img.readAsBytes(), img.name);
      ref.invalidate(miClienteProvider);
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await ref.read(perfilRepositoryProvider).actualizarDatos(
            telefono: _telefono.text.trim(),
            contactoEmergencia: _emergencia.text.trim(),
            fechaNacimiento: _nacimiento,
          );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos actualizados')));
    } catch (e) {
      if (mounted) mostrarError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cliente;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Stack(children: [
            CircleAvatar(
              radius: 56,
              backgroundImage: c.fotoUrl != null ? NetworkImage(c.fotoUrl!) : null,
              child: _subiendo
                  ? const CircularProgressIndicator()
                  : (c.fotoUrl == null ? const Icon(Icons.person, size: 56) : null),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton.filled(icon: const Icon(Icons.camera_alt), onPressed: _cambiarFoto),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text(c.nombre, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        Text(c.email, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        TextField(
          controller: _telefono,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emergencia,
          decoration: const InputDecoration(
            labelText: 'Contacto de emergencia',
            helperText: 'Nombre y teléfono',
            prefixIcon: Icon(Icons.health_and_safety_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.cake_outlined),
            title: const Text('Fecha de nacimiento'),
            subtitle: Text(_nacimiento == null ? 'Agregar' : Fechas.formato(_nacimiento!)),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _nacimiento ?? DateTime(2000),
                firstDate: DateTime(1930),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _nacimiento = Fechas.soloFecha(d));
            },
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: Text(_guardando ? 'Guardando…' : 'Guardar cambios'),
        ),
      ],
    );
  }
}
