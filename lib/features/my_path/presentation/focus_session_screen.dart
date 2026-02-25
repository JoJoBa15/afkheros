import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/afk_shell_app_bar.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/utils/time_format.dart';
import '../../../state/game_state.dart';
import '../../../state/settings_state.dart';
import 'victory_screen.dart';

enum FocusSessionType { timer, stopwatch }

class FocusSessionScreen extends StatefulWidget {
  final Duration duration; // timer: durata reale | stopwatch: CAP (es. 60m)
  final String? debugLabel;
  final FocusDisplayMode displayMode;
  final FocusSessionType type;

  const FocusSessionScreen({
    super.key,
    required this.duration,
    required this.displayMode,
    this.debugLabel,
    this.type = FocusSessionType.timer,
  });

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  Timer? _timer;
  Timer? _pixelShiftTimer;

  late final DateTime _startedAt;

  late int _remainingSeconds; // timer
  int _elapsedSeconds = 0; // stopwatch

  double _x = 0;
  double _y = 0;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();

    if (widget.type == FocusSessionType.timer) {
      _remainingSeconds = widget.duration.inSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _remainingSeconds--);
        if (_remainingSeconds <= 0) {
          _timer?.cancel();
          _finishTimer();
        }
      });
    } else {
      _elapsedSeconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsedSeconds++);
      });
    }

    if (widget.displayMode == FocusDisplayMode.oledSafe) {
      _pixelShiftTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!mounted) return;
        final random = Random();
        setState(() {
          _x = (random.nextDouble() * 10) - 5;
          _y = (random.nextDouble() * 10) - 5;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pixelShiftTimer?.cancel();
    super.dispose();
  }

  (_Band, double) _bandAt(DateTime t) {
    final h = t.hour;
    if (h >= 6 && h < 11) return (_Band.morning, 1.10);
    if (h >= 11 && h < 17) return (_Band.afternoon, 1.00);
    if (h >= 17 && h < 22) return (_Band.evening, 1.05);
    return (_Band.night, 1.00);
  }

  int _coinsForTimer(int minutes) {
    final (_, mult) = _bandAt(_startedAt);
    final x = minutes / 60.0;
    final base = (pow(x, 1.25) * 120).round(); // max 120 a 60m
    return (base * mult).round();
  }

  int _coinsForStopwatch(int elapsedMinutes, int capMinutes) {
    final (_, mult) = _bandAt(_startedAt);
    if (elapsedMinutes < 15) return 0;
    final effective = elapsedMinutes > capMinutes ? capMinutes : elapsedMinutes;
    final base = effective * 2; // 2 monete/min fino al cap
    return (base * mult).round();
  }

  int _ironForMinutes(int minutes) {
    if (minutes >= 60) return 4;
    if (minutes >= 40) return 3;
    if (minutes >= 25) return 2;
    if (minutes >= 15) return 1;
    return 0;
  }

  void _pushVictory(FocusRewards rewards) {
    context.read<GameState>().addRewards(addGold: rewards.gold, addGems: rewards.gems, addIron: rewards.iron);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => VictoryScreen(rewards: rewards)));
  }

  void _finishTimer() {
    final minutes = widget.duration.inMinutes;
    final rewards = FocusRewards(
      gold: _coinsForTimer(minutes),
      gems: 0,
      iron: _ironForMinutes(minutes),
    );
    _pushVictory(rewards);
  }

  void _finishStopwatch() {
    final capMinutes = widget.duration.inMinutes > 0 ? widget.duration.inMinutes : 60;
    final minutes = _elapsedSeconds ~/ 60;

    if (minutes < 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Per ottenere ricompense servono almeno 15 minuti.')),
      );
      return;
    }

    final rewards = FocusRewards(
      gold: _coinsForStopwatch(minutes, capMinutes),
      gems: 0,
      iron: _ironForMinutes(minutes > capMinutes ? capMinutes : minutes),
    );
    _pushVictory(rewards);
  }

  Future<void> _confirmCancelTimer() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Interrompere?'),
        content: const Text('Se interrompi, non ottieni ricompense.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continua')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Interrompi')),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) Navigator.of(context).pop();
  }

  Future<void> _confirmStopwatchEnd() async {
    final minutes = _elapsedSeconds ~/ 60;
    final canReward = minutes >= 15;

    final res = await showDialog<_StopwatchAction>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Terminare cronometro?'),
        content: Text(canReward
            ? 'Tempo: ${formatSeconds(_elapsedSeconds)}\nVuoi riscuotere le ricompense?'
            : 'Tempo: ${formatSeconds(_elapsedSeconds)}\nServono almeno 15 minuti per ottenere ricompense.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, _StopwatchAction.continue_), child: const Text('Continua')),
          TextButton(
            onPressed: () => Navigator.pop(context, _StopwatchAction.cancelNoReward),
            child: const Text('Interrompi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _StopwatchAction.finish),
            child: Text(canReward ? 'Termina & Riscuoti' : 'Termina'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (res == _StopwatchAction.cancelNoReward) {
      Navigator.of(context).pop();
      return;
    }
    if (res == _StopwatchAction.finish) {
      _finishStopwatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOledSafe = widget.displayMode == FocusDisplayMode.oledSafe;

    final bool isTimer = widget.type == FocusSessionType.timer;

    final int cap = (widget.type == FocusSessionType.stopwatch)
        ? (widget.duration.inSeconds > 0 ? widget.duration.inSeconds : 3600)
        : widget.duration.inSeconds;

    final int remaining = isTimer ? _remainingSeconds.clamp(0, cap) : 0;
    final int elapsed = isTimer ? 0 : _elapsedSeconds;

    final double progress = isTimer
        ? (cap == 0 ? 1.0 : 1.0 - (remaining / cap))
        : (cap == 0 ? 0.0 : (elapsed / cap).clamp(0.0, 1.0));

    final title = isTimer ? 'Rimani concentrato.' : 'Cronometro attivo.';
    final timeText = isTimer ? formatSeconds(remaining) : formatSeconds(elapsed);
    final hint = isTimer
        ? 'Modalità timer attiva.'
        : 'Minimo 15 min per ottenere ricompense.';

    final trailing = isTimer
        ? _StopChip(label: 'Interrompi', onTap: _confirmCancelTimer)
        : _StopChip(label: 'Termina', onTap: _confirmStopwatchEnd);

    if (isOledSafe) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(widget.debugLabel ?? 'Focus Session'),
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilledButton.icon(
                onPressed: isTimer ? _confirmCancelTimer : _confirmStopwatchEnd,
                icon: const Icon(Icons.stop),
                label: Text(isTimer ? 'Interrompi' : 'Termina'),
              ),
            )
          ],
        ),
        body: _FocusBody(
          isOledSafe: true,
          x: _x,
          y: _y,
          title: title,
          timeText: timeText,
          progress: progress,
          hint: hint,
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AfkShellAppBar.back(trailing: trailing),
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground(dimming: 0.60)),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: AfkShellAppBar.kHeight),
              child: _FocusBody(
                isOledSafe: false,
                x: _x,
                y: _y,
                title: title,
                timeText: timeText,
                progress: progress,
                hint: hint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StopwatchAction { continue_, cancelNoReward, finish }
enum _Band { morning, afternoon, evening, night }

class _FocusBody extends StatelessWidget {
  const _FocusBody({
    required this.isOledSafe,
    required this.x,
    required this.y,
    required this.title,
    required this.timeText,
    required this.progress,
    required this.hint,
  });

  final bool isOledSafe;
  final double x;
  final double y;
  final String title;
  final String timeText;
  final double progress;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      color: isOledSafe ? Colors.black : Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Transform.translate(
            offset: Offset(x, y),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOledSafe ? const Color(0xFF0B0B0B) : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOledSafe ? const Color(0xFF1A1A1A) : const Color(0xFF333333),
                ),
              ),
              child: Column(
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: isOledSafe ? Colors.white70 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 10),
                  Text(hint, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _StopChip extends StatelessWidget {
  const _StopChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stop_rounded, size: 18, color: Colors.white.withValues(alpha: 0.92)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.92),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}