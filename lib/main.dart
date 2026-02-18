import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const AfkHeroApp(),
    ),
  );
}

class AfkHeroApp extends StatelessWidget {
  const AfkHeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFK Hero (Focus)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF141414),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB68D40), // “oro” medievale
          brightness: Brightness.dark,
        ),
      ),
      home: const RootShell(),
    );
  }
}

/// =======================
/// GAME STATE (semplice)
/// =======================
class GameState extends ChangeNotifier {
  String username = 'Hero';
  int level = 1;

  int gold = 120;
  int gems = 5;
  int iron = 0;

  final List<GameItem> inventory = [];
  GameItem? equipped;

  void addRewards({int addGold = 0, int addGems = 0, int addIron = 0}) {
    gold += addGold;
    gems += addGems;
    iron += addIron;
    notifyListeners();
  }

  bool craft(GameRecipe recipe) {
    if (iron < recipe.ironCost) return false;
    iron -= recipe.ironCost;
    inventory.add(recipe.result);
    notifyListeners();
    return true;
  }

  void equipItem(GameItem item) {
    equipped = item;
    notifyListeners();
  }
}

class GameItem {
  final String id;
  final String name;
  final IconData icon;

  const GameItem({required this.id, required this.name, required this.icon});
}

class GameRecipe {
  final String id;
  final String name;
  final int ironCost;
  final GameItem result;

  const GameRecipe({
    required this.id,
    required this.name,
    required this.ironCost,
    required this.result,
  });
}

