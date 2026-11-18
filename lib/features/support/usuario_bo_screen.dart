import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_user.dart';
import '../../data/models/usuario_bo.dart';
import '../shared/widgets/async_body.dart';
import '../shared/widgets/ui.dart';
import 'backoffice_screen.dart';

/// Ficha de una cuenta en el backoffice: actividad, datos, rol, bloqueo y accesos.
class UsuarioBOScreen extends ConsumerWidget {
  const UsuarioBOScreen({super.key, required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yo = ref.watch(sessionProvider).value?.user.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: AsyncBody(
        value: ref.watch(usuariosBOProvider),
        onRetry: () => ref.invalidate(usuariosBOProvider),
        data: (todos) {
          final u = todos.where((x) => x.id == userId).firstOrNull;
          if (u == null) {
            return const EmptyState(icono: Icons.person_off_outlined, titulo: 'Esta cuenta ya no existe');
          }
          final esYo = u.id == yo;
          return RefreshIndicator(
            onRefresh: () {
              ref.invalidate(accesosBOProvider(userId));
              return ref.refresh(usuariosBOProvider.future);
            },
            child: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
              _Cabecera(usuario: u, esYo: esYo),
              const SectionTitle('Actividad'),
              _Actividad(usuario: u),
              const SectionTitle('Datos'),
              _Datos(key: ValueKey('datos-${u.id}-${u.nombre}-${u.email}-${u.telefono}'), usuario: u),
              const SectionTitle('Rol'),
              _RolEditor(usuario: u, esYo: esYo),
              if (u.esCliente) ...[
                const SectionTitle('Seguridad'),
                _Bloqueo(usuario: u, esYo: esYo),
              ],
              const SectionTitle('Inicios de sesión'),
              _Accesos(userId: u.id),
              if (!esYo && !u.rolFijo) ...[
                const SectionTitle('Zona de peligro'),
                _Eliminar(usuario: u),
              ],
            ]),
          );
        },
      ),
    );
  }
}

