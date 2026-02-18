import 'package:flutter/material.dart';

/// Bottom navigation bar “in stile gioco” con 5 tab.
/// - Sfondo scuro “pietra/legno”
/// - Pulsante centrale leggermente più grande
/// - Importante: SafeArea è messo FUORI dalla Container con altezza fissa,
///   così evitiamo il classico errore "Bottom overflowed by ...".
class PixelBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const PixelBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  /// Altezza della barra (solo la barra, senza considerare il padding del SafeArea).
  static const double _barHeight = 74;

  @override
  Widget build(BuildContext context) {
    // Perché SafeArea fuori?
    // Se lo metti dentro una Container con height fissa, il padding del SafeArea
    // "mangia" spazio interno e i widget rischiano di non starci => overflow.
    // Così invece la barra resta alta _barHeight e il SafeArea aggiunge spazio extra fuori.
    return SafeArea(
      top: false,
      child: Container(
        height: _barHeight,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          border: Border(top: BorderSide(color: Color(0xFF333333))),
        ),
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

/// Elemento “standard” della nav: icona + label.
/// Usare mainAxisSize.min evita che la Column cerchi altezza extra
/// e riduce la probabilità di overflow su schermi piccoli / gesture bar grandi.
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
        // Padding un po' più “safe” (vertical 8) per stare bene anche con SafeArea.
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: c),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: c,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Elemento centrale “speciale”: cerchio più grande, un po' in evidenza.
/// Anche qui: mainAxisSize.min e qualche pixel in meno di padding aiutano contro overflow.
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
        // Vertical 4 invece di 6: su device con gesture bar grossa aiuta parecchio.
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
