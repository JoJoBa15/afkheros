import 'package:flutter/material.dart';
import 'root_shell.dart';

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
          seedColor: const Color(0xFFB68D40),
          brightness: Brightness.dark,
        ),
      ),
      home: const RootShell(),
    );
  }
}
