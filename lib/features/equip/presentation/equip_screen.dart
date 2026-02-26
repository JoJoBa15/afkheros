import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/game_state.dart';

class EquipScreen extends StatelessWidget {
  const EquipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildSectionTitle('Equipaggiamento Attivo'),
              const SizedBox(height: 10),
              _buildActiveEquipCard(context, gs.equipped),
              const SizedBox(height: 24),
              _buildSectionTitle('Il Tuo Inventario'),
              const SizedBox(height: 10),
              if (gs.inventory.isEmpty)
                _buildEmptyState()
              else
                GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gs.inventory.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final item = gs.inventory[index];
                    final isEquipped = gs.equipped?.id == item.id;
                    return _buildInventorySlot(context, item, isEquipped);
                  },
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildActiveEquipCard(BuildContext context, GameItem? item) {
    return _LiquidEquipContainer(
      padding: const EdgeInsets.all(20),
      glow: item != null,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: item != null ? Colors.cyan.withValues(alpha: 0.4) : Colors.white10,
                width: 1.5,
              ),
              boxShadow: item != null ? [
                BoxShadow(
                  color: Colors.cyan.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ] : null,
            ),
            child: Icon(
              item?.icon ?? Icons.help_outline_rounded,
              color: item != null ? Colors.white : Colors.white24,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item?.name ?? 'Nessun Oggetto',
                  style: TextStyle(
                    color: item != null ? Colors.white : Colors.white38,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  item != null ? 'IN USO ORA' : 'Seleziona un oggetto sotto',
                  style: TextStyle(
                    color: item != null ? Colors.cyanAccent.withValues(alpha: 0.7) : Colors.white24,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (item != null)
            const Icon(Icons.check_circle_rounded, color: Colors.cyanAccent, size: 24),
        ],
      ),
    );
  }

  Widget _buildInventorySlot(BuildContext context, GameItem item, bool isEquipped) {
    return GestureDetector(
      onTap: () => context.read<GameState>().equipItem(item),
      child: _LiquidEquipContainer(
        padding: const EdgeInsets.all(12),
        glow: isEquipped,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: isEquipped ? Colors.white : Colors.white70,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isEquipped ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: isEquipped ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
            if (isEquipped)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.cyanAccent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return _LiquidEquipContainer(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text(
            'L\'inventario è vuoto',
            style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w800),
          ),
          const Text(
            'Forgia qualcosa nella tab Forge!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LiquidEquipContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool glow;

  const _LiquidEquipContainer({required this.child, this.padding = EdgeInsets.zero, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                glow ? Colors.cyan.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
                glow ? Colors.cyan.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: glow ? Colors.cyanAccent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.12),
              width: glow ? 1.5 : 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
