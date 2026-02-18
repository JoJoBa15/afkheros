import 'package:flutter/material.dart';

class PixelBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const PixelBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  static const double _h = 74;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _h,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF333333))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              label: 'Shop',
              icon: Icons.shopping_bag,
              selected: currentIndex == 0,
              onTap: () => onChanged(0),
            ),
            _NavItem(
              label: 'Forge',
              icon: Icons.hardware,
              selected: currentIndex == 1,
              onTap: () => onChanged(1),
            ),
            _CenterNavItem(
              label: 'My Path',
              icon: Icons.explore,
              selected: currentIndex == 2,
              onTap: () => onChanged(2),
            ),
            _NavItem(
              label: 'Equip',
              icon: Icons.backpack,
              selected: currentIndex == 3,
              onTap: () => onChanged(3),
            ),
            _NavItem(
              label: 'Clan',
              icon: Icons.shield,
              selected: currentIndex == 4,
              onTap: () => onChanged(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = selected ? Theme.of(context).colorScheme.primary : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: c),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CenterNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? primary : const Color(0xFF2A2A2A),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4A4A4A)),
              ),
              child: Icon(icon, color: selected ? Colors.black : Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? primary : Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
