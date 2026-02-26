import 'dart:ui';
import 'package:flutter/material.dart';

class ClanScreen extends StatelessWidget {
  const ClanScreen({super.key});

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
              _buildSanctuaryCore(),
              const SizedBox(height: 24),
              _buildSectionTitle('Maestri del Santuario'),
              const SizedBox(height: 12),
              _buildLeaderboard(context),
              const SizedBox(height: 24),
              _buildSectionTitle('Azioni Sacre'),
              const SizedBox(height: 12),
              _buildSanctuaryActions(),
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

  Widget _buildSanctuaryCore() {
    return _LiquidClanContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Orbe di energia pulsante (simulato)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.indigoAccent.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const Icon(Icons.wb_sunny_rounded, color: Colors.amberAccent, size: 40),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Focus Collettivo',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const Text(
            '12,450 XP',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Il Santuario splende di luce propria oggi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context) {
    final players = [
      ('Zeffiro', '2,400', Icons.looks_one_rounded, Colors.amber),
      ('AuraMaster', '1,950', Icons.looks_two_rounded, Colors.blueGrey),
      ('ZenArcher', '1,720', Icons.looks_3_rounded, Colors.brown),
    ];

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = players[index];
        return _LiquidClanContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(p.$3, color: p.$4, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  p.$1,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              Text(
                p.$2,
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 14),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.auto_awesome, color: Colors.white24, size: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSanctuaryActions() {
    return GridView.count(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildActionButton(Icons.favorite_rounded, 'Donazione', Colors.redAccent),
        _buildActionButton(Icons.groups_rounded, 'Raduno', Colors.blueAccent),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return _LiquidClanContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.8), size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}

class _LiquidClanContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _LiquidClanContainer({required this.child, this.padding = EdgeInsets.zero});

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
