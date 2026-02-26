import 'dart:ui';
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
        _LiquidCurrencyChip(
          icon: Icons.monetization_on_rounded,
          value: gs.gold,
          iconColor: const Color(0xFFFFD700),
          glowColor: const Color(0xFFFFAB00).withValues(alpha: 0.3),
        ),
        const SizedBox(width: 10),
        _LiquidCurrencyChip(
          icon: Icons.diamond_rounded,
          value: gs.gems,
          iconColor: const Color(0xFF00E5FF),
          glowColor: const Color(0xFF00B8D4).withValues(alpha: 0.3),
        ),
      ],
    );
  }
}

class _LiquidCurrencyChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color iconColor;
  final Color glowColor;

  const _LiquidCurrencyChip({
    required this.icon,
    required this.value,
    required this.iconColor,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow soffuso dietro l'icona
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: glowColor,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    icon,
                    size: 17,
                    color: iconColor,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                _formatValue(value),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  color: Colors.white.withValues(alpha: 0.95),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(int val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}k';
    return '$val';
  }
}
