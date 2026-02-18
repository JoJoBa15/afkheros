import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/game_state.dart';
import '../../../core/widgets/pixel_panel.dart';

class EquipScreen extends StatelessWidget {
  const EquipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Equip', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          PixelPanel(
            child: Row(
              children: [
                const Text('Equip attuale: ', style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Text(gs.equipped?.name ?? 'Nessuno', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: gs.inventory.isEmpty
                ? const Center(child: Text('Inventario vuoto. Fai focus e poi craft.'))
                : GridView.builder(
                    itemCount: gs.inventory.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, i) {
                      final item = gs.inventory[i];
                      final isEq = gs.equipped?.id == item.id;
                      return InkWell(
                        onTap: () => context.read<GameState>().equipItem(item),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F1F),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isEq ? Theme.of(context).colorScheme.primary : const Color(0xFF333333),
                              width: isEq ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.icon, size: 30),
                              const SizedBox(height: 8),
                              Text(
                                item.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            ],
                          ),
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
