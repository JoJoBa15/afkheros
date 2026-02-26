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

class _RootShellState extends State<RootShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int _index = 2;
  late final PageController _pageController;
  bool _paging = false;

  late final AnimationController _sessionMenuCtrl;
  bool _sessionMenuActive = false;
  DateTime _sessionMenuNow = DateTime.now();

  static const double _contentBottomPad =
      PixelBottomNavBar.barHeight + PixelBottomNavBar.centerLift + 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _index);
    _applyImmersiveSticky();

    _sessionMenuCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _sessionMenuCtrl.dispose();
    super.dispose();
  }

  void _openSessionMenu(DateTime now) {
    _sessionMenuNow = now;
    if (_sessionMenuActive) return;
    HapticFeedback.lightImpact();
    setState(() => _sessionMenuActive = true);
    _sessionMenuCtrl.forward(from: 0);
  }

  Future<void> _closeSessionMenu() async {
    if (!_sessionMenuActive) return;
    await _sessionMenuCtrl.reverse();
    if (mounted) setState(() => _sessionMenuActive = false);
  }

  void _handleSessionDragUpdate(DragUpdateDetails details) {
    final h = MediaQuery.of(context).size.height * 0.54;
    
    if (!_sessionMenuActive && details.delta.dy < -2) {
      _sessionMenuNow = DateTime.now();
      setState(() => _sessionMenuActive = true);
      _sessionMenuCtrl.value = 0;
    }
    
    if (_sessionMenuActive) {
      _sessionMenuCtrl.value -= details.delta.dy / h;
    }
  }

  void _handleSessionDragEnd(DragEndDetails details) {
    if (!_sessionMenuActive) return;
    
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -200) {
      _sessionMenuCtrl.forward();
      return;
    }
    if (velocity > 200) {
      _closeSessionMenu();
      return;
    }
    if (_sessionMenuCtrl.value > 0.3) {
      _sessionMenuCtrl.forward();
    } else {
      _closeSessionMenu();
    }
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
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutExpo,
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

    return PopScope(
      canPop: !_sessionMenuActive,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _closeSessionMenu();
      },
      child: Scaffold(
        drawer: const ProfileDrawer(),
        drawerEnableOpenDragGesture: !_sessionMenuActive,
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(AfkShellAppBar.kHeight),
          child: AnimatedBuilder(
            animation: _sessionMenuCtrl,
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(_sessionMenuCtrl.value);
              return IgnorePointer(
                ignoring: _sessionMenuActive,
                child: Opacity(
                  opacity: (1.0 - 0.20 * t).clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: AfkShellAppBar.drawer(title: tabTitle),
          ),
        ),
        body: AnimatedBuilder(
          animation: Listenable.merge([_pageController, _sessionMenuCtrl]),
          builder: (context, _) {
            final page = _currentPage();
            final distMyPath01 = (page - 2.0).abs().clamp(0.0, 1.0);
            final bgDimming = 0.65 * distMyPath01;

            return Stack(
              children: [
                Positioned.fill(
                  child: TickerMode(
                    enabled: !_paging,
                    child: AppBackground(dimming: bgDimming),
                  ),
                ),
                
                Positioned.fill(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollStartNotification) {
                        if (!_paging) setState(() => _paging = true);
                      } else if (n is ScrollEndNotification) {
                        if (_paging) setState(() => _paging = false);
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      physics: _sessionMenuActive
                          ? const NeverScrollableScrollPhysics()
                          : const PageScrollPhysics(),
                      itemCount: 5,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        final delta = (page - i).abs().clamp(0.0, 1.0);
                        final scaleY = 1.0 - (0.012 * delta);
                        final lift = 3.0 * delta;

                        final Widget pageChild = switch (i) {
                          0 => const ShopScreen(),
                          1 => const BlacksmithScreen(),
                          2 => GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onVerticalDragUpdate: _handleSessionDragUpdate,
                              onVerticalDragEnd: _handleSessionDragEnd,
                              child: MyPathScreen(onOpenSessionMenu: _openSessionMenu),
                            ),
                          3 => const EquipScreen(),
                          4 => const ClanScreen(),
                          _ => const SizedBox.shrink(),
                        };

                        return _KeepAlive(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..translateByDouble(0.0, lift, 0.0, 1.0)
                              ..scaleByDouble(1.0, scaleY, 1.0, 1.0),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: AfkShellAppBar.kHeight,
                                bottom: _contentBottomPad,
                              ),
                              child: pageChild,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedBuilder(
                    animation: _sessionMenuCtrl,
                    builder: (context, child) {
                      final t = Curves.easeOutCubic.transform(_sessionMenuCtrl.value);
                      final opacity = (1.0 - t).clamp(0.0, 1.0);
                      return IgnorePointer(
                        ignoring: _sessionMenuActive,
                        child: Transform.translate(
                          offset: Offset(0, 18 * t),
                          child: Opacity(opacity: opacity, child: child),
                        ),
                      );
                    },
                    child: PixelBottomNavBar(
                      currentIndex: _index,
                      page: page,
                      environment: distMyPath01,
                      onChanged: _goToTab,
                    ),
                  ),
                ),

                if (_sessionMenuActive)
                  Positioned.fill(
                    child: _SessionMenuOverlay(
                      controller: _sessionMenuCtrl,
                      now: _sessionMenuNow,
                      onClose: _closeSessionMenu,
                      onDragUpdate: _handleSessionDragUpdate,
                      onDragEnd: _handleSessionDragEnd,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SessionMenuOverlay extends StatelessWidget {
  const _SessionMenuOverlay({
    required this.controller,
    required this.now,
    required this.onClose,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final AnimationController controller;
  final DateTime now;
  final Future<void> Function() onClose;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final ValueChanged<DragEndDetails> onDragEnd;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(controller.value);
        final size = MediaQuery.of(context).size;
        final h = size.height;

        final maxH = h * 0.75;
        final minH = (maxH < 420.0) ? maxH : 420.0;
        final sheetH = (h * 0.54).clamp(minH, maxH);

        const double margin = 14.0;
        double dy = (1 - t) * (sheetH + margin + 60);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onClose(),
                onVerticalDragUpdate: onDragUpdate,
                onVerticalDragEnd: onDragEnd,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8.0 * t, sigmaY: 8.0 * t),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45 * t),
                  ),
                ),
              ),
            ),
            Positioned(
              left: margin,
              right: margin,
              bottom: margin,
              child: GestureDetector(
                onVerticalDragUpdate: onDragUpdate,
                onVerticalDragEnd: onDragEnd,
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: SizedBox(
                    height: sheetH,
                    child: SessionStartSheet(
                      now: now,
                      onClose: onClose,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