/// =======================
/// ROOT SHELL (Header + Body + BottomNav)
/// =======================
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 2; // My Path di default (centrale)

  final _tabs = const [
    ShopScreen(),
    BlacksmithScreen(),
    MyPathScreen(),
    EquipScreen(),
    ClanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ProfileDrawer(),
      appBar: AppBar(
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
          _CurrenciesBar(),
          SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),
      bottomNavigationBar: PixelBottomNavBar(
        currentIndex: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _CurrenciesBar extends StatelessWidget {
  const _CurrenciesBar();

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Row(
      children: [
        _CurrencyChip(icon: Icons.circle, label: '${gs.gold}', tooltip: 'Oro'),
        const SizedBox(width: 8),
        _CurrencyChip(icon: Icons.diamond, label: '${gs.gems}', tooltip: 'Gemme'),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;

  const _CurrencyChip({
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// BOTTOM NAV (5 tab, centrale più grande)
/// =======================
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

/// =======================
/// DRAWER PROFILO
/// =======================
class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Drawer(
      backgroundColor: const Color(0xFF171717),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1F1F1F)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Color(0xFF2A2A2A),
              child: Icon(Icons.person),
            ),
            accountName: Text(gs.username),
            accountEmail: Text('Lv. ${gs.level}'),
          ),
          _drawerItem(
            context,
            icon: Icons.campaign,
            title: 'Comunicazioni',
            onTap: () => _open(context, 'Comunicazioni'),
          ),
          _drawerItem(
            context,
            icon: Icons.emoji_events,
            title: 'Record',
            onTap: () => _open(context, 'Record'),
          ),
          _drawerItem(
            context,
            icon: Icons.history,
            title: 'Cronologia',
            onTap: () => _open(context, 'Cronologia'),
          ),
          _drawerItem(
            context,
            icon: Icons.group,
            title: 'Amici',
            onTap: () => _open(context, 'Amici'),
          ),
          const Spacer(),
          const Divider(height: 1),
          _drawerItem(
            context,
            icon: Icons.settings,
            title: 'Impostazioni',
            onTap: () => _open(context, 'Impostazioni'),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _open(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SimplePage(title: title)),
    );
  }
}

class SimplePage extends StatelessWidget {
  final String title;
  const SimplePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('TODO: $title', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

/// =======================
/// TAB: MY PATH (Home + Timer)
/// =======================
class MyPathScreen extends StatelessWidget {
  const MyPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _HeroCard(equipped: gs.equipped),
          const SizedBox(height: 16),

          // Preset timer
          _TimerPresetRow(
            onStart: (d) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => FocusSessionScreen(duration: d)),
              );
            },
          ),

          const SizedBox(height: 16),
          _TipBox(
            text:
                'Flusso base:\nFocus → Vittoria (+Ferro) → Forge (craft) → Equip (indossa).',
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // “Quick test” per non aspettare 25 minuti mentre valuti l’AI
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FocusSessionScreen(
                          duration: Duration(seconds: 15),
                          debugLabel: 'Quick Test',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bolt),
                  label: const Text('Quick Test (15s)'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final GameItem? equipped;
  const _HeroCard({required this.equipped});

  @override
  Widget build(BuildContext context) {
    final eqName = equipped?.name ?? 'Nessun equip';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3A3A3A)),
            ),
            child: const Icon(Icons.person, size: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Path', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Equip: $eqName', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                const Text('Il tuo eroe è pronto a concentrarsi.', style: TextStyle(color: Colors.white60)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _TimerPresetRow extends StatelessWidget {
  final void Function(Duration) onStart;
  const _TimerPresetRow({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PresetButton(
            label: '25 min',
            icon: Icons.play_arrow,
            onTap: () => onStart(const Duration(minutes: 25)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PresetButton(
            label: '45 min',
            icon: Icons.play_arrow,
            onTap: () => onStart(const Duration(minutes: 45)),
          ),
        ),
      ],
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PresetButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text('Inizia ($label)'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  final String text;
  const _TipBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, height: 1.35)),
    );
  }
}

/// =======================
/// TIMER FULL-SCREEN
/// =======================
class FocusSessionScreen extends StatefulWidget {
  final Duration duration;
  final String? debugLabel;

  const FocusSessionScreen({super.key, required this.duration, this.debugLabel});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  Timer? _timer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _finish();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish() {
    // Ricompense base (puoi bilanciarle dopo)
    final rewards = FocusRewards(
      gold: 10,
      gems: 0,
      iron: widget.duration.inMinutes >= 25 ? 3 : 1,
    );

    // Applica reward
    context.read<GameState>().addRewards(
          addGold: rewards.gold,
          addGems: rewards.gems,
          addIron: rewards.iron,
        );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => VictoryScreen(rewards: rewards)),
    );
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Interrompere?'),
        content: const Text('Se interrompi, non ottieni ricompense.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continua')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Interrompi')),
        ],
      ),
    );
    if (ok == true) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.duration.inSeconds;
    final remaining = _remainingSeconds.clamp(0, total);
    final progress = total == 0 ? 1.0 : 1.0 - (remaining / total);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.debugLabel ?? 'Focus Session'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmCancel,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Rimani concentrato.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatSeconds(remaining),
                    style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 10),
                  const Text('La NavBar è nascosta: modalità full focus.', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _confirmCancel,
              icon: const Icon(Icons.stop),
              label: const Text('Interrompi'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

String _formatSeconds(int s) {
  final m = s ~/ 60;
  final r = s % 60;
  final mm = m.toString().padLeft(2, '0');
  final rr = r.toString().padLeft(2, '0');
  return '$mm:$rr';
}

class FocusRewards {
  final int gold;
  final int gems;
  final int iron;

  const FocusRewards({required this.gold, required this.gems, required this.iron});
}

class VictoryScreen extends StatelessWidget {
  final FocusRewards rewards;
  const VictoryScreen({super.key, required this.rewards});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vittoria!')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ricompense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text('🪙 Oro: +${rewards.gold}'),
                  Text('💎 Gemme: +${rewards.gems}'),
                  Text('⛓️ Ferro: +${rewards.iron}'),
                ],
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Torna al Cammino'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// TAB: SHOP
/// =======================
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shop', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cassa Gratis (placeholder Ads)', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Simula “guarda pubblicità → ottieni bonus”.'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<GameState>().addRewards(addGold: 20, addGems: 1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hai ottenuto +20 Oro e +1 Gemma!')),
                    );
                  },
                  icon: const Icon(Icons.card_giftcard),
                  label: const Text('Apri Cassa'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _panel(
            child: Text('Bilancio attuale → Oro: ${gs.gold}, Gemme: ${gs.gems}, Ferro: ${gs.iron}'),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// TAB: BLACKSMITH
/// =======================
class BlacksmithScreen extends StatelessWidget {
  const BlacksmithScreen({super.key});

  static const recipes = [
    GameRecipe(
      id: 'sword_iron',
      name: 'Spada di Ferro',
      ironCost: 3,
      result: GameItem(id: 'item_sword_iron', name: 'Spada di Ferro', icon: Icons.gavel),
    ),
    GameRecipe(
      id: 'helm_iron',
      name: 'Elmo di Ferro',
      ironCost: 2,
      result: GameItem(id: 'item_helm_iron', name: 'Elmo di Ferro', icon: Icons.sports_mma),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Blacksmith', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Ferro disponibile: ${gs.iron}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: recipes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = recipes[i];
                return _panel(
                  child: Row(
                    children: [
                      Icon(r.result.icon, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('Costo: ${r.ironCost} Ferro', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final ok = context.read<GameState>().craft(r);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? 'Craft riuscito: ${r.result.name}' : 'Ferro insufficiente'),
                            ),
                          );
                        },
                        child: const Text('Craft'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// TAB: EQUIP (inventario + equip)
/// =======================
class EquipScreen extends StatelessWidget {
  const EquipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Equip', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _panel(
            child: Row(
              children: [
                const Text('Equip attuale: ', style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Text(gs.equipped?.name ?? 'Nessuno', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: gs.inventory.isEmpty
                ? const Center(child: Text('Inventario vuoto. Fai focus e poi craft in Blacksmith.'))
                : GridView.builder(
                    itemCount: gs.inventory.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, i) {
                      final item = gs.inventory[i];
                      final isEq = gs.equipped?.id == item.id;
                      return InkWell(
                        onTap: () => context.read<GameState>().equipItem(item),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F1F),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isEq ? Theme.of(context).colorScheme.primary : const Color(0xFF333333),
                              width: isEq ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.icon, size: 30),
                              const SizedBox(height: 8),
                              Text(
                                item.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// TAB: CLAN (placeholder)
/// =======================
class ClanScreen extends StatelessWidget {
  const ClanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Clan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _panel(
            child: const Text('TODO: Leaderboard / Boss / Chat (in futuro).'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: const [
                ListTile(leading: Icon(Icons.emoji_events), title: Text('1) PlayerOne - 1200')),
                ListTile(leading: Icon(Icons.emoji_events), title: Text('2) PlayerTwo - 950')),
                ListTile(leading: Icon(Icons.emoji_events), title: Text('3) PlayerThree - 720')),
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// =======================
/// UI helper panel
/// =======================
Widget _panel({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF1F1F1F),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF333333)),
    ),
    child: child,
  );
}
