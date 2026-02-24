import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/game_state.dart';
import 'simple_page.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Drawer(
      // Sfondo del drawer nero assoluto
      backgroundColor: Colors.black,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            // Sfondo dell'header nero assoluto
            decoration: const BoxDecoration(color: Colors.black),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Color(0xFF1A1A1A), // Grigio scurissimo per staccare dal nero
              child: Icon(Icons.person, color: Colors.white70),
            ),
            accountName: Text(gs.username),
            accountEmail: Text('Lv. ${gs.level}'),
          ),
          
          _drawerItem(
            context,
            icon: Icons.campaign,
            title: 'Comunicazioni',
            onTap: () => _open(context, 'Comunicazioni'),
          ),
          _drawerItem(
            context,
            icon: Icons.emoji_events,
            title: 'Record',
            onTap: () => _open(context, 'Record'),
          ),
          _drawerItem(
            context,
            icon: Icons.history,
            title: 'Cronologia',
            onTap: () => _open(context, 'Cronologia'),
          ),
          _drawerItem(
            context,
            icon: Icons.group,
            title: 'Amici',
            onTap: () => _open(context, 'Amici'),
          ),
          
          const Spacer(),
          const Divider(height: 1, color: Color(0xFF1A1A1A)), // Divider scuro
          
          _drawerItem(
            context,
            icon: Icons.settings,
            title: 'Impostazioni',
            onTap: () => _open(context, 'Impostazioni'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context); // chiude drawer
        onTap();
      },
    );
  }

  void _open(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SimplePage(title: title)),
    );
  }
}