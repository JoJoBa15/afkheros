import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../state/settings_state.dart';
import 'focus_session_screen.dart';

/// Tab centrale: CTA “Concentrati!”
///
/// Il background e l’header sono gestiti dal RootShell (AppBackground + AfkShellAppBar).
/// Qui manteniamo solo la CTA + palette dinamica (giorno/notte) per avere lo stesso look.
class MyPathScreen extends StatefulWidget {
  const MyPathScreen({super.key});

  @override
  State<MyPathScreen> createState() => _MyPathScreenState();
}

class _MyPathScreenState extends State<MyPathScreen> {
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
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

    return Align(
      alignment: const Alignment(0, -0.08),
      child: _FocusCTA(
        palette: palette,
        onTap: () => _showDurationPicker(context),
      ),
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

// -----------------------------------------------------------------------------
// PALETTE (stessa logica di MyPath originale)
// -----------------------------------------------------------------------------
class _DayPalette {
  const _DayPalette({
    required this.cta,
    required this.glow,
    required this.night,
  });

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

    final dawnB = bump(6.75 * 60, 95); // ~06:45
    final duskB = bump(18.50 * 60, 110); // ~18:30
    final twilight = math.max(dawnB, duskB);
    final duskMix = duskB / (dawnB + duskB + 1e-6);

    // CTA gradient
    Color blend(Color a, Color b, double t) => Color.lerp(a, b, t)!;

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
      cta: cta,
      glow: glow,
      night: night,
    );
  }
}

class _DurationPicker extends StatelessWidget {
  const _DurationPicker();

  void _startSession(BuildContext context, Duration duration) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusSessionScreen(
          duration: duration,
          displayMode: FocusDisplayMode.fullscreen,
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
