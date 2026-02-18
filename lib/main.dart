import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/afk_hero_app.dart';
import 'state/game_state.dart';
import 'state/settings_state.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
        ChangeNotifierProvider(create: (_) => SettingsState()),
      ],
      child: const AfkHeroApp(),
  ),
);

}
