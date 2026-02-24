import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';

class CurrenciesBar extends StatelessWidget {
  const CurrenciesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CurrencyInline(icon: Icons.monetization_on_rounded, value: gs.gold),
        const SizedBox(width: 15),
        _CurrencyInline(icon: Icons.diamond_outlined, value: gs.gems),
      ],
    );
  }
}

class _CurrencyInline extends StatelessWidget {
  final IconData icon;
  final int value;

  const _CurrencyInline({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.90)),
        const SizedBox(width: 6),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
            height: 1.0,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}