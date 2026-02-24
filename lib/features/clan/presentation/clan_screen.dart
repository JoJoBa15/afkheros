import 'package:flutter/material.dart';
import '../../../core/widgets/pixel_panel.dart';

class ClanScreen extends StatelessWidget {
  const ClanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const PixelPanel(
            child: Text('TODO: Leaderboard / Boss / Chat (in futuro).'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: const [
                ListTile(leading: Icon(Icons.emoji_events), title: Text('1) PlayerOne - 1200')),
                ListTile(leading: Icon(Icons.emoji_events), title: Text('2) PlayerTwo - 950')),
                ListTile(leading: Icon(Icons.emoji_events), title: Text('3) PlayerThree - 720')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
