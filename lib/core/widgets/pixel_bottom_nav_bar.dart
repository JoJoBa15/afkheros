import 'dart:ui';
import 'package:flutter/material.dart';

/// Bottom navigation bar "Liquid Glass" (sempre uguale, non dipende dall'orario).
/// - Blur + tint scuro (glass) + bordino luminoso
/// - Pulsante centrale "orb" leggermente sollevato
/// - Selezione animata (pill soft) sui tab laterali
///
/// Usata da RootShell:
/// bottomNavigationBar: PixelBottomNavBar(currentIndex: _index, onChanged: ...)
class PixelBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const PixelBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  static const double _barHeight = 74;
  static const double _radius = 26;
  static const double _centerSize = 58;
  static const double _centerLift = 18;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    // Colori glass (tint scuro + highlight)
    final glassTint = _op(const Color(0xFF0B0B0B), 0.35);
    final border = _op(Colors.white, 0.14);
    final highlight = _op(Colors.white, 0.10);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: SizedBox(
          height: _barHeight + _centerLift, // spazio extra per l'orb sollevato
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Glass background (solo la barra, non l'orb)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _GlassShell(
                  height: _barHeight,
                  radius: _radius,
                  tint: glassTint,
                  border: border,
                  highlight: highlight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _GlassNavItem(
                          label: 'Shop',
                          icon: Icons.shopping_bag,
                          selected: currentIndex == 0,
                          onTap: () => onChanged(0),
                          selectedColor: primary,
                        ),
                      ),
                      Expanded(
                        child: _GlassNavItem(
                          label: 'Forge',
                          icon: Icons.hardware,
                          selected: currentIndex == 1,
                          onTap: () => onChanged(1),
                          selectedColor: primary,
                        ),
                      ),

                      // spazio centrale per l'orb
                      const SizedBox(width: _centerSize + 16),

                      Expanded(
                        child: _GlassNavItem(
                          label: 'Equip',
                          icon: Icons.backpack,
                          selected: currentIndex == 3,
                          onTap: () => onChanged(3),
                          selectedColor: primary,
                        ),
                      ),
                      Expanded(
                        child: _GlassNavItem(
                          label: 'Clan',
                          icon: Icons.shield,
                          selected: currentIndex == 4,
                          onTap: () => onChanged(4),
                          selectedColor: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Orb centrale (sollevato)
              Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: const Offset(0, -_centerLift),
                  child: _CenterOrbItem(
                    size: _centerSize,
                    label: 'My Path',
                    icon: Icons.explore,
                    selected: currentIndex == 2,
                    onTap: () => onChanged(2),
                    accent: primary,
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

class _GlassShell extends StatelessWidget {
  final double height;
  final double radius;
  final Color tint;
  final Color border;
  final Color highlight;
  final Widget child;

  const _GlassShell({
    required this.height,
    required this.radius,
    required this.tint,
    required this.border,
    required this.highlight,
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
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: r,
              color: tint,
              border: Border.all(color: border, width: 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _op(Colors.white, 0.08),
                  _op(Colors.white, 0.03),
                ],
              ),
            ),
            child: Stack(
              children: [
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

                // content
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
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _GlassNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final base = Colors.white;
    final inactive = _op(base, 0.68);
    final active = selectedColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: selected ? _op(active, 0.10) : Colors.transparent,
              border: selected
                  ? Border.all(color: _op(active, 0.22), width: 1)
                  : Border.all(color: Colors.transparent, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  scale: selected ? 1.08 : 1.0,
                  child: Icon(icon, color: selected ? active : inactive, size: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? active : inactive,
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
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  const _CenterOrbItem({
    required this.size,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveIcon = _op(Colors.white, 0.85);
    final activeIcon = const Color(0xFF0B0B0B);

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
              // Orb
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
                    if (selected)
                      BoxShadow(
                        color: _op(accent, 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? _op(accent, 0.35) : _op(Colors.white, 0.16),
                          width: 1,
                        ),
                        gradient: selected
                            ? RadialGradient(
                                center: const Alignment(-0.25, -0.35),
                                stops: const [0.0, 0.65, 1.0],
                                colors: [
                                  _op(Colors.white, 0.35),
                                  _op(accent, 0.95),
                                  _op(accent, 0.65),
                                ],
                              )
                            : RadialGradient(
                                center: const Alignment(-0.25, -0.35),
                                stops: const [0.0, 0.70, 1.0],
                                colors: [
                                  _op(Colors.white, 0.20),
                                  _op(const Color(0xFF141414), 0.70),
                                  _op(const Color(0xFF0B0B0B), 0.80),
                                ],
                              ),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          size: 26,
                          color: selected ? activeIcon : inactiveIcon,
                        ),
                      ),
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
                  color: selected ? accent : _op(Colors.white, 0.70),
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