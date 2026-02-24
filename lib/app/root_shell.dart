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
                // ✅ Durante lo swipe/snap tra tab blocchiamo il ticker del background.
                // Questo libera GPU/CPU e rende la transizione “olio” anche su Android.
                child: TickerMode(
                  enabled: !_paging,
                  child: AppBackground(dimming: bgDimming),
                ),
              ),

              // Bottom scrim: evita che la parte bassa resti troppo “chiara”
              // nelle tab non-MyPath, e maschera eventuali micro-seams durante lo snap.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withValues(alpha: 0.22 * distMyPath01),
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
                    if (n is ScrollStartNotification) {
                      if (!_paging) setState(() => _paging = true);
                    } else if (n is ScrollEndNotification) {
                      if (_paging) setState(() => _paging = false);
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    // ✅ Evita “overshoot”/glow sui bordi durante lo snap tra pagine.
                    physics: const PageScrollPhysics(),
                    itemCount: 5,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final delta = (page - i).abs().clamp(0.0, 1.0);
                      // ✅ Effetto “depth” più sottile: meno bordi visibili sui lati
                      // e meno rischio di artefatti durante lo snap.
                      final scaleY = 1.0 - (0.018 * delta);
                      final lift = 6.0 * delta;

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

              // ✅ IMPORTANTISSIMO: la BottomNav viene disegnata DENTRO la stessa Stack del body.
              // Se la lasciamo in Scaffold.bottomNavigationBar, il body (e quindi lo scrim/dimming)
              // non copre davvero l’area sotto la nav -> si vede una “differenza” in basso.
              // Così invece background + scrim + nav sono un unico layer continuo.
              Align(
                alignment: Alignment.bottomCenter,
                child: PixelBottomNavBar(
                  currentIndex: _index,
                  page: page,
                  onChanged: _goToTab,
                ),
              ),
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

    // ✅ Performance: niente BackdropFilter full-screen.
    // Manteniamo la stessa “leggibilità” con un semplice scrim/gradient overlay
    // (molto più leggero e senza artefatti sui bordi).
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
