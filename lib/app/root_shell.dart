import 'package:flutter/material.dart';

import '../core/widgets/pixel_bottom_nav_bar.dart';
import '../core/widgets/profile_drawer.dart';
import '../core/widgets/currency_chip.dart';

import '../features/shop/presentation/shop_screen.dart';
import '../features/blacksmith/presentation/blacksmith_screen.dart';
import '../features/my_path/presentation/my_path_screen.dart';
import '../features/equip/presentation/equip_screen.dart';
import '../features/clan/presentation/clan_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 2; // My Path default

  final _tabs = const [
    ShopScreen(),
    BlacksmithScreen(),
    MyPathScreen(),
    EquipScreen(),
    ClanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ProfileDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Profilo',
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2A2A2A),
              child: Icon(Icons.person, size: 18),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: const [
          CurrenciesBar(),
          SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),
      bottomNavigationBar: PixelBottomNavBar(
        currentIndex: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