/// Aplica cambios y refresca la lista. Devuelve true si se guardó.
Future<bool> _guardar(BuildContext context, WidgetRef ref, int id, Map<String, dynamic> cambios, String ok) async {
  try {
    await ref.read(adminRepositoryProvider).editarUsuarioBO(id, cambios);
    ref.invalidate(usuariosBOProvider);
    ref.invalidate(clientesProvider); // nombre/correo/bloqueo también se ven en Clientes
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
    return true;
  } catch (e) {
    if (context.mounted) mostrarError(context, e);
    return false;
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.usuario, required this.esYo});
  final UsuarioBO usuario;
  final bool esYo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final u = usuario;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        Avatar(fotoUrl: u.fotoUrl, iniciales: u.iniciales, radio: 32),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u.nombreVisible + (esYo ? ' (tú)' : ''),
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(u.email, style: t.bodyMedium?.copyWith(color: AppColors.textoSuave)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              RolBadge(u.rol),
              if (u.bloqueado)
                const _Etiqueta(icono: Icons.block, texto: 'Bloqueado', color: AppColors.expirado),
              if (u.rolFijo)
                const _Etiqueta(icono: Icons.lock_outline, texto: 'Rol fijo', color: AppColors.textoSuave),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.icono, required this.texto, required this.color});
  final IconData icono;
  final String texto;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icono, size: 13, color: color),
          const SizedBox(width: 4),
          Text(texto, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _Actividad extends StatelessWidget {
  const _Actividad({required this.usuario});
  final UsuarioBO usuario;

  @override
  Widget build(BuildContext context) {
    final u = usuario;
    final f = DateFormat('d MMM yyyy, HH:mm', 'es_MX');
    String exacta(DateTime? d) => d == null ? '' : f.format(d);
    final plataforma = switch (u.ultimaPlataforma) {
      'web' => 'Web (PWA)',
      'android' => 'Android',
      'ios' => 'iPhone',
      _ => 'Sin dato',
    };
    return Card(
      child: Column(children: [
        _Dato(Icons.bolt, 'Última actividad', haceTiempo(u.ultimaActividad), exacta(u.ultimaActividad)),
        _Dato(Icons.login, 'Último inicio de sesión', haceTiempo(u.ultimoLogin), exacta(u.ultimoLogin)),
        _Dato(Icons.repeat, 'Inicios de sesión', '${u.logins}', ''),
        _Dato(iconoPlataforma(u.ultimaPlataforma), 'Última plataforma', plataforma, ''),
        _Dato(u.metodo == 'password' ? Icons.password : Icons.g_mobiledata, 'Entra con',
            u.metodo == 'password' ? 'Correo y contraseña' : 'Google', ''),
        _Dato(u.pushActivo ? Icons.notifications_active_outlined : Icons.notifications_off_outlined, 'Notificaciones',
            u.pushActivo ? 'Activas' : 'Sin activar', ''),
        _Dato(Icons.event, 'Cuenta creada', DateFormat("d 'de' MMMM yyyy", 'es_MX').format(u.creadoEn), ''),
      ]),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.titulo, this.valor, this.detalle);
  final IconData icono;
  final String titulo;
  final String valor;
  final String detalle;
  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        leading: Icon(icono, color: AppColors.textoSuave),
        title: Text(titulo),
        subtitle: detalle.isEmpty ? null : Text(detalle),
        trailing: Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}

class _Datos extends ConsumerStatefulWidget {
  const _Datos({super.key, required this.usuario});
  final UsuarioBO usuario;
  @override
  ConsumerState<_Datos> createState() => _DatosState();
}

class _DatosState extends ConsumerState<_Datos> {
  late final _nombre = TextEditingController(text: widget.usuario.nombre);
  late final _email = TextEditingController(text: widget.usuario.email);
  late final _tel = TextEditingController(text: widget.usuario.telefono);
  bool _guardando = false;

  Map<String, dynamic> get _cambios {
    final u = widget.usuario;
    return {
      if (_nombre.text.trim() != u.nombre) 'nombre': _nombre.text.trim(),
      if (_email.text.trim().toLowerCase() != u.email) 'email': _email.text.trim(),
      if (u.esCliente && _tel.text.trim() != u.telefono) 'telefono': _tel.text.trim(),
    };
  }

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _tel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.usuario;
    final cambios = _cambios;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            enabled: !u.rolFijo,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo',
              prefixIcon: const Icon(Icons.alternate_email),
              helperText: u.rolFijo
                  ? 'Lo fija la configuración del servidor'
                  : (u.metodo == 'google' ? 'Entra con Google: debe coincidir con su cuenta de Google' : null),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (u.esCliente) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _tel,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined)),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: cambios.isEmpty || _guardando
                ? null
                : () async {
                    setState(() => _guardando = true);
                    await _guardar(context, ref, u.id, cambios, 'Datos guardados');
                    if (mounted) setState(() => _guardando = false);
                  },
            child: Text(_guardando ? 'Guardando…' : 'Guardar cambios'),
          ),
        ]),
      ),
    );
  }
}

class _RolEditor extends ConsumerWidget {
  const _RolEditor({required this.usuario, required this.esYo});
  final UsuarioBO usuario;
  final bool esYo;

  static const _descripcion = {
    Rol.usuario: 'Cliente: ve su plan, horarios, avisos y progreso.',
    Rol.admin: 'Admin: administra clientes, pagos, horarios, planes y avisos.',
    Rol.support: 'Support: todo lo del admin más este backoffice.',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = usuario;
    final bloqueado = esYo || u.rolFijo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<Rol>(
            segments: [for (final r in Rol.values) ButtonSegment(value: r, label: Text(r.etiqueta))],
            selected: {u.rol},
            showSelectedIcon: false,
            onSelectionChanged: bloqueado
                ? null
                : (s) async {
                    final nuevo = s.first;
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('¿Hacer ${nuevo.etiqueta.toLowerCase()} a ${u.nombreVisible}?'),
                        content: Text('${_descripcion[nuevo]}\n\nEl cambio aplica de inmediato.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cambiar rol')),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await _guardar(context, ref, u.id, {'rol': nuevo.name}, 'Ahora es ${nuevo.etiqueta}');
                    }
                  },
          ),
          const SizedBox(height: 10),
          Text(
            esYo
                ? 'No puedes cambiar tu propio rol.'
                : u.rolFijo
                    ? 'Este correo está en ADMIN_EMAILS / SUPPORT_EMAILS del servidor: su rol se cambia allí.'
                    : _descripcion[u.rol]!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textoSuave),
          ),
        ]),
      ),
    );
  }
}

