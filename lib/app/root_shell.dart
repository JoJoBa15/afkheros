import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/widgets/pixel_bottom_nav_bar.dart';
import '../core/widgets/profile_drawer.dart';
import '../core/widgets/currency_chip.dart';
import '../core/widgets/game_status_strip.dart';

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

  final _tabs = const [
    ShopScreen(),
    BlacksmithScreen(),
    MyPathScreen(),
    EquipScreen(),
    ClanScreen(),
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
      extendBodyBehindAppBar: isMyPath,
      extendBody: isMyPath,
      backgroundColor: isMyPath ? Colors.transparent : null,
      appBar: isMyPath ? _buildMyPathAppBar() : _buildDefaultAppBar(),
      body: IndexedStack(index: _index, children: _tabs),
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
      titleSpacing: 0,
      leading: Builder(
        builder: (context) => IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: const [CurrenciesBar(), SizedBox(width: 8)],
    );
  }

  PreferredSizeWidget _buildMyPathAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      primary: false,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: 124,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      title: const _MyPathAppleTop(),
    );
  }
}

class _MyPathAppleTop extends StatelessWidget {
  const _MyPathAppleTop();

  @override
  Widget build(BuildContext context) {
    final vp = MediaQuery.of(context).viewPadding;

    const baseSide = 14.0;
    final leftPad = baseSide + (vp.left > 0 ? vp.left : 0);
    final rightPad = baseSide + (vp.right > 0 ? vp.right : 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GameStatusStrip(),
        const SizedBox(height: 10),

        Padding(
          padding: EdgeInsets.only(left: leftPad, right: rightPad),
          child: _AppleUnifiedGlassBar(
            child: Row(
              children: [
                // left
                InkWell(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 22,
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ),
                ),

                // center safe zone: lascia spazio alla camera/notch ma senza “vuoto brutto”
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: _CenterSafeHairline(
                      leftFade: 28,
                      rightFade: 28,
                    ),
                  ),
                ),

                // right
                const Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: CurrenciesBar(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Una sola barra glass: Apple-like, pulita.
class _AppleUnifiedGlassBar extends StatelessWidget {
  final Widget child;
  const _AppleUnifiedGlassBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(22);

    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: r,
            // glass “chiaro” ma non latteo: si integra col blu del background
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.06),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Hairline centrale: dà continuità senza mettere testo/icone al centro.
class _CenterSafeHairline extends StatelessWidget {
  final double leftFade;
  final double rightFade;

  const _CenterSafeHairline({
    required this.leftFade,
    required this.rightFade,
  });

  @override
  Widget build(BuildContext context) {
    // linea sottilissima con fade ai bordi
    return SizedBox(
      height: 100,
      width: 120,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.22),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}