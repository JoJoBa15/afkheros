import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';

class CurrenciesBar extends StatelessWidget {
  const CurrenciesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Row(
      children: [
        CurrencyChip(icon: Icons.circle, label: '${gs.gold}', tooltip: 'Oro'),
        const SizedBox(width: 8),
        CurrencyChip(icon: Icons.diamond, label: '${gs.gems}', tooltip: 'Gemme'),
        const SizedBox(width: 8),
      ],
    );
  }
}

class CurrencyChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;

  const CurrencyChip({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
