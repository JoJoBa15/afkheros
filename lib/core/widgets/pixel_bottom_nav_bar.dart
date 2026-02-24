import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Bottom navigation bar "Liquid Glass"
/// - Blur + glass più trasparente (si vede davvero il background)
/// - Glow gradiente ANIMATO (profondità, non grigio fisso)
/// - Orb centrale sollevato
class PixelBottomNavBar extends StatefulWidget {
  final int currentIndex;

  /// Progress continuo (es: PageController.page) per una selezione “seamless” durante lo swipe.
  ///
  /// Se null, usa currentIndex.
  final double? page;

  final ValueChanged<int> onChanged;

  const PixelBottomNavBar({
    super.key,
    required this.currentIndex,
    this.page,
    required this.onChanged,
  });

  static const double barHeight = 74;
  static const double radius = 26;
  static const double centerSize = 58;
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
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
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

    // ✅ più trasparente -> si vede il background dietro
    final glassTint = _op(Colors.black, 0.14);
    final border = _op(Colors.white, 0.14);
    final highlight = _op(Colors.white, 0.10);

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
              final t = _anim.value; // 0..1
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
                      tint: glassTint,
                      border: border,
                      highlight: highlight,
                      glowDx: dx,
                      glowColors: [
                        primary.withOpacity(0.22),
                        tertiary.withOpacity(0.16),
                        secondary.withOpacity(0.12),
                      ],
                      child: Row(
                        children: [
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
                          const SizedBox(
                            width: PixelBottomNavBar.centerSize + 16,
                          ),
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
  final double glowDx;
  final List<Color> glowColors;
  final Widget child;

  const _GlassShell({
    required this.height,
    required this.radius,
    required this.tint,
    required this.border,
    required this.highlight,
    required this.glowDx,
    required this.glowColors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: _op(Colors.black, 0.45),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              // ✅ niente nero pieno
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Stack(
              children: [
                // ✅ Glow “profondità” che si muove
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(glowDx * 50, 0),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
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

                // highlight top (effetto vetro)
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: child,
                ),
              ],
            ),
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

  @override
  Widget build(BuildContext context) {
    final t = selection.clamp(0.0, 1.0);

    final inactive = _op(Colors.white, 0.68);
    final active = selectedColor;

    final iconColor = Color.lerp(inactive, active, t)!;
    final labelColor = Color.lerp(inactive, active, t)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: active.withOpacity(0.10 * t),
              border: Border.all(
                color: active.withOpacity(0.22 * t),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  scale: 1.0 + (0.08 * t),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    letterSpacing: 0.2,
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
    required this.glowDx,
    required this.glowA,
    required this.glowB,
  });

  @override
  Widget build(BuildContext context) {
    final t = selection.clamp(0.0, 1.0);

    final inactiveIcon = _op(Colors.white, 0.88);
    final activeIcon = const Color(0xFF0B0B0B);
    final iconColor = Color.lerp(inactiveIcon, activeIcon, t)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _op(Colors.black, 0.50),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: accent.withOpacity(0.30 * t),
                      blurRadius: 22,
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
                          child: Transform.translate(
                            offset: Offset(glowDx * 18, 0),
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: 18,
                                sigmaY: 18,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: const Alignment(-0.25, -0.35),
                                    stops: const [0.0, 0.70, 1.0],
                                    colors: [
                                      Colors.white.withOpacity(0.22),
                                      glowA.withOpacity(0.55),
                                      glowB.withOpacity(0.30),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color.lerp(
                                  _op(Colors.white, 0.16),
                                  _op(accent, 0.35),
                                  t,
                                )!,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(
                            icon,
                            size: 26,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color.lerp(_op(Colors.white, 0.70), accent, t),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _op(Color c, double opacity) {
  final o = opacity.clamp(0.0, 1.0);
  return c.withAlpha((o * 255).round());
}
