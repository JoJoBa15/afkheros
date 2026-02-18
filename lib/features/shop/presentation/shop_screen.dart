import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/game_state.dart';
import '../../../core/widgets/pixel_panel.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shop', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          PixelPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cassa Gratis (placeholder Ads)', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Simula “guarda pubblicità → ottieni bonus”.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<GameState>().addRewards(addGold: 20, addGems: 1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hai ottenuto +20 Oro e +1 Gemma!')),
                    );
                  },
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('Apri Cassa'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PixelPanel(
            child: Text('Bilancio → Oro: ${gs.gold}, Gemme: ${gs.gems}, Ferro: ${gs.iron}'),
          ),
        ],
      ),
    );
  }
}
