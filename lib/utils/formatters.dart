// lib/utils/formatters.dart

import 'package:intl/intl.dart';

/// Rp 1,5jt / Rp 2M / Rp 50.000
String fmtMoney(double value) {
  if (value <= 0) return 'Rp 0';
  if (value >= 1e9) {
    final m = value / 1e9;
    return 'Rp ${m == m.truncateToDouble() ? m.truncate() : m.toStringAsFixed(1)}M';
  }
  if (value >= 1e6) {
    final jt = value / 1e6;
    return 'Rp ${jt == jt.truncateToDouble() ? jt.truncate() : jt.toStringAsFixed(1)}jt';
  }
  return 'Rp ${NumberFormat('#,###', 'id_ID').format(value.toInt())}';
}

/// "12 Januari 2025"
String fmtDate(DateTime? date) {
  if (date == null) return '—';
  return DateFormat('d MMMM yyyy', 'id_ID').format(date);
}

/// "baru saja", "5 menit lalu", dll.
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date).inSeconds;
  if (diff < 60)    return 'baru saja';
  if (diff < 3600)  return '${diff ~/ 60} menit lalu';
  if (diff < 86400) return '${diff ~/ 3600} jam lalu';
  return '${diff ~/ 86400} hari lalu';
}

extension StringExt on String {
  String get capitalizeFirst =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}
