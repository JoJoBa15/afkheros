import 'package:flutter/material.dart';
import 'dart:async'; // Serve per simulare il timer

void main() {
  runApp(const AfkHeroApp());
}

class AfkHeroApp extends StatelessWidget {
  const AfkHeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFK Hero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // TEMA: Stile "Pixel Art" / RPG Scuro
        scaffoldBackgroundColor: const Color(0xFF2D2D2D), // Grigio Pietra scuro
        primaryColor: const Color(0xFF8D6E63), // Marrone Legno
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3E2723), // Marrone molto scuro
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        // Definiamo uno stile di testo di base che ricordi i giochi retro
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Monospace'),
          titleLarge: TextStyle(color: Colors.amber, fontFamily: 'Monospace', fontWeight: FontWeight.bold),
        ),
      ),
      home: const MainGameScreen(),
    );
  }
}

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  // STATO: Quale tab è selezionato? (Iniziamo dal 2 = My Path)
  int _selectedIndex = 2;
  
  // STATO: Il timer è attivo?
  bool _isFocusMode = false;

  // Variabili simulate per il timer
  int _secondsRemaining = 1500; // 25 minuti
  Timer? _timer;

  // --- LOGICA TIMER ---
  void _startFocusSession() {
    setState(() {
      _isFocusMode = true; // Questo nasconderà la NavBar
      _secondsRemaining = 25 * 60; // Reset a 25 min
    });

    // Simulazione conto alla rovescia
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _completeSession();
      }
    });
  }

  void _giveUpSession() {
    _timer?.cancel();
    setState(() {
      _isFocusMode = false; // La NavBar riappare
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('L\'eroe è fuggito! Nessun bottino ottenuto.')),
    );
  }

  void _completeSession() {
    _timer?.cancel();
    setState(() {
      _isFocusMode = false;
    });
    // Mostra dialogo vittoria
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3E2723),
        title: const Text("VITTORIA!", style: TextStyle(color: Colors.amber)),
        content: const Text("Hai ottenuto: 25 Ferro + 100 XP", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("RISCATTA", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  // 1. HEADER (AppBar)
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      // Profilo a sinistra che apre il Drawer
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white), // Placeholder Avatar Pixel
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: const Text("AFK HERO", style: TextStyle(fontSize: 16)),
      centerTitle: true,
      actions: [
        // Valute a destra
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Row(
            children: const [
              Icon(Icons.diamond, color: Colors.cyanAccent, size: 16),
              SizedBox(width: 4),
              Text("50", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 12),
              Icon(Icons.monetization_on, color: Colors.amber, size: 16),
              SizedBox(width: 4),
              Text("1200", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }

  // 2. DRAWER (Menu Laterale)
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF2D2D2D), // Sfondo scuro
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF3E2723)), // Header Marrone
            accountName: Text("Eroe Novizio", style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text("Livello 3 - Guerriero"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.face, size: 40, color: Colors.black),
            ),
          ),
          _drawerItem(Icons.campaign, "Comunicazioni"),
          _drawerItem(Icons.emoji_events, "Record"),
          _drawerItem(Icons.history, "Cronologia"),
          _drawerItem(Icons.group, "Amici"),
          const Divider(color: Colors.grey),
          _drawerItem(Icons.settings, "Impostazioni"),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context); // Chiude il drawer
      },
    );
  }

  // 3. NAVBAR (Bottom Navigation)
  Widget? _buildBottomNavBar() {
    // Se siamo in "Focus Mode", la navbar DEVE sparire (ritorna null)
    if (_isFocusMode) return null;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black, width: 2)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Necessario per 5 icone
        backgroundColor: const Color(0xFF1E1E1E), // Grigio Pietra molto scuro
        selectedItemColor: Colors.amber, // Colore attivo
        unselectedItemColor: Colors.grey, // Colore inattivo
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Fabbro'),
          BottomNavigationBarItem(
            // Icona centrale più grande e "rialzata" visivamente
            icon: Icon(Icons.play_circle_fill, size: 48), 
            label: 'My Path',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.backpack), label: 'Equip'),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Clan'),
        ],
      ),
    );
  }

  // 4. BODY (Contenuto Centrale)
  Widget _buildBody() {
    // Se il timer è attivo, mostriamo SOLO la schermata di Focus, ignorando le tab
    if (_isFocusMode) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.nature_people, size: 100, color: Colors.green), // L'albero/Eroe
            const SizedBox(height: 30),
            Text(
              "${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
              style: const TextStyle(fontSize: 50, color: Colors.white, fontFamily: 'Monospace'),
            ),
            const SizedBox(height: 10),
            const Text("L'eroe sta esplorando...", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: _giveUpSession,
              icon: const Icon(Icons.exit_to_app),
              label: const Text("ARRENDITI (Perdi tutto)"),
            )
          ],
        ),
      );
    }

    // Altrimenti mostriamo la tab selezionata
    switch (_selectedIndex) {
      case 0: return const Center(child: Text("🛒 SHOP\n\nCompra Gemme & Guarda Ads"));
      case 1: return const Center(child: Text("🔨 FABBRO\n\nForgia la tua spada qui"));
      case 2: return _buildHomePath(); // La schermata principale
      case 3: return const Center(child: Text("🎒 EQUIP\n\nInventario Oggetti"));
      case 4: return const Center(child: Text("🛡️ CLAN\n\nClassifiche & Boss"));
      default: return Container();
    }
  }

  // Schermata "My Path" (Home) quando NON sei in focus
  Widget _buildHomePath() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Eroe e ambientazione
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey),
            ),
            child: const Center(child: Icon(Icons.person_outline, size: 80, color: Colors.white)),
          ),
          const SizedBox(height: 30),
          const Text("Pronto per l'avventura?", style: TextStyle(fontSize: 20)),
          const SizedBox(height: 20),
          
          // Bottone START
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _startFocusSession,
            child: const Text("INIZIA FOCUS (25 min)", style: TextStyle(fontSize: 18, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Se siamo in focus mode, possiamo nascondere anche l'appbar se vogliamo un'immersione totale
      // Per ora la lascio visibile per vedere le gemme
      appBar: _buildAppBar(), 
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(), // Qui avviene la magia (mostra/nascondi)
    );
  }
}