String formatSeconds(int s) {
  final m = s ~/ 60;
  final r = s % 60;
  final mm = m.toString().padLeft(2, '0');
  final rr = r.toString().padLeft(2, '0');
  return '$mm:$rr';
}
