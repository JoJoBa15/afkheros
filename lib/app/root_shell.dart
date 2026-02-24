import 'dart:ui';

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
  late final PageController _pageController;

  static const double _contentBottomPad =
      PixelBottomNavBar.barHeight + PixelBottomNavBar.centerLift + 26;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _index);
    _applyImmersiveSticky();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _applyImmersiveSticky();
  }

  Future<void> _applyImmersiveSticky() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _goToTab(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  double _currentPage() {
    if (!_pageController.hasClients) return _index.toDouble();
    return _pageController.page ?? _index.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final String? tabTitle = switch (_index) {
      0 => 'Shop',
      1 => 'Forge',
      3 => 'Equip',
      4 => 'Clan',
      _ => null,
    };

    return Scaffold(
      drawer: const ProfileDrawer(),
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AfkShellAppBar.drawer(title: tabTitle),
      body: AnimatedBuilder(
        animation: _pageController,
        builder: (context, _) {
          final page = _currentPage();

          // 0 su MyPath, 1 su tutte le altre tab.
          final distMyPath01 = (page - 2.0).abs().clamp(0.0, 1.0);
          final bgDimming = 0.42 * distMyPath01;
          final glassT = distMyPath01;

          return Stack(
            children: [
              Positioned.fill(
                child: AppBackground(
                  dimming: bgDimming,
                ),
              ),

              Positioned.fill(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
                  itemCount: 5,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final delta = (page - i).abs().clamp(0.0, 1.0);
                    final scale = 1.0 - (0.030 * delta);
                    final opacity = 1.0 - (0.12 * delta);
                    final lift = 10.0 * delta;

                    final Widget raw = switch (i) {
                      0 => const ShopScreen(),
                      1 => const BlacksmithScreen(),
                      2 => const MyPathScreen(),
                      3 => const EquipScreen(),
                      4 => const ClanScreen(),
                      _ => const SizedBox.shrink(),
                    };

                    final Widget pageChild = (i == 2)
                        ? raw
                        : _ShellContent(
                            glassT: glassT,
                            child: raw,
                          );

                    return _KeepAlive(
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, lift),
                          child: Transform.scale(
                            scale: scale,
                            child: pageChild,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _pageController,
        builder: (context, _) {
          return PixelBottomNavBar(
            currentIndex: _index,
            page: _currentPage(),
            onChanged: _goToTab,
          );
        },
      ),
    );
  }
}

class _ShellContent extends StatelessWidget {
  const _ShellContent({required this.child, required this.glassT});
  final Widget child;
  final double glassT;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AfkShellAppBar.kHeight,
        bottom: _RootShellState._contentBottomPad,
      ),
      child: _ContentGlass(t: glassT, child: child),
    );
  }
}

/// “Glass soft” dietro ai contenuti delle tab non-MyPath.
///
/// - Blur leggerissimo del background
/// - Overlay molto tenue (leggibilità senza ammazzare i colori)
class _ContentGlass extends StatelessWidget {
  const _ContentGlass({required this.child, required this.t});
  final Widget child;
  final double t; // 0..1

  @override
  Widget build(BuildContext context) {
    if (t <= 0.001) return child;

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.04 * t),
                      Colors.black.withOpacity(0.10 * t),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}