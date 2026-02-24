import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/widgets/pixel_bottom_nav_bar.dart';
import '../core/widgets/profile_drawer.dart';
import '../core/widgets/currency_chip.dart';
import '../core/widgets/game_status_strip.dart';

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

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _index = 2; // My Path default

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
    // ✅ su alcuni device, tornando in app riappaiono le barre: le rimettiamo sticky
    if (state == AppLifecycleState.resumed) {
      _applyImmersiveSticky();
    }
  }

  Future<void> _applyImmersiveSticky() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    final isMyPath = _index == 2;

    return Scaffold(
      drawer: const ProfileDrawer(),

      // ✅ sfondo sotto AppBar (già lo avevi)
      extendBodyBehindAppBar: isMyPath,

      // ✅ IMPORTANTISSIMO: permette al body di “scendere” dietro la bottom nav
      extendBody: isMyPath,

      // ✅ evita che lo Scaffold “riempia” con nero sotto
      backgroundColor: isMyPath ? Colors.transparent : null,

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
          child: IndexedStack(index: _index, children: _tabs),
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
      // ✅ AppBar “glass” trasparente
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,

      // ✅ NON vogliamo padding automatico (lo gestiamo noi con SafeArea nella strip)
      primary: false,

      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),

      automaticallyImplyLeading: false,
      titleSpacing: 0,

      // Altezza maggiore: strip (ora+batteria) + riga profilo/valute
      toolbarHeight: 106,

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
      barrierColor: Colors.transparent, // lo gestiamo noi nel blur overlay
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Ora + Batteria (notch/punch-hole safe)
        const GameStatusStrip(),

        // Riga principale header (profilo + valute)
        Padding(
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
        ),
      ],
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

          // Blur e dim più morbidi (meno “nero”)
          final sigma = 14.0 * v;
          final dim = 0.30 * v;

          // Card animata separatamente
          final scale = 0.965 + (1.0 - 0.965) * v;

          return SizedBox.expand(
            child: Stack(
              children: [
                // ✅ FIX bande laterali: ClipRect + BackdropFilter full-screen
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
                // glass scuro “blu-grigio”
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

                  const _SectionTitle('Profilo'),
                  const SizedBox(height: 8),
                  _ModernTile(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Gestione profilo',
                    subtitle: 'Account, avatar, progressi',
                    onTap: () {
                      onClose();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('TODO: schermata profilo')),
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  const _SectionTitle('App'),
                  const SizedBox(height: 8),
                  _ModernTile(
                    icon: Icons.tune_rounded,
                    title: 'Impostazioni app',
                    subtitle: 'Audio, notifiche, privacy',
                    onTap: () {
                      onClose();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('TODO: impostazioni app')),
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  const _SectionTitle('Focus'),
                  const SizedBox(height: 8),
                  _ModernTile(
                    icon: Icons.timer_outlined,
                    title: 'Strumenti Focus',
                    subtitle: 'Preset, suoni, blocco distrazioni',
                    onTap: () {
                      onClose();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('TODO: strumenti focus')),
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  const _SectionTitle('Accessibilità'),
                  const SizedBox(height: 8),
                  _ModernTile(
                    icon: Icons.shield_moon_outlined,
                    title: 'Modalità OLED-safe',
                    subtitle: 'Riduce burn-in e luminosità fissa',
                    trailing: Switch(
                      value: settings.isOledSafe,
                      onChanged: (v) {
                        settings.setFocusDisplayMode(
                          v ? FocusDisplayMode.oledSafe : FocusDisplayMode.normal,
                        );
                      },
                    ),
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

/// Card “pill” moderne
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