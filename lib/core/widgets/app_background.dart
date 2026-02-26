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
  late final AnimationController _auroraAnim;
  late final AnimationController _breathAnim;
  
  Timer? _clock;
  DateTime _now = DateTime.now();
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();

    // Movimento orbitale fluido (più veloce di prima)
    _auroraAnim = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 15),
    )..repeat(); 

    // Ciclo di respirazione Zen (chiaro e pulsante)
    _breathAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _stars = _StarField.generate(seed: 99, count: 70);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _auroraAnim.dispose();
    _breathAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DayPalette.fromNow(_now);

    return AnimatedBuilder(
      animation: Listenable.merge([_auroraAnim, _breathAnim]),
      builder: (context, _) {
        final t = _auroraAnim.value;
        final breath = Curves.easeInOutSine.transform(_breathAnim.value);
        final d = widget.dimming.clamp(0.0, 1.0);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: palette.sky,
            ),
          ),
          child: Stack(
            children: [
              // LIVELLO 1: Base Aurora (Lenta)
              _AuroraLayer(t: t, breath: breath, palette: palette, speedMult: 1.0, scale: 1.5),
              
              // LIVELLO 2: Luci di contrasto (Veloce)
              Opacity(
                opacity: 0.4,
                child: _AuroraLayer(t: (t * 1.6) % 1.0, breath: breath, palette: palette, speedMult: -1.2, scale: 1.2),
              ),

              // STELLE (Solo di notte o sera)
              if (palette.nightThreshold > 0.2)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _StarsPainter(
                        stars: _stars,
                        t: t,
                        alpha: ((palette.nightThreshold - 0.2) / 0.8).clamp(0.0, 1.0),
                      ),
                    ),
                  ),
                ),

              // Vignette "respirante"
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.5 - (0.3 * breath),
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.25 + (0.2 * breath)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Dimmer (da RootShell)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: d * 0.85),
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

class _AuroraLayer extends StatelessWidget {
  const _AuroraLayer({
    required this.t, 
    required this.breath, 
    required this.palette, 
    required this.speedMult,
    required this.scale,
  });

  final double t, breath, speedMult, scale;
  final _DayPalette palette;

  @override
  Widget build(BuildContext context) {
    final angle = t * math.pi * 2 * speedMult;
    final bPulse = 1.0 + (breath * 0.15);

    return Stack(
      children: [
        // Blob A: In alto a sinistra, orbita ampia
        _Blob(
          alignment: Alignment(-0.6 + math.sin(angle) * 0.4, -0.7 + math.cos(angle) * 0.3),
          sizeFactor: scale * 1.3 * bPulse,
          colors: palette.blobA,
          blur: 40 + (breath * 20),
        ),
        // Blob B: In basso a destra, orbita contraria
        _Blob(
          alignment: Alignment(0.7 + math.cos(angle * 0.8) * 0.4, 0.6 + math.sin(angle * 0.8) * 0.4),
          sizeFactor: scale * 1.1 * bPulse,
          colors: palette.blobB,
          blur: 50 + (breath * 25),
        ),
        // Blob C: Centrale, fluttuazione pulsante
        _Blob(
          alignment: Alignment(math.sin(angle * 0.5) * 0.2, math.cos(angle * 0.5) * 0.2),
          sizeFactor: scale * 1.5 * bPulse,
          colors: palette.blobC,
          blur: 60 + (breath * 30),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.alignment, required this.sizeFactor, required this.colors, required this.blur});
  final Alignment alignment;
  final double sizeFactor, blur;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final d = math.max(size.width, size.height) * sizeFactor;
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: d, height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: colors, 
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarField {
  static List<_Star> generate({required int seed, required int count}) {
    final rnd = math.Random(seed);
    return List.generate(count, (_) => _Star(rnd.nextDouble(), math.pow(rnd.nextDouble(), 2.2).toDouble(), 0.5 + rnd.nextDouble() * 1.2, rnd.nextDouble() * math.pi * 2));
  }
}

class _Star {
  const _Star(this.x, this.y, this.r, this.phase);
  final double x, y, r, phase;
}

class _StarsPainter extends CustomPainter {
  _StarsPainter({required this.stars, required this.t, required this.alpha});
  final List<_Star> stars;
  final double t, alpha;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    for (final s in stars) {
      final sparkle = (0.3 + 0.7 * math.sin(s.phase + t * math.pi * 8)).clamp(0.0, 1.0);
      p.color = Colors.white.withValues(alpha: alpha * sparkle * 0.6);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.r, p);
    }
  }
  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => true;
}

class _DayPalette {
  final List<Color> sky, blobA, blobB, blobC;
  final double nightThreshold;

  _DayPalette({required this.sky, required this.blobA, required this.blobB, required this.blobC, required this.nightThreshold});

  static _DayPalette fromNow(DateTime now) {
    final h = now.hour + now.minute / 60.0;

    double intensity(double peak, double spread, double x) {
      final d = (x - peak).abs();
      return (1.0 - (d / spread)).clamp(0.0, 1.0);
    }

    final wDawn = intensity(6.5, 2.5, h);
    final wDay = intensity(12.5, 4.0, h);
    final wAft = intensity(16.0, 3.0, h); // Post-pranzo / Pomeriggio
    final wSun = intensity(19.5, 2.0, h);
    final wNight = (h < 5.0 || h > 21.0) ? 1.0 : 0.0;

    List<Color> lerpL(List<Color> a, List<Color> b, double t) => 
        List.generate(a.length, (i) => Color.lerp(a[i], b[i], t)!);

    final skyNight = [const Color(0xFF02040A), const Color(0xFF080C1E), const Color(0xFF10152B)];
    final skyDawn = [const Color(0xFF1A1F3C), const Color(0xFF6B4E81), const Color(0xFFFF9E80)];
    final skyDay = [const Color(0xFF4CAFFF), const Color(0xFF2D62FF), const Color(0xFF12256E)];
    final skyAft = [const Color(0xFF6BBFFF), const Color(0xFF7B8CFF), const Color(0xFFF2A379)]; // Caldo pomeridiano
    final skySun = [const Color(0xFF241A4B), const Color(0xFFFF5E78), const Color(0xFFFFC371)];

    var sky = skyDay;
    if (wDawn > 0) sky = lerpL(sky, skyDawn, wDawn);
    if (wAft > 0) sky = lerpL(sky, skyAft, wAft);
    if (wSun > 0) sky = lerpL(sky, skySun, wSun);
    if (wNight > 0.1) sky = lerpL(sky, skyNight, 0.8);

    // Blobs che cambiano colore col tempo
    final blobA = Color.lerp(const Color(0xFF4DFFBC), const Color(0xFFFFB36E), wAft + wSun)!;
    final blobB = Color.lerp(const Color(0xFFFF85E3), const Color(0xFFFF3D68), wSun)!;
    final blobC = Color.lerp(const Color(0xFF5096FF), const Color(0xFF9050FF), wSun)!;

    return _DayPalette(
      sky: sky,
      blobA: [blobA, Colors.transparent, Colors.transparent],
      blobB: [blobB, Colors.transparent, Colors.transparent],
      blobC: [blobC, Colors.transparent, Colors.transparent],
      nightThreshold: wNight + (wSun * 0.5),
    );
  }
}
