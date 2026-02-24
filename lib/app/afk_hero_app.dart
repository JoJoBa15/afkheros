import 'package:flutter/material.dart';
import 'root_shell.dart';

class AfkHeroApp extends StatelessWidget {
  const AfkHeroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFK Hero (Focus)',
      debugShowCheckedModeBanner: false,
      // ✅ Niente glow / stretch ai bordi durante gli scroll (evita “flash” colorati)
      scrollBehavior: const _NoOverscrollIndicatorBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        // Sfondo nero assoluto
        scaffoldBackgroundColor: Colors.black,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B7CFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const RootShell(),
    );
  }
}

/// Rimuove gli indicatori di overscroll (glow / stretch) che in alcune animazioni
/// possono “sparaflashare” sui bordi dello schermo.
class _NoOverscrollIndicatorBehavior extends MaterialScrollBehavior {
  const _NoOverscrollIndicatorBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}