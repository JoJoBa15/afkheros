import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_background.dart';
import '../../../core/utils/time_format.dart';
import '../../../state/game_state.dart';
import '../../../state/settings_state.dart';
import '../../../core/services/battery_service.dart';
import 'victory_screen.dart';

enum FocusSessionType { timer, stopwatch }

class FocusSessionScreen extends StatefulWidget {
  final Duration duration;
  final FocusDisplayMode displayMode;
  final FocusSessionType type;

  const FocusSessionScreen({
    super.key,
    required this.duration,
    required this.displayMode,
    this.type = FocusSessionType.timer,
  });

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> with TickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final AnimationController _voidCtrl; 
  
  Timer? _timer;
  late int _remainingSeconds;
  int _elapsedSeconds = 0;
  
  DateTime _now = DateTime.now();
  BatteryInfo? _battery;
  Timer? _statusTimer;

  bool _isVoidActive = false;
  double _dragToUnlock = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration.inSeconds;
    
    _breathCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _voidCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _startSessionTimer();
    _startStatusUpdates();
    _applyImmersiveMode();
  }

  void _applyImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _startSessionTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (widget.type == FocusSessionType.timer) {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _timer?.cancel();
            _finishSession();
          }
        } else {
          _elapsedSeconds++;
        }
      });
    });
  }

  void _startStatusUpdates() {
    _syncStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) => _syncStatus());
  }

  Future<void> _syncStatus() async {
    final info = await BatteryService.getBatteryInfo();
    if (!mounted) return;
    setState(() {
      _now = DateTime.now();
      _battery = info;
    });
  }

  void _finishSession() {
    final minutes = widget.type == FocusSessionType.timer ? widget.duration.inMinutes : _elapsedSeconds ~/ 60;
    final rewards = FocusRewards(gold: minutes * 2, gems: 0, iron: minutes >= 15 ? 1 : 0);
    context.read<GameState>().addRewards(addGold: rewards.gold, addIron: rewards.iron);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => VictoryScreen(rewards: rewards)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusTimer?.cancel();
    _breathCtrl.dispose();
    _voidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground(dimming: 0.4)),

          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              opacity: _isVoidActive ? 0.0 : 1.0,
              child: _buildMainUI(),
            ),
          ),

          if (_isVoidActive || _voidCtrl.isAnimating)
            Positioned.fill(
              child: FadeTransition(
                opacity: _voidCtrl,
                child: GestureDetector(
                  onVerticalDragUpdate: (d) {
                    setState(() {
                      _dragToUnlock -= d.delta.dy;
                      if (_dragToUnlock > 150) _toggleVoid(false);
                    });
                  },
                  onVerticalDragEnd: (_) => setState(() => _dragToUnlock = 0),
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _breathCtrl,
                            builder: (context, _) => Container(
                              width: 12 + (_breathCtrl.value * 4),
                              height: 12 + (_breathCtrl.value * 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.15 + (_breathCtrl.value * 0.1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Opacity(
                            opacity: (_dragToUnlock / 150).clamp(0.0, 1.0),
                            child: const Text(
                              'Trascina su per sbloccare',
                              style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainUI() {
    final timeText = widget.type == FocusSessionType.timer ? formatSeconds(_remainingSeconds) : formatSeconds(_elapsedSeconds);
    final progress = widget.type == FocusSessionType.timer 
        ? (1.0 - (_remainingSeconds / widget.duration.inSeconds)).clamp(0.0, 1.0)
        : (_elapsedSeconds / 3600).clamp(0.0, 1.0);

    return Column(
      children: [
        _buildTopStatus(),
        const Spacer(),
        _buildFocusLens(timeText, progress),
        const Spacer(),
        _buildBottomActions(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTopStatus() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              Text(
                'Tempo Attuale',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    _battery?.isCharging == true ? Icons.bolt_rounded : Icons.battery_full_rounded,
                    size: 16,
                    color: _battery?.isCharging == true ? Colors.greenAccent : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_battery?.level ?? '--'}%',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Text(
                'Energia S25',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusLens(String time, double progress) {
    return AnimatedBuilder(
      animation: _breathCtrl,
      builder: (context, _) {
        final b = Curves.easeInOutSine.transform(_breathCtrl.value);
        return Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.05 + (b * 0.05)),
                blurRadius: 60,
                spreadRadius: 10,
              )
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1 + (b * 0.1)), width: 1.5),
                  gradient: RadialGradient(
                    colors: [Colors.white.withValues(alpha: 0.05), Colors.transparent],
                    stops: const [0.2, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.type == FocusSessionType.timer ? 'TIMER' : 'CRONOMETRO',
                      style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: -2),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 140,
                      height: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation(Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircularAction(
          icon: Icons.close_rounded,
          label: 'INTERROMPI',
          onTap: _confirmCancel,
          color: Colors.redAccent.withValues(alpha: 0.2),
        ),
        _buildCircularAction(
          icon: Icons.visibility_off_rounded,
          label: 'DEEP BLACK',
          onTap: () => _toggleVoid(true),
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ],
    );
  }

  Widget _buildCircularAction({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }

  void _toggleVoid(bool active) {
    setState(() {
      _isVoidActive = active;
      _dragToUnlock = 0;
      if (active) {
        _voidCtrl.forward();
        HapticFeedback.heavyImpact();
      } else {
        _voidCtrl.reverse();
        HapticFeedback.mediumImpact();
      }
    });
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.white10),
          ),
          title: const Text('Abbandonare?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          content: const Text('Perderai i progressi di questa sessione.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CONTINUA', style: TextStyle(color: Colors.white38))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('ABBANDONA')),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (ok == true) Navigator.of(context).pop();
  }
}
