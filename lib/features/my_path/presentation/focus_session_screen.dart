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

class FocusSessionScreen extends StatefulWidget {
  final Duration duration;
  final String? debugLabel;
  final FocusDisplayMode displayMode;

  const FocusSessionScreen({
    super.key,
    required this.duration,
    required this.displayMode,
    this.debugLabel,
  });

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  Timer? _timer;
  Timer? _pixelShiftTimer;
  late int _remainingSeconds;
  double _x = 0;
  double _y = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration.inSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _finish();
      }
    });

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

  void _finish() {
    final rewards = FocusRewards(
      gold: 10,
      gems: 0,
      iron: widget.duration.inMinutes >= 25 ? 3 : 1,
    );

    context.read<GameState>().addRewards(
          addGold: rewards.gold,
          addGems: rewards.gems,
          addIron: rewards.iron,
        );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => VictoryScreen(rewards: rewards)),
    );
  }

  Future<void> _confirmCancel() async {
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

  @override
  Widget build(BuildContext context) {
    final isOledSafe = widget.displayMode == FocusDisplayMode.oledSafe;

    final total = widget.duration.inSeconds;
    final remaining = _remainingSeconds.clamp(0, total);
    final progress = total == 0 ? 1.0 : 1.0 - (remaining / total);

    if (isOledSafe) {
      // Modalità “protetta”: rimaniamo sul nero pieno.
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
                onPressed: _confirmCancel,
                icon: const Icon(Icons.stop),
                label: const Text('Interrompi'),
              ),
            )
          ],
        ),
        body: _FocusBody(
          isOledSafe: true,
          x: _x,
          y: _y,
          remaining: remaining,
          progress: progress,
        ),
      );
    }

    // Modalità fullscreen: stesso header + stesso background (più scuro).
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AfkShellAppBar.back(
        trailing: _StopChip(onTap: _confirmCancel),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: AppBackground(dimming: 0.60),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: AfkShellAppBar.kHeight),
              child: _FocusBody(
                isOledSafe: false,
                x: _x,
                y: _y,
                remaining: remaining,
                progress: progress,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusBody extends StatelessWidget {
  const _FocusBody({
    required this.isOledSafe,
    required this.x,
    required this.y,
    required this.remaining,
    required this.progress,
  });

  final bool isOledSafe;
  final double x;
  final double y;
  final int remaining;
  final double progress;

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
                  Text(
                    isOledSafe ? 'Modalità protetta attiva.' : 'Rimani concentrato.',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatSeconds(remaining),
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: isOledSafe ? Colors.white70 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 10),
                  Text(
                    isOledSafe
                        ? 'Schermo scuro per ridurre il rischio di immagini persistenti.'
                        : 'Modalità focus attiva.',
                    style: const TextStyle(color: Colors.white70),
                  ),
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
  const _StopChip({required this.onTap});
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
              'Interrompi',
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
