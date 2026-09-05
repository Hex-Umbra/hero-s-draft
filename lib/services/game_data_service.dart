import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/data/enemy_data.dart';
import '../models/data/hero_data.dart';
import '../models/data/card_data.dart';
import '../models/data/event_data.dart';
import '../models/data/passive_data.dart';
import '../models/data/relic_data.dart';
import '../models/data/forge_upgrade_data.dart';
import '../models/data/game_data_registry.dart';
import '../models/data/audio_data.dart';
import 'game_data_loader.dart';

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
    // `cache: false` : `loadGameDataRegistry` (donc `buildTutorialTestRegistry`)
    // rappelle cette fonction avec le meme `path` a chaque construction de
    // registre. Le cache de `AssetBundle.loadString` retournerait alors le
    // `Future` deja regle de l'appel precedent ; sous `flutter test`, ce
    // `Future` vient de la zone d'un `testWidgets` deja termine et ne se
    // resout jamais si on l'attend depuis un nouveau test. Voir le meme
    // correctif sur `GameDataLoader._read` (`game_data_loader.dart`).
    final String content = await rootBundle.loadString(path, cache: false);
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

/// Construit le registre complet : les entites depuis [bundle], l audio
/// depuis `rootBundle`.
///
/// **Unique declaration des huit sources du jeu.** Le provider de production
/// et le registre des tests du tutoriel passent tous deux par ici : une
/// seconde declaration serait une seconde verite, et c est exactement ce que
/// ce chantier supprime.
///
/// L audio fait exception au seam : `loadAudioData` lit `rootBundle` en dur
/// (`game_data_service.dart:63`) et ses propres tests simulent le canal
/// `flutter/assets` plutot que d injecter un bundle. Sans consequence
/// aujourd hui — seul `rootBundle` est passe ici — mais l ecrire evite de
/// promettre un seam complet qui n existe pas.
///
/// Le motif de chemin porte la selection ET l injection : `*` vaut un
/// segment, et les segments captures alimentent `inject`.
Future<GameDataRegistry> loadGameDataRegistry(AssetBundle bundle) async {
  final loader = GameDataLoader(bundle);

  // `redundantFields` autorise le fichier a redeclarer un champ injecte, a
  // l identique. `id` y reste a titre permanent : le porter rend le fichier
  // lisible hors contexte. `heroClass` et `category` n y sont que le temps de
  // la migration — la tache de durcissement les en retire.
  final cards = await loader.loadAll<CardData>([
    EntitySource(
      'assets/data/cards/*.json',
      CardData.fromJson,
      inject: (c) => {'id': c[0], 'category': 'global'},
      redundantFields: const {'id', 'category'},
    ),
    EntitySource(
      'assets/data/classes/*/cards/*.json',
      CardData.fromJson,
      inject: (c) => {
        'id': c[1],
        'heroClass': c[0],
        'category': 'characterSpecific',
      },
      redundantFields: const {'id', 'heroClass', 'category'},
    ),
  ]);

  final relics = await loader.loadAll<RelicData>([
    EntitySource('assets/data/relics/*.json', RelicData.fromJson,
        inject: (c) => {'id': c[0]}),
  ]);

  final events = await loader.loadAll<EventData>([
    EntitySource('assets/data/events/*.json', EventData.fromJson,
        inject: (c) => {'id': c[0]}),
  ]);

  final forgeUpgrades = await loader.loadAll<ForgeUpgradeData>([
    EntitySource('assets/data/forge_upgrades/*.json', ForgeUpgradeData.fromJson,
        inject: (c) => {'id': c[0]}),
  ]);

  // Les passifs restent a plat, sans injection d appartenance (decision D4) :
  // `PassiveData` n a pas de champ `heroClass`, donc une injection y serait
  // silencieusement jetee par `fromJson` — un no-op qu aucun test ne pourrait
  // detecter. Et P-41 refait entierement ce modele.
  final passives = await loader.loadAll<PassiveData>([
    EntitySource('assets/data/passives/*.json', PassiveData.fromJson,
        inject: (c) => {'id': c[0]}),
  ]);

  final heroes = await loader.loadAll<HeroData>([
    EntitySource('assets/data/classes/*/class.json', HeroData.fromJson,
        inject: (c) => {'id': c[0]}),
  ]);

  final enemies = await loader.loadAll<EnemyData>([
    EntitySource('assets/data/enemies/*/enemy.json', EnemyData.fromJson,
        inject: (c) => {'id': c[0]}),
  ]);

  // Une fois seulement, a la fin : les fautes de toutes les categories sont
  // remontees ensemble. Corriger une faute par cycle de rebuild, sur 72
  // fichiers, serait invivable.
  loader.throwIfFailed();

  // L audio est le seul sous-systeme auquel il est interdit de faire echouer
  // le demarrage : `loadAudioData` ne leve jamais et reste hors du chargeur.
  final audio = await loadAudioData('assets/data/audio.json');

  return GameDataRegistry(
    enemies: enemies,
    heroes: heroes,
    cards: cards,
    events: events,
    passives: passives,
    relics: relics,
    forgeUpgrades: forgeUpgrades,
    audio: audio,
  );
}

final gameDataLoaderProvider = FutureProvider<GameDataRegistry>((ref) async {
  final List<List<dynamic>> results = await Future.wait([
    _loadJsonList('assets/data/enemies.json'),
    _loadJsonList('assets/data/heroes.json'),
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
  final cardsList = results[2];
  final eventsList = results[3];
  final passivesList = results[4];
  final relicsList = results[5];
  final heroCardsList = results[6];
  final forgeUpgradesList = results[7];

  final allCards = [
    ...cardsList,
    ...heroCardsList,
  ];

  return GameDataRegistry(
    enemies: _mapList(enemiesList, EnemyData.fromJson, 'EnemyData'),
    heroes: _mapList(heroesList, HeroData.fromJson, 'HeroData'),
    cards: _mapList(allCards, CardData.fromJson, 'CardData'),
    events: _mapList(eventsList, EventData.fromJson, 'EventData'),
    passives: _mapList(passivesList, PassiveData.fromJson, 'PassiveData'),
    relics: _mapList(relicsList, RelicData.fromJson, 'RelicData'),
    forgeUpgrades: _mapList(forgeUpgradesList, ForgeUpgradeData.fromJson, 'ForgeUpgradeData'),
    audio: audio,
  );
});
