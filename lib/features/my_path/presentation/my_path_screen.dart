import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/game_state.dart';
import '../../../core/widgets/pixel_panel.dart';
import 'focus_session_screen.dart';

class MyPathScreen extends StatelessWidget {
  const MyPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _HeroCard(equipped: gs.equipped),
          const SizedBox(height: 16),

          _TimerPresetRow(
            onStart: (d) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => FocusSessionScreen(duration: d)),
              );
            },
          ),

          const SizedBox(height: 16),
          const PixelPanel(
            child: Text(
              'Flusso base:\nFocus → Vittoria (+Ferro) → Forge (craft) → Equip (indossa).',
              style: TextStyle(color: Colors.white70, height: 1.35),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FocusSessionScreen(
                          duration: Duration(seconds: 15),
                          debugLabel: 'Quick Test',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bolt),
                  label: const Text('Quick Test (15s)'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final GameItem? equipped;
  const _HeroCard({required this.equipped});

  @override
  Widget build(BuildContext context) {
    final eqName = equipped?.name ?? 'Nessun equip';
    return PixelPanel(
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3A3A3A)),
            ),
            child: const Icon(Icons.person, size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Path', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Equip: $eqName', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                const Text('Il tuo eroe è pronto a concentrarsi.', style: TextStyle(color: Colors.white60)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _TimerPresetRow extends StatelessWidget {
  final void Function(Duration) onStart;
  const _TimerPresetRow({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PresetButton(
            label: '25 min',
            icon: Icons.play_arrow,
            onTap: () => onStart(const Duration(minutes: 25)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PresetButton(
            label: '45 min',
            icon: Icons.play_arrow,
            onTap: () => onStart(const Duration(minutes: 45)),
          ),
        ),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PresetButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text('Inizia ($label)'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
