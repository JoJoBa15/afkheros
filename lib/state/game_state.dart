import 'package:flutter/material.dart';

class GameState extends ChangeNotifier {
  String username = 'AlphaTester';
  int level = 1;

  int gold = 1000;
  int gems = 500;
  int iron = 100;

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

class FocusRewards {
  final int gold;
  final int gems;
  final int iron;

  const FocusRewards({required this.gold, required this.gems, required this.iron});
}
