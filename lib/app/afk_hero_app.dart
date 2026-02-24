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