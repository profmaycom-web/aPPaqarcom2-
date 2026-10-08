String formatCompactNumber(num value) {
  final v = value.toDouble();
  if (v.abs() >= 1000000) {
    final m = v / 1000000;
    return '${m.toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}M';
  }
  if (v.abs() >= 1000) {
    final k = v / 1000;
    return '${k.toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
  }
  return v.toStringAsFixed(0);
}
