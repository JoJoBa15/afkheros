import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../state/settings_state.dart';
import 'focus_session_screen.dart';

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

  void _openStartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SessionStartSheet(now: _now),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DayPalette.fromNow(_now);

    return Align(
      alignment: const Alignment(0, 0),
      child: _FocusCTA(palette: palette, onTap: () => _openStartSheet(context)),
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

  final _ctaKey = GlobalKey<_CtaButtonState>();
  Offset _tap01 = const Offset(0.5, 0.5);
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diameter = math.min(size.width, size.height) * 0.44;

    return GestureDetector(
      onTapDown: (d) {
        setState(() => _down = true);
        final p = d.localPosition;
        final dx = (p.dx / diameter).clamp(0.0, 1.0);
        final dy = (p.dy / diameter).clamp(0.0, 1.0);
        _tap01 = Offset(dx, dy);
      },
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        if (_opening) return;
        _opening = true;

        _ctaKey.currentState?.playClick(_tap01);

        Future.delayed(const Duration(milliseconds: 120), () {
          if (!mounted) return;
          widget.onTap();
          _opening = false;
        });
      },
      child: AnimatedScale(
        scale: _down ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              OverflowBox(
                alignment: Alignment.center,
                minWidth: 0,
                minHeight: 0,
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: _DancingBlob(
                  diameter: diameter,
                  palette: widget.palette,
                ),
              ),
              _CtaButton(
                key: _ctaKey,
                diameter: diameter,
                palette: widget.palette,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CTA glass + click sheen/ripple
class _CtaButton extends StatefulWidget {
  const _CtaButton({super.key, required this.diameter, required this.palette});

  final double diameter;
  final _DayPalette palette;

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _click;
  Offset _tap01 = const Offset(0.5, 0.5);

  @override
  void initState() {
    super.initState();
    _click = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
  }

  @override
  void dispose() {
    _click.dispose();
    super.dispose();
  }

  void playClick(Offset tap01) {
    _tap01 = tap01;
    _click.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diameter;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _click,
        builder: (_, _) {
          final t = Curves.easeInOutCubic.transform(_click.value);

          final sheenX = lerpDouble(-d * 0.95, d * 0.95, t)!;
          final sheenOpacity = (math.sin(
            math.pi * _click.value,
          )).clamp(0.0, 1.0);

          final rippleScale = lerpDouble(
            0.15,
            1.55,
            Curves.easeOutCubic.transform(_click.value),
          )!;
          final rippleOpacity = lerpDouble(
            0.28,
            0.0,
            Curves.easeOut.transform(_click.value),
          )!;

          final ring = (math.sin(math.pi * _click.value)).clamp(0.0, 1.0);

          return Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.palette.cta,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.26),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  blurRadius: 40,
                  spreadRadius: 2,
                  color: widget.palette.glow.withValues(alpha: 0.22),
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.55, -0.65),
                        radius: 1.15,
                        colors: [
                          Colors.white.withValues(alpha: 0.24),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.62],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.75, 0.85),
                        radius: 1.05,
                        colors: [
                          Colors.black.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.70],
                      ),
                    ),
                  ),
                  if (_click.value > 0)
                    Align(
                      alignment: Alignment(
                        _tap01.dx * 2 - 1,
                        _tap01.dy * 2 - 1,
                      ),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Transform.scale(
                          scale: rippleScale,
                          child: Container(
                            width: d * 0.55,
                            height: d * 0.55,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: rippleOpacity),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_click.value > 0)
                    Opacity(
                      opacity: 0.85 * sheenOpacity,
                      child: Transform.translate(
                        offset: Offset(sheenX, 0),
                        child: Transform.rotate(
                          angle: -0.55,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 10,
                              sigmaY: 10,
                            ),
                            child: Container(
                              width: d * 0.55,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  CustomPaint(
                    painter: _GlassRingPainter(
                      pulse: ring,
                      glow: widget.palette.glow,
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 44,
                          color: Colors.white.withValues(alpha: 0.96),
                        ),
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
                            color: Colors.white.withValues(alpha: 0.84),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlassRingPainter extends CustomPainter {
  _GlassRingPainter({required this.pulse, required this.glow});
  final double pulse;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(r, r), radius: r);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.42),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.30),
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.42),
        ],
        stops: const [0.0, 0.28, 0.55, 0.78, 1.0],
      ).createShader(rect);

    canvas.drawCircle(Offset(r, r), r - 0.9, rimPaint);

    if (pulse > 0) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = glow.withValues(alpha: 0.18 * pulse);
      canvas.drawCircle(Offset(r, r), r - 1.4, p);
    }

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(r, r), r * 0.78, inner);
  }

  @override
  bool shouldRepaint(covariant _GlassRingPainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.glow != glow;
}

/// === BLOB (lascio i TUOI valori) ===
class _DancingBlob extends StatefulWidget {
  const _DancingBlob({required this.diameter, required this.palette});

  final double diameter;
  final _DayPalette palette;

  @override
  State<_DancingBlob> createState() => _DancingBlobState();
}

