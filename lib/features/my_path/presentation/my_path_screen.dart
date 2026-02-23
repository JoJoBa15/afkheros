import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/settings_state.dart';
import 'focus_session_screen.dart';

class MyPathScreen extends StatefulWidget {
  const MyPathScreen({super.key});

  @override
  State<MyPathScreen> createState() => _MyPathScreenState();
}

class _MyPathScreenState extends State<MyPathScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  Timer? _clock;
  DateTime _now = DateTime.now();

  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);

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

  void _showDurationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => const _DurationPicker(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DayPalette.fromNow(_now);

    return Stack(
      children: [
        // BACKGROUND FULLSCREEN (dietro AppBar trasparente del RootShell)
        Positioned.fill(
          child: AnimatedBuilder(
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
                    // Aurora blobs (profondità)
                    _AuroraBlobs(t: t, palette: palette),

                    // Stars SOLO se notte (no “pixel morti”: fisse + twinkle leggero)
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

                    // Vignette soft per focus al centro
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.12),
                              radius: 1.05,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.32),
                              ],
                              stops: const [0.62, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Scrim top per leggibilità AppBar
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.center,
                              colors: [
                                Colors.black.withOpacity(0.20),
                                Colors.transparent,
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
          ),
        ),

        // CTA CENTRALE
        Align(
          alignment: const Alignment(0, -0.08),
          child: _FocusCTA(
            palette: palette,
            onTap: () => _showDurationPicker(context),
          ),
        ),
      ],
    );
  }
}

class _FocusCTA extends StatefulWidget {
  const _FocusCTA({required this.palette, required this.onTap});

  final _DayPalette palette;
  final VoidCallback onTap;

  @override
  State<_FocusCTA> createState() => _FocusCTAState();
}

class _FocusCTAState extends State<_FocusCTA> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diameter = math.min(size.width, size.height) * 0.44;

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.palette.cta,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 34,
                spreadRadius: 2,
                color: widget.palette.glow.withOpacity(0.28),
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                alignment: Alignment.center,
                color: Colors.white.withOpacity(0.06),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 44, color: Colors.white.withOpacity(0.96)),
                    const SizedBox(height: 10),
                    const Text(
                      'Concentrati!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Avvia una sessione',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.84),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  const _DurationPicker();

  void _startSession(BuildContext context, Duration duration) {
    final settings = context.read<SettingsState>();
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusSessionScreen(
          duration: duration,
          displayMode: settings.focusDisplayMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const durations = [
      Duration(minutes: 15),
      Duration(minutes: 25),
      Duration(minutes: 45),
      Duration(minutes: 60),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 26),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1B2530).withOpacity(0.78),
                const Color(0xFF0F1217).withOpacity(0.82),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Per quanto tempo?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.55,
                children: durations.map((d) {
                  return InkWell(
                    onTap: () => _startSession(context, d),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.06),
                          ],
                        ),
                        border: Border.all(color: Colors.white.withOpacity(0.10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.22),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${d.inMinutes} minuti',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Annulla',
                  style: TextStyle(color: Colors.white.withOpacity(0.75)),
                ),
              ),
            ],
          ),
        ),
      ),
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
  final double r;     // px base
  final double phase; // 0..2π
}

