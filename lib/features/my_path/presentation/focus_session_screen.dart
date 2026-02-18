import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/game_state.dart';
import '../../../core/utils/time_format.dart';
import 'victory_screen.dart';

class FocusSessionScreen extends StatefulWidget {
  final Duration duration;
  final String? debugLabel;

  const FocusSessionScreen({super.key, required this.duration, this.debugLabel});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  Timer? _timer;
  late int _remainingSeconds;

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
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    if (ok == true) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.duration.inSeconds;
    final remaining = _remainingSeconds.clamp(0, total);
    final progress = total == 0 ? 1.0 : 1.0 - (remaining / total);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.debugLabel ?? 'Focus Session'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmCancel,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Rimani concentrato.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatSeconds(remaining),
                    style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 10),
                  const Text('La NavBar è nascosta: modalità focus.', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _confirmCancel,
              icon: const Icon(Icons.stop),
              label: const Text('Interrompi'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
