import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class MyPathBackground extends StatefulWidget {
  const MyPathBackground({super.key});

  @override
  State<MyPathBackground> createState() => _MyPathBackgroundState();
}

class _MyPathBackgroundState extends State<MyPathBackground>
    with TickerProviderStateMixin {
  static const _w = 1024.0;
  static const _h = 1536.0;

  late final AnimationController _fx; // particelle + flicker + mist
  late final Timer _clock;

  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();

    _fx = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    // L'orario non serve aggiornarlo ogni frame: basta 1 volta al minuto.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    _fx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blend = _computeBlend(_now);

    // Intensità overlay in base alla fase (0..1)
    final mist = _mistIntensity(_now);
    final nightness = _nightness(_now); // 0 day -> 1 night
    final dust = lerpDouble(0.18, 0.55, nightness)!;
    final glow = lerpDouble(0.10, 0.85, nightness)!;

    return Align(
      alignment: Alignment.bottomCenter,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: _w,
          height: _h,
          child: AnimatedBuilder(
            animation: _fx,
            builder: (_, __) {
              final tFx = _fx.value;
              final tBlend = smoothstep(blend.t);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // BASE: due immagini sovrapposte, stessa posizione, stessa scala
                  Opacity(
                    opacity: 1 - tBlend,
                    child: Image.asset(
                      blend.a,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                  Opacity(
                    opacity: tBlend,
                    child: Image.asset(
                      blend.b,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),

                  // OVERLAY: nebbia del mattino (solo sunrise -> primo day)
                  if (mist > 0.001)
                    CustomPaint(
                      painter: MistPainter(
                        t: tFx,
                        intensity: mist,
                      ),
                    ),

                  // OVERLAY: luce lanterna (flicker) vicino all’ingresso
                  if (glow > 0.001)
                    CustomPaint(
                      painter: LanternGlowPainter(
                        t: tFx,
                        intensity: glow,
                      ),
                    ),

                  // OVERLAY: polvere/particelle vicino miniera
                  if (dust > 0.001)
                    CustomPaint(
                      painter: DustPainter(
                        t: tFx,
                        intensity: dust,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ---------- TIME BLEND (4 fasi) ----------

class _Blend {
  final String a;
  final String b;
  final double t; // 0..1
  const _Blend(this.a, this.b, this.t);
}

_Blend _computeBlend(DateTime now) {
  const sunrise = 'assets/images/bg/mine_sunrise.png';
  const day = 'assets/images/bg/mine_day.png';
  const sunset = 'assets/images/bg/mine_sunset.png';
  const night = 'assets/images/bg/mine_night.png';

  final m = now.hour * 60 + now.minute;

  // Personalizza qui le fasce come vuoi (minuti da mezzanotte)
  const sunriseStart = 6 * 60;      // 06:00
  const sunriseEnd   = 8 * 60;      // 08:00
  const sunsetStart  = 17 * 60;     // 17:00
  const sunsetEnd    = 19 * 60;     // 19:00
  const nightStart   = 20 * 60 + 30; // 20:30

  // sunrise -> day
  if (m >= sunriseStart && m < sunriseEnd) {
    final t = (m - sunriseStart) / (sunriseEnd - sunriseStart);
    return _Blend(sunrise, day, t);
  }

  // day fisso
  if (m >= sunriseEnd && m < sunsetStart) {
    return const _Blend(day, day, 0);
  }

  // day -> sunset
  if (m >= sunsetStart && m < sunsetEnd) {
    final t = (m - sunsetStart) / (sunsetEnd - sunsetStart);
    return _Blend(day, sunset, t);
  }

  // sunset -> night (tramonto lungo “cinema”)
  if (m >= sunsetEnd && m < nightStart) {
    final t = (m - sunsetEnd) / (nightStart - sunsetEnd);
    return _Blend(sunset, night, t);
  }

  // night fisso (anche dopo mezzanotte)
  return const _Blend(night, night, 0);
}

double smoothstep(double t) => t * t * (3 - 2 * t);
double clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

double _nightness(DateTime now) {
  // 0..1: più è notte, più aumentano glow/dust
  final m = now.hour * 60 + now.minute;
  const nightFrom = 19 * 60; // 19:00
  const nightTo   = 23 * 60; // 23:00
  if (m <= nightFrom) return 0;
  if (m >= nightTo) return 1;
  return smoothstep((m - nightFrom) / (nightTo - nightFrom));
}

double _mistIntensity(DateTime now) {
  // Nebbia: forte al mattino, sparisce verso tarda mattina
  final m = now.hour * 60 + now.minute;
  const mistFrom = 6 * 60;   // 06:00
  const mistTo   = 10 * 60;  // 10:00
  if (m < mistFrom) return 0;
  if (m > mistTo) return 0;
  final x = 1 - (m - mistFrom) / (mistTo - mistFrom); // decrescente
  return smoothstep(clamp01(x)) * 0.9;
}

/// ---------- OVERLAY PAINTERS (NO ASSET, NO TAGLI) ----------

double _hash01(int n) {
  // pseudo-random deterministico 0..1
  n = (n ^ 0xA3C59AC3) * 2654435761;
  n = (n ^ (n >> 16)) * 2246822519;
  n = (n ^ (n >> 13)) * 3266489917;
  n = n ^ (n >> 16);
  return (n & 0xFFFFFF) / 0xFFFFFF;
}

class LanternGlowPainter extends CustomPainter {
  final double t;         // 0..1 (loop)
  final double intensity; // 0..1
  LanternGlowPainter({required this.t, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    // POSIZIONE luce: tarata per l’immagine (modifica se vuoi)
    final glowCenter = Offset(size.width * 0.62, size.height * 0.74);

    // Flicker “organico” (niente random a scatti)
    final flicker =
        0.75 +
        0.15 * math.sin(t * math.pi * 2 * 3.0) +
        0.10 * math.sin(t * math.pi * 2 * 7.0);
    final a = clamp01(intensity * flicker);

    final r1 = size.width * 0.09;
    final r2 = size.width * 0.20;

    final paint = Paint()
      ..isAntiAlias = false
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        colors: [
          Color.lerp(
            const Color(0x00FFD08A),
            const Color(0xCCFFD08A),
            a,
          )!,
          const Color(0x00000000),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: r2));

    canvas.drawCircle(glowCenter, r2, paint);

    // piccolo “core” più caldo
    final core = Paint()
      ..isAntiAlias = false
      ..blendMode = BlendMode.screen
      ..color = Color.fromARGB((160 * a).round(), 255, 220, 160);
    canvas.drawCircle(glowCenter, r1, core);
  }

  @override
  bool shouldRepaint(covariant LanternGlowPainter old) =>
      old.t != t || old.intensity != intensity;
}

class MistPainter extends CustomPainter {
  final double t;
  final double intensity;
  MistPainter({required this.t, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..blendMode = BlendMode.screen;

    // fascia nebbia vicino all'orizzonte della foresta
    final baseY = size.height * 0.42;
    final bandH = size.height * 0.18;

    // Disegno “blobs” a blocchetti (look pixel)
    const blobs = 48;
    for (int i = 0; i < blobs; i++) {
      final p = _hash01(i * 97);
      final q = _hash01(i * 193);

      final speed = 0.02 + 0.05 * q;
      final x = (p + t * speed) % 1.0;

      final y = baseY + (q - 0.5) * bandH * 0.55;
      final w = size.width * (0.10 + 0.18 * _hash01(i * 311));
      final h = bandH * (0.10 + 0.18 * _hash01(i * 431));

      final alpha = (18 + (55 * intensity).round());
      paint.color = Color.fromARGB(alpha, 220, 235, 255);

      // pixel blocks (rettangoli)
      final rect = Rect.fromLTWH(
        x * size.width - w * 0.5,
        y,
        w,
        h,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MistPainter old) =>
      old.t != t || old.intensity != intensity;
}

class DustPainter extends CustomPainter {
  final double t;
  final double intensity;
  DustPainter({required this.t, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..blendMode = BlendMode.screen;

    // Area spawn vicino all’ingresso miniera
    final origin = Offset(size.width * 0.55, size.height * 0.78);
    final areaW = size.width * 0.20;
    final areaH = size.height * 0.10;

    // particelle: quadrettini 1..3 px
    const count = 120;
    for (int i = 0; i < count; i++) {
      final a = _hash01(i * 101);
      final b = _hash01(i * 503);

      // fase personale per ogni particella
      final phase = (t + a) % 1.0;

      final x = origin.dx + (a - 0.5) * areaW;
      final y = origin.dy - phase * areaH - (b * 22);

      final sizePx = 1 + (3 * _hash01(i * 887)).floor();
      final alpha = (255 * intensity * (1 - phase) * 0.25).round().clamp(0, 80);

      paint.color = Color.fromARGB(alpha, 255, 235, 200);

      // “pixel” = rettangolo
      canvas.drawRect(
        Rect.fromLTWH(x, y, sizePx.toDouble(), sizePx.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DustPainter old) =>
      old.t != t || old.intensity != intensity;
}