class _DancingBlobState extends State<_DancingBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _rnd = math.Random(77);

  Offset _curOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;

  double _curScale = 1.0;
  double _targetScale = 1.0;

  double _curBlur = 88.0;
  double _targetBlur = 102.0;

  @override
  void initState() {
    super.initState();
    _c =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 9800),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) {
            _snapToTarget();
            _pickNext();
          }
        });
    _pickNext();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _snapToTarget() {
    _curOffset = _targetOffset;
    _curScale = _targetScale;
    _curBlur = _targetBlur;
  }

  void _pickNext() {
    final amp = widget.diameter * 0.15;
    double rr(double min, double max) => min + _rnd.nextDouble() * (max - min);

    _targetOffset = Offset(rr(-amp, amp), rr(-amp, amp));
    _targetScale = rr(0.98, 1.06);
    _targetBlur = rr(90, 112);

    final ms = 8800 + _rnd.nextInt(5200);
    _c.duration = Duration(milliseconds: ms.clamp(8000, 14000).toInt());
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final outerSize = widget.diameter * 3.30;
    final innerSize = widget.diameter * 1.85;

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final tt = Curves.easeInOutCubic.transform(_c.value);
            final o = Offset.lerp(_curOffset, _targetOffset, tt)!;
            final s = lerpDouble(_curScale, _targetScale, tt)!;
            final blur = lerpDouble(_curBlur, _targetBlur, tt)!;

            return Transform.translate(
              offset: o,
              child: Transform.scale(
                scale: s,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: Container(
                        width: outerSize,
                        height: outerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.palette.glow.withValues(alpha: 0.36),
                              widget.palette.cta.last.withValues(alpha: 0.18),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.62, 1.0],
                          ),
                        ),
                      ),
                    ),
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: blur * 0.60,
                        sigmaY: blur * 0.60,
                      ),
                      child: Container(
                        width: innerSize,
                        height: innerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              widget.palette.glow.withValues(alpha: 0.40),
                              widget.palette.cta.first.withValues(alpha: 0.40),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DayPalette {
  const _DayPalette({
    required this.cta,
    required this.glow,
    required this.night,
  });

  final List<Color> cta;
  final Color glow;
  final double night;

  static _DayPalette fromNow(DateTime now) {
    final m = now.hour * 60 + now.minute;
    final day01 = ((math.sin((m / 1440.0) * math.pi * 2 - math.pi / 2) + 1) / 2)
        .clamp(0.0, 1.0);
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

    Color blend(Color a, Color b, double t) => Color.lerp(a, b, t)!;

    final ctaA = blend(const Color(0xFF8DF7FF), const Color(0xFF5B7CFF), night);
    final ctaB = blend(const Color(0xFF5B7CFF), const Color(0xFFB07CFF), night);

    final ctaWarmA = blend(
      const Color(0xFFFFC38B),
      const Color(0xFFFF8C4B),
      duskMix,
    );
    final ctaWarmB = blend(
      const Color(0xFFFF6B9A),
      const Color(0xFFFF4D8D),
      duskMix,
    );

    final cta = [
      blend(ctaA, ctaWarmA, twilight),
      blend(ctaB, ctaWarmB, twilight),
    ];

    final glow = blend(
      const Color(0xFF2EC4FF),
      const Color(0xFFFF8C4B),
      twilight,
    );

    return _DayPalette(cta: cta, glow: glow, night: night);
  }
}

/// ======================
/// BOTTOM SHEET APPLE STYLE
/// ======================
enum _StartMode { timer, stopwatch }

class _SessionStartSheet extends StatefulWidget {
  const _SessionStartSheet({required this.now});
  final DateTime now;

  @override
  State<_SessionStartSheet> createState() => _SessionStartSheetState();
}

class _SessionStartSheetState extends State<_SessionStartSheet> {
  _StartMode _mode = _StartMode.timer;

  final List<int> _timerMinutes = const [1, 10, 15, 20, 25, 30, 40, 50, 60];
  late int _timerIndex;

  late final FixedExtentScrollController _timerController;

  @override
  void initState() {
    super.initState();
    _timerIndex = _timerMinutes.indexOf(20);
    if (_timerIndex < 0) _timerIndex = 0;
    _timerController = FixedExtentScrollController(initialItem: _timerIndex);
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _setMode(_StartMode m) {
    if (m == _mode) return;
    setState(() => _mode = m);
  }

  (_Band, double) _bandNow() {
    final h = widget.now.hour;
    if (h >= 6 && h < 11) return (_Band.morning, 1.10);
    if (h >= 11 && h < 17) return (_Band.afternoon, 1.00);
    if (h >= 17 && h < 22) return (_Band.evening, 1.05);
    return (_Band.night, 1.00);
  }

  int _estimateTimerCoins(int minutes) {
    final (_, mult) = _bandNow();
    final x = minutes / 60.0;
    final base = (math.pow(x, 1.25) * 120).round();
    return (base * mult).round();
  }

  String _bandLabel(_Band b) {
    switch (b) {
      case _Band.morning:
        return 'Mattina';
      case _Band.afternoon:
        return 'Pomeriggio';
      case _Band.evening:
        return 'Sera';
      case _Band.night:
        return 'Notte';
    }
  }

  void _startTimer() {
    final minutes = _timerMinutes[_timerIndex];
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusSessionScreen(
          type: FocusSessionType.timer,
          duration: Duration(minutes: minutes),
          displayMode: FocusDisplayMode.fullscreen,
        ),
      ),
    );
  }

  void _startStopwatch() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FocusSessionScreen(
          type: FocusSessionType.stopwatch,
          // Qui “duration” è il CAP (max ricompensa = 60 min)
          duration: Duration(minutes: 60),
          displayMode: FocusDisplayMode.fullscreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final (band, mult) = _bandNow();
    final bandText = mult > 1.0
        ? 'Bonus ${_bandLabel(band)} +${((mult - 1) * 100).round()}%'
        : _bandLabel(band);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: math.max(12, bottom),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1B2530).withValues(alpha: 0.78),
                    const Color(0xFF0F1217).withValues(alpha: 0.86),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Avvia sessione',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Text(
                          bandText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Segmented control (glass)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: CupertinoSlidingSegmentedControl<_StartMode>(
                      groupValue: _mode,
                      backgroundColor: Colors.transparent,
                      thumbColor: Colors.white.withValues(alpha: 0.12),
                      onValueChanged: (v) => _setMode(v ?? _StartMode.timer),
                      children: const {
                        _StartMode.timer: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          child: Text(
                            'Timer',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _StartMode.stopwatch: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          child: Text(
                            'Cronometro',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    height:
                        240, // ✅ altezza fissa = niente “salti” tra Timer e Cronometro
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 340),
                      reverseDuration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,

                      // ✅ overlay stabile (evita micro-resize durante lo switch)
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          children: <Widget>[
                            ...previousChildren,
                            // ignore: use_null_aware_elements
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },

                      // ✅ direzione “per tab”: Timer↔sinistra, Cronometro↔destra
                      // ✅ e in uscita ognuno esce verso il SUO lato (non più stessa direzione)
                      transitionBuilder: (child, anim) {
                        final isTimer = child.key == const ValueKey('timer');
                        final side = isTimer ? -1.0 : 1.0;

                        final curved = CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                          reverseCurve: Curves.easeInCubic,
                        );

                        final isExiting =
                            anim.status == AnimationStatus.reverse;

                        final slide = isExiting
                            ? Tween<Offset>(
                                begin: Offset.zero,
                                end: Offset(
                                  0.14 * side,
                                  0,
                                ), // esce verso il suo lato
                              ).animate(ReverseAnimation(curved))
                            : Tween<Offset>(
                                begin: Offset(
                                  0.14 * side,
                                  0,
                                ), // entra dal suo lato
                                end: Offset.zero,
                              ).animate(curved);

                        return FadeTransition(
                          opacity: curved,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },

                      child: (_mode == _StartMode.timer)
                          ? _TimerPanel(
                              key: const ValueKey('timer'),
                              controller: _timerController,
                              minutes: _timerMinutes,
                              selectedIndex: _timerIndex,
                              onChanged: (i) => setState(() => _timerIndex = i),
                              estimateCoins: _estimateTimerCoins,
                            )
                          : const _StopwatchPanel(key: ValueKey('stopwatch')),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // CTA bottom
                  _GlassPrimaryButton(
                    label: _mode == _StartMode.timer
                        ? 'Avvia timer'
                        : 'Avvia cronometro',
                    onTap: _mode == _StartMode.timer
                        ? _startTimer
                        : _startStopwatch,
                  ),

                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({
    super.key,
    required this.controller,
    required this.minutes,
    required this.selectedIndex,
    required this.onChanged,
    required this.estimateCoins,
  });

  final FixedExtentScrollController controller;
  final List<int> minutes;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final int Function(int minutes) estimateCoins;

  @override
  Widget build(BuildContext context) {
    final selMin = minutes[selectedIndex];
    final coins = estimateCoins(selMin);

    return Column(
      key: key,
      children: [
        Text(
          'Seleziona durata',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.86),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: CupertinoPicker(
              scrollController: controller,
              itemExtent: 44,
              magnification: 1.12,
              squeeze: 1.06,
              useMagnifier: true,
              onSelectedItemChanged: onChanged,
              children: minutes.map((m) {
                final label = (m == 1) ? '1 minuto (beta)' : '$m minuti';
                return Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Ricompensa stimata: +$coins monete (max a 60 min)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.80),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StopwatchPanel extends StatelessWidget {
  const _StopwatchPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      children: [
        Text(
          'Ora sei in Cronometro',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• Soglia minima: 15 minuti',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '• Ricompensa: 2 monete/min (fino a 60 min)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '• Oltre 60 min: continui, ma la ricompensa resta “cap”',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassPrimaryButton extends StatelessWidget {
  const _GlassPrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15.5,
            ),
          ),
        ),
      ),
    );
  }
}

enum _Band { morning, afternoon, evening, night }
