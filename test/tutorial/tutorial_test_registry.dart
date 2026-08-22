import 'dart:convert';
import 'dart:io';

import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

List<Map<String, dynamic>> _readJson(String path) {
  final raw = File(path).readAsStringSync();
  return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
}

/// Registre bâti sur les JSON réels du dépôt.
///
/// Les tests du tutoriel utilisent les vraies données plutôt que des
/// fixtures inventées : c'est précisément la fidélité qu'on cherche à
/// garantir.
GameDataRegistry buildTutorialTestRegistry() {
  final cards = [
    ..._readJson('assets/data/cards.json'),
    ..._readJson('assets/data/hero_cards.json'),
  ].map(CardData.fromJson).toList();

  return GameDataRegistry(
    enemies: _readJson('assets/data/enemies.json').map(EnemyData.fromJson).toList(),
    heroes: _readJson('assets/data/heroes.json').map(HeroData.fromJson).toList(),
    skills: const [],
    cards: cards,
    events: const [],
    passives: _readJson('assets/data/passives.json').map(PassiveData.fromJson).toList(),
    relics: _readJson('assets/data/relics.json').map(RelicData.fromJson).toList(),
    forgeUpgrades: const [],
  );
}
