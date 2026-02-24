import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/widgets/app_background.dart';
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

  static const double _navSafePadding = 112; // spazio per non finire sotto la navbar glass

  @override
  Widget build(BuildContext context) {
    final isMyPath = _index == 2;
    final topPad = MediaQuery.of(context).padding.top + (isMyPath ? 0 : kToolbarHeight);
    final bottomPad = _navSafePadding + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const ProfileDrawer(),

      // ✅ Serve per avere background anche dietro AppBar e dietro navbar
      extendBody: true,
      extendBodyBehindAppBar: true,

      appBar: isMyPath ? _buildMyPathAppBar() : _buildDefaultAppBar(),

      body: Stack(
        fit: StackFit.expand,
        children: [
          // ✅ Background globale riusando quello già fatto
          const Positioned.fill(child: AppBackground()),

          // ✅ Tutte le altre tab più “dark” sopra, così riusi lo stesso gradiente/scene
          if (!isMyPath)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.black.withOpacity(0.55)),
              ),
            ),

          // Contenuto tab (con padding solo quando NON è MyPath)
          Padding(
            padding: EdgeInsets.fromLTRB(0, topPad, 0, isMyPath ? 0 : bottomPad),
            child: AnimatedSwitcher(
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
                child: _tabs[_index],
              ),
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

  PreferredSizeWidget _buildDefaultAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      centerTitle: false,
      titleSpacing: 0,

      // ✅ Glass AppBar (così si vede il background dietro e non “blocco grigio”)
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ),
      ),

      leading: Builder(
        builder: (context) => IconButton(
          tooltip: 'Profilo',
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withOpacity(0.10),
            child: const Icon(Icons.person, size: 18, color: Colors.white),
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
      toolbarHeight: 72,
      title: const _MyPathAppBarContent(),
    );
  }
}

class _MyPathAppBarContent extends StatelessWidget {
  const _MyPathAppBarContent();

  void _openMyPathMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return _MyPathMenuOverlay(progress: curved);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => _openMyPathMenu(context),
            borderRadius: BorderRadius.circular(999),
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

class _MyPathMenuOverlay extends StatelessWidget {
  final Animation<double> progress;
  const _MyPathMenuOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final v = progress.value;
          final sigma = 14.0 * v;
          final dim = 0.30 * v;
          final scale = 0.965 + (1.0 - 0.965) * v;

          return SizedBox.expand(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                        child: Container(color: Colors.black.withOpacity(dim)),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: v,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: _MyPathMenuCard(
                            onClose: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MyPathMenuCard extends StatelessWidget {
  final VoidCallback onClose;
  const _MyPathMenuCard({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsState>(
      builder: (context, settings, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 34,
                    spreadRadius: 2,
                    offset: const Offset(0, 18),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2F3A46).withOpacity(0.62),
                    const Color(0xFF15181D).withOpacity(0.66),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.10),
                          border: Border.all(color: Colors.white.withOpacity(0.14)),
                        ),
                        child: const Icon(Icons.person_outline, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        splashRadius: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DividerSoftModern(),
                  const SizedBox(height: 14),

                  const _SectionTitle('Accessibilità'),
                  const SizedBox(height: 8),
                  _ModernTile(
                    icon: Icons.shield_moon_outlined,
                    title: 'Modalità OLED-safe',
                    subtitle: 'Riduce burn-in e luminosità fissa',
                    
                    
                    onTap: () {
                      settings.setFocusDisplayMode(
                        settings.isOledSafe ? FocusDisplayMode.normal : FocusDisplayMode.oledSafe,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModernTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ModernTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.10),
              Colors.white.withOpacity(0.06),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.62),
                        fontSize: 12.5,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.55),
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1.25,
        ),
      ),
    );
  }
}

class _DividerSoftModern extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withOpacity(0.16),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}