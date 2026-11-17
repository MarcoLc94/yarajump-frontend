import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Logo de Yara Jump (assets/images/logo.png). Si aún no existe, muestra un ícono.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(gradient: AppColors.gradiente),
            child: Icon(Icons.sports_gymnastics, size: size * 0.55, color: Colors.white),
          ),
        ),
      );
}

/// Encabezado con el gradiente de marca, usado en las pantallas principales.
class GradientHeader extends StatelessWidget {
  const GradientHeader({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.gradiente,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: SafeArea(bottom: false, child: Padding(padding: padding, child: child)),
      );
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.fotoUrl, required this.iniciales, this.radio = 24});
  final String? fotoUrl;
  final String iniciales;
  final double radio;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radio,
        backgroundColor: AppColors.primario.withValues(alpha: 0.12),
        foregroundImage: fotoUrl != null ? NetworkImage(fotoUrl!) : null,
        child: Text(
          iniciales,
          style: TextStyle(color: AppColors.primario, fontWeight: FontWeight.w700, fontSize: radio * 0.7),
        ),
      );
}

/// Mensaje para listas vacías.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icono, required this.titulo, this.mensaje, this.accion});
  final IconData icono;
  final String titulo;
  final String? mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.primario.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icono, size: 40, color: AppColors.primario),
          ),
          const SizedBox(height: 16),
          Text(titulo, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          if (mensaje != null) ...[
            const SizedBox(height: 6),
            Text(mensaje!, style: t.bodyMedium?.copyWith(color: AppColors.textoSuave), textAlign: TextAlign.center),
          ],
          if (accion != null) ...[const SizedBox(height: 20), accion!],
        ]),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.texto, {super.key, this.trailing});
  final String texto;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
        child: Row(children: [
          Expanded(
            child: Text(texto,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Tarjeta de dato: ícono + valor + etiqueta.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icono, required this.valor, required this.etiqueta, this.color});
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primario;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppTheme.radio),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icono, color: c, size: 22),
        const SizedBox(height: 10),
        Text(valor, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        Text(etiqueta, style: t.bodySmall?.copyWith(color: AppColors.textoSuave)),
      ]),
    );
  }
}

/// Chip con los días de la semana de un horario (L M X J V S D).
class DiasSemana extends StatelessWidget {
  const DiasSemana({super.key, required this.dias});
  final List<int> dias;

  static const _letras = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var d = 1; d <= 7; d++)
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dias.contains(d) ? AppColors.primario : AppColors.borde.withValues(alpha: 0.6),
            ),
            child: Text(
              _letras[d - 1],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: dias.contains(d) ? Colors.white : AppColors.textoSuave,
              ),
            ),
          ),
      ]);
}
