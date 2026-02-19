import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/widgets/pixel_bottom_nav_bar.dart';
import '../core/widgets/profile_drawer.dart';
import '../core/widgets/currency_chip.dart';

import '../features/shop/presentation/shop_screen.dart';
import '../features/blacksmith/presentation/blacksmith_screen.dart';
import '../features/my_path/presentation/my_path_screen.dart';
import '../features/equip/presentation/equip_screen.dart';
import '../features/clan/presentation/clan_screen.dart';

import '../state/settings_state.dart';

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
    final isMyPath = _index == 2;

    return Scaffold(
      drawer: const ProfileDrawer(),

      // SOLO su MyPath: il body passa dietro l’AppBar (sfondo fino in cima)
      extendBodyBehindAppBar: isMyPath,

      appBar: isMyPath ? _buildMyPathAppBar() : _buildDefaultAppBar(),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final fade = FadeTransition(opacity: animation, child: child);
          final offsetTween = Tween(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(position: offsetTween, child: fade);
        },
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: IndexedStack(
            index: _index,
            children: _tabs,
          ),
        ),
      ),

      bottomNavigationBar: PixelBottomNavBar(
        currentIndex: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }

  PreferredSizeWidget _buildDefaultAppBar() {
    return AppBar(
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
    );
  }

  PreferredSizeWidget _buildMyPathAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,

      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),

      automaticallyImplyLeading: false,
      titleSpacing: 0,

      // più compatto (meno fascia nera sopra)
      toolbarHeight: 72,

      title: const _MyPathAppBarContent(),
    );
  }
}

class _MyPathAppBarContent extends StatelessWidget {
  const _MyPathAppBarContent();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          PopupMenuButton<int>(
            onSelected: (value) {
              if (value == 0) {
                settings.setFocusDisplayMode(
                  settings.isOledSafe
                      ? FocusDisplayMode.normal
                      : FocusDisplayMode.oledSafe,
                );
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 0,
                checked: settings.isOledSafe,
                child: const Text('Modalità OLED-safe'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 1,
                enabled: false,
                child: Text('Impostazioni'),
              ),
            ],

            // ✅ USER BUTTON più grande
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),

          const Spacer(),
          const CurrenciesBar(),
        ],
      ),
    );
  }
}