class _StarField {
  static List<_Star> generate({required int seed, required int count}) {
    final rnd = math.Random(seed);
    return List.generate(count, (_) {
      // Più stelle in alto
      final x = rnd.nextDouble();
      final y = math.pow(rnd.nextDouble(), 1.6).toDouble(); // bias top
      final r = 0.6 + rnd.nextDouble() * 1.6;
      final ph = rnd.nextDouble() * math.pi * 2;
      return _Star(x, y, r, ph);
    });
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter({required this.stars, required this.t, required this.alpha});

  final List<_Star> stars;
  final double t;      // 0..1
  final double alpha;  // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final base = (0.10 + 0.55 * alpha).clamp(0.0, 0.70);
    final tw = math.sin(t * math.pi * 2);

    for (final s in stars) {
      final px = s.x * size.width;
      final py = s.y * size.height;

      // Twinkle leggero (no apparizioni/sparizioni aggressive)
      final flicker = 0.75 + 0.25 * math.sin(s.phase + tw * 1.2);
      final a = (base * flicker).clamp(0.0, 0.70);

      final paint = Paint()..color = Colors.white.withOpacity(a);
      canvas.drawCircle(Offset(px, py), s.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.alpha != alpha;
  }
}

// -----------------------------------------------------------------------------
// PALETTE (offline, smooth)
// -----------------------------------------------------------------------------
class _DayPalette {
  const _DayPalette({
    required this.sky,
    required this.blobA,
    required this.blobB,
    required this.blobC,
    required this.cta,
    required this.glow,
    required this.night,
  });

  final List<Color> sky;
  final List<Color> blobA;
  final List<Color> blobB;
  final List<Color> blobC;
  final List<Color> cta;
  final Color glow;
  final double night; // 0..1

  static _DayPalette fromNow(DateTime now) {
    final m = now.hour * 60 + now.minute;

    // Day curve (0 night -> 1 day) con sinusoide
    final day01 = ((math.sin((m / 1440.0) * math.pi * 2 - math.pi / 2) + 1) / 2).clamp(0.0, 1.0);
    final night = (1.0 - day01).clamp(0.0, 1.0);

    // Twilight bumps (dawn + dusk)
    double bump(double centerMin, double widthMin) {
      final d = (m - centerMin).abs();
      final x = (1.0 - (d / widthMin)).clamp(0.0, 1.0);
      return x * x * (3 - 2 * x); // smoothstep
    }

    final dawnB = bump(6.75 * 60, 95);   // ~06:45 (ampiezza)
    final duskB = bump(18.50 * 60, 110); // ~18:30
    final twilight = math.max(dawnB, duskB);
    final duskMix = duskB / (dawnB + duskB + 1e-6);

    // Anchors
    const nightTop = Color(0xFF05081A);
    const nightBottom = Color(0xFF0D1230);

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

    // Blobs: mischia tra day cool / night cool / warm
    final coolA = Color.lerp(const Color(0xFF2EC4FF), const Color(0xFF5B7CFF), night)!;
    final coolB = Color.lerp(const Color(0xFF7CFFB5), const Color(0xFFB07CFF), night)!;
    final coolC = Color.lerp(const Color(0xFFFFF3A6), const Color(0xFF1CFFF0), night)!;

    final warmA = Color.lerp(const Color(0xFFFFC38B), const Color(0xFFFF8C4B), duskMix)!;
    final warmB = Color.lerp(const Color(0xFFFF6B9A), const Color(0xFFFF4D8D), duskMix)!;
    final warmC = Color.lerp(const Color(0xFF6DEBFF), const Color(0xFF6B7CFF), duskMix)!;

    Color blend(Color a, Color b, double t) => Color.lerp(a, b, t)!;

    final blobA = [
      blend(coolA, warmA, twilight).withOpacity(0.95),
      blend(coolA, warmA, twilight).withOpacity(0.00),
      Colors.transparent,
    ];

    final blobB = [
      blend(coolB, warmB, twilight).withOpacity(0.90),
      blend(coolB, warmB, twilight).withOpacity(0.00),
      Colors.transparent,
    ];

    final blobC = [
      blend(coolC, warmC, twilight).withOpacity(0.85),
      blend(coolC, warmC, twilight).withOpacity(0.00),
      Colors.transparent,
    ];

    // CTA gradient
    final ctaA = blend(const Color(0xFF8DF7FF), const Color(0xFF5B7CFF), night);
    final ctaB = blend(const Color(0xFF5B7CFF), const Color(0xFFB07CFF), night);

    final ctaWarmA = blend(const Color(0xFFFFC38B), const Color(0xFFFF8C4B), duskMix);
    final ctaWarmB = blend(const Color(0xFFFF6B9A), const Color(0xFFFF4D8D), duskMix);

    final cta = [
      blend(ctaA, ctaWarmA, twilight),
      blend(ctaB, ctaWarmB, twilight),
    ];

    final glow = blend(const Color(0xFF2EC4FF), const Color(0xFFFF8C4B), twilight);

    return _DayPalette(
      sky: [top, bottom],
      blobA: blobA,
      blobB: blobB,
      blobC: blobC,
      cta: cta,
      glow: glow,
      night: night,
    );
  }
}