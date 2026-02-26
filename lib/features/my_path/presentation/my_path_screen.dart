import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'focus_session_screen.dart';
import '../../../state/settings_state.dart';

class MyPathScreen extends StatefulWidget {
  const MyPathScreen({
    super.key,
    required this.onOpenSessionMenu,
  });

  final ValueChanged<DateTime> onOpenSessionMenu;

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: const Alignment(0, 0),
          child: _ZenCoreCTA(
            onTap: () => widget.onOpenSessionMenu(_now),
          ),
        ),
      ],
    );
  }
}

class _ZenCoreCTA extends StatefulWidget {
  final VoidCallback onTap;
  const _ZenCoreCTA({required this.onTap});

  @override
  State<_ZenCoreCTA> createState() => _ZenCoreCTAState();
}

class _ZenCoreCTAState extends State<_ZenCoreCTA> with TickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final AnimationController _rotationCtrl;
  late final AnimationController _shockwaveCtrl;
  bool _isDown = false;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _rotationCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _shockwaveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _rotationCtrl.dispose();
    _shockwaveCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _shockwaveCtrl.forward(from: 0);
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 150), widget.onTap);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diameter = math.min(size.width, size.height) * 0.48;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isDown = true),
      onTapUp: (_) => setState(() => _isDown = false),
      onTapCancel: () => setState(() => _isDown = false),
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathCtrl, _rotationCtrl, _shockwaveCtrl]),
        builder: (context, _) {
          final breath = Curves.easeInOutSine.transform(_breathCtrl.value);
          final shock = _shockwaveCtrl.value;
          final scale = (1.0 + (breath * 0.04)) * (_isDown ? 0.92 : 1.0);

          return SizedBox(
            width: diameter * 1.5,
            height: diameter * 1.5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (shock > 0 && shock < 1)
                  CustomPaint(
                    painter: _ShockwavePainter(progress: shock, color: Colors.white),
                    size: Size(diameter * 1.4, diameter * 1.4),
                  ),
                Container(
                  width: diameter * 1.1,
                  height: diameter * 1.1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.white.withValues(alpha: 0.12 + (breath * 0.08)), Colors.transparent],
                    ),
                  ),
                ),
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 15)),
                      ],
                    ),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: CustomPaint(
                          painter: _ZenCorePainter(breath: breath, rotation: _rotationCtrl.value),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: diameter * 0.22, color: Colors.white.withValues(alpha: 0.9)),
                                const SizedBox(height: 8),
                                Text(
                                  'FOCUS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: diameter * 0.14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    shadows: [Shadow(color: Colors.cyanAccent.withValues(alpha: 0.5), blurRadius: 10)],
                                  ),
                                ),
                                Text('Tocca per iniziare', style: TextStyle(color: Colors.white38, fontSize: diameter * 0.07, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
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
    );
  }
}

class _ZenCorePainter extends CustomPainter {
  final double breath;
  final double rotation;
  _ZenCorePainter({required this.breath, required this.rotation});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final bodyPaint = Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.02)]).createShader(rect);
    canvas.drawCircle(center, radius, bodyPaint);
    final rimPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..shader = SweepGradient(transform: GradientRotation(rotation * math.pi * 2), colors: [Colors.transparent, Colors.white.withValues(alpha: 0.4 + (breath * 0.2)), Colors.transparent, Colors.white.withValues(alpha: 0.1), Colors.transparent], stops: const [0.0, 0.25, 0.5, 0.8, 1.0]).createShader(rect);
    canvas.drawCircle(center, radius - 1.25, rimPaint);
    final glossPaint = Paint()..shader = RadialGradient(center: const Alignment(-0.3, -0.4), radius: 0.6, colors: [Colors.white.withValues(alpha: 0.25), Colors.transparent]).createShader(rect);
    canvas.drawCircle(center, radius, glossPaint);
  }
  @override
  bool shouldRepaint(covariant _ZenCorePainter old) => true;
}

class _ShockwavePainter extends CustomPainter {
  final double progress;
  final Color color;
  _ShockwavePainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    canvas.drawCircle(center, radius, Paint()..color = color.withValues(alpha: opacity * 0.3)..style = PaintingStyle.stroke..strokeWidth = 4.0);
  }
  @override
  bool shouldRepaint(covariant _ShockwavePainter old) => old.progress != progress;
}

// --- POPUP START SESSION ---
enum _StartMode { timer, stopwatch }
enum _Band { morning, afternoon, evening, night }

class SessionStartSheet extends StatefulWidget {
  const SessionStartSheet({super.key, required this.now, required this.onClose});
  final DateTime now;
  final VoidCallback onClose;
  @override
  State<SessionStartSheet> createState() => _SessionStartSheetState();
}

class _SessionStartSheetState extends State<SessionStartSheet> {
  _StartMode _mode = _StartMode.timer;
  final List<int> _timerMinutes = const [1, 10, 15, 20, 25, 30, 40, 50, 60];
  late int _timerIndex;
  late final FixedExtentScrollController _timerController;

  @override
  void initState() {
    super.initState();
    _timerIndex = _timerMinutes.indexOf(20);
    _timerController = FixedExtentScrollController(initialItem: _timerIndex >= 0 ? _timerIndex : 0);
  }

  @override
  void dispose() { _timerController.dispose(); super.dispose(); }

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

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(38);
    final selectedMinutes = _timerMinutes[_timerIndex];
    final estimatedCoins = _estimateTimerCoins(selectedMinutes);

    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF1E2A38).withValues(alpha: 0.88), const Color(0xFF0F1217).withValues(alpha: 0.94)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1.4, strokeAlign: BorderSide.strokeAlignInside),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  const Text('Avvia Sessione', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  CupertinoSlidingSegmentedControl<_StartMode>(
                    groupValue: _mode,
                    backgroundColor: Colors.black26,
                    thumbColor: Colors.white12,
                    onValueChanged: (v) => setState(() => _mode = v!),
                    children: const {
                      _StartMode.timer: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Timer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                      _StartMode.stopwatch: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Cronometro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_mode == _StartMode.timer)
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              scrollController: _timerController,
                              itemExtent: 44,
                              onSelectedItemChanged: (i) => setState(() => _timerIndex = i),
                              children: _timerMinutes.map((m) => Center(child: Text('$m minuti', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)))).toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withValues(alpha: 0.2))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 8),
                                Text('Premio stimato: +$estimatedCoins monete', style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.white24, size: 48),
                            const SizedBox(height: 16),
                            _infoRow(Icons.check_circle_outline_rounded, 'Minimo 15 minuti'),
                            const SizedBox(height: 10),
                            _infoRow(Icons.add_chart_rounded, '2 monete / min'),
                            const SizedBox(height: 10),
                            _infoRow(Icons.whatshot_rounded, 'Bonus orario attivo'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final m = _timerMinutes[_timerIndex];
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => FocusSessionScreen(type: _mode == _StartMode.timer ? FocusSessionType.timer : FocusSessionType.stopwatch, duration: Duration(minutes: _mode == _StartMode.timer ? m : 60), displayMode: FocusDisplayMode.fullscreen)));
                      widget.onClose();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: const Text('INIZIA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0)),
                  ),
                  TextButton(onPressed: widget.onClose, child: const Text('Annulla', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
