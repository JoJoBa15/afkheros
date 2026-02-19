import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Sfondo "My Path" con:
/// - 4 PNG base (sunrise/day/sunset/night) in crossfade
/// - cielo procedurale a bande pixel + stelle (night twinkle)
/// - sole/luna che si muovono in base all'orario
/// - nuvole procedurali (no asset)
/// - foglie che cadono (day>night)
/// - nebbia al mattino (sunrise)
/// - glow lanterna che sfarfalla (night)
/// - polvere vicino all'ingresso miniera (night>day)
///
/// API compatibile con il tuo progetto: MyPathBackground({ parallaxOffset })
class MyPathBackground extends StatefulWidget {
  final double parallaxOffset; // puoi collegarlo a scroll/drag in futuro
  const MyPathBackground({super.key, this.parallaxOffset = 0});

  @override
  State<MyPathBackground> createState() => _MyPathBackgroundState();
}

class _MyPathBackgroundState extends State<MyPathBackground>
    with TickerProviderStateMixin {
  static const _w = 1024.0;
  static const _h = 1536.0;

  late final AnimationController _anim;
  late final Timer _clock;

  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();

    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blend = _computeBlend(_now);
    final night = _nightness(_now);        // 0..1
    final mist = _mistIntensity(_now);     // 0..1
    final dusk = _duskIntensity(_now);     // 0..1 (tramonto/prime ore notte)

    // intensità effetti (tweak qui se vuoi)
    final glow = lerpDouble(0.10, 0.95, night)!;              // lanterna
    final dust = lerpDouble(0.14, 0.55, night)!;              // polvere
    final leaves = lerpDouble(0.55, 0.18, night)!;            // foglie
    final clouds = (1.0 - night).clamp(0.0, 1.0) * 0.90;       // nuvole
    final stars = night;                                      // stelle

    return Align(
      alignment: Alignment.bottomCenter,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: _w,
          height: _h,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              final t = _anim.value; // 0..1 loop

              // Micro “idle parallax” anche se parallaxOffset=0 (molto leggero)
              final idle =
                  0.25 * math.sin(t * math.pi * 2 * 0.35) +
                  0.18 * math.sin(t * math.pi * 2 * 0.11);
              final p = widget.parallaxOffset + idle;

              final tt = smoothstep(blend.t);

              return RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1) Cielo + stelle
                    CustomPaint(
                      painter: PixelSkyPainter(
                        now: _now,
                        t: t,
                        parallax: p,
                        stars: stars,
                      ),
                    ),

                    // 2) Sole/Luna
                    CustomPaint(
                      painter: SunMoonPainter(
                        now: _now,
                        t: t,
                        parallax: p,
                      ),
                    ),

                    // 3) Nuvole (procedurali, no asset)
                    if (clouds > 0.001)
                      CustomPaint(
                        painter: CloudsPainter(
                          t: t,
                          intensity: clouds,
                          parallax: p,
                        ),
                      ),

                    // 4) Foglie (in primo piano)
                    if (leaves > 0.001)
                      CustomPaint(
                        painter: LeavesPainter(
                          t: t,
                          intensity: leaves,
                          parallax: p,
                        ),
                      ),

                    // 5) Miniera (crossfade)
                    Opacity(
                      opacity: 1 - tt,
                      child: Image.asset(
                        blend.a,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                    Opacity(
                      opacity: tt,
                      child: Image.asset(
                        blend.b,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.none,
                      ),
                    ),

                    // 6) Nebbia mattutina
                    if (mist > 0.001)
                      CustomPaint(
                        painter: MistPainter(
                          t: t,
                          intensity: mist,
                          parallax: p,
                        ),
                      ),

                    // 7) Glow lanterna
                    if (glow > 0.001)
                      CustomPaint(
                        painter: LanternGlowPainter(
                          t: t,
                          intensity: glow,
                          parallax: p,
                        ),
                      ),

                    // 8) Polvere vicino ingresso miniera
                    if (dust > 0.001)
                      CustomPaint(
                        painter: DustPainter(
                          t: t,
                          intensity: dust,
                          parallax: p,
                        ),
                      ),

                    // 9) Lucciole (tramonto/sera)
                    if (dusk > 0.001)
                      CustomPaint(
                        painter: FirefliesPainter(
                          t: t,
                          intensity: dusk,
                          parallax: p,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ------------------- TIME BLEND (4 PNG) -------------------

class _Blend {
  final String a, b;
  final double t;
  const _Blend(this.a, this.b, this.t);
}

_Blend _computeBlend(DateTime now) {
  const sunrise = 'assets/images/bg/mine_sunrise.png';
  const day = 'assets/images/bg/mine_day.png';
  const sunset = 'assets/images/bg/mine_sunset.png';
  const night = 'assets/images/bg/mine_night.png';

  final m = now.hour * 60 + now.minute;

  const sunriseStart = 6 * 60, sunriseEnd = 8 * 60;
  const sunsetStart = 17 * 60, sunsetEnd = 19 * 60;
  const nightStart = 20 * 60 + 30;

  if (m >= sunriseStart && m < sunriseEnd) {
    return _Blend(
      sunrise,
      day,
      (m - sunriseStart) / (sunriseEnd - sunriseStart),
    );
  }
  if (m >= sunriseEnd && m < sunsetStart) return const _Blend(day, day, 0);

  if (m >= sunsetStart && m < sunsetEnd) {
    return _Blend(
      day,
      sunset,
      (m - sunsetStart) / (sunsetEnd - sunsetStart),
    );
  }

  if (m >= sunsetEnd && m < nightStart) {
    return _Blend(
      sunset,
      night,
      (m - sunsetEnd) / (nightStart - sunsetEnd),
    );
  }

  return const _Blend(night, night, 0);
}

double _nightness(DateTime now) {
  final m = now.hour * 60 + now.minute;
  const nightFrom = 19 * 60;
  const nightTo = 23 * 60;
  final t = (m - nightFrom) / (nightTo - nightFrom);
  return smoothstep(t.clamp(0.0, 1.0));
}

double _mistIntensity(DateTime now) {
  final m = now.hour * 60 + now.minute;
  const mistFrom = 6 * 60, mistTo = 10 * 60;
  if (m < mistFrom || m > mistTo) return 0;
  final x = 1 - (m - mistFrom) / (mistTo - mistFrom);
  return smoothstep(x.clamp(0.0, 1.0)) * 0.9;
}

/// Lucciole: da ~18:00 a ~23:00 (picco 20:30)
double _duskIntensity(DateTime now) {
  final m = now.hour * 60 + now.minute;
  const from = 18 * 60;
  const peak = 20 * 60 + 30;
  const to = 23 * 60;

  if (m < from || m > to) return 0;

  if (m <= peak) {
    final t = (m - from) / (peak - from);
    return smoothstep(t.clamp(0.0, 1.0)) * 0.75;
  } else {
    final t = 1 - (m - peak) / (to - peak);
    return smoothstep(t.clamp(0.0, 1.0)) * 0.75;
  }
}

/// ------------------- SKY + STARS -------------------

class PixelSkyPainter extends CustomPainter {
  final DateTime now;
  final double t;
  final double parallax;
  final double stars;

  PixelSkyPainter({
    required this.now,
    required this.t,
    required this.parallax,
    required this.stars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scheme = _skyScheme(now);

    // Bande pixel (niente gradient smooth)
    const bands = 44;
    final yShift = (parallax * 6).roundToDouble();
    for (int i = 0; i < bands; i++) {
      final u = i / (bands - 1);
      final c = Color.lerp(scheme.top, scheme.bottom, u)!;
      final y0 = (u * size.height + yShift).roundToDouble();
      final y1 = (((i + 1) / (bands - 1)) * size.height + yShift).roundToDouble();
      canvas.drawRect(
        Rect.fromLTWH(0, y0, size.width, (y1 - y0).abs() + 2),
        Paint()..color = c..isAntiAlias = false,
      );
    }

    // Stelle (procedurali) con micro twinkle
    if (stars > 0.01) {
      final tw = 0.85 + 0.15 * math.sin(t * math.pi * 2 * 2.0);
      final alpha = (95 * stars * tw).round().clamp(0, 140);
      final p = Paint()
        ..color = Color.fromARGB(alpha, 255, 255, 255)
        ..isAntiAlias = false;

      // Parallax minimo (stelle quasi ferme)
      final xShift = (parallax * 2);
      for (int i = 0; i < 72; i++) {
        final x = (_hash1(i * 97) * size.width + xShift) % size.width;
        final y = _hash1(i * 53) * (size.height * 0.55);
        canvas.drawRect(
          Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), 2, 2),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelSkyPainter old) =>
      old.now.minute != now.minute ||
      old.t != t ||
      old.parallax != parallax ||
      old.stars != stars;
}

class _SkyScheme {
  final Color top, bottom;
  const _SkyScheme(this.top, this.bottom);
}

_SkyScheme _skyScheme(DateTime now) {
  final m = now.hour * 60 + now.minute;

  if (m >= 6 * 60 && m < 8 * 60) {
    return const _SkyScheme(Color(0xFF2B2D6E), Color(0xFFFFB36A)); // sunrise
  }
  if (m >= 8 * 60 && m < 17 * 60) {
    return const _SkyScheme(Color(0xFF4CA7FF), Color(0xFFBFE8FF)); // day
  }
  if (m >= 17 * 60 && m < 20 * 60 + 30) {
    return const _SkyScheme(Color(0xFF3A2C6E), Color(0xFFFF7A59)); // sunset
  }
  return const _SkyScheme(Color(0xFF0B1026), Color(0xFF151B35)); // night
}

/// ------------------- SUN / MOON -------------------

class SunMoonPainter extends CustomPainter {
  final DateTime now;
  final double t;
  final double parallax;

  SunMoonPainter({required this.now, required this.t, required this.parallax});

  @override
  void paint(Canvas canvas, Size size) {
    final m = now.hour * 60 + now.minute;
    const rise = 6 * 60, set = 20 * 60 + 30;
    final isSun = m >= rise && m <= set;

    if (isSun) {
      final u = ((m - rise) / (set - rise)).clamp(0.0, 1.0);

      // arco solare: x scorre, y fa una "U" invertita
      final x = (lerpDouble(-0.1, 1.1, u)! * size.width) + parallax * 3;
      final peak = size.height * 0.16;
      final base = size.height * 0.42;
      final y = (base - math.sin(math.pi * u) * (base - peak)) + parallax * 2;

      final wobble = 0.98 + 0.02 * math.sin(t * math.pi * 2 * 3.0);
      final r = (size.width * 0.045 * wobble).roundToDouble();
      final center = Offset(x.roundToDouble(), y.roundToDouble());

      final glow = Paint()
        ..isAntiAlias = false
        ..blendMode = BlendMode.screen
        ..shader = const RadialGradient(
          colors: [Color(0x66FFD27A), Color(0x00FFD27A)],
        ).createShader(Rect.fromCircle(center: center, radius: r * 4));
      canvas.drawCircle(center, r * 4, glow);

      canvas.drawRect(
        Rect.fromLTWH(
          (center.dx - r).roundToDouble(),
          (center.dy - r).roundToDouble(),
          (2 * r).roundToDouble(),
          (2 * r).roundToDouble(),
        ),
        Paint()..color = const Color(0xFFFFD27A)..isAntiAlias = false,
      );
    } else {
      final night = _nightness(now);
      if (night < 0.05) return;

      final x = (size.width * 0.18 + parallax * 2).roundToDouble();
      final y = (size.height * 0.22 + parallax * 2).roundToDouble();
      final center = Offset(x, y);

      final r = (size.width * 0.035).roundToDouble();
      final alpha = (150 * night).round().clamp(0, 150);

      canvas.drawRect(
        Rect.fromLTWH(
          (center.dx - r).roundToDouble(),
          (center.dy - r).roundToDouble(),
          (2 * r).roundToDouble(),
          (2 * r).roundToDouble(),
        ),
        Paint()
          ..color = Color.fromARGB(alpha, 220, 230, 255)
          ..isAntiAlias = false,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SunMoonPainter old) =>
      old.now.minute != now.minute || old.t != t || old.parallax != parallax;
}

/// ------------------- CLOUDS (procedurali) -------------------

class CloudsPainter extends CustomPainter {
  final double t;
  final double intensity;
  final double parallax;

  CloudsPainter({
    required this.t,
    required this.intensity,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // “pixel clouds”: gruppi di rettangoli, 3 layer con velocità diversa
    final basePaint = Paint()
      ..isAntiAlias = false
      ..color = Color.fromARGB((40 * intensity).round().clamp(0, 70), 240, 248, 255);

    _layer(canvas, size, basePaint, y: 0.16, speed: 0.06, scale: 1.15, par: 0.35, seed: 10);
    _layer(canvas, size, basePaint, y: 0.12, speed: 0.09, scale: 1.00, par: 0.50, seed: 20);
    _layer(canvas, size, basePaint, y: 0.20, speed: 0.04, scale: 1.30, par: 0.25, seed: 30);
  }

  void _layer(Canvas canvas, Size size, Paint paint,
      {required double y, required double speed, required double scale, required double par, required int seed}) {
    for (int i = 0; i < 3; i++) {
      final baseX = _hash1(seed + i * 17) * (size.width + 500) - 250;
      final x = (baseX + t * (size.width * speed) + parallax * 10 * par) % (size.width + 500) - 250;
      final cy = (size.height * y + (i - 1) * 16 + parallax * 3 * par).roundToDouble();

      _cloud(canvas, Offset(x, cy), scale: scale, paint: paint, seed: seed + i * 101);
    }
  }

  void _cloud(Canvas canvas, Offset c, {required double scale, required Paint paint, required int seed}) {
    final s = 14.0 * scale;
    // pattern a blocchi (stile pixel)
    final blocks = <Offset>[
      const Offset(-3, 0),
      const Offset(-2, -1),
      const Offset(-1, -2),
      const Offset(0, -2),
      const Offset(1, -2),
      const Offset(2, -1),
      const Offset(3, 0),
      const Offset(-2, 1),
      const Offset(-1, 1),
      const Offset(0, 1),
      const Offset(1, 1),
      const Offset(2, 1),
    ];

    final jitter = (_hash1(seed) - 0.5) * 6;
    for (final b in blocks) {
      final w = s + (_hash1(seed + b.dx.toInt() * 13 + b.dy.toInt() * 7) * 6);
      final h = s * 0.75;
      canvas.drawRect(
        Rect.fromLTWH(
          (c.dx + (b.dx * s) + jitter).roundToDouble(),
          (c.dy + (b.dy * s * 0.6)).roundToDouble(),
          w.roundToDouble(),
          h.roundToDouble(),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CloudsPainter old) =>
      old.t != t || old.intensity != intensity || old.parallax != parallax;
}

/// ------------------- LEAVES -------------------

class LeavesPainter extends CustomPainter {
  final double t;
  final double intensity;
  final double parallax;

  LeavesPainter({
    required this.t,
    required this.intensity,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = (90 * intensity).round().clamp(20, 120);
    final p = Paint()..isAntiAlias = false;

    final palette = <Color>[
      const Color(0xFFD54B2E),
      const Color(0xFFE7A93A),
      const Color(0xFFB5482F),
    ];

    for (int i = 0; i < count; i++) {
      final a = _hash1(i * 101);
      final b = _hash1(i * 503);
      final phase = (t + a) % 1.0;

      final xBase = a * size.width;
      final drift = math.sin((phase + b) * math.pi * 2) * (18 + 22 * b);
      final x = xBase + drift + parallax * 6;
      final y = phase * size.height * 0.78 + (b * 70) + parallax * 3;

      final c = palette[(i + (b * 10).floor()) % palette.length];
      final alpha = (160 * intensity * (1 - phase)).round().clamp(0, 160);
      p.color = c.withAlpha(alpha);

      final s = 2 + (3 * _hash1(i * 887)).floor(); // 2..5 px
      canvas.drawRect(
        Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), s.toDouble(), s.toDouble()),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LeavesPainter old) =>
      old.t != t || old.intensity != intensity || old.parallax != parallax;
}

/// ------------------- MIST -------------------

class MistPainter extends CustomPainter {
  final double t;
  final double intensity;
  final double parallax;

  MistPainter({
    required this.t,
    required this.intensity,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * 0.40 + parallax * 3;
    final bandH = size.height * 0.22;

    final paint = Paint()
      ..isAntiAlias = false
      ..blendMode = BlendMode.screen;

    const layers = 4;
    for (int layer = 0; layer < layers; layer++) {
      final layerT = (t * (0.10 + layer * 0.04)) % 1.0;
      final alpha = (10 + 22 * intensity).round().clamp(0, 45);
      paint.color = Color.fromARGB(alpha, 220, 235, 255);

      final stripes = 10 + layer * 3;
      for (int i = 0; i < stripes; i++) {
        final w = size.width * (0.35 + 0.2 * _hash1((layer + 1) * 1000 + i * 31));
        final x = ((i / stripes) * size.width + layerT * 120 + parallax * 3) % (size.width + w) - w;
        final y = baseY + (i / stripes - 0.5) * bandH * 0.35 + layer * 10;
        final h = 18 + (12 * _hash1((layer + 1) * 2000 + i * 77)).round();

        canvas.drawRect(
          Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), w.roundToDouble(), h.toDouble()),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MistPainter old) =>
      old.t != t || old.intensity != intensity || old.parallax != parallax;
}

/// ------------------- LANTERN GLOW -------------------

class LanternGlowPainter extends CustomPainter {
  final double t;
  final double intensity;
  final double parallax;

  LanternGlowPainter({
    required this.t,
    required this.intensity,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // posizione glow: tarata sulla tua scena miniera
    final glowCenter = Offset(
      size.width * 0.62 + parallax * 2,
      size.height * 0.74 + parallax * 1.5,
    );

    final flicker =
        0.80 +
        math.sin(t * math.pi * 2 * 2.1) * 0.15 +
        math.sin(t * math.pi * 2 * 5.7) * 0.08 +
        math.sin(t * math.pi * 2 * 13.3) * 0.05;

    final a = (intensity * flicker).clamp(0.0, 1.0);

    final rOuter = size.width * 0.22;
    final rInner = size.width * 0.08;

    final paint = Paint()
      ..isAntiAlias = false
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0x00FFD08A), const Color(0xAAFFB05A), a)!,
          const Color(0x00000000),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: rOuter));

    canvas.drawCircle(glowCenter, rOuter, paint);

    final corePaint = Paint()
      ..isAntiAlias = false
      ..blendMode = BlendMode.plus
      ..color = Color.fromARGB((200 * a).round(), 255, 230, 180);

    canvas.drawCircle(glowCenter, rInner, corePaint);
  }

  @override
  bool shouldRepaint(covariant LanternGlowPainter old) =>
      old.t != t || old.intensity != intensity || old.parallax != parallax;
}

/// ------------------- DUST -------------------

class DustPainter extends CustomPainter {
  final double t;
  final double intensity;
  final double parallax;

  DustPainter({
    required this.t,
    required this.intensity,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // area spawn vicino ingresso miniera
    final origin = Offset(
      size.width * 0.55 + parallax * 2,
      size.height * 0.78 + parallax * 1.5,
    );

    final areaW = size.width * 0.22;
    final areaH = size.height * 0.12;

    final paint = Paint()
      ..isAntiAlias = false
      ..blendMode = BlendMode.screen;

    const count = 110;
    for (int i = 0; i < count; i++) {
      final a = _hash1(i * 101);
      final b = _hash1(i * 503);
      final phase = (t + a) % 1.0;

      final x = origin.dx + (a - 0.5) * areaW + math.sin((phase + b) * math.pi * 2) * 8;
      final y = origin.dy - phase * areaH - (b * 18);

      final sizePx = 1 + (3 * _hash1(i * 887)).floor(); // 1..3
      final alpha = (255 * intensity * (1 - phase) * 0.22).round().clamp(0, 70);

      paint.color = Color.fromARGB(alpha, 255, 235, 200);
      canvas.drawRect(Rect.fromLTWH(x, y, sizePx.toDouble(), sizePx.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(covariant DustPainter old) =>
      old.t != t || old.intensity != intensity || old.parallax != parallax;
}

/// ------------------- FIREFLIES -------------------

class FirefliesPainter extends CustomPainter {
  final double t;
  final double intensity;
  final double parallax;

  FirefliesPainter({
    required this.t,
    required this.intensity,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = false
      ..blendMode = BlendMode.screen;

    // zona: davanti alla foresta / sopra il sentiero
    final box = Rect.fromLTWH(
      size.width * 0.10 + parallax * 2,
      size.height * 0.40 + parallax * 2,
      size.width * 0.80,
      size.height * 0.28,
    );

    const n = 12;
    for (int i = 0; i < n; i++) {
      final a = _hash1(9000 + i * 37);
      final b = _hash1(9100 + i * 91);
      final sp = 0.10 + 0.25 * b;

      // traiettoria lenta + bobbing
      final u = (t * sp + a) % 1.0;
      final x = box.left + u * box.width;
      final y = box.top + (0.5 + 0.35 * math.sin((u + b) * math.pi * 2)) * box.height;

      // blink
      final blink = 0.25 + 0.75 * (0.5 + 0.5 * math.sin((t + a) * math.pi * 2 * (2.0 + 2.0 * b)));
      final alpha = (120 * intensity * blink).round().clamp(0, 140);

      paint.color = Color.fromARGB(alpha, 255, 240, 170);

      // pixel dot + tiny glow
      canvas.drawRect(
        Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), 2, 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FirefliesPainter old) =>
      old.t != t || old.intensity != intensity || old.parallax != parallax;
}

/// ------------------- UTILS -------------------

double _hash1(int n) {
  n = (n ^ 0xA3C59AC3) * 2654435761;
  n = (n ^ (n >> 16)) * 2246822519;
  n = (n ^ (n >> 13)) * 3266489917;
  n = n ^ (n >> 16);
  return (n & 0xFFFFFF) / 0xFFFFFF;
}

double smoothstep(double t) => t * t * (3 - 2 * t);
