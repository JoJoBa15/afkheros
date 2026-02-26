import 'package:flutter/material.dart';
import 'root_shell.dart';

class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FOCUS!',
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
