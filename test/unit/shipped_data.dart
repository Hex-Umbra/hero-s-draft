import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

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

/// Une carte neutre telle que le jeu la livre (`assets/data/cards/`).
CardData shippedCard(String id) =>
    CardData.fromJson(_shipped('assets/data/cards/$id.json', id));

/// Une relique telle que le jeu la livre (`assets/data/relics/`).
RelicData shippedRelic(String id) =>
    RelicData.fromJson(_shipped('assets/data/relics/$id.json', id));

/// Le catalogue des charges tel que le jeu le livre (`assets/data/charges/`).
ChargeCatalog shippedChargeCatalog() => ChargeCatalog.of([
      for (final id in _idsIn('assets/data/charges'))
        ChargeData.fromJson(_shipped('assets/data/charges/$id.json', id)),
    ]);

/// La surcharge qui donne le catalogue livré à un test qui joue ou pose une
/// charge : sans elle, `chargeCatalogProvider` rend le catalogue vide et rien
/// ne se pose (spec P-53, A4).
Override shippedChargeOverride() =>
    chargeCatalogProvider.overrideWithValue(shippedChargeCatalog());

/// Les ids des fichiers d'un dossier livré, triés.
List<String> _idsIn(String directory) => [
      for (final file in Directory(directory).listSync())
        if (file is File && file.path.endsWith('.json'))
          file.uri.pathSegments.last.replaceAll('.json', ''),
    ]..sort();

/// Les ids des runes livrées.
List<String> shippedRuneIds() => _idsIn('assets/data/forge_upgrades');

/// Les cartes neutres livrées.
List<CardData> shippedNeutralCards() =>
    [for (final id in _idsIn('assets/data/cards')) shippedCard(id)];

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
