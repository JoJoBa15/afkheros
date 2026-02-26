import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/game_state.dart';

class BlacksmithScreen extends StatelessWidget {
  const BlacksmithScreen({super.key});

  static const recipes = [
    GameRecipe(
      id: 'sword_iron',
      name: 'Spada di Ferro',
      ironCost: 3,
      result: GameItem(id: 'item_sword_iron', name: 'Spada di Ferro', icon: Icons.colorize_rounded),
    ),
    GameRecipe(
      id: 'helm_iron',
      name: 'Elmo di Ferro',
      ironCost: 2,
      result: GameItem(id: 'item_helm_iron', name: 'Elmo di Ferro', icon: Icons.shield_moon_rounded),
    ),
    GameRecipe(
      id: 'shield_iron',
      name: 'Scudo Pesante',
      ironCost: 4,
      result: GameItem(id: 'item_shield_iron', name: 'Scudo Pesante', icon: Icons.shield_rounded),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildMaterialsHeader(gs.iron),
              const SizedBox(height: 24),
              _buildSectionTitle('Ricette Disponibili'),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recipes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildForgeCard(context, recipes[index], gs.iron);
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildMaterialsHeader(int iron) {
    return _LiquidForgeContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.hardware_rounded, color: Colors.blueGrey, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FERRO DISPONIBILE', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w800)),
              Text('$iron Unità', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const Spacer(),
          Text(
            'FORGIA ATTIVA',
            style: TextStyle(color: Colors.orangeAccent.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildForgeCard(BuildContext context, GameRecipe recipe, int currentIron) {
    final canCraft = currentIron >= recipe.ironCost;

    return _LiquidForgeContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(recipe.result.icon, color: Colors.white.withValues(alpha: 0.9), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.hardware_rounded, size: 12, color: canCraft ? Colors.white54 : Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.ironCost} Ferro richiesto',
                      style: TextStyle(
                        color: canCraft ? Colors.white54 : Colors.redAccent.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canCraft ? () {
              final ok = context.read<GameState>().craft(recipe);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'Hai forgiato: ${recipe.result.name}' : 'Errore nella forgia')),
              );
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canCraft ? Colors.white : Colors.white.withValues(alpha: 0.05),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
              disabledForegroundColor: Colors.white24,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('FORGIA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _LiquidForgeContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _LiquidForgeContainer({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
