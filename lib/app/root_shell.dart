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
  bool _paging = false;
  bool _focusMenuOpen = false;
  final ValueNotifier<int> _focusMenuCloseReq = ValueNotifier<int>(0);

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
    _focusMenuCloseReq.dispose();
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
    if (_focusMenuOpen) return; // app “bloccata” mentre il menu Focus è aperto
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

    final bool lockShell = _focusMenuOpen;

    return Scaffold(
      drawer: const ProfileDrawer(),
      drawerEnableOpenDragGesture: !lockShell,
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(AfkShellAppBar.kHeight),
        child: AnimatedOpacity(
          opacity: lockShell ? 0.55 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: IgnorePointer(
            ignoring: lockShell,
            child: AfkShellAppBar.drawer(title: tabTitle),
          ),
        ),
      ),
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
                child: TickerMode(
                  enabled: !_paging,
                  child: AppBackground(dimming: bgDimming),
                ),
              ),

              // ✅ Bottom scrim SEMPRE presente, poi aumenta fuori MyPath:
              // uniforma la base e riduce la lettura dei cambi background dietro la nav.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withValues(
                            alpha: (0.10 + 0.16 * distMyPath01).clamp(0.0, 1.0),
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    // 🔒 “paging” SOLO per lo swipe orizzontale del PageView.
                    // Evita che il drag/scroll verticale del menu Focus blocchi animazioni globali.
                    final dir = n.metrics.axisDirection;
                    final isHorizontal =
                        dir == AxisDirection.left || dir == AxisDirection.right;
                    if (!isHorizontal) return false;

                    if (n is ScrollStartNotification) {
                      if (!_paging) setState(() => _paging = true);
                    } else if (n is ScrollEndNotification) {
                      if (_paging) setState(() => _paging = false);
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    physics: lockShell
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    itemCount: 5,
                    onPageChanged: (i) {
                      setState(() {
                        _index = i;
                        if (i != 2) _focusMenuOpen = false;
                      });
                    },
                    itemBuilder: (context, i) {
                      final delta = (page - i).abs().clamp(0.0, 1.0);
                      final scaleY = 1.0 - (0.018 * delta);
                      final lift = 6.0 * delta;

                      final Widget raw = switch (i) {
                        0 => const ShopScreen(),
                        1 => const BlacksmithScreen(),
                        2 => MyPathScreen(
                            onFocusMenuOpenChanged: (open) {
                              if (!mounted) return;
                              if (_focusMenuOpen == open) return;
                              setState(() => _focusMenuOpen = open);
                            },
                            closeSignal: _focusMenuCloseReq,
                          ),
                        3 => const EquipScreen(),
                        4 => const ClanScreen(),
                        _ => const SizedBox.shrink(),
                      };

                      final Widget pageChild = (i == 2)
                          ? raw
                          : _ShellContent(glassT: glassT, child: raw);

                      return _KeepAlive(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..translateByDouble(0.0, lift, 0.0, 1.0)
                            ..scaleByDouble(1.0, scaleY, 1.0, 1.0),
                          child: pageChild,
                        ),
                      );
                    },
                  ),
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedOpacity(
                  opacity: lockShell ? 0.55 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: IgnorePointer(
                    ignoring: lockShell,
                    child: PixelBottomNavBar(
                      currentIndex: _index,
                      page: page,
                      environment: distMyPath01, // ✅ nav segue lo scurire
                      onChanged: _goToTab,
                    ),
                  ),
                ),
              ),

              // 🔒 Zone “fuori menu” ma sopra UI (AppBar + Navbar): tap = chiudi menu.
              if (lockShell && _index == 2) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: AfkShellAppBar.kHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _focusMenuCloseReq.value++,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _contentBottomPad +
                      MediaQuery.of(context).padding.bottom,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _focusMenuCloseReq.value++,
                  ),
                ),
              ],
            ],
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

class _ContentGlass extends StatelessWidget {
  const _ContentGlass({required this.child, required this.t});
  final Widget child;
  final double t; // 0..1

  @override
  Widget build(BuildContext context) {
    if (t <= 0.001) return child;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06 * t),
                    Colors.black.withValues(alpha: 0.14 * t),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
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