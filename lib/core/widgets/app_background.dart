import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Background globale (aurora + blur + stelle solo di notte)
/// - Non dipende da MyPathBackground
/// - Riutilizzabile sotto TUTTE le schermate
class AppBackground extends StatefulWidget {
  /// Quanto scurire il background (0..1).
  ///
  /// Utile per riusare lo stesso sky/aurora ovunque ma con “mood” diverso.
  final double dimming;

  const AppBackground({super.key, this.dimming = 0.0});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  Timer? _clock;
  DateTime _now = DateTime.now();
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 18))
      ..repeat(reverse: true);

    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _stars = _StarField.generate(seed: 42, count: 90);
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
        final d = widget.dimming.clamp(0.0, 1.0);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: palette.sky,
            ),
          ),
          child: Stack(
            children: [
              _AuroraBlobs(t: t, palette: palette),

              if (palette.night > 0.55)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _StarsPainter(
                        stars: _stars,
                        t: t,
                        alpha: (palette.night - 0.55) / (1.0 - 0.55),
                      ),
                    ),
                  ),
                ),

              // Vignette (focus centro)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.12),
                        radius: 1.05,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.32),
                        ],
                        stops: const [0.62, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Scrim top (leggibilità appbar)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ✅ Dimmer globale SEMPRE presente (niente pop)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(
                            alpha: (d * 0.70).clamp(0.0, 1.0),
                          ),
                          Colors.black.withValues(
                            alpha: d,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// AURORA BLOBS
// -----------------------------------------------------------------------------
class _AuroraBlobs extends StatelessWidget {
  const _AuroraBlobs({required this.t, required this.palette});

  final double t;
  final _DayPalette palette;

  @override
  Widget build(BuildContext context) {
    final wob1 = math.sin(t * math.pi * 2);
    final wob2 = math.cos(t * math.pi * 2);
    final wob3 = math.sin((t + 0.33) * math.pi * 2);

    return Stack(
      children: [
        _Blob(
          alignment: Alignment(-0.9 + wob2 * 0.10, -1.05 + wob1 * 0.10),
          sizeFactor: 1.25,
          colors: palette.blobA,
          blurSigma: 46,
        ),
        _Blob(
          alignment: Alignment(0.85 + wob1 * 0.10, -0.55 + wob3 * 0.12),
          sizeFactor: 1.15,
          colors: palette.blobB,
          blurSigma: 50,
        ),
        _Blob(
          alignment: Alignment(-0.18 + wob3 * 0.10, 0.92 + wob2 * 0.10),
          sizeFactor: 1.35,
          colors: palette.blobC,
          blurSigma: 58,
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.alignment,
    required this.sizeFactor,
    required this.colors,
    required this.blurSigma,
  });

  final Alignment alignment;
  final double sizeFactor;
  final List<Color> colors;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diameter = math.max(size.width, size.height) * sizeFactor;

    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: colors,
              stops: const [0.0, 0.65, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STARS
// -----------------------------------------------------------------------------
class _Star {
  const _Star(this.x, this.y, this.r, this.phase);
  final double x; // 0..1
  final double y; // 0..1
  final double r; // px
  final double phase; // 0..2π
}

class _StarField {
  static List<_Star> generate({required int seed, required int count}) {
    final rnd = math.Random(seed);
    return List.generate(count, (_) {
      final x = rnd.nextDouble();
      final y = math.pow(rnd.nextDouble(), 1.6).toDouble();
      final r = 0.6 + rnd.nextDouble() * 1.6;
      final ph = rnd.nextDouble() * math.pi * 2;
      return _Star(x, y, r, ph);
    });
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter({required this.stars, required this.t, required this.alpha});

  final List<_Star> stars;
  final double t;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    for (final s in stars) {
      final tw = (0.65 + 0.35 * math.sin(s.phase + t * math.pi * 2)).clamp(0.0, 1.0);
      final a = (alpha * tw * 0.95).clamp(0.0, 1.0);

      p.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.alpha != alpha;
  }
}

// -----------------------------------------------------------------------------
// PALETTE (sky + aurora)
// -----------------------------------------------------------------------------
class _DayPalette {
  _DayPalette({
    required this.sky,
    required this.blobA,
    required this.blobB,
    required this.blobC,
    required this.night,
  });

  final List<Color> sky;
  final List<Color> blobA;
  final List<Color> blobB;
  final List<Color> blobC;
  final double night;

  static _DayPalette fromNow(DateTime now) {
    final h = now.hour + now.minute / 60.0;

    double smoothstep(double a, double b, double x) {
      final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
      return t * t * (3 - 2 * t);
    }

    final night = 1.0 - smoothstep(6.5, 8.5, h) + smoothstep(18.0, 20.0, h);
    final n = night.clamp(0.0, 1.0);

    // brighter morning window (~6..12)
    final morning =
        (smoothstep(6.0, 8.2, h) * (1.0 - smoothstep(10.8, 12.0, h)))
            .clamp(0.0, 1.0);

    List<Color> lerpCols(List<Color> a, List<Color> b, double t) {
      return List.generate(a.length, (i) => Color.lerp(a[i], b[i], t)!);
    }

    const skyDay = [
      Color(0xFF3E86FF),
      Color(0xFF2759FF),
      Color(0xFF142A66),
    ];
    const skyMorning = [
      Color(0xFF78D7FF),
      Color(0xFF5A9BFF),
      Color(0xFF243A8A),
    ];
    const skyNight = [
      Color(0xFF070812),
      Color(0xFF080A1A),
      Color(0xFF0B0F2B),
    ];

    const blobADay = [
      Color(0xFF5DFFB4),
      Color(0x005DFFB4),
      Color(0x00000000),
    ];
    const blobANight = [
      Color(0xFF35FFB0),
      Color(0x0035FFB0),
      Color(0x00000000),
    ];

    const blobBDay = [
      Color(0xFFFF6EDC),
      Color(0x00FF6EDC),
      Color(0x00000000),
    ];
    const blobBNight = [
      Color(0xFFB35CFF),
      Color(0x00B35CFF),
      Color(0x00000000),
    ];

    const blobCDay = [
      Color(0xFF7CFFE6),
      Color(0x007CFFE6),
      Color(0x00000000),
    ];
    const blobCNight = [
      Color(0xFF4BD4FF),
      Color(0x004BD4FF),
      Color(0x00000000),
    ];

    return _DayPalette(
      sky: lerpCols(lerpCols(skyDay, skyMorning, morning), skyNight, n),
      blobA: lerpCols(blobADay, blobANight, n),
      blobB: lerpCols(blobBDay, blobBNight, n),
      blobC: lerpCols(blobCDay, blobCNight, n),
      night: n,
    );
  }
}