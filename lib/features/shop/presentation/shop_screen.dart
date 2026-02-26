import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/game_state.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              _buildSectionTitle('Offerte Speciali'),
              const SizedBox(height: 10),
              _buildFeaturedOffer(context),
              const SizedBox(height: 24),
              _buildSectionTitle('Valute'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero, // ✅ Rimosso spazio vuoto
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 155, 
                ),
                itemBuilder: (context, index) {
                  final data = [
                    ('Sacco d\'Oro', '500 Monete', '€ 0.99', Icons.monetization_on_rounded, Colors.amber),
                    ('Scrigno Gemme', '100 Gemme', '€ 1.99', Icons.diamond_rounded, Colors.cyan),
                    ('Pozione Focus', 'Boost +20%', '€ 0.49', Icons.bolt_rounded, Colors.purpleAccent),
                    ('Lingotto Ferro', 'Materiale Raro', '€ 2.99', Icons.hardware_rounded, Colors.blueGrey),
                  ];
                  final item = data[index];
                  return _buildShopCard(
                    context,
                    title: item.$1,
                    subtitle: item.$2,
                    price: item.$3,
                    icon: item.$4,
                    color: item.$5,
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Premi Gratis'),
              const SizedBox(height: 10),
              _buildFreeChest(context),
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

  Widget _buildFeaturedOffer(BuildContext context) {
    return _LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'MIGLIOR VALORE',
                  style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Starter Pack Eroe',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tutto quello che ti serve per scalare la classifica.',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.95),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                child: const Text('€ 4.99', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, {required String title, required String subtitle, required String price, required IconData icon, required Color color}) {
    return _LiquidGlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: color),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            price,
            style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeChest(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<GameState>().addRewards(addGold: 50);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hai riscattato 50 Monete gratis!')),
        );
      },
      child: _LiquidGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: Colors.greenAccent, size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Cassa Giornaliera', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  Text('Tocca per riscattare ora', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _LiquidGlassContainer({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
