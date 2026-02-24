import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/widgets/app_background.dart';
import '../core/widgets/afk_shell_app_bar.dart';
import '../core/widgets/pixel_bottom_nav_bar.dart';
import '../core/widgets/profile_drawer.dart';

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

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _index = 2;

  static const double _contentBottomPad =
      PixelBottomNavBar.barHeight + PixelBottomNavBar.centerLift + 26;

  final _tabs = const [
    _ShellContent(child: ShopScreen()),
    _ShellContent(child: BlacksmithScreen()),
    MyPathScreen(),
    _ShellContent(child: EquipScreen()),
    _ShellContent(child: ClanScreen()),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyImmersiveSticky();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _applyImmersiveSticky();
  }

  Future<void> _applyImmersiveSticky() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    final isMyPath = _index == 2;

    return Scaffold(
      drawer: const ProfileDrawer(),
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: const AfkShellAppBar.drawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: AppBackground(
              dimming: isMyPath ? 0.0 : 0.42,
            ),
          ),

          Positioned.fill(
            child: IndexedStack(
              index: _index,
              children: _tabs,
            ),
          ),
        ],
      ),
      bottomNavigationBar: PixelBottomNavBar(
        currentIndex: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _ShellContent extends StatelessWidget {
  const _ShellContent({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AfkShellAppBar.kHeight,
        bottom: _RootShellState._contentBottomPad,
      ),
      child: child,
    );
  }
}