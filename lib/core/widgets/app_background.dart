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

class _AppBackgroundState extends State<AppBackground> with SingleTickerProviderStateMixin {
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

              // Dimmer globale (per schermate non-MyPath)
              if (widget.dimming > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 
                              (widget.dimming * 0.70).clamp(0.0, 1.0),
                            ),
                            Colors.black.withValues(alpha: 
                              widget.dimming.clamp(0.0, 1.0),
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
  final double x;     // 0..1
  final double y;     // 0..1
  final double r;     // px
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
    final base = (0.10 + 0.55 * alpha).clamp(0.0, 0.70);
    final tw = math.sin(t * math.pi * 2);

    for (final s in stars) {
      final px = s.x * size.width;
      final py = s.y * size.height;

      final flicker = 0.75 + 0.25 * math.sin(s.phase + tw * 1.2);
      final a = (base * flicker).clamp(0.0, 0.70);

      final paint = Paint()..color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(px, py), s.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.alpha != alpha;
  }
}

// -----------------------------------------------------------------------------
// PALETTE (offline)
/// ---------------------------------------------------------------------------
class _DayPalette {
  const _DayPalette({
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
    final m = now.hour * 60 + now.minute;

    final day01 = ((math.sin((m / 1440.0) * math.pi * 2 - math.pi / 2) + 1) / 2).clamp(0.0, 1.0);
    final night = (1.0 - day01).clamp(0.0, 1.0);

    double bump(double centerMin, double widthMin) {
      final d = (m - centerMin).abs();
      final x = (1.0 - (d / widthMin)).clamp(0.0, 1.0);
      return x * x * (3 - 2 * x);
    }

    final dawnB = bump(6.75 * 60, 95);
    final duskB = bump(18.50 * 60, 110);
    final twilight = math.max(dawnB, duskB);
    final duskMix = duskB / (dawnB + duskB + 1e-6);

    const nightTop = Color.fromARGB(255, 0, 0, 0);
    const nightBottom = Color.fromARGB(255, 0, 0, 0);

    const dayTop = Color(0xFF071C3E);
    const dayBottom = Color(0xFF24B7FF);

    const sunriseTop = Color(0xFF24134E);
    const sunriseBottom = Color(0xFFFFB07A);

    const sunsetTop = Color(0xFF1A0C2E);
    const sunsetBottom = Color(0xFFFF7A62);

    final baseTop = Color.lerp(nightTop, dayTop, day01)!;
    final baseBottom = Color.lerp(nightBottom, dayBottom, day01)!;

    final warmTop = Color.lerp(sunriseTop, sunsetTop, duskMix)!;
    final warmBottom = Color.lerp(sunriseBottom, sunsetBottom, duskMix)!;

    final top = Color.lerp(baseTop, warmTop, twilight * 0.55)!;
    final bottom = Color.lerp(baseBottom, warmBottom, twilight * 0.65)!;

    final coolA = Color.lerp(const Color(0xFF2EC4FF), const Color(0xFF5B7CFF), night)!;
    final coolB = Color.lerp(const Color(0xFF7CFFB5), const Color(0xFFB07CFF), night)!;
    final coolC = Color.lerp(const Color(0xFFFFF3A6), const Color(0xFF1CFFF0), night)!;

    final warmA = Color.lerp(const Color(0xFFFFC38B), const Color(0xFFFF8C4B), duskMix)!;
    final warmB = Color.lerp(const Color(0xFFFF6B9A), const Color(0xFFFF4D8D), duskMix)!;
    final warmC = Color.lerp(const Color(0xFF6DEBFF), const Color(0xFF6B7CFF), duskMix)!;

    Color blend(Color a, Color b, double t) => Color.lerp(a, b, t)!;

    final blobA = [
      blend(coolA, warmA, twilight).withValues(alpha: 0.95),
      blend(coolA, warmA, twilight).withValues(alpha: 0.00),
      Colors.transparent,
    ];
    final blobB = [
      blend(coolB, warmB, twilight).withValues(alpha: 0.90),
      blend(coolB, warmB, twilight).withValues(alpha: 0.00),
      Colors.transparent,
    ];
    final blobC = [
      blend(coolC, warmC, twilight).withValues(alpha: 0.85),
      blend(coolC, warmC, twilight).withValues(alpha: 0.00),
      Colors.transparent,
    ];

    return _DayPalette(
      sky: [top, bottom],
      blobA: blobA,
      blobB: blobB,
      blobC: blobC,
      night: night,
    );
  }
}