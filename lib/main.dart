import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');
  await NotificationService.instance.init(); // Firebase opcional (solo push)
  await _precargarFuentes();

  runApp(const ProviderScope(child: YaraJumpingApp()));
}

/// Descarga Poppins antes de pintar la app. Si no, en web los textos que se dibujan
/// al inicio miden su ancho con la fuente provisional y luego quedan cortados (p. ej. chips).
Future<void> _precargarFuentes() async {
  for (final w in [FontWeight.w400, FontWeight.w500, FontWeight.w600, FontWeight.w700, FontWeight.w800, FontWeight.w900]) {
    GoogleFonts.poppins(fontWeight: w);
  }
  try {
    await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 3)); // sin internet: sigue con la de respaldo
  } catch (_) {}
}
