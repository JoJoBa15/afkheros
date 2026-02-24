import 'package:flutter/material.dart';
import '../../../state/game_state.dart';

import '../../../core/widgets/afk_shell_app_bar.dart';
import '../../../core/widgets/app_background.dart';

class VictoryScreen extends StatelessWidget {
  final FocusRewards rewards;
  const VictoryScreen({super.key, required this.rewards});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: const AfkShellAppBar.back(),
      body: Stack(
        children: [
          const Positioned.fill(
            child: AppBackground(dimming: 0.52),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: AfkShellAppBar.kHeight),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ricompense',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          Text('🪙 Oro: +${rewards.gold}'),
                          Text('💎 Gemme: +${rewards.gems}'),
                          Text('⛓️ Ferro: +${rewards.iron}'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Torna al Cammino'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
