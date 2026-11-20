import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_user.dart';
import '../../data/models/usuario_bo.dart';
import '../shared/widgets/async_body.dart';
import '../shared/widgets/ui.dart';
import 'ajustes_screen.dart';
import 'usuario_bo_screen.dart';

enum FiltroBO {
  todos('Todos'),
  clientes('Clientes'),
  staff('Admin y support'),
  bloqueados('Bloqueados'),
  inactivos('Sin actividad 30 días');

  const FiltroBO(this.etiqueta);
  final String etiqueta;
}

enum OrdenBO {
  actividad('Actividad reciente'),
  nuevos('Más nuevos'),
  logins('Más inicios de sesión');

  const OrdenBO(this.etiqueta);
  final String etiqueta;
}

/// "hace un momento", "hace 5 min", "hace 3 h", "ayer 18:20", "12 nov 18:20", "12 nov 2025"
String haceTiempo(DateTime? d, {DateTime? ahora}) {
  if (d == null) return 'Nunca';
  final n = ahora ?? DateTime.now();
  final dif = n.difference(d);
  if (dif.inMinutes < 1) return 'Hace un momento';
  if (dif.inMinutes < 60) return 'Hace ${dif.inMinutes} min';
  final hoy = DateTime(n.year, n.month, n.day);
  final dia = DateTime(d.year, d.month, d.day);
  final hora = DateFormat('HH:mm').format(d);
  if (dia == hoy) return 'Hace ${dif.inHours} h';
  if (hoy.difference(dia).inDays == 1) return 'Ayer $hora';
  if (d.year == n.year) return '${DateFormat('d MMM', 'es_MX').format(d)} $hora';
  return DateFormat('d MMM yyyy', 'es_MX').format(d);
}

IconData iconoPlataforma(String p) => switch (p) {
      'web' => Icons.language,
      'android' => Icons.android,
      'ios' => Icons.phone_iphone,
      _ => Icons.devices_other,
    };

Color colorRol(Rol r) => switch (r) {
      Rol.support => AppColors.secundario,
      Rol.admin => AppColors.primario,
      Rol.usuario => AppColors.textoSuave,
    };

class RolBadge extends StatelessWidget {
  const RolBadge(this.rol, {super.key});
  final Rol rol;
  @override
  Widget build(BuildContext context) {
    final c = colorRol(rol);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(rol.etiqueta, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

/// Backoffice (solo support): todas las cuentas con su actividad, rol y estado.
class BackofficeScreen extends ConsumerStatefulWidget {
  const BackofficeScreen({super.key});
  @override
  ConsumerState<BackofficeScreen> createState() => _BackofficeScreenState();
}

class _BackofficeScreenState extends ConsumerState<BackofficeScreen> {
  var _filtro = FiltroBO.todos;
  var _orden = OrdenBO.actividad;
  var _busqueda = '';

  List<UsuarioBO> _aplicar(List<UsuarioBO> todos) {
    final q = _busqueda.trim().toLowerCase();
    final hace30 = DateTime.now().subtract(const Duration(days: 30));
    final l = todos.where((u) {
      if (q.isNotEmpty && !u.nombre.toLowerCase().contains(q) && !u.email.toLowerCase().contains(q)) return false;
      return switch (_filtro) {
        FiltroBO.todos => true,
        FiltroBO.clientes => u.rol == Rol.usuario,
        FiltroBO.staff => u.rol != Rol.usuario,
        FiltroBO.bloqueados => u.bloqueado,
        FiltroBO.inactivos => u.ultimaActividad == null || u.ultimaActividad!.isBefore(hace30),
      };
    }).toList();
    final viejo = DateTime(2000);
    switch (_orden) {
      case OrdenBO.actividad:
        l.sort((a, b) => (b.ultimaActividad ?? viejo).compareTo(a.ultimaActividad ?? viejo));
      case OrdenBO.nuevos:
        l.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      case OrdenBO.logins:
        l.sort((a, b) => b.logins.compareTo(a.logins));
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = ref.watch(usuariosBOProvider);
    return AsyncBody(
      value: usuarios,
      onRetry: () => ref.invalidate(usuariosBOProvider),
      data: (todos) {
        final lista = _aplicar(todos);
        return RefreshIndicator(
          onRefresh: () {
            ref.invalidate(ajustesProvider);
            return ref.refresh(usuariosBOProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const AjustesCard(),
              _Resumen(usuarios: todos),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o correo',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _busqueda = v),
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  children: [
                    for (final f in FiltroBO.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f.etiqueta),
                          selected: _filtro == f,
                          onSelected: (_) => setState(() => _filtro = f),
                        ),
                      ),
                  ],
                ),
              ),
              SectionTitle(
                '${lista.length} cuenta${lista.length == 1 ? '' : 's'}',
                trailing: PopupMenuButton<OrdenBO>(
                  tooltip: 'Ordenar',
                  initialValue: _orden,
                  onSelected: (o) => setState(() => _orden = o),
                  itemBuilder: (_) => [for (final o in OrdenBO.values) PopupMenuItem(value: o, child: Text(o.etiqueta))],
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.sort, size: 18, color: AppColors.textoSuave),
                    const SizedBox(width: 4),
                    Text(_orden.etiqueta, style: const TextStyle(color: AppColors.textoSuave, fontSize: 13)),
                  ]),
                ),
              ),
              if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: EmptyState(icono: Icons.manage_search, titulo: 'Sin cuentas con ese filtro'),
                )
              else
                for (final u in lista) _UsuarioTile(usuario: u),
            ],
          ),
        );
      },
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.usuarios});
  final List<UsuarioBO> usuarios;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now().subtract(const Duration(hours: 24));
    final activos = usuarios.where((u) => u.ultimaActividad?.isAfter(hoy) ?? false).length;
    final staff = usuarios.where((u) => u.rol != Rol.usuario).length;
    final bloqueados = usuarios.where((u) => u.bloqueado).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        Expanded(child: StatTile(icono: Icons.people_alt_outlined, valor: '${usuarios.length}', etiqueta: 'Cuentas')),
        const SizedBox(width: 8),
        Expanded(
            child: StatTile(
                icono: Icons.bolt, valor: '$activos', etiqueta: 'Activas 24 h', color: AppColors.activo)),
        const SizedBox(width: 8),
        Expanded(
            child: StatTile(
                icono: Icons.admin_panel_settings_outlined,
                valor: '$staff',
                etiqueta: 'Staff',
                color: AppColors.secundario)),
        const SizedBox(width: 8),
        Expanded(
            child: StatTile(
                icono: Icons.block, valor: '$bloqueados', etiqueta: 'Bloqueadas', color: AppColors.expirado)),
      ]),
    );
  }
}

class _UsuarioTile extends StatelessWidget {
  const _UsuarioTile({required this.usuario});
  final UsuarioBO usuario;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final u = usuario;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radio),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => UsuarioBOScreen(userId: u.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Avatar(fotoUrl: u.fotoUrl, iniciales: u.iniciales, radio: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(u.nombreVisible,
                        overflow: TextOverflow.ellipsis, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                  RolBadge(u.rol),
                  if (u.bloqueado) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.block, size: 16, color: AppColors.expirado),
                  ],
                ]),
                Text(u.email,
                    overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(iconoPlataforma(u.ultimaPlataforma), size: 14, color: AppColors.textoSuave),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Activo: ${haceTiempo(u.ultimaActividad)} · ${u.logins} inicio${u.logins == 1 ? '' : 's'}',
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: AppColors.textoSuave),
                    ),
                  ),
                ]),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textoSuave),
          ]),
        ),
      ),
    );
  }
}
