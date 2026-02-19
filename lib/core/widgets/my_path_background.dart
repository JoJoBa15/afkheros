import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Background di My Path: cielo procedurale + sole/luna + crossfade miniera + overlay (nebbia, glow).
class MyPathBackground extends StatefulWidget {
  final double parallaxOffset;

  const MyPathBackground({
    super.key,
    this.parallaxOffset = 0,
  });

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
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();

    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
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
    final mineBlend = _computeBlend(_now);
    final nightness = _nightness(_now);
    final mist = _mistIntensity(_now);

    // ✅ FIX “sfondo tagliato”:
    // prima era Align(bottom) + FittedBox(fitWidth) => su schermi alti resta banda sopra.
    // adesso: SizedBox.expand + FittedBox(cover) => copre TUTTO lo schermo, ancorato in basso.
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: _w,
            height: _h,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) {
                final t = _anim.value;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1) Cielo (procedurale)
                    CustomPaint(
                      painter: PixelSkyPainter(
                        now: _now,
                        parallax: widget.parallaxOffset,
                      ),
                    ),

                    // 2) Sole/Luna (procedurale)
                    CustomPaint(
                      painter: SunMoonPainter(
                        now: _now,
                        t: t,
                        parallax: widget.parallaxOffset,
                      ),
                    ),

                    // 3) Nuvole (commentato finché non hai l’asset)
                    /*
                    Opacity(
                      opacity: (1.0 - nightness).clamp(0.0, 1.0),
                      child: _CloudLayer(t: t, parallax: widget.parallaxOffset),
                    ),
                    */

                    // 4) Miniera (immagini)
                    Opacity(
                      opacity: 1 - smoothstep(mineBlend.t),
                      child: Image.asset(
                        mineBlend.a,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                    Opacity(
                      opacity: smoothstep(mineBlend.t),
                      child: Image.asset(
                        mineBlend.b,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.none,
                      ),
                    ),

                    // 5) OVERLAYS
                    if (mist > 0.001)
                      CustomPaint(painter: MistPainter(t: t, intensity: mist)),

                    if (nightness > 0.001)
                      CustomPaint(
                        painter: LanternGlowPainter(
                          t: t,
                          intensity: nightness,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// --- Logica Temporale & Blend Miniera ---

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

// --- Painters Procedurali per il Cielo ---

class PixelSkyPainter extends CustomPainter {
  final DateTime now;
  final double parallax;

  PixelSkyPainter({
    required this.now,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final yShift = (parallax * 10).roundToDouble();

    final scheme = _skyScheme(now);

    const bands = 40;
    for (int i = 0; i < bands; i++) {
      final t = i / (bands - 1);
      final c = Color.lerp(scheme.top, scheme.bottom, t)!;

      final y0 = (t * h + yShift).roundToDouble();
      final y1 = (((i + 1) / (bands - 1)) * h + yShift).roundToDouble();

      final rect = Rect.fromLTWH(
        0,
        y0,
        size.width,
        (y1 - y0).abs() + 2,
      );

      canvas.drawRect(
        rect,
        Paint()
          ..color = c
          ..isAntiAlias = false,
      );
    }

    final night = _nightness(now);
    if (night > 0.05) {
      final p = Paint()
        ..color = Color.fromARGB((80 * night).round(), 255, 255, 255)
        ..isAntiAlias = false;

      for (int i = 0; i < 60; i++) {
        final x = _hash1(i * 97) * size.width;
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
      old.now.minute != now.minute || old.parallax != parallax;
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

class SunMoonPainter extends CustomPainter {
  final DateTime now;
  final double t;
  final double parallax;

  SunMoonPainter({
    required this.now,
    required this.t,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final m = now.hour * 60 + now.minute;

    const rise = 6 * 60, set = 20 * 60 + 30;
    final isDaySun = m >= rise && m <= set;

    final center = isDaySun
        ? _sunPos(size, m, rise, set, parallax)
        : _moonPos(size, m, parallax);

    final night = _nightness(now);

    if (isDaySun) {
      final wobble = 0.98 + 0.02 * math.sin(t * math.pi * 2 * 3.0);
      final r = (size.width * 0.045 * wobble).roundToDouble();

      final glow = Paint()
        ..isAntiAlias = false
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: [
            const Color(0x66FFD27A),
            const Color(0x00FFD27A),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 4));

      canvas.drawCircle(center, r * 4, glow);

      canvas.drawRect(
        Rect.fromLTWH(
          (center.dx - r).roundToDouble(),
          (center.dy - r).roundToDouble(),
          (2 * r).roundToDouble(),
          (2 * r).roundToDouble(),
        ),
        Paint()
          ..color = const Color(0xFFFFD27A)
          ..isAntiAlias = false,
      );
    } else {
      final r = (size.width * 0.035).roundToDouble();
      final alpha = (150 * night).round().clamp(0, 150);

      final paint = Paint()
        ..color = Color.fromARGB(alpha, 220, 230, 255)
        ..isAntiAlias = false;

      canvas.drawRect(
        Rect.fromLTWH(
          (center.dx - r).roundToDouble(),
          (center.dy - r).roundToDouble(),
          (2 * r).roundToDouble(),
          (2 * r).roundToDouble(),
        ),
        paint,
      );
    }
  }

  Offset _sunPos(Size size, int m, int rise, int set, double parallax) {
    final tt = ((m - rise) / (set - rise)).clamp(0.0, 1.0);
    final x = lerpDouble(-0.1, 1.1, tt)! * size.width;

    final peak = size.height * 0.18;
    final base = size.height * 0.42;
    final y =
        (base - math.sin(math.pi * tt) * (base - peak)) + parallax * 6;

    return Offset(x.roundToDouble(), y.roundToDouble());
  }

  Offset _moonPos(Size size, int m, double parallax) {
    final x = (size.width * 0.18 + parallax * 4).roundToDouble();
    final y = (size.height * 0.22 + parallax * 6).roundToDouble();
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant SunMoonPainter old) =>
      old.now.minute != now.minute || old.t != t || old.parallax != parallax;
}

// --- Painters per Overlay (Lantern, Mist) ---

class LanternGlowPainter extends CustomPainter {
  final double t;
  final double intensity;

  LanternGlowPainter({
    required this.t,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glowCenter = Offset(size.width * 0.62, size.height * 0.74);

    final flicker = 0.8 +
        math.sin(t * math.pi * 2 * 2.1) * 0.15 +
        math.sin(t * math.pi * 2 * 5.7) * 0.08 +
        math.sin(t * math.pi * 2 * 13.3) * 0.05;

    final a = (intensity * flicker).clamp(0.0, 1.0);

    final rOuter = size.width * 0.22;
    final rInner = size.width * 0.08;

    final paint = Paint()
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
      ..blendMode = BlendMode.plus
      ..color = Color.fromARGB((200 * a).round(), 255, 230, 180);

    canvas.drawCircle(glowCenter, rInner, corePaint);
  }

  @override
  bool shouldRepaint(covariant LanternGlowPainter old) =>
      old.t != t || old.intensity != intensity;
}

class MistPainter extends CustomPainter {
  final double t;
  final double intensity;

  MistPainter({
    required this.t,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    final baseY = size.height * 0.42;
    final bandH = size.height * 0.18;

    const blobs = 48;
    for (int i = 0; i < blobs; i++) {
      final p = _hash1(i * 97);
      final q = _hash1(i * 193);

      final speed = 0.02 + 0.05 * q;
      final x = (p + t * speed) % 1.0;

      final y = baseY + (q - 0.5) * bandH * 0.55;

      final w = size.width * (0.10 + 0.18 * _hash1(i * 311));
      final h = bandH * (0.10 + 0.18 * _hash1(i * 431));

      final alpha = (18 + (55 * intensity).round());
      paint.color = Color.fromARGB(alpha, 220, 235, 255);

      canvas.drawRect(
        Rect.fromLTWH(x * size.width - w * 0.5, y, w, h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MistPainter old) =>
      old.t != t || old.intensity != intensity;
}

// --- Utility ---

double _hash1(int n) {
  n = (n ^ 0xA3C59AC3) * 2654435761;
  n = (n ^ (n >> 16)) * 2246822519;
  n = (n ^ (n >> 13)) * 3266489917;
  n = n ^ (n >> 16);
  return (n & 0xFFFFFF) / 0xFFFFFF;
}

double smoothstep(double t) => t * t * (3 - 2 * t);
