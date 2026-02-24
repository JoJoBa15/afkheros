import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/game_state.dart';
import '../../../core/widgets/pixel_panel.dart';

class BlacksmithScreen extends StatelessWidget {
  const BlacksmithScreen({super.key});

  static const recipes = [
    GameRecipe(
      id: 'sword_iron',
      name: 'Spada di Ferro',
      ironCost: 3,
      result: GameItem(id: 'item_sword_iron', name: 'Spada di Ferro', icon: Icons.gavel),
    ),
    GameRecipe(
      id: 'helm_iron',
      name: 'Elmo di Ferro',
      ironCost: 2,
      result: GameItem(id: 'item_helm_iron', name: 'Elmo di Ferro', icon: Icons.sports_mma),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text('Ferro disponibile: ${gs.iron}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: recipes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = recipes[i];
                return PixelPanel(
                  child: Row(
                    children: [
                      Icon(r.result.icon, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('Costo: ${r.ironCost} Ferro', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final ok = context.read<GameState>().craft(r);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? 'Craft: ${r.result.name}' : 'Ferro insufficiente')),
                          );
                        },
                        child: const Text('Craft'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
