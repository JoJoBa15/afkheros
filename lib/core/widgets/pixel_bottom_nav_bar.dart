import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class PixelBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final double? page;
  final double environment; // 0..1 (0=MyPath, 1=altre tab)
  final ValueChanged<int> onChanged;

  const PixelBottomNavBar({
    super.key,
    required this.currentIndex,
    this.page,
    this.environment = 0.0,
    required this.onChanged,
  });

  static const double barHeight = 78;
  static const double radius = 26;
  static const double centerSize = 60;
  static const double centerLift = 18;

  @override
  State<PixelBottomNavBar> createState() => _PixelBottomNavBarState();
}

class _PixelBottomNavBarState extends State<PixelBottomNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final secondary = scheme.secondary;
    final tertiary = scheme.tertiary;

    final env = widget.environment.clamp(0.0, 1.0);

    final tint = _op(Colors.black, 0.18 + 0.12 * env); // 0.18..0.30
    final border = _op(Colors.white, 0.16 - 0.02 * env);
    final highlight = _op(Colors.white, 0.10 - 0.02 * env);

    final page = widget.page ?? widget.currentIndex.toDouble();

    double sel(int index) {
      final d = (page - index).abs();
      return (1.0 - d).clamp(0.0, 1.0);
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: SizedBox(
          height: PixelBottomNavBar.barHeight + PixelBottomNavBar.centerLift,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final t = _anim.value;
              final dx = math.sin(t * math.pi * 2) * 0.35;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _GlassShell(
                      height: PixelBottomNavBar.barHeight,
                      radius: PixelBottomNavBar.radius,
                      tint: tint,
                      border: border,
                      highlight: highlight,
                      environment: env,
                      glowDx: dx,
                      glowColors: [
                        primary.withValues(alpha: 0.18),
                        tertiary.withValues(alpha: 0.14),
                        secondary.withValues(alpha: 0.10),
                      ],
                      child: Row(
                        children: [
                          // ✅ senza padding interno: il “click area” parte dal bordo reale della shell
                          Expanded(
                            child: _GlassNavItem(
                              label: 'Shop',
                              icon: Icons.shopping_bag,
                              selection: sel(0),
                              onTap: () => widget.onChanged(0),
                              selectedColor: primary,
                            ),
                          ),
                          Expanded(
                            child: _GlassNavItem(
                              label: 'Forge',
                              icon: Icons.hardware,
                              selection: sel(1),
                              onTap: () => widget.onChanged(1),
                              selectedColor: primary,
                            ),
                          ),
                          const SizedBox(width: PixelBottomNavBar.centerSize + 16),
                          Expanded(
                            child: _GlassNavItem(
                              label: 'Equip',
                              icon: Icons.backpack,
                              selection: sel(3),
                              onTap: () => widget.onChanged(3),
                              selectedColor: primary,
                            ),
                          ),
                          Expanded(
                            child: _GlassNavItem(
                              label: 'Clan',
                              icon: Icons.shield,
                              selection: sel(4),
                              onTap: () => widget.onChanged(4),
                              selectedColor: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.translate(
                      offset: const Offset(0, -0.5),
                      child: _CenterOrbItem(
                        size: PixelBottomNavBar.centerSize,
                        label: 'My Path',
                        icon: Icons.explore,
                        selection: sel(2),
                        onTap: () => widget.onChanged(2),
                        accent: primary,
                        environment: env,
                        glowDx: dx,
                        glowA: primary,
                        glowB: tertiary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlassShell extends StatelessWidget {
  final double height;
  final double radius;
  final Color tint;
  final Color border;
  final Color highlight;
  final double environment;
  final double glowDx;
  final List<Color> glowColors;
  final Widget child;

  const _GlassShell({
    required this.height,
    required this.radius,
    required this.tint,
    required this.border,
    required this.highlight,
    required this.environment,
    required this.glowDx,
    required this.glowColors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final env = environment.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: _op(Colors.black, 0.50),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(decoration: BoxDecoration(color: tint)),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(glowDx * 50, 0),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: const Alignment(-1, -1),
                            end: const Alignment(1, 1),
                            colors: glowColors,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.55, 1.0],
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.02),
                          Colors.black.withValues(alpha: 0.12 + 0.10 * env),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(0, -1),
                        end: const Alignment(0, 1),
                        stops: const [0.0, 0.35, 1.0],
                        colors: [
                          highlight,
                          _op(Colors.white, 0.03),
                          _op(Colors.white, 0.00),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ✅ niente padding: click-area coincide con i bordi della barra
              child,

              // bordo SOPRA tutto (pulito, senza artefatti)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: r,
                      border: Border.all(color: border, width: 1.25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final double selection; // 0..1
  final VoidCallback onTap;
  final Color selectedColor;

  const _GlassNavItem({
    required this.label,
    required this.icon,
    required this.selection,
    required this.onTap,
    required this.selectedColor,
  });

  static const double _bubble = 46;
  static const double _iconSize = 25;

  @override
  Widget build(BuildContext context) {
    final t = selection.clamp(0.0, 1.0);

    final inactive = _op(Colors.white, 0.72);
    final active = selectedColor;

    final ring = Color.lerp(
      _op(Colors.white, 0.18),
      active.withValues(alpha: 0.62),
      t,
    )!;
    final fill = Color.lerp(
      Colors.black.withValues(alpha: 0.14),
      active.withValues(alpha: 0.16),
      t,
    )!;

    final iconColor = Color.lerp(inactive, active, t)!;
    final labelColor = Color.lerp(inactive, active, t)!;

    final borderW = 1.25 + (1.05 * t);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // ✅ ora l’InkWell copre davvero tutta la “corsia” fino ai bordi
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: PixelBottomNavBar.barHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: _bubble,
                  height: _bubble,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill,
                    border: Border.all(color: ring, width: borderW),
                    boxShadow: [
                      if (t > 0.01)
                        BoxShadow(
                          color: active.withValues(alpha: 0.22 * t),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      scale: 1.0 + (0.10 * t),
                      child: Icon(icon, color: iconColor, size: _iconSize),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 14,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                      color: labelColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterOrbItem extends StatelessWidget {
  final double size;
  final String label;
  final IconData icon;
  final double selection; // 0..1
  final VoidCallback onTap;
  final Color accent;
  final double environment;

  final double glowDx;
  final Color glowA;
  final Color glowB;

  const _CenterOrbItem({
    required this.size,
    required this.label,
    required this.icon,
    required this.selection,
    required this.onTap,
    required this.accent,
    required this.environment,
    required this.glowDx,
    required this.glowA,
    required this.glowB,
  });

  @override
  Widget build(BuildContext context) {
    final t = selection.clamp(0.0, 1.0);
    final env = environment.clamp(0.0, 1.0);

    final inactiveIcon = _op(Colors.white, 0.92);
    final activeIcon = const Color(0xFF0B0B0B);
    final iconColor = Color.lerp(inactiveIcon, activeIcon, t)!;

    final ring = Color.lerp(_op(Colors.white, 0.18), _op(accent, 0.52), t)!;
    final ringW = 1.35 + (1.10 * t);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ niente più splash ovale: ripple SOLO circolare sul bottone
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkResponse(
              onTap: onTap,
              containedInkWell: true,
              highlightShape: BoxShape.circle,
              customBorder: const CircleBorder(),
              radius: size / 2 + 18,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _op(Colors.black, 0.55),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: accent.withValues(alpha: 0.30 * t),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color:
                                  Colors.black.withValues(alpha: 0.14 + 0.10 * env),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Transform.translate(
                            offset: Offset(glowDx * 18, 0),
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: const Alignment(-0.25, -0.35),
                                    stops: const [0.0, 0.72, 1.0],
                                    colors: [
                                      Colors.white.withValues(alpha: 0.16),
                                      glowA.withValues(alpha: 0.52),
                                      glowB.withValues(alpha: 0.28),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.06),
                                    Colors.black.withValues(
                                        alpha: 0.10 + 0.10 * env),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: ring, width: ringW),
                            ),
                          ),
                        ),
                        Center(
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            scale: 1.0 + (0.10 * t),
                            child: Icon(icon, size: 28, color: iconColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // label tappabile senza “ovale” (niente ripple qui)
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.translucent,
            child: SizedBox(
              height: 14,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: Color.lerp(_op(Colors.white, 0.72), accent, t),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _op(Color c, double opacity) {
  final o = opacity.clamp(0.0, 1.0);
  return c.withAlpha((o * 255).round());
}