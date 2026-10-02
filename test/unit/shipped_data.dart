import 'dart:convert';
import 'dart:io';

import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

/// Les entités telles que le jeu les livre, lues dans leur fichier par leur
/// vrai `fromJson`, l'id injecté comme le fait le chargeur : un test du moteur
/// de runes joue la donnée, pas une recopie (spec P-43 E1, §8).
Map<String, dynamic> _shipped(String path, String id) => {
      ...jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
      'id': id,
    };

ForgeUpgradeData shippedRune(String id) => ForgeUpgradeData.fromJson(
      _shipped('assets/data/forge_upgrades/$id.json', id),
    );

/// Construit — et installe, `GameDataRegistry` étant un singleton — un
/// registre qui ne porte que les runes livrées [runeIds] et les [cards].
GameDataRegistry shippedRuneRegistry(
  List<String> runeIds, {
  List<CardData> cards = const [],
}) =>
    GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: cards,
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: [for (final id in runeIds) shippedRune(id)],
    );