class _Bloqueo extends ConsumerWidget {
  const _Bloqueo({required this.usuario, required this.esYo});
  final UsuarioBO usuario;
  final bool esYo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = usuario;
    return Card(
      child: SwitchListTile(
        secondary: Icon(u.bloqueado ? Icons.gpp_bad_outlined : Icons.verified_user_outlined,
            color: u.bloqueado ? AppColors.expirado : AppColors.activo),
        title: const Text('Acceso bloqueado'),
        subtitle: Text(u.bloqueado
            ? 'Solo ve el mensaje de seguridad y el botón de WhatsApp.'
            : 'Al bloquear se cancelan sus apartados pendientes.'),
        value: u.bloqueado,
        activeThumbColor: AppColors.expirado,
        onChanged: esYo
            ? null
            : (v) async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(v ? '¿Bloquear a ${u.nombreVisible}?' : '¿Devolver el acceso a ${u.nombreVisible}?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      FilledButton(
                        style: v ? FilledButton.styleFrom(backgroundColor: AppColors.expirado) : null,
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(v ? 'Bloquear' : 'Desbloquear'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await _guardar(context, ref, u.id, {'bloqueado': v}, v ? 'Cuenta bloqueada' : 'Acceso devuelto');
                }
              },
      ),
    );
  }
}

class _Accesos extends ConsumerWidget {
  const _Accesos({required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = DateFormat('EEE d MMM yyyy, HH:mm', 'es_MX');
    return ref.watch(accesosBOProvider(userId)).when(
          loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('$e')),
          data: (as) => as.isEmpty
              ? const Card(
                  child: ListTile(
                    leading: Icon(Icons.history_toggle_off),
                    title: Text('Sin inicios de sesión registrados'),
                    subtitle: Text('Se registran desde esta versión en adelante.'),
                  ),
                )
              : Card(
                  child: Column(children: [
                    for (final a in as)
                      ListTile(
                        dense: true,
                        leading: Icon(iconoPlataforma(a.plataforma), color: AppColors.textoSuave),
                        title: Text(f.format(a.fecha)),
                        trailing: Text(switch (a.metodo) {
                          'google' => 'Google',
                          'password' => 'Contraseña',
                          _ => a.metodo,
                        }),
                      ),
                  ]),
                ),
        );
  }
}

class _Eliminar extends ConsumerWidget {
  const _Eliminar({required this.usuario});
  final UsuarioBO usuario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = usuario;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.delete_forever_outlined, color: AppColors.expirado),
        title: const Text('Eliminar cuenta', style: TextStyle(color: AppColors.expirado, fontWeight: FontWeight.w700)),
        subtitle: const Text('No se puede deshacer.'),
        onTap: () async {
          var conCliente = false;
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => StatefulBuilder(
              builder: (ctx, setState) => AlertDialog(
                icon: const Icon(Icons.warning_amber_rounded, color: AppColors.expirado),
                title: Text('¿Eliminar la cuenta de ${u.nombreVisible}?'),
                content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Se borra la cuenta ${u.email} y su historial de accesos. '
                      'Si vuelve a entrar con ese correo se le crea una cuenta nueva.'),
                  if (u.esCliente)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: conCliente,
                      onChanged: (v) => setState(() => conCliente = v ?? false),
                      title: const Text('Borrar también su ficha de cliente'),
                      subtitle: const Text('Plan, pagos, progreso y solicitudes.'),
                    ),
                ]),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.expirado),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ),
          );
          if (ok != true || !context.mounted) return;
          final nav = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);
          try {
            await ref.read(adminRepositoryProvider).eliminarUsuarioBO(u.id, conCliente: conCliente);
            ref.invalidate(usuariosBOProvider);
            refrescarAdmin(ref);
            nav.pop();
            messenger.showSnackBar(SnackBar(content: Text('Cuenta ${u.email} eliminada')));
          } catch (e) {
            if (context.mounted) mostrarError(context, e);
          }
        },
      ),
    );
  }
}
