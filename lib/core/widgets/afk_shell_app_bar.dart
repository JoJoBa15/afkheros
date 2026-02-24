import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'currency_chip.dart';
import 'game_status_strip.dart';

/// AppBar “unificata” (status strip + glass bar) da riusare su tutte le schermate.
///
/// - In RootShell: leading = menu (drawer), trailing = valute
/// - In screen pushate: leading = back/close, trailing custom (es. Stop)
class AfkShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double kHeight = 124;

  final AfkShellLeading leadingMode;
  final VoidCallback? onLeadingTap;
  final Widget? trailing;
  final String? title;

  const AfkShellAppBar({
    super.key,
    required this.leadingMode,
    this.onLeadingTap,
    this.trailing,
    this.title,
  });

  const AfkShellAppBar.drawer({super.key, this.trailing, this.title})
      : leadingMode = AfkShellLeading.drawer,
        onLeadingTap = null;

  const AfkShellAppBar.back({super.key, this.onLeadingTap, this.trailing, this.title})
      : leadingMode = AfkShellLeading.back;

  @override
  Size get preferredSize => const Size.fromHeight(kHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      primary: false,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: kHeight,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      title: _AfkShellHeader(
        leadingMode: leadingMode,
        onLeadingTap: onLeadingTap,
        trailing: trailing,
        title: title,
      ),
    );
  }
}

enum AfkShellLeading { drawer, back, none }

class _AfkShellHeader extends StatelessWidget {
  const _AfkShellHeader({
    required this.leadingMode,
    required this.onLeadingTap,
    required this.trailing,
    required this.title,
  });

  final AfkShellLeading leadingMode;
  final VoidCallback? onLeadingTap;
  final Widget? trailing;
  final String? title;

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
                _Leading(
                  mode: leadingMode,
                  onTap: onLeadingTap,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: _CenterTitleOrHairline(
                      title: title,
                      leftFade: 28,
                      rightFade: 28,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: trailing ?? const CurrenciesBar(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.mode, required this.onTap});
  final AfkShellLeading mode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (mode == AfkShellLeading.none) {
      return const SizedBox(width: 44);
    }

    final icon = switch (mode) {
      AfkShellLeading.drawer => Icons.menu_rounded,
      AfkShellLeading.back => Icons.arrow_back_ios_new_rounded,
      AfkShellLeading.none => Icons.menu_rounded,
    };

    return Builder(
      builder: (ctx) {
        final handler = onTap ??
            switch (mode) {
              AfkShellLeading.drawer => () => Scaffold.of(ctx).openDrawer(),
              AfkShellLeading.back => () => Navigator.of(ctx).maybePop(),
              AfkShellLeading.none => () {},
            };

        return InkWell(
        onTap: handler,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Icon(
            icon,
            size: 22,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      );
      },
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.06),
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

class _CenterTitleOrHairline extends StatelessWidget {
  final String? title;
  final double leftFade;
  final double rightFade;

  const _CenterTitleOrHairline({
    required this.title,
    required this.leftFade,
    required this.rightFade,
  });

  @override
  Widget build(BuildContext context) {
    final t = title?.trim();

    final child = (t == null || t.isEmpty)
        ? _CenterSafeHairline(
            key: const ValueKey('hairline'),
            leftFade: leftFade,
            rightFade: rightFade,
          )
        : SizedBox(
            key: ValueKey('title_$t'),
            height: 45,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.70,
                  child: _CenterSafeHairline(leftFade: leftFade, rightFade: rightFade),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    t,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (w, a) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(a);
        return FadeTransition(
          opacity: a,
          child: SlideTransition(position: slide, child: w),
        );
      },
      child: child,
    );
  }
}

/// Hairline centrale: dà continuità senza mettere testo/icone al centro.
class _CenterSafeHairline extends StatelessWidget {
  final double leftFade;
  final double rightFade;

  const _CenterSafeHairline({
    super.key,
    required this.leftFade,
    required this.rightFade,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 120,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.22),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
