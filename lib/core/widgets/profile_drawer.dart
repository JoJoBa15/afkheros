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
      backgroundColor: const Color(0xFF171717),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1F1F1F)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Color(0xFF2A2A2A),
              child: Icon(Icons.person),
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
          const Divider(height: 1),
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
      leading: Icon(icon),
      title: Text(title),
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
