import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/afk_hero_app.dart';
import 'state/game_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const AfkHeroApp(),
    ),
  );
}