import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/data/enemy_data.dart';
import '../models/data/hero_data.dart';
import '../models/data/skill_data.dart';
import '../models/data/card_data.dart';
import '../models/data/event_data.dart';
import '../models/data/passive_data.dart';
import '../models/data/relic_data.dart';
import '../models/data/forge_upgrade_data.dart';
import '../models/data/game_data_registry.dart';
import '../models/data/audio_data.dart';

Future<List<dynamic>> _loadJsonList(String path) async {
  try {
    final String content = await rootBundle.loadString(path);
    final decoded = jsonDecode(content);
    if (decoded is! List) {
      throw FormatException('Le fichier JSON doit être une liste à la racine.');
    }
    return decoded;
  } catch (e, stack) {
    throw Exception('Erreur de chargement/décodage pour le fichier "$path": $e\n$stack');
  }
}

List<T> _mapList<T>(
  List<dynamic> list,
  T Function(Map<String, dynamic>) fromJson,
  String modelName,
) {
  final List<T> result = [];
  for (int i = 0; i < list.length; i++) {
    final item = list[i];
    if (item is! Map<String, dynamic>) {
      throw Exception(
        'L\'élément à l\'index $i pour le modèle "$modelName" n\'est pas un Map<String, dynamic>. Reçu: $item',
      );
    }
    try {
      result.add(fromJson(item));
    } catch (e, stack) {
      throw Exception(
        'Erreur de parsing dans le modèle "$modelName" à l\'index $i (données: $item): $e\n$stack',
      );
    }
  }
  return result;
}

/// Charge `audio.json`. Contrairement a `_loadJsonList`, cette fonction ne
/// leve jamais : l'audio est le seul sous-systeme auquel il est interdit de
/// faire echouer le demarrage du jeu. Fichier absent ou malforme = catalogue
/// desactive, jeu silencieux, trace en debug pour rester diagnosticable.
///
/// Publique (pas de prefixe `_`) et annotee `@visibleForTesting` uniquement
/// pour que les tests puissent l'appeler directement avec un path/contenu
/// controle : elle ne fait pas partie de l'API publique du service.
@visibleForTesting
Future<AudioData> loadAudioData(String path) async {
  try {
    final String content = await rootBundle.loadString(path);
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      debugPrint(
        '[audio] "$path" ne decode pas vers un objet JSON : catalogue desactive',
      );
      return const AudioData.disabled();
    }
    return AudioData.fromJson(decoded);
  } catch (e) {
    debugPrint('[audio] echec de chargement de "$path" : $e, catalogue desactive');
    return const AudioData.disabled();
  }
}

final gameDataLoaderProvider = FutureProvider<GameDataRegistry>((ref) async {
  final List<List<dynamic>> results = await Future.wait([
    _loadJsonList('assets/data/enemies.json'),
    _loadJsonList('assets/data/heroes.json'),
    _loadJsonList('assets/data/skills.json'),
    _loadJsonList('assets/data/cards.json'),
    _loadJsonList('assets/data/events.json'),
    _loadJsonList('assets/data/passives.json'),
    _loadJsonList('assets/data/relics.json'),
    _loadJsonList('assets/data/hero_cards.json'),
    _loadJsonList('assets/data/forge_upgrades.json'),
  ]);

  final audio = await loadAudioData('assets/data/audio.json');

  final enemiesList = results[0];
  final heroesList = results[1];
  final skillsList = results[2];
  final cardsList = results[3];
  final eventsList = results[4];
  final passivesList = results[5];
  final relicsList = results[6];
  final heroCardsList = results[7];
  final forgeUpgradesList = results[8];

  final allCards = [
    ...cardsList,
    ...heroCardsList,
  ];

  return GameDataRegistry(
    enemies: _mapList(enemiesList, EnemyData.fromJson, 'EnemyData'),
    heroes: _mapList(heroesList, HeroData.fromJson, 'HeroData'),
    skills: _mapList(skillsList, SkillData.fromJson, 'SkillData'),
    cards: _mapList(allCards, CardData.fromJson, 'CardData'),
    events: _mapList(eventsList, EventData.fromJson, 'EventData'),
    passives: _mapList(passivesList, PassiveData.fromJson, 'PassiveData'),
    relics: _mapList(relicsList, RelicData.fromJson, 'RelicData'),
    forgeUpgrades: _mapList(forgeUpgradesList, ForgeUpgradeData.fromJson, 'ForgeUpgradeData'),
    audio: audio,
  );
});
