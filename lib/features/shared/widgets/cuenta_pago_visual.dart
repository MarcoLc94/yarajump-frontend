import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/cuenta_pago.dart';

/// Dibujo de la cuenta donde pagar: tarjeta de débito o CLABE (estilo banco),
/// con botón para copiar el número.
class CuentaPagoVisual extends StatelessWidget {
  const CuentaPagoVisual({super.key, required this.cuenta, this.copiable = true});
  final CuentaPago cuenta;
  final bool copiable;

  Future<void> _copiar(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: cuenta.numero));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(cuenta.tipo == TipoCuenta.tarjeta ? 'Número de tarjeta copiado' : 'CLABE copiada'),
    ));
  }

  /// Ancho de una tarjeta real en pantalla: en tablet/escritorio no se estira.
  static const anchoMaximo = 420.0;

  @override
  Widget build(BuildContext context) {
    final dibujo = cuenta.tipo == TipoCuenta.tarjeta ? _Tarjeta(cuenta) : _Clabe(cuenta);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: anchoMaximo),
        child: !copiable
            ? dibujo
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                dibujo,
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _copiar(context),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(cuenta.tipo == TipoCuenta.tarjeta ? 'Copiar número' : 'Copiar CLABE'),
                  ),
                ),
              ]),
      ),
    );
  }
}

TextStyle _digitos(double size, Color color) =>
    GoogleFonts.robotoMono(fontSize: size, color: color, fontWeight: FontWeight.w600, letterSpacing: 1.2);

// ---------------------------------------------------------------------------
// Tarjeta de débito
// ---------------------------------------------------------------------------
class _Tarjeta extends StatelessWidget {
  const _Tarjeta(this.c);
  final CuentaPago c;

  @override
  Widget build(BuildContext context) {
    final numero = c.numero.isEmpty ? '•••• •••• •••• ••••' : c.numeroFormateado;
    return AspectRatio(
      aspectRatio: 1.586, // proporción real de una tarjeta
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primario, AppColors.secundario, Color(0xFF2E0F4A)],
          ),
          boxShadow: [
            BoxShadow(color: AppColors.secundario.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(children: [
          // Círculos decorativos
          Positioned(right: -60, top: -50, child: _circulo(200, 0.10)),
          Positioned(left: -40, bottom: -90, child: _circulo(220, 0.07)),
          LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth;
            return Padding(
              padding: EdgeInsets.all(w * 0.065),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      c.banco.isEmpty ? 'Tarjeta de débito' : c.banco,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: w * 0.05),
                    ),
                  ),
                  Icon(Icons.contactless_outlined, color: Colors.white70, size: w * 0.075),
                ]),
                SizedBox(height: w * 0.05),
                _Chip(ancho: w * 0.13),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(numero, style: _digitos(w * 0.068, Colors.white)),
                ),
                SizedBox(height: w * 0.04),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('TITULAR',
                          style: TextStyle(color: Colors.white60, fontSize: w * 0.026, letterSpacing: 1.5)),
                      Text(
                        c.titular.isEmpty ? '—' : c.titular.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: w * 0.04, letterSpacing: 1),
                      ),
                    ]),
                  ),
                  _LogoRed(red: c.red, alto: w * 0.09),
                ]),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  static Widget _circulo(double d, double alpha) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.ancho});
  final double ancho;

  @override
  Widget build(BuildContext context) => Container(
        width: ancho,
        height: ancho * 0.75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ancho * 0.14),
          gradient: const LinearGradient(colors: [Color(0xFFF3D98B), Color(0xFFC9A24A), Color(0xFFEBCB75)]),
        ),
        child: CustomPaint(painter: _ChipLineas()),
      );
}

class _ChipLineas extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0xFF9C7A2E).withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, s.height / 3), Offset(s.width, s.height / 3), p);
    canvas.drawLine(Offset(0, s.height * 2 / 3), Offset(s.width, s.height * 2 / 3), p);
    canvas.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height / 3), p);
    canvas.drawLine(Offset(s.width / 2, s.height * 2 / 3), Offset(s.width / 2, s.height), p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: s.center(Offset.zero), width: s.width * 0.34, height: s.height * 0.34),
          const Radius.circular(2)),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoRed extends StatelessWidget {
  const _LogoRed({required this.red, required this.alto});
  final String? red;
  final double alto;

  @override
  Widget build(BuildContext context) => switch (red) {
        'VISA' => Text('VISA',
            style: TextStyle(
                color: Colors.white,
                fontSize: alto * 0.7,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1)),
        'MASTERCARD' => SizedBox(
            width: alto * 1.6,
            height: alto,
            child: Stack(children: [
              Positioned(left: 0, child: _disco(const Color(0xFFEB001B))),
              Positioned(right: 0, child: _disco(const Color(0xFFF79E1B).withValues(alpha: 0.9))),
            ]),
          ),
        'AMEX' => Text('AMEX',
            style: TextStyle(color: Colors.white, fontSize: alto * 0.55, fontWeight: FontWeight.w900, letterSpacing: 2)),
        _ => const SizedBox.shrink(),
      };

  Widget _disco(Color c) => Container(width: alto, height: alto, decoration: BoxDecoration(shape: BoxShape.circle, color: c));
}

// ---------------------------------------------------------------------------
// CLABE: dibujo tipo banco
// ---------------------------------------------------------------------------
class _Clabe extends StatelessWidget {
  const _Clabe(this.c);
  final CuentaPago c;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final numero = c.numero.isEmpty ? '••• ••• ••••••••••• •' : c.numeroFormateado;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borde),
        boxShadow: [BoxShadow(color: AppColors.secundario.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Stack(children: [
        // Edificio de banco como marca de agua
        Positioned(
          right: -18,
          bottom: -22,
          child: Icon(Icons.account_balance, size: 150, color: AppColors.secundario.withValues(alpha: 0.06)),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Franja superior con el banco
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF2E0F4A), AppColors.secundario]),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    c.banco.isEmpty ? 'Transferencia bancaria' : c.banco,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  Text('Transferencia SPEI', style: t.bodySmall?.copyWith(color: Colors.white70)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white54),
                ),
                child: const Text('SPEI',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CLABE INTERBANCARIA',
                  style: t.labelSmall?.copyWith(color: AppColors.textoSuave, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(numero, style: _digitos(22, AppColors.texto)),
              ),
              const SizedBox(height: 14),
              Text('BENEFICIARIO',
                  style: t.labelSmall?.copyWith(color: AppColors.textoSuave, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
              Text(c.titular.isEmpty ? '—' : c.titular,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ]),
    );
  }
}
