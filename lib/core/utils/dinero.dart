import 'package:intl/intl.dart';

final _formato = NumberFormat.currency(locale: 'es_MX', symbol: r'$', decimalDigits: 0);

/// 1300 → "$1,300"
String dinero(num n) => _formato.format(n);
