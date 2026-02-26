import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class AppBackground extends StatefulWidget {
  final double dimming;

  const AppBackground({super.key, this.dimming = 0.0});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with TickerProviderStateMixin {
  late final AnimationController _anim;
  Timer? _clock;
  DateTime _now = DateTime.now();
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 30), // Più lento = meno calcoli/cambi
    )..repeat(); 

    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _stars = _StarField.generate(seed: 42, count: 40); // Ridotte per risparmiare CPU
  }

  @override
  void dispose() {
    _clock?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DayPalette.fromNow(_now);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;
        // Ciclo respiro più ampio e calmo
        final breath = (math.sin(t * math.pi * 2 * 2) + 1) / 2; 
        final d = widget.dimming.clamp(0.0, 1.0);

        return CustomPaint(
          painter: _ZenBackgroundPainter(
            palette: palette,
            t: t,
            breath: breath,
            dimming: d,
            stars: _stars,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ZenBackgroundPainter extends CustomPainter {
  final _DayPalette palette;
  final double t, breath, dimming;
  final List<_Star> stars;

  _ZenBackgroundPainter({
    required this.palette,
    required this.t,
    required this.breath,
    required this.dimming,
    required this.stars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. CIELO BASE (Gradienti lineari sono molto ottimizzati)
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: palette.sky,
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    final angle = t * math.pi * 2;

    // 2. BLOBS (Ottimizzati: solo 2 blob + 1 centrale, meno stop)
    
    // Blob A: Superiore
    _drawGlow(canvas, 
      center: Offset(size.width * 0.3 + math.sin(angle * 0.4) * 80, size.height * 0.25 + math.cos(angle * 0.3) * 60),
      radius: size.width * 1.2,
      color: palette.blobA,
      opacity: 0.35 + (breath * 0.05)
    );

    // Blob B: Inferiore
    _drawGlow(canvas, 
      center: Offset(size.width * 0.7 + math.cos(angle * 0.5) * 100, size.height * 0.75 + math.sin(angle * 0.4) * 80),
      radius: size.width * 1.1,
      color: palette.blobB,
      opacity: 0.25 + (breath * 0.1)
    );

    // ✅ GLOW BIANCO CENTRALE (Ridotto stop e raggio)
    _drawGlow(canvas, 
      center: Offset(size.width * 0.5, size.height * 0.5),
      radius: size.width * 0.7 + (breath * 30),
      color: Colors.white,
      opacity: 0.10 + (breath * 0.04)
    );

    // 3. STELLE (Solo se necessario e ottimizzate)
    if (palette.nightThreshold > 0.3) {
      final sAlpha = ((palette.nightThreshold - 0.3) / 0.7).clamp(0.0, 1.0);
      final starPaint = Paint()..style = PaintingStyle.fill;
      for (final s in stars) {
        final sparkle = (0.5 + 0.5 * math.sin(s.phase + t * math.pi * 6)).clamp(0.0, 1.0);
        starPaint.color = Colors.white.withValues(alpha: sAlpha * sparkle * 0.4);
        canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r, starPaint);
      }
    }

    // 4. DIMMING (Semplice rettangolo nero se attivo)
    if (dimming > 0.01) {
      canvas.drawRect(rect, Paint()..color = Colors.black.withValues(alpha: dimming * 0.80));
    }
  }

  // Versione ultra-leggera senza calcoli inutili
  void _drawGlow(Canvas canvas, {required Offset center, required double radius, required Color color, required double opacity}) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.2, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _ZenBackgroundPainter old) => 
    old.t != t || old.breath != breath || old.dimming != dimming || old.palette != palette;
}

class _Star {
  const _Star(this.x, this.y, this.r, this.phase);
  final double x, y, r, phase;
}

class _StarField {
  static List<_Star> generate({required int seed, required int count}) {
    final rnd = math.Random(seed);
    return List.generate(count, (_) => _Star(rnd.nextDouble(), math.pow(rnd.nextDouble(), 2.5).toDouble(), 0.5 + rnd.nextDouble() * 1.0, rnd.nextDouble() * math.pi * 2));
  }
}

class _DayPalette {
  final List<Color> sky;
  final Color blobA, blobB;
  final double nightThreshold;

  _DayPalette({required this.sky, required this.blobA, required this.blobB, required this.nightThreshold});

  static _DayPalette fromNow(DateTime now) {
    final h = now.hour + now.minute / 60.0;
    double intens(double p, double s, double x) => (1.0 - (x - p).abs() / s).clamp(0.0, 1.0);

    final wDawn = intens(6.5, 2.5, h);
    final wAft = intens(16.5, 3.5, h); 
    final wSun = intens(19.5, 2.0, h);
    final wNight = (h < 5.5 || h > 21.5) ? 1.0 : 0.0;

    List<Color> mix(List<Color> a, List<Color> b, double t) => List.generate(a.length, (i) => Color.lerp(a[i], b[i], t)!);

    final sN = [const Color(0xFF02040A), const Color(0xFF080C1E), const Color(0xFF10152B)];
    final sD = [const Color(0xFF1A1F3C), const Color(0xFF4A3B6B), const Color(0xFFFF9E80)];
    final sDay = [const Color(0xFF4CAFFF), const Color(0xFF2D62FF), const Color(0xFF12256E)];
    final sA = [const Color(0xFF5AB9FF), const Color(0xFF6A85FF), const Color(0xFFE89F71)];
    final sS = [const Color(0xFF241A4B), const Color(0xFFFF5E78), const Color(0xFFFFC371)];

    var sky = sDay;
    if (wDawn > 0) sky = mix(sky, sD, wDawn);
    if (wAft > 0) sky = mix(sky, sA, wAft);
    if (wSun > 0) sky = mix(sky, sS, wSun);
    if (wNight > 0.1) sky = mix(sky, sN, 0.85);

    final bA = Color.lerp(const Color(0xFF00FFD0), const Color(0xFFFFB36E), wAft + wSun)!; 
    final bB = Color.lerp(const Color(0xFF5390FF), const Color(0xFFBC70FF), wSun + wAft * 0.4)!; 

    return _DayPalette(sky: sky, blobA: bA, blobB: bB, nightThreshold: wNight + (wSun * 0.4));
  }
}
