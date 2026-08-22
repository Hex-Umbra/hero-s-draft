# P-45 — Fidélité du tutoriel — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Réaligner le tutoriel autonome sur le jeu réel — 50 écarts corrigés, dont 13 éliminés à la racine en faisant lire au tutoriel les données et les widgets du jeu, et deux étapes d'amont ajoutées (choix de classe, draft du deck de départ).

**Architecture:** `lib/tutorial/tutorial_loader.dart` devient l'unique point Riverpod du dossier : il `watch` `gameDataLoaderProvider` et injecte le `GameDataRegistry` dans `TutorialScreen`, qui le passe à `TutorialEngine`. Les POJOs `TutorialCard` / `TutorialEnemy` disparaissent au profit de `CardInstance`, `EnemyInstance` et `EntityStats`, ce qui permet de réutiliser `UiCard`, `EnemyIntentsPanel`, `StatusEffectsPanel`, `LevelUpRewardService` et `DamagePipeline` tels quels. `resetMockState()` devient `prepareStep()`, qui préserve une tranche persistante (classe choisie, deck drafté) à travers les étapes.

**Tech Stack:** Flutter · Riverpod 2.x (`FutureProvider` en lecture seule, un seul point d'entrée) · `ChangeNotifier` local pour le moteur · `flutter_test` pour les tests unitaires et widget.

**Spec:** `docs/superpowers/specs/2026-08-22-p45-fidelite-du-tutoriel-design.md`

## Global Constraints

- **Bilinguisme obligatoire.** Tout texte visible par le joueur existe en `fr` et en `en`. Dans `lib/tutorial/`, la convention est le doublage de champs (`titleFr`/`titleEn`, `bodyFr`/`bodyEn`), pas l'ARB. Une chaîne ajoutée sans son pendant est un défaut bloquant.
- **Un seul fichier de `lib/tutorial/` importe `flutter_riverpod` : `tutorial_loader.dart`.** Tout autre import est un défaut bloquant, vérifié par un test (Task 2).
- **Ne jamais utiliser `GameDataRegistry.instance`.** Ce singleton statique existe (`game_data_registry.dart:20-21`) mais `CLAUDE.md` interdit les singletons pour l'état partagé. Le registre se passe **toujours** par constructeur.
- **Providers d'état interdits dans `lib/tutorial/`** : `runProvider`, `deckProvider`, `combatProvider`, `inventoryProvider`, `skillProvider`, `rewardProvider`, `shopProvider`, `eventProvider`, `checkpointProvider`.
- **`dart analyze` doit rendre zéro problème** après chaque tâche, avant le commit. C'est une règle du dépôt (`CLAUDE.md`).
- **Pas de code mort, pas d'import inutilisé, pas de bloc commenté** dans le code commité.
- **Résolution des fixtures : `firstWhere` sans `orElse`.** Un `orElse` réintroduirait les valeurs en dur que ce chantier supprime. Le garde-fou est le test de Task 1.
- **Ne jamais éditer `assets/data/patch_notes.json` à la main** — le skill `patch-notes-writer` s'en charge (Task 17).
- **Numérotation des étapes** : le parcours cible compte 15 étapes. Correspondance ancien → nouveau : 01→01, *(02 et 03 sont neuves)*, 02→04, 03→05, 04→06, 05→07, 06→08, 07→09, 08→10, 09→11, 10→12, 11→13, 12→14, 13→15.

---

## Structure des fichiers

**Créés**

| Fichier | Responsabilité |
|:---|:---|
| `lib/tutorial/tutorial_fixtures.dart` | Ids des entrées de `assets/data/` utilisées par le tutoriel, et leur résolution contre le registre |
| `lib/tutorial/tutorial_loader.dart` | Unique frontière Riverpod : résout `gameDataLoaderProvider`, injecte le registre |
| `lib/tutorial/widgets/tutorial_class_choice_widget.dart` | Étape 02 |
| `lib/tutorial/widgets/tutorial_starter_deck_widget.dart` | Étape 03 |
| `test/tutorial/tutorial_fixtures_test.dart` | Garde-fou de fidélité contre les JSON réels |
| `test/tutorial/tutorial_isolation_test.dart` | Vérifie la frontière Riverpod unique |
| `test/widget/tutorial_class_step_test.dart` | Étape 02 |
| `test/widget/tutorial_starter_draft_test.dart` | Étape 03 |

**Modifiés**

| Fichier | Nature |
|:---|:---|
| `lib/tutorial/tutorial_engine.dart` | Refonte : registre injecté, modèles réels, `prepareStep`, tranche persistante |
| `lib/tutorial/tutorial_step.dart` | Deux valeurs d'enum ajoutées |
| `lib/tutorial/tutorial_data.dart` | Deux étapes ajoutées, 16 textes corrigés |
| `lib/tutorial/tutorial_screen.dart` | Registre en paramètre, switch à 15 branches, verrou 02/03 |
| `lib/tutorial/widgets/*.dart` | 11 widgets d'étape retouchés |
| `lib/ui/screens/home_screen.dart:188` | Pousse `TutorialLoader` |
| `lib/ui/widgets/map/map_legend.dart:128-131` | `x2` → `x3` |
| `lib/l10n/app_fr.arb` · `app_en.arb` | `legendBossXp` aligné |
| `test/tutorial/tutorial_engine_test.dart` | Réécrit |

---

## Task 1: Le module de fixtures et son garde-fou

Fondation de tout le chantier : le point unique où le tutoriel nomme les données du jeu, et le test qui empêche ces noms de pourrir.

**Files:**
- Create: `lib/tutorial/tutorial_fixtures.dart`
- Test: `test/tutorial/tutorial_fixtures_test.dart`

**Interfaces:**
- Consumes: `GameDataRegistry`, `CardData`, `EnemyData`, `HeroData`, `PassiveData`, `RelicData`
- Produces: `TutorialFixtureIds` (constantes) et `TutorialFixtures(registry)` avec `card(String id)`, `trainingEnemy`, `sampleRelic`, `heroes`, `passiveFor(HeroData)`, `starterPool`

> **Note sur le chargement des JSON dans le test.** Aucun test du dépôt ne lit les assets réels aujourd'hui. On passe par `dart:io` plutôt que `rootBundle` : `flutter test` s'exécute depuis la racine du paquet, les chemins relatifs `assets/data/*.json` résolvent donc directement, et on évite toute initialisation de binding. Le décodage passe par les vraies factories `fromJson`, ce qui valide le parsing en prime.

- [ ] **Step 1: Écrire le test qui échoue**

Créer `test/tutorial/tutorial_fixtures_test.dart` :

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/tutorial/tutorial_fixtures.dart';

List<Map<String, dynamic>> _readJson(String path) {
  final raw = File(path).readAsStringSync();
  return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
}

/// Construit un registre à partir des JSON réels du dépôt, sans rootBundle.
GameDataRegistry _realRegistry() {
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

void main() {
  late TutorialFixtures fixtures;

  setUp(() {
    fixtures = TutorialFixtures(_realRegistry());
  });

  group('Existence des fixtures', () {
    test('les trois classes du tutoriel existent', () {
      expect(fixtures.heroes.map((h) => h.id), ['paladin', 'berserker', 'mage']);
    });

    test('chaque classe a un passif résoluble', () {
      for (final hero in fixtures.heroes) {
        expect(fixtures.passiveFor(hero).id, hero.passiveTrait);
      }
    });

    test('les trois cartes de démonstration existent', () {
      expect(fixtures.card(TutorialFixtureIds.strike).id, 'strike_basic');
      expect(fixtures.card(TutorialFixtureIds.defend).id, 'defend_basic');
      expect(fixtures.card(TutorialFixtureIds.fireball).id, 'fireball');
    });

    test('l\'ennemi et la relique de démonstration existent', () {
      expect(fixtures.trainingEnemy.id, 'slime');
      expect(fixtures.sampleRelic.id, 'iron_talisman');
    });
  });

  group('Propriétés dont la pédagogie dépend', () {
    test('Frappe est une attaque ciblée qui inflige des dégâts', () {
      final strike = fixtures.card(TutorialFixtureIds.strike);
      expect(strike.type, CardType.attack);
      expect(strike.target, CardTarget.singleEnemy);
      expect(strike.effects.any((e) => e.type == 'damage'), isTrue);
    });

    test('Défense est une Compétence sur soi qui donne de l\'armure', () {
      final defend = fixtures.card(TutorialFixtureIds.defend);
      expect(defend.type, CardType.skill);
      expect(defend.target, CardTarget.self);
      expect(defend.effects.any((e) => e.type == 'armor'), isTrue);
    });

    test('Boule de Feu applique bien Brûlure', () {
      final fireball = fixtures.card(TutorialFixtureIds.fireball);
      expect(fireball.type, CardType.attack);
      expect(
        fireball.effects.any((e) => e.type == 'apply_status' && e.statusId == 'burn'),
        isTrue,
      );
    });

    test('le Slime a une intention d\'attaque exploitable', () {
      final slime = fixtures.trainingEnemy;
      expect(slime.intents, isNotNull);
      expect(slime.intents!, isNotEmpty);
      expect(slime.maxHp, greaterThan(0));
    });

    test('le Talisman de Fer se déclenche en début de tour', () {
      final relic = fixtures.sampleRelic;
      expect(relic.trigger, RelicTrigger.startOfTurn);
      expect(relic.effectType, 'gain_armor');
    });

    test('le pool de départ ne contient que des cartes globales non-statut', () {
      expect(fixtures.starterPool, isNotEmpty);
      expect(fixtures.starterPool.length, greaterThanOrEqualTo(5));
      for (final card in fixtures.starterPool) {
        expect(card.category, CardCategory.global);
        expect(card.type, isNot(CardType.status));
      }
    });
  });

  group('Politique fail-fast', () {
    test('un id absent lève au lieu de retomber sur une valeur en dur', () {
      expect(() => fixtures.card('id_qui_nexiste_pas'), throwsStateError);
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

Run: `flutter test test/tutorial/tutorial_fixtures_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:roguelike_card_game/tutorial/tutorial_fixtures.dart'`

- [ ] **Step 3: Écrire l'implémentation minimale**

Créer `lib/tutorial/tutorial_fixtures.dart` :

```dart
import '../models/data/card_data.dart';
import '../models/data/enemy_data.dart';
import '../models/data/game_data_registry.dart';
import '../models/data/hero_data.dart';
import '../models/data/passive_data.dart';
import '../models/data/relic_data.dart';

/// Ids des entrées de `assets/data/` sur lesquelles le tutoriel s'appuie.
///
/// Le tutoriel ne nomme les données du jeu qu'ici. Toute autre référence en
/// dur à un id de carte, d'ennemi ou de relique dans `lib/tutorial/` est un
/// défaut.
class TutorialFixtureIds {
  const TutorialFixtureIds._();

  static const String strike = 'strike_basic';
  static const String defend = 'defend_basic';
  static const String fireball = 'fireball';
  static const String trainingEnemy = 'slime';
  static const String sampleRelic = 'iron_talisman';
  static const List<String> heroes = ['paladin', 'berserker', 'mage'];
}

/// Résout les fixtures du tutoriel contre le registre de données du jeu.
///
/// La résolution est délibérément *fail-fast* : `firstWhere` sans `orElse`.
/// Un repli réintroduirait les valeurs en dur que ce module supprime, et le
/// garde-fou `test/tutorial/tutorial_fixtures_test.dart` attrape l'absence
/// en CI avant qu'elle n'atteigne l'exécution.
class TutorialFixtures {
  final GameDataRegistry registry;

  const TutorialFixtures(this.registry);

  CardData card(String id) => registry.cards.firstWhere((c) => c.id == id);

  EnemyData get trainingEnemy =>
      registry.enemies.firstWhere((e) => e.id == TutorialFixtureIds.trainingEnemy);

  RelicData get sampleRelic =>
      registry.relics.firstWhere((r) => r.id == TutorialFixtureIds.sampleRelic);

  List<HeroData> get heroes => TutorialFixtureIds.heroes
      .map((id) => registry.heroes.firstWhere((h) => h.id == id))
      .toList();

  PassiveData passiveFor(HeroData hero) =>
      registry.passives.firstWhere((p) => p.id == hero.passiveTrait);

  /// Le pool du draft de départ, filtré comme `StarterDeckDraftScreen`.
  List<CardData> get starterPool => registry.cards
      .where((c) => c.category == CardCategory.global && c.type != CardType.status)
      .toList();
}
```

- [ ] **Step 4: Lancer le test pour vérifier qu'il passe**

Run: `flutter test test/tutorial/tutorial_fixtures_test.dart`
Expected: PASS — 12 tests

- [ ] **Step 5: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/tutorial/tutorial_fixtures.dart test/tutorial/tutorial_fixtures_test.dart
git commit -m "feat(tutorial): resoudre les fixtures contre le registre de donnees"
```

---

## Task 2: La frontière Riverpod unique

**Files:**
- Create: `lib/tutorial/tutorial_loader.dart`
- Create: `test/tutorial/tutorial_isolation_test.dart`
- Modify: `lib/tutorial/tutorial_engine.dart` (constructeur)
- Modify: `lib/tutorial/tutorial_screen.dart` (paramètre `data`)
- Modify: `lib/ui/screens/home_screen.dart:186-192`
- Modify: `test/tutorial/tutorial_engine_test.dart` (le moteur exige désormais un registre)

**Interfaces:**
- Consumes: `TutorialFixtures` (Task 1), `gameDataLoaderProvider`
- Produces: `TutorialLoader` (widget sans paramètre), `TutorialEngine({required GameDataRegistry data})` exposant `TutorialFixtures get fixtures`, `TutorialScreen({required GameDataRegistry data})`

- [ ] **Step 1: Écrire le test d'isolation qui échoue**

Créer `test/tutorial/tutorial_isolation_test.dart` :

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le tutoriel est autonome vis-à-vis de l'état du jeu : un seul fichier du
/// dossier a le droit de toucher Riverpod, et seulement pour lire des
/// données immuables. Voir ADR-081 et `_rules/08-00`.
void main() {
  test('un seul fichier de lib/tutorial/ importe flutter_riverpod', () {
    final offenders = <String>[];

    for (final entity in Directory('lib/tutorial').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll(r'\', '/');
      if (normalized.endsWith('lib/tutorial/tutorial_loader.dart')) continue;
      if (entity.readAsStringSync().contains('flutter_riverpod')) {
        offenders.add(normalized);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Seul tutorial_loader.dart peut importer Riverpod. '
          'Fichiers fautifs : ${offenders.join(", ")}',
    );
  });

  test('aucun provider d\'etat n\'est reference dans lib/tutorial/', () {
    const forbidden = [
      'runProvider',
      'deckProvider',
      'combatProvider',
      'inventoryProvider',
      'skillProvider',
      'rewardProvider',
      'shopProvider',
      'eventProvider',
      'checkpointProvider',
      'GameDataRegistry.instance',
    ];
    final offenders = <String>[];

    for (final entity in Directory('lib/tutorial').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      for (final symbol in forbidden) {
        if (content.contains(symbol)) {
          offenders.add('${entity.path.replaceAll(r'\', '/')} → $symbol');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il passe déjà (état de départ vert)**

Run: `flutter test test/tutorial/tutorial_isolation_test.dart`
Expected: PASS — aucun fichier n'importe Riverpod aujourd'hui. Ce test est un **cliquet** : il doit rester vert après l'ajout du loader. S'il échoue ici, c'est que la règle est déjà violée et il faut le signaler avant de continuer.

- [ ] **Step 3: Créer le loader**

Créer `lib/tutorial/tutorial_loader.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/game_data_service.dart';
import 'tutorial_screen.dart';

/// Unique frontière Riverpod de `lib/tutorial/`.
///
/// Résout `gameDataLoaderProvider` — un `FutureProvider` de données
/// immuables, sans aucun état de run — et injecte le registre dans
/// [TutorialScreen], qui le passe au moteur. Aucun autre fichier du dossier
/// n'a le droit d'importer Riverpod : voir ADR-081.
class TutorialLoader extends ConsumerWidget {
  const TutorialLoader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return ref
        .watch(gameDataLoaderProvider)
        .when(
          data: (registry) => TutorialScreen(data: registry),
          loading: () => const Scaffold(
            backgroundColor: Color(0xFF0B0F19),
            body: Center(child: CircularProgressIndicator(color: Colors.amber)),
          ),
          error: (error, _) => Scaffold(
            backgroundColor: const Color(0xFF0B0F19),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isFrench
                          ? 'Impossible de charger les données du jeu.'
                          : 'Could not load game data.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(isFrench ? 'Retour' : 'Back'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
  }
}
```

- [ ] **Step 4: Faire porter le registre au moteur et à l'écran**

Dans `lib/tutorial/tutorial_engine.dart`, remplacer la déclaration de classe et son en-tête :

```dart
class TutorialEngine extends ChangeNotifier {
  final GameDataRegistry data;
  late final TutorialFixtures fixtures;

  int _currentStepIndex = 0;
  final TutorialMockState mockState = TutorialMockState();

  TutorialEngine({required this.data}) {
    fixtures = TutorialFixtures(data);
  }

  int get currentStepIndex => _currentStepIndex;
```

Ajouter en tête du fichier :

```dart
import '../models/data/game_data_registry.dart';
import 'tutorial_fixtures.dart';
```

Dans `lib/tutorial/tutorial_screen.dart`, remplacer la déclaration du widget et l'`initState` :

```dart
class TutorialScreen extends StatefulWidget {
  final GameDataRegistry data;

  const TutorialScreen({super.key, required this.data});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}
```

```dart
  @override
  void initState() {
    super.initState();
    _engine = TutorialEngine(data: widget.data);
    _engine.resetMockState();
    _pageController = PageController(initialPage: _engine.currentStepIndex);
    _engine.addListener(_onEngineChanged);
  }
```

Ajouter l'import `import '../models/data/game_data_registry.dart';` dans `tutorial_screen.dart`.

- [ ] **Step 5: Brancher `HomeScreen` sur le loader**

Dans `lib/ui/screens/home_screen.dart`, remplacer l'import `tutorial_screen.dart` par `tutorial_loader.dart`, et à la ligne 188 :

```dart
                            builder: (context) => const TutorialLoader(),
```

- [ ] **Step 6: Adapter le test moteur existant pour qu'il compile**

Dans `test/tutorial/tutorial_engine_test.dart`, remplacer le `setUp` :

```dart
    setUp(() {
      engine = TutorialEngine(data: buildTutorialTestRegistry());
      engine.resetMockState();
    });
```

et ajouter, en tête de fichier, un helper partagé qui sera réutilisé par toutes les tâches suivantes — le créer dans `test/tutorial/tutorial_test_registry.dart` :

```dart
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
```

Puis remplacer la fonction `_realRegistry()` de `tutorial_fixtures_test.dart` par un import de ce helper, pour ne pas dupliquer la lecture des JSON.

- [ ] **Step 7: Lancer les tests**

Run: `flutter test test/tutorial/`
Expected: PASS — le test d'isolation reste vert (le loader est exclu par nom), les fixtures passent, le test moteur compile et passe.

- [ ] **Step 8: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add lib/tutorial/tutorial_loader.dart lib/tutorial/tutorial_engine.dart lib/tutorial/tutorial_screen.dart lib/ui/screens/home_screen.dart test/tutorial/
git commit -m "feat(tutorial): injecter le registre de donnees via une frontiere Riverpod unique"
```

---

## Task 3: Les POJOs cèdent la place aux modèles du jeu

**Files:**
- Modify: `lib/tutorial/tutorial_engine.dart` (suppression de `TutorialCard:4` et `TutorialEnemy:26`, refonte de `TutorialMockState:48` et `playCard:221`)
- Modify: `lib/tutorial/widgets/tutorial_cards_widget.dart`, `tutorial_play_card_widget.dart`, `tutorial_merge_widget.dart` (typage de la main)
- Modify: `test/tutorial/tutorial_engine_test.dart`

**Interfaces:**
- Consumes: `TutorialFixtures` (Task 1), `CardInstance`, `EnemyInstance`, `EntityStats`, `StatusEffect`, `DamagePipeline`
- Produces: `TutorialMockState` avec `heroStats` (`EntityStats`), `hand` (`List<CardInstance>`), `enemy` (`EnemyInstance?`) ; `TutorialEngine.playCard(CardInstance)` → `bool`

> **Pourquoi `EnemyInstance` et non un POJO mutable.** `EnemyInstance` est immuable et se met à jour par `copyWith`. C'est ce qui permet de passer directement `[mockState.enemy!]` à `EnemyIntentsPanel` en Task 11, et d'obtenir les 4 paliers d'attaque gratuitement.

- [ ] **Step 1: Écrire les tests qui échouent**

Remplacer intégralement `test/tutorial/tutorial_engine_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/tutorial_fixtures.dart';

import 'tutorial_test_registry.dart';

void main() {
  late TutorialEngine engine;

  setUp(() {
    engine = TutorialEngine(data: buildTutorialTestRegistry());
    engine.resetMockState();
  });

  group('Modèles réels', () {
    test('la main est composée de CardInstance issues du registre', () {
      engine.seedHand([
        TutorialFixtureIds.strike,
        TutorialFixtureIds.defend,
      ]);

      expect(engine.mockState.hand, everyElement(isA<CardInstance>()));
      expect(engine.mockState.hand.first.data.id, 'strike_basic');
      // La valeur vient du JSON, pas d'une constante recopiée.
      expect(engine.mockState.hand.first.data.cost, 1);
    });

    test('l\'ennemi d\'entraînement porte les stats du JSON', () {
      engine.seedEnemy();

      final enemy = engine.mockState.enemy!;
      final slime = engine.fixtures.trainingEnemy;
      expect(enemy.stats.maxPv, slime.maxHp);
      expect(enemy.stats.currentPv, slime.maxHp);
      expect(enemy.data.id, 'slime');
    });

    test('les stats du héros sont un EntityStats', () {
      expect(engine.mockState.heroStats.maxPv, greaterThan(0));
      expect(engine.mockState.heroStats.armure, 0);
    });
  });

  group('playCard passe par les vrais calculs', () {
    test('une attaque retire les dégâts du JSON aux PV de l\'ennemi', () {
      engine.seedEnemy();
      engine.seedHand([TutorialFixtureIds.strike]);

      final slimeHp = engine.fixtures.trainingEnemy.maxHp;
      final strikeDamage = engine.fixtures
          .card(TutorialFixtureIds.strike)
          .effects
          .firstWhere((e) => e.type == 'damage')
          .value;

      final played = engine.playCard(engine.mockState.hand.first);

      expect(played, isTrue);
      expect(engine.mockState.enemy!.stats.currentPv, slimeHp - strikeDamage);
    });

    test('une carte de Défense donne de l\'armure même sans ennemi', () {
      // Régression : le gain d'armure était imbriqué dans `if (enemy != null)`.
      engine.seedHand([TutorialFixtureIds.defend]);
      expect(engine.mockState.enemy, isNull);

      final armorValue = engine.fixtures
          .card(TutorialFixtureIds.defend)
          .effects
          .firstWhere((e) => e.type == 'armor')
          .value;

      engine.playCard(engine.mockState.hand.first);

      expect(engine.mockState.heroStats.armure, armorValue);
    });

    test('une carte trop chère n\'est pas jouée', () {
      engine.seedHand([TutorialFixtureIds.fireball]);
      engine.setMana(0);

      expect(engine.playCard(engine.mockState.hand.first), isFalse);
      expect(engine.mockState.hand, hasLength(1));
    });
  });

  group('L\'absorption d\'armure suit EntityStats.takeDamage', () {
    test('sans armure, tous les dégâts vont aux PV', () {
      final before = engine.mockState.heroStats.currentPv;
      engine.applyDamageToHero(10);
      expect(engine.mockState.heroStats.currentPv, before - 10);
    });

    test('avec armure, l\'armure encaisse en premier', () {
      engine.setHeroArmor(4);
      final before = engine.mockState.heroStats.currentPv;

      engine.applyDamageToHero(10);

      expect(engine.mockState.heroStats.armure, 0);
      expect(engine.mockState.heroStats.currentPv, before - 6);
    });
  });
}
```

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/tutorial/tutorial_engine_test.dart`
Expected: FAIL — `seedHand`, `seedEnemy`, `setMana`, `setHeroArmor`, `applyDamageToHero` n'existent pas ; `mockState.heroStats` non plus.

- [ ] **Step 3: Refondre `TutorialMockState` et `playCard`**

Dans `lib/tutorial/tutorial_engine.dart`, **supprimer** les classes `TutorialCard` (ligne 4) et `TutorialEnemy` (ligne 26), et remplacer `TutorialMockState` par :

```dart
class TutorialMockState {
  // --- Tranche persistante (écrite par les étapes 02 et 03) ---
  HeroData? chosenHero;
  PassiveData? activePassive;
  List<CardInstance> masterDeck = [];

  // --- Tranche scratch (réinitialisée à chaque étape) ---
  EntityStats heroStats = EntityStats(
    maxPv: 80,
    currentPv: 80,
    maxMana: 3,
    currentMana: 3,
    armure: 0,
    attaque: 0,
  );
  List<CardInstance> hand = [];
  EnemyInstance? enemy;
  int playerXp = 0;
  int xpToNextLevel = 100;
  int playerLevel = 1;
  bool hasDrafted = false;

  /// Statistiques de départ dérivées de la classe choisie, ou valeurs de
  /// repli tant que l'étape 02 n'a pas été franchie.
  EntityStats baseStatsForHero() {
    final hero = chosenHero;
    if (hero == null) {
      return EntityStats(
        maxPv: 80,
        currentPv: 80,
        maxMana: 3,
        currentMana: 3,
        armure: 0,
        attaque: 0,
      );
    }
    return EntityStats(
      maxPv: hero.maxHp,
      currentPv: hero.maxHp,
      maxMana: hero.maxMana,
      currentMana: hero.maxMana,
      armure: 0,
      armorMastery: hero.armorMastery,
      attaque: 0,
      luck: hero.luck,
    );
  }

  /// Réinitialise uniquement la tranche scratch.
  void resetScratch() {
    heroStats = baseStatsForHero();
    hand = [];
    enemy = null;
    playerXp = 0;
    xpToNextLevel = 100;
    playerLevel = 1;
    hasDrafted = false;
  }
}
```

Ajouter les imports nécessaires en tête de `tutorial_engine.dart` :

```dart
import '../models/card_instance.dart';
import '../models/data/hero_data.dart';
import '../models/data/passive_data.dart';
import '../models/entity_stats.dart';
import '../models/enemy_instance.dart';
import '../game/services/damage_pipeline.dart';
```

- [ ] **Step 4: Écrire les helpers de peuplement et le nouveau `playCard`**

Toujours dans `TutorialEngine`, remplacer `playCard` (ligne 221) et ajouter les helpers :

```dart
  /// Peuple la main à partir d'ids de cartes du registre.
  void seedHand(List<String> cardIds) {
    mockState.hand = cardIds
        .map((id) => CardInstance(data: fixtures.card(id)))
        .toList();
    notifyListeners();
  }

  /// Place l'ennemi d'entraînement, intention comprise.
  void seedEnemy() {
    final data = fixtures.trainingEnemy;
    mockState.enemy = EnemyInstance(
      data: data,
      stats: EntityStats(
        maxPv: data.maxHp,
        currentPv: data.maxHp,
        armure: 0,
        attaque: data.baseDamage,
      ),
      currentIntent: data.intents?.first,
    );
    notifyListeners();
  }

  void setMana(int value) {
    mockState.heroStats = mockState.heroStats.copyWith(currentMana: value);
    notifyListeners();
  }

  void setHeroArmor(int value) {
    mockState.heroStats = mockState.heroStats.copyWith(armure: value);
    notifyListeners();
  }

  /// Applique des dégâts au héros via la vraie formule d'absorption.
  void applyDamageToHero(int amount) {
    mockState.heroStats = mockState.heroStats.takeDamage(amount);
    notifyListeners();
  }

  /// Joue une carte de la main. Les dégâts passent par le pipeline réel :
  /// avec `critChance: 0`, il est déterministe.
  bool playCard(CardInstance card) {
    if (mockState.heroStats.currentMana < card.currentCost) return false;

    mockState.heroStats = mockState.heroStats.copyWith(
      currentMana: mockState.heroStats.currentMana - card.currentCost,
    );
    mockState.hand.remove(card);

    for (final effect in card.data.effects) {
      final scaled = (effect.value * card.rarityMultiplier).round();

      if (effect.type == 'damage') {
        final enemy = mockState.enemy;
        if (enemy == null) continue;
        final (dealt, isCrit) = DamagePipeline.calculate(
          initialDamage: scaled + mockState.heroStats.effectiveAttaque,
          attackerStats: mockState.heroStats,
          defenderStats: enemy.stats,
        );
        mockState.enemy = enemy.copyWith(
          stats: enemy.stats.takeDamage(dealt, isCrit: isCrit),
        );
      } else if (effect.type == 'armor') {
        mockState.heroStats = mockState.heroStats.copyWith(
          armure: mockState.heroStats.armure + scaled,
        );
      }
    }

    notifyListeners();
    return true;
  }
```

Supprimer `simulateDamageTake` (remplacé par `applyDamageToHero`) et adapter `mergeCards` / `gainXp` au nouveau typage : `mergeCards` produit désormais un `CardInstance` de rareté supérieure.

```dart
  /// Fusionne les 3 exemplaires de la main en une carte de rareté
  /// supérieure, comme `DeckNotifier.mergeCards`.
  void mergeCards() {
    if (mockState.hand.length != 3) return;
    final base = mockState.hand.first;
    final nextIndex = (base.rarity.index + 1).clamp(0, CardRarity.values.length - 1);
    mockState.hand = [
      CardInstance(data: base.data, rarity: CardRarity.values[nextIndex]),
    ];
    notifyListeners();
  }
```

Ajouter `import '../models/data/card_data.dart';` pour `CardRarity`.

- [ ] **Step 5: Adapter les trois widgets qui typaient la main**

Dans `tutorial_cards_widget.dart`, `tutorial_play_card_widget.dart` et `tutorial_merge_widget.dart`, remplacer chaque `TutorialCard` par `CardInstance`, chaque `card.nameFr` / `card.nameEn` par `card.data.getName(locale)`, chaque `card.cost` par `card.currentCost`, et chaque `card.id` par `card.data.id`. L'affichage lui-même est retouché en Tasks 8, 7 et 12 ; ici on se contente de faire compiler.

- [ ] **Step 6: Lancer les tests**

Run: `flutter test test/tutorial/`
Expected: PASS — 8 nouveaux cas moteur, dont la régression du gain d'armure sans ennemi.

- [ ] **Step 7: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/tutorial/ test/tutorial/
git commit -m "refactor(tutorial): remplacer les POJOs du mock par les modeles du jeu"
```

---

## Task 4: `prepareStep()` et la tranche persistante

**Files:**
- Modify: `lib/tutorial/tutorial_engine.dart` (`resetMockState:102` → `prepareStep`)
- Modify: `lib/tutorial/tutorial_screen.dart` (appels)
- Modify: `test/tutorial/tutorial_engine_test.dart`

**Interfaces:**
- Consumes: `TutorialMockState` (Task 3)
- Produces: `TutorialEngine.prepareStep(int index)`, `TutorialEngine.minReachableStep` (getter `int`), `nextStep()` / `prevStep()` respectant le verrou

- [ ] **Step 1: Écrire les tests qui échouent**

Ajouter à `test/tutorial/tutorial_engine_test.dart` :

```dart
  group('Parcours à état', () {
    test('la classe choisie survit aux changements d\'étape', () {
      final paladin = engine.fixtures.heroes.first;
      engine.chooseHero(paladin);

      engine.nextStep();
      engine.nextStep();

      expect(engine.mockState.chosenHero?.id, 'paladin');
      expect(engine.mockState.activePassive?.id, 'regenArmor');
    });

    test('les stats du héros dérivent de la classe choisie', () {
      final mage = engine.fixtures.heroes.firstWhere((h) => h.id == 'mage');
      engine.chooseHero(mage);
      engine.prepareStep(engine.currentStepIndex);

      expect(engine.mockState.heroStats.maxPv, 60);
      expect(engine.mockState.heroStats.maxMana, 3);
    });

    test('le deck drafté survit aux changements d\'étape', () {
      final pool = engine.fixtures.starterPool.take(5).toList();
      engine.chooseHero(engine.fixtures.heroes.first);
      engine.setStarterDeck(pool);

      final expectedSize = 5 + engine.fixtures.heroes.first.skills.length;
      engine.nextStep();

      expect(engine.mockState.masterDeck, hasLength(expectedSize));
    });

    test('la tranche scratch est bien réinitialisée entre deux étapes', () {
      engine.seedEnemy();
      engine.nextStep();
      expect(engine.mockState.enemy, isNull);
    });
  });

  group('Verrou des étapes d\'amont', () {
    test('minReachableStep vaut 0 avant l\'étape 03', () {
      expect(engine.minReachableStep, 0);
    });

    test('une fois l\'étape 03 franchie, on ne redescend plus sous 03', () {
      while (engine.currentStepIndex < 3) {
        engine.nextStep();
      }
      expect(engine.minReachableStep, 3);

      engine.prevStep();
      engine.prevStep();
      engine.prevStep();

      expect(engine.currentStepIndex, 3);
    });
  });
```

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/tutorial/tutorial_engine_test.dart`
Expected: FAIL — `chooseHero`, `setStarterDeck`, `prepareStep`, `minReachableStep` n'existent pas.

- [ ] **Step 3: Implémenter le parcours à état**

Dans `TutorialEngine`, remplacer `resetMockState()` (ligne 102) par :

```dart
  /// Indice plancher du retour en arrière une fois les étapes d'amont
  /// franchies : c'est « La Carte du Monde », la première étape qui suit le
  /// draft de départ. Revenir en deçà invaliderait la classe et le deck dont
  /// dépendent toutes les étapes suivantes.
  static const int _upstreamFloorIndex = 3;

  bool _upstreamLocked = false;

  int get minReachableStep => _upstreamLocked ? _upstreamFloorIndex : 0;

  void chooseHero(HeroData hero) {
    mockState.chosenHero = hero;
    mockState.activePassive = fixtures.passiveFor(hero);
    mockState.heroStats = mockState.baseStatsForHero();
    notifyListeners();
  }

  /// Fixe le deck de départ : les cartes choisies plus les cartes de classe,
  /// comme `StarterDeckDraftScreen._startAdventure`.
  void setStarterDeck(List<CardData> chosen) {
    final hero = mockState.chosenHero;
    final classCards = hero == null
        ? <CardData>[]
        : hero.skills.map(fixtures.card).toList();

    mockState.masterDeck = [
      ...classCards.map((c) => CardInstance(data: c)),
      ...chosen.map((c) => CardInstance(data: c)),
    ];
    notifyListeners();
  }

  /// Prépare l'étape [index] : réinitialise la tranche scratch, puis pose le
  /// décor propre à l'étape. La tranche persistante (classe, deck) survit.
  void prepareStep(int index) {
    mockState.resetScratch();

    switch (kTutorialSteps[index].type) {
      case TutorialStepType.cards:
        seedHand([
          TutorialFixtureIds.strike,
          TutorialFixtureIds.defend,
          TutorialFixtureIds.fireball,
        ]);
        break;
      case TutorialStepType.playCard:
        seedEnemy();
        seedHand([TutorialFixtureIds.strike, TutorialFixtureIds.defend]);
        break;
      case TutorialStepType.armorDamage:
        seedEnemy();
        break;
      case TutorialStepType.merge:
        seedHand([
          TutorialFixtureIds.strike,
          TutorialFixtureIds.strike,
          TutorialFixtureIds.strike,
        ]);
        break;
      case TutorialStepType.draft:
        mockState.playerLevel = 2;
        break;
      default:
        break;
    }
  }
```

et remplacer `nextStep` / `prevStep` :

```dart
  void nextStep() {
    if (_currentStepIndex >= kTutorialSteps.length - 1) return;
    _currentStepIndex++;
    // `>=` et non `>` : atteindre le plancher suffit à verrouiller l'amont.
    if (_currentStepIndex >= _upstreamFloorIndex) _upstreamLocked = true;
    prepareStep(_currentStepIndex);
    notifyListeners();
  }

  void prevStep() {
    if (_currentStepIndex <= minReachableStep) return;
    _currentStepIndex--;
    prepareStep(_currentStepIndex);
    notifyListeners();
  }
```

> **Attention au piège de l'ancien `switch`.** L'ancien code branchait sur l'**indice** (`case 4:`, `case 5:`…). Avec deux étapes insérées en amont, tous ces indices se décalent. Le nouveau `switch` branche sur `kTutorialSteps[index].type`, qui ne bouge pas quand on insère une étape.

- [ ] **Step 4: Répercuter le renommage dans l'écran**

Dans `lib/tutorial/tutorial_screen.dart`, remplacer les deux appels `_engine.resetMockState()` par `_engine.prepareStep(_engine.currentStepIndex)`, et conditionner le bouton « Précédent » (ligne 322) :

```dart
                                      if (_engine.currentStepIndex >
                                          _engine.minReachableStep)
```

Faire de même dans les `initState()` des widgets d'étape qui appellent `widget.engine.resetMockState()` (`tutorial_cards_widget.dart`, `tutorial_draft_widget.dart`, `tutorial_merge_widget.dart`, `tutorial_relics_widget.dart`, `tutorial_xp_widget.dart`) : ces appels deviennent inutiles puisque `prepareStep` est déjà passé — **les supprimer** plutôt que les renommer.

- [ ] **Step 5: Lancer les tests**

Run: `flutter test test/tutorial/`
Expected: PASS — 6 nouveaux cas.

- [ ] **Step 6: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/tutorial/ test/tutorial/
git commit -m "feat(tutorial): parcours a etat avec tranche persistante et verrou d'amont"
```

---

## Task 5: Étape 02 — Choix de classe

**Files:**
- Create: `lib/tutorial/widgets/tutorial_class_choice_widget.dart`
- Create: `test/widget/tutorial_class_step_test.dart`
- Modify: `lib/tutorial/tutorial_step.dart` (valeur d'enum `classChoice`)
- Modify: `lib/tutorial/tutorial_data.dart` (entrée en position 2)
- Modify: `lib/tutorial/tutorial_screen.dart` (`_buildIllustration`, `_isStepActionComplete`)

**Interfaces:**
- Consumes: `TutorialEngine.fixtures.heroes`, `fixtures.passiveFor()`, `TutorialEngine.chooseHero()`
- Produces: `TutorialClassChoiceWidget({required TutorialEngine engine})`

- [ ] **Step 1: Écrire le test qui échoue**

Créer `test/widget/tutorial_class_step_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/widgets/tutorial_class_choice_widget.dart';

import '../tutorial/tutorial_test_registry.dart';

Future<TutorialEngine> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final engine = TutorialEngine(data: buildTutorialTestRegistry());
  engine.prepareStep(0);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: const Locale('fr', ''),
      home: Scaffold(body: TutorialClassChoiceWidget(engine: engine)),
    ),
  );
  await tester.pumpAndSettle();
  return engine;
}

void main() {
  testWidgets('les trois classes s\'affichent avec leurs PV réels', (tester) async {
    await _pump(tester);

    expect(find.text('Le Paladin'), findsOneWidget);
    expect(find.text('Le Berserker'), findsOneWidget);
    expect(find.text('Le Mage'), findsOneWidget);

    expect(find.text('100 PV'), findsOneWidget);
    expect(find.text('80 PV'), findsOneWidget);
    expect(find.text('60 PV'), findsOneWidget);
  });

  testWidgets('le passif de chaque classe est affiché depuis passives.json', (tester) async {
    await _pump(tester);

    expect(find.text('Régénération d\'Armure'), findsOneWidget);
    expect(find.text('Armure du Berserker'), findsOneWidget);
    expect(find.text('Armure Magique'), findsOneWidget);
  });

  testWidgets('choisir une classe l\'écrit dans la tranche persistante', (tester) async {
    final engine = await _pump(tester);
    expect(engine.mockState.chosenHero, isNull);

    await tester.tap(find.text('Le Mage'));
    await tester.pumpAndSettle();

    expect(engine.mockState.chosenHero?.id, 'mage');
    expect(engine.mockState.activePassive?.id, 'spellArmor');
    expect(engine.mockState.heroStats.maxPv, 60);
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

Run: `flutter test test/widget/tutorial_class_step_test.dart`
Expected: FAIL — `tutorial_class_choice_widget.dart` n'existe pas.

- [ ] **Step 3: Ajouter la valeur d'enum**

Dans `lib/tutorial/tutorial_step.dart`, insérer `classChoice` et `starterDeck` juste après `welcome` :

```dart
enum TutorialStepType {
  welcome,
  classChoice,
  starterDeck,
  map,
  nodeTypes,
  combatOverview,
  cards,
  playCard,
  armorDamage,
  elements,
  enemies,
  merge,
  xp,
  draft,
  relics,
}
```

- [ ] **Step 4: Ajouter l'étape aux données**

Dans `lib/tutorial/tutorial_data.dart`, insérer en deuxième position (juste après l'entrée `welcome`) :

```dart
  TutorialStep(
    titleEn: 'Choose Your Class',
    titleFr: 'Choisissez votre classe',
    bodyEn:
        'Every run starts here. The three classes differ by their health pool '
        'and — above all — by their passive, which decides how they earn Armor. '
        'Pick one: the rest of this tutorial will use it.',
    bodyFr:
        'Toute partie commence ici. Les trois classes se distinguent par leurs '
        'points de vie et surtout par leur passif, qui décide de la façon dont '
        'elles gagnent de l\'Armure. Choisissez-en une : la suite de ce '
        'tutoriel s\'y adaptera.',
    type: TutorialStepType.classChoice,
  ),
```

- [ ] **Step 5: Écrire le widget**

Créer `lib/tutorial/widgets/tutorial_class_choice_widget.dart` :

```dart
import 'package:flutter/material.dart';

import '../../models/data/hero_data.dart';
import '../tutorial_engine.dart';

/// Étape 02 — choix de classe.
///
/// Les trois héros, leurs points de vie et leur passif viennent de
/// `heroes.json` et `passives.json` : aucune valeur n'est écrite ici.
class TutorialClassChoiceWidget extends StatefulWidget {
  final TutorialEngine engine;

  const TutorialClassChoiceWidget({super.key, required this.engine});

  @override
  State<TutorialClassChoiceWidget> createState() =>
      _TutorialClassChoiceWidgetState();
}

class _TutorialClassChoiceWidgetState extends State<TutorialClassChoiceWidget> {
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isFrench = locale == 'fr';
    final heroes = widget.engine.fixtures.heroes;
    final chosenId = widget.engine.mockState.chosenHero?.id;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            isFrench ? 'Choisissez votre classe' : 'Choose your class',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: heroes
                    .map((hero) => _buildHeroCard(hero, locale, chosenId == hero.id))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(HeroData hero, String locale, bool isSelected) {
    final passive = widget.engine.fixtures.passiveFor(hero);

    return InkWell(
      onTap: () {
        widget.engine.chooseHero(hero);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 190,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.amber
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hero.getName(locale),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${hero.maxHp} ${locale == 'fr' ? 'PV' : 'HP'}',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              '${hero.maxMana} ${locale == 'fr' ? 'Mana' : 'Mana'}',
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
            ),
            const Divider(color: Colors.white12, height: 18),
            Text(
              passive.getName(locale),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              passive.getDescription(locale),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Brancher l'étape dans l'écran**

Dans `lib/tutorial/tutorial_screen.dart`, ajouter au `switch` de `_buildIllustration` :

```dart
      case TutorialStepType.classChoice:
        return TutorialClassChoiceWidget(engine: _engine);
```

et au `switch` de `_isStepActionComplete` :

```dart
      case TutorialStepType.classChoice:
        return engine.mockState.chosenHero != null;
```

Ajouter l'import du widget.

- [ ] **Step 7: Lancer les tests**

Run: `flutter test test/widget/tutorial_class_step_test.dart test/tutorial/`
Expected: PASS

- [ ] **Step 8: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add lib/tutorial/ test/widget/tutorial_class_step_test.dart
git commit -m "feat(tutorial): ajouter l'etape de choix de classe"
```

---

## Task 6: Étape 03 — Draft du deck de départ

**Files:**
- Create: `lib/tutorial/widgets/tutorial_starter_deck_widget.dart`
- Create: `test/widget/tutorial_starter_draft_test.dart`
- Modify: `lib/tutorial/tutorial_data.dart` (entrée en position 3)
- Modify: `lib/tutorial/tutorial_screen.dart`

**Interfaces:**
- Consumes: `TutorialEngine.fixtures.starterPool`, `TutorialEngine.setStarterDeck()`, `UiCard.fromData`
- Produces: `TutorialStarterDeckWidget({required TutorialEngine engine})`

- [ ] **Step 1: Écrire le test qui échoue**

Créer `test/widget/tutorial_starter_draft_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/widgets/tutorial_starter_deck_widget.dart';

import '../tutorial/tutorial_test_registry.dart';

Future<TutorialEngine> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final engine = TutorialEngine(data: buildTutorialTestRegistry());
  engine.chooseHero(engine.fixtures.heroes.first); // paladin

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: const Locale('fr', ''),
      home: Scaffold(body: TutorialStarterDeckWidget(engine: engine)),
    ),
  );
  await tester.pumpAndSettle();
  return engine;
}

void main() {
  testWidgets('le compteur démarre à 0/5', (tester) async {
    await _pump(tester);
    expect(find.text('0 / 5'), findsOneWidget);
  });

  testWidgets('sélectionner 5 cartes remplit le deck avec les cartes de classe', (tester) async {
    final engine = await _pump(tester);
    final pool = engine.fixtures.starterPool;

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(ValueKey('tutorial-pool-${pool[i].id}')));
      await tester.pump();
    }

    expect(find.text('5 / 5'), findsOneWidget);
    // 5 choisies + 2 cartes de classe du Paladin.
    expect(engine.mockState.masterDeck, hasLength(7));
    expect(
      engine.mockState.masterDeck.map((c) => c.data.id),
      containsAll(<String>['holy_shield', 'smite']),
    );
  });

  testWidgets('la sélection est bornée à 5', (tester) async {
    final engine = await _pump(tester);
    final pool = engine.fixtures.starterPool;

    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(ValueKey('tutorial-pool-${pool[i].id}')));
      await tester.pump();
    }

    expect(find.text('5 / 5'), findsOneWidget);
    expect(engine.mockState.masterDeck, hasLength(7));
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

Run: `flutter test test/widget/tutorial_starter_draft_test.dart`
Expected: FAIL — `tutorial_starter_deck_widget.dart` n'existe pas.

- [ ] **Step 3: Ajouter l'étape aux données**

Dans `lib/tutorial/tutorial_data.dart`, insérer en troisième position :

```dart
  TutorialStep(
    titleEn: 'Your Starting Deck',
    titleFr: 'Votre deck de départ',
    bodyEn:
        'Pick 5 cards from the common pool. Your class cards are added on top, '
        'automatically — they are unique, and unlike the others they can never '
        'be merged. This deck is the one you will play with for the rest of '
        'the tutorial.',
    bodyFr:
        'Choisissez 5 cartes dans le pool commun. Les cartes de votre classe '
        's\'y ajoutent automatiquement : elles sont uniques et, contrairement '
        'aux autres, ne pourront jamais être fusionnées. C\'est avec ce deck '
        'que vous jouerez le reste du tutoriel.',
    type: TutorialStepType.starterDeck,
  ),
```

- [ ] **Step 4: Écrire le widget**

Créer `lib/tutorial/widgets/tutorial_starter_deck_widget.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';

import '../../models/data/card_data.dart';
import '../../ui/widgets/ui_card.dart';
import '../tutorial_engine.dart';

/// Étape 03 — draft du deck de départ.
///
/// Le pool est celui de `StarterDeckDraftScreen` : cartes globales non-statut.
/// Les cartes s'affichent avec le vrai [UiCard], donc le vrai médaillon de
/// mana et les vrais badges d'effets.
class TutorialStarterDeckWidget extends StatefulWidget {
  final TutorialEngine engine;

  const TutorialStarterDeckWidget({super.key, required this.engine});

  @override
  State<TutorialStarterDeckWidget> createState() =>
      _TutorialStarterDeckWidgetState();
}

class _TutorialStarterDeckWidgetState extends State<TutorialStarterDeckWidget> {
  static const int _target = 5;
  final List<CardData> _selected = [];

  void _toggle(CardData card) {
    setState(() {
      if (_selected.remove(card)) return;
      if (_selected.length < _target) _selected.add(card);
    });
    widget.engine.setStarterDeck(_selected.length == _target ? _selected : []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isFrench = locale == 'fr';
    final pool = widget.engine.fixtures.starterPool;
    final classCards = widget.engine.mockState.chosenHero?.skills
            .map(widget.engine.fixtures.card)
            .toList() ??
        const <CardData>[];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFrench ? 'Choisissez 5 cartes' : 'Pick 5 cards',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${_selected.length} / $_target',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: pool.map((card) {
                  return SizedBox(
                    key: ValueKey('tutorial-pool-${card.id}'),
                    width: 84,
                    child: UiCard.fromData(
                      card: card,
                      locale: locale,
                      l10n: l10n,
                      isSelected: _selected.contains(card),
                      onTap: () => _toggle(card),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Text(
              isFrench
                  ? 'Ajoutées d\'office : ${classCards.map((c) => c.getName(locale)).join(", ")}'
                  : 'Added automatically: ${classCards.map((c) => c.getName(locale)).join(", ")}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade300, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Brancher l'étape dans l'écran**

Dans `tutorial_screen.dart`, ajouter au `switch` de `_buildIllustration` :

```dart
      case TutorialStepType.starterDeck:
        return TutorialStarterDeckWidget(engine: _engine);
```

et à `_isStepActionComplete` :

```dart
      case TutorialStepType.starterDeck:
        return engine.mockState.masterDeck.isNotEmpty;
```

- [ ] **Step 6: Lancer les tests**

Run: `flutter test test/widget/ test/tutorial/`
Expected: PASS

- [ ] **Step 7: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/tutorial/ test/widget/tutorial_starter_draft_test.dart
git commit -m "feat(tutorial): ajouter l'etape de draft du deck de depart"
```

---

## Task 7: Étape 08 — Jouer des cartes & finir le tour

Absorbe les écarts 04·3, 06·1, 06·2 et 06·4. C'est la tâche de contenu la plus lourde.

**Files:**
- Modify: `lib/tutorial/widgets/tutorial_play_card_widget.dart`
- Modify: `lib/tutorial/tutorial_data.dart` (entrée `playCard`)
- Modify: `lib/tutorial/tutorial_screen.dart` (`_isStepActionComplete` pour `playCard`)
- Modify: `test/tutorial/tutorial_engine_test.dart`

**Interfaces:**
- Consumes: `TutorialEngine.playCard()`, `seedHand()`, `seedEnemy()`
- Produces: `TutorialEngine.endTurn()` → `bool` (retourne `false` au premier appel s'il reste du mana, `true` au second), `TutorialEngine.manaWarningPending` (getter `bool`)

- [ ] **Step 1: Écrire les tests qui échouent**

Ajouter à `test/tutorial/tutorial_engine_test.dart` :

```dart
  group('Fin de tour', () {
    test('finir le tour avec du mana exige une seconde confirmation', () {
      engine.seedEnemy();
      engine.seedHand([TutorialFixtureIds.strike]);
      engine.setMana(3);

      expect(engine.endTurn(), isFalse);
      expect(engine.manaWarningPending, isTrue);

      expect(engine.endTurn(), isTrue);
    });

    test('sans mana restant, le tour se termine du premier coup', () {
      engine.seedEnemy();
      engine.setMana(0);

      expect(engine.endTurn(), isTrue);
      expect(engine.manaWarningPending, isFalse);
    });

    test('jouer une carte annule la confirmation en attente', () {
      engine.seedEnemy();
      engine.seedHand([TutorialFixtureIds.strike]);
      engine.setMana(3);
      engine.endTurn();
      expect(engine.manaWarningPending, isTrue);

      engine.playCard(engine.mockState.hand.first);

      expect(engine.manaWarningPending, isFalse);
    });

    test('le nouveau tour remet l\'armure à zéro et le mana au max', () {
      engine.seedEnemy();
      engine.setHeroArmor(7);
      engine.setMana(0);

      engine.endTurn();

      expect(engine.mockState.heroStats.armure, 0);
      expect(
        engine.mockState.heroStats.currentMana,
        engine.mockState.heroStats.maxMana,
      );
    });
  });
```

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/tutorial/tutorial_engine_test.dart`
Expected: FAIL — `endTurn` et `manaWarningPending` n'existent pas.

- [ ] **Step 3: Implémenter la fin de tour dans le moteur**

Ajouter à `TutorialEngine` :

```dart
  bool _manaWarningPending = false;

  bool get manaWarningPending => _manaWarningPending;

  /// Reproduit la double confirmation du jeu : terminer le tour avec du mana
  /// restant demande deux clics. Le second tour ouvre avec l'armure remise à
  /// zéro et le mana au maximum, comme `RunController.startTurn()`.
  bool endTurn() {
    if (mockState.heroStats.currentMana > 0 && !_manaWarningPending) {
      _manaWarningPending = true;
      notifyListeners();
      return false;
    }

    _manaWarningPending = false;
    mockState.heroStats = mockState.heroStats.copyWith(
      armure: 0,
      currentMana: mockState.heroStats.maxMana,
    );
    notifyListeners();
    return true;
  }
```

et, en tête de `playCard`, après la vérification du mana :

```dart
    _manaWarningPending = false;
```

- [ ] **Step 4: Corriger le texte de l'étape**

Dans `lib/tutorial/tutorial_data.dart`, remplacer l'entrée `playCard` :

```dart
  TutorialStep(
    titleEn: 'Playing Cards & Ending the Turn',
    titleFr: 'Jouer des cartes & finir le tour',
    bodyEn:
        'A turn draws 5 cards. To play one, **drag it onto its target**: an '
        'enemy for attacks, your Hero card in the centre for cards that '
        'affect you. Dragging a card to the bottom of the screen cancels it.\n\n'
        'You can also tap a card to raise it, then tap its target.\n\n'
        'When you end your turn, any leftover Mana triggers a warning — a '
        'second click confirms. Your hand is discarded, the enemy acts, and '
        'your next turn opens with your Armor back to 0 and your Mana refilled.',
    bodyFr:
        'Un tour pioche 5 cartes. Pour en jouer une, **glissez-la sur sa '
        'cible** : un ennemi pour les attaques, votre carte Héros au centre '
        'pour les cartes qui vous visent. Relâcher la carte en bas de l\'écran '
        'l\'annule.\n\n'
        'Vous pouvez aussi appuyer sur une carte pour la relever, puis appuyer '
        'sur sa cible.\n\n'
        'Quand vous finissez votre tour, le mana restant déclenche un '
        'avertissement — un second clic confirme. Votre main est défaussée, '
        'l\'ennemi agit, puis votre tour suivant s\'ouvre avec votre Armure '
        'remise à 0 et votre Mana refait.',
    type: TutorialStepType.playCard,
  ),
```

- [ ] **Step 5: Retoucher le widget**

Dans `lib/tutorial/widgets/tutorial_play_card_widget.dart` :

1. Remplacer la cible « barre PV/Mana » par une **carte Héros** explicitement libellée, placée au centre du plateau sous l'ennemi — le `GestureDetector` de la zone `flex: 2` devient une carte visuelle titrée « Héros » / « Hero », et le message d'erreur devient : `'Glissez ou touchez la carte Héros au centre !'` / `'Drag or tap the Hero card in the centre!'`.
2. Envelopper chaque carte de la main dans un `Draggable<CardInstance>`, et faire de l'ennemi et de la carte Héros des `DragTarget<CardInstance>`. Le tap-puis-tap existant est conservé tel quel comme alternative.

```dart
  Widget _draggableCard(CardInstance card, String locale, AppLocalizations l10n) {
    final view = SizedBox(
      width: 84,
      child: UiCard.fromInstance(card: card, locale: locale, l10n: l10n),
    );

    return Draggable<CardInstance>(
      data: card,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.1, child: view),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: view),
      child: view,
    );
  }

  Widget _dropTarget({
    required Widget child,
    required bool Function(CardInstance) accepts,
  }) {
    return DragTarget<CardInstance>(
      onWillAcceptWithDetails: (details) => accepts(details.data),
      onAcceptWithDetails: (details) {
        if (widget.engine.playCard(details.data)) setState(() {});
      },
      builder: (context, candidate, rejected) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: candidate.isNotEmpty
                ? Colors.amber
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: child,
      ),
    );
  }
```

L'ennemi accepte les cartes dont `card.data.target == CardTarget.singleEnemy`, la carte Héros celles dont `target == CardTarget.self`.
3. Ajouter une bande basse de 60 px libellée « Relâcher ici pour annuler » / « Drop here to cancel », `DragTarget` qui ne fait rien sinon reposer la carte.
4. Ajouter un bouton « Fin de Tour » / « End Turn » appelant `widget.engine.endTurn()` ; quand `engine.manaWarningPending` est vrai, afficher au-dessus l'avertissement `'Mana restant. Terminer le tour ?'` / `'Mana remaining. End the turn?'`.
5. Ajouter un bandeau discret en haut : `'Pioche : 5 cartes par tour · Main max : 10'` / `'Draw: 5 cards per turn · Max hand: 10'`.

- [ ] **Step 6: Élargir la condition de complétion**

Dans `tutorial_screen.dart`, remplacer la branche `playCard` de `_isStepActionComplete` :

```dart
      case TutorialStepType.playCard:
        final enemy = engine.mockState.enemy;
        return enemy != null &&
            enemy.stats.currentPv < enemy.stats.maxPv &&
            engine.mockState.heroStats.armure > 0;
```

> Le seuil `hp < 20` codé en dur disparaît : on compare aux PV max réels de l'ennemi.

- [ ] **Step 7: Lancer les tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 8: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add lib/tutorial/ test/tutorial/
git commit -m "feat(tutorial): enseigner le glisser-deposer et le cycle de tour complet"
```

---

## Task 8: Étape 07 — Cartes & Mana sur le vrai `UiCard`

**Files:**
- Modify: `lib/tutorial/widgets/tutorial_cards_widget.dart` (suppression de `TutorialUiCard`)
- Modify: `lib/tutorial/widgets/tutorial_merge_widget.dart` (dépendait de `TutorialUiCard`)
- Modify: `lib/tutorial/tutorial_data.dart` (entrée `cards`)

**Interfaces:**
- Consumes: `UiCard.fromInstance`, `TutorialEngine.mockState.hand`
- Produces: aucun nouveau symbole — `TutorialUiCard` est **supprimé**

- [ ] **Step 1: Supprimer `TutorialUiCard` et brancher `UiCard`**

Dans `tutorial_cards_widget.dart`, supprimer intégralement la classe `TutorialUiCard` (lignes 4-298) et remplacer son usage par :

```dart
                          child: UiCard.fromInstance(
                            card: card,
                            locale: locale,
                            l10n: l10n,
                            isSelected: isSelected,
                            onTap: () => setState(() => _selectedCardIndex = index),
                          ),
```

Ajouter les imports `package:roguelike_card_game/l10n/app_localizations.dart` et `../../ui/widgets/ui_card.dart`, et retirer le bloc `cardDesc` codé en dur (les descriptions viennent désormais du JSON).

- [ ] **Step 2: Corriger le texte de l'étape**

Dans `tutorial_data.dart`, remplacer l'entrée `cards` :

```dart
  TutorialStep(
    titleEn: 'Cards & Mana',
    titleFr: 'Les Cartes & le Mana',
    bodyEn:
        'Playing a card costs Mana. The cost sits in the **round cyan medallion '
        'at the top-left corner** of the card.\n\n'
        '• **Card body**: icons and numbers, not sentences — a sword for damage, '
        'a shield for Armor, and so on.\n'
        '• **Full description**: **tap** the card. It rises, its description '
        'panel opens, and every valid target lights up. Hovering only enlarges it.\n'
        '• **Three types**: Attack, Skill and Power. A Power is exiled once '
        'played — it will not come back this combat.\n\n'
        'The damage printed on a card is not the final number: your Hero\'s '
        'Attack stat is added on top, and rarity multiplies the base value.',
    bodyFr:
        'Jouer une carte coûte du Mana. Le coût est inscrit dans le **médaillon '
        'rond cyan en haut à gauche** de la carte.\n\n'
        '• **Corps de la carte** : des icônes et des chiffres, pas des phrases — '
        'une épée pour les dégâts, un bouclier pour l\'Armure, etc.\n'
        '• **Description complète** : **appuyez** sur la carte. Elle se relève, '
        'son panneau de description s\'ouvre et les cibles valides s\'illuminent. '
        'Le survol ne fait que l\'agrandir.\n'
        '• **Trois types** : Attaque, Compétence et Pouvoir. Un Pouvoir joué part '
        'à l\'exil — il ne reviendra pas de ce combat.\n\n'
        'Les dégâts imprimés sur une carte ne sont pas le chiffre final : '
        'l\'Attaque de votre héros s\'y ajoute, et la rareté multiplie la valeur '
        'de base.',
    type: TutorialStepType.cards,
  ),
```

- [ ] **Step 3: Réparer `tutorial_merge_widget.dart`**

Le widget de fusion importait `TutorialUiCard` depuis `tutorial_cards_widget.dart`. Remplacer ses trois `TutorialUiCard` par `UiCard.fromInstance` alimentés par `widget.engine.mockState.hand`, et sa carte résultat par la sortie de `engine.mergeCards()`. Le détail du contenu est traité en Task 12 ; ici, faire compiler et rendre.

- [ ] **Step 4: Lancer les tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 5: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/tutorial/
git commit -m "feat(tutorial): afficher les cartes avec le vrai UiCard"
```

---

## Task 9: Étape 09 — Armure, passif de classe et Maîtrise

**Files:**
- Modify: `lib/tutorial/widgets/tutorial_armor_widget.dart`
- Modify: `lib/tutorial/tutorial_data.dart` (entrée `armorDamage`)

**Interfaces:**
- Consumes: `TutorialEngine.mockState.activePassive`, `applyDamageToHero()`, `setHeroArmor()`

- [ ] **Step 1: Corriger le texte de l'étape**

```dart
  TutorialStep(
    titleEn: 'Armor & Damage',
    titleFr: 'Armure & Dégâts',
    bodyEn:
        'Armor absorbs damage before your HP. Any damage left over after the '
        'Armor is gone hits your health.\n\n'
        '**Armor always resets to 0 at the start of your turn** — every class, '
        'no exception — and again at the end of a combat. It is a one-turn '
        'expense, never a stock you build up.\n\n'
        'What your class changes is *how you earn it*: that is your passive. '
        'Armor Mastery, a permanent stat, is added to every Armor gain your '
        'passive or your relics produce.',
    bodyFr:
        'L\'Armure absorbe les dégâts avant vos PV. Ce qui dépasse une fois '
        'l\'Armure épuisée entame votre santé.\n\n'
        '**L\'Armure retombe toujours à 0 au début de votre tour** — toutes '
        'classes confondues, sans exception — et de nouveau à la fin d\'un '
        'combat. C\'est une dépense pour un tour, jamais un stock qu\'on '
        'accumule.\n\n'
        'Ce que votre classe change, c\'est la *façon d\'en gagner* : c\'est '
        'votre passif. La Maîtrise d\'Armure, statistique permanente, s\'ajoute '
        'à chaque gain d\'Armure produit par votre passif ou vos reliques.',
    type: TutorialStepType.armorDamage,
  ),
```

- [ ] **Step 2: Afficher le passif choisi dans le widget**

Dans `tutorial_armor_widget.dart`, ajouter sous les deux panneaux comparatifs un encart qui lit la tranche persistante :

```dart
            Builder(
              builder: (context) {
                final passive = widget.engine.mockState.activePassive;
                if (passive == null) return const SizedBox.shrink();
                final locale = Localizations.localeOf(context).languageCode;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale == 'fr'
                            ? 'Votre passif : ${passive.getName(locale)}'
                            : 'Your passive: ${passive.getName(locale)}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        passive.getDescription(locale),
                        style: TextStyle(color: Colors.grey.shade300, fontSize: 11.5),
                      ),
                    ],
                  ),
                );
              },
            ),
```

Remplacer par ailleurs les valeurs `-4 Armure / -6 HP` codées en dur par un appel à `widget.engine.applyDamageToHero(10)` après `setHeroArmor(4)`, et lire les PV et l'armure résultants dans `engine.mockState.heroStats` — la démonstration passe alors par la vraie formule.

- [ ] **Step 3: Lancer les tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 4: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/tutorial/
git commit -m "fix(tutorial): corriger la regle d'armure et montrer le passif choisi"
```

---

## Task 10: Étape 10 — Effets élémentaires

**Files:**
- Modify: `lib/tutorial/widgets/tutorial_elements_widget.dart`
- Modify: `lib/tutorial/tutorial_data.dart` (entrée `elements`)

- [ ] **Step 1: Corriger le texte de l'étape**

```dart
  TutorialStep(
    titleEn: 'Elemental Effects',
    titleFr: 'Les Effets Élémentaires',
    bodyEn:
        'Some cards apply status effects to enemies:\n'
        '• 🧪 Poison: damage equal to its value at the start of their turn. '
        'The value never drops — only the duration ticks down.\n'
        '• 🔥 Burn: damage at the start of their turn, then the value drops by 1. '
        'It vanishes when it reaches 0.\n'
        '• ❄️ Freeze: halves their next attack. The duration only ticks down '
        'once they have attacked.\n'
        '• ⚡ Shock: adds its value to **every** hit they take while it lasts.',
    bodyFr:
        'Certaines cartes appliquent des altérations aux ennemis :\n'
        '• 🧪 Poison : inflige sa valeur en dégâts au début de leur tour. '
        'La valeur ne baisse jamais — seule la durée décrémente.\n'
        '• 🔥 Brûlure : inflige des dégâts au début de leur tour, puis la valeur '
        'perd 1. Elle disparaît en atteignant 0.\n'
        '• ❄️ Gel : divise par deux leur prochaine attaque. La durée ne '
        'décrémente qu\'une fois qu\'ils ont attaqué.\n'
        '• ⚡ Électrocution : ajoute sa valeur à **chaque** coup qu\'ils '
        'subissent tant qu\'elle dure.',
    type: TutorialStepType.elements,
  ),
```

- [ ] **Step 2: Corriger les simulations du widget**

Dans `tutorial_elements_widget.dart` :

- `descFr` du Poison → `'Inflige sa valeur au début du tour. La valeur ne baisse pas ; la durée décrémente.'` · `descEn` → `'Deals its value at the start of the turn. The value holds; the duration ticks down.'`
- `descFr` de la Brûlure → `'Inflige sa valeur au début du tour ennemi, puis perd 1.'` · `descEn` → `'Deals its value at the start of the enemy turn, then loses 1.'`
- Dans le `Timer.periodic`, remplacer la simulation du Poison par une valeur **constante** avec une durée qui décroît (`3 → 3 → 3`, durée `2 → 1 → expiré`), et celle de la Brûlure par `6 → 5 → 4 …` au lieu de la division par deux.
- Le libellé de l'Électrocution est déjà correct : ne pas y toucher.

- [ ] **Step 3: Ajouter le tableau des cinq statuts manquants**

Ajouter sous la galerie un second bloc défilable :

| Statut | FR | EN |
|:---|:---|:---|
| Vulnérable | `+50 % de dégâts subis` | `+50% damage taken` |
| Faiblesse | `-25 % de dégâts infligés` | `-25% damage dealt` |
| Force | `S'ajoute aux dégâts de chaque attaque` | `Adds to every attack's damage` |
| Éveil d'Attaque | `Donne de la Force au début du tour` | `Grants Strength at the start of the turn` |
| Métallisation | `Donne de l'Armure au début du tour` | `Grants Armor at the start of the turn` |

Précédé de la ligne d'introduction : `'Cinq autres altérations circulent en combat :'` / `'Five more status effects circulate in combat:'`

- [ ] **Step 4: Montrer les statuts dans le vrai panneau du HUD**

La spec (§4.5) prévoit de réutiliser `StatusEffectsPanel` à cette étape, pour que le joueur reconnaisse en combat ce que le tutoriel lui a montré. Ajouter en pied d'étape un aperçu alimenté par de vrais `StatusEffect`, construits avec les mêmes ids que `EffectResolver.createStatus` :

```dart
              StatusEffectsPanel(
                statuses: const [
                  StatusEffect(
                    id: 'poison',
                    name: 'Poison',
                    type: StatusType.debuff,
                    value: 3,
                    duration: 2,
                  ),
                  StatusEffect(
                    id: 'burn',
                    name: 'Brûlure',
                    type: StatusType.debuff,
                    value: 2,
                    duration: 2,
                  ),
                ],
              ),
```

Imports : `../../models/status_effect.dart` et `../../ui/widgets/hud/status_effects_panel.dart`. Précéder d'une légende : `'Voilà comment ils apparaissent en combat :'` / `'This is how they show up in combat:'`

- [ ] **Step 5: Lancer les tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/tutorial/
git commit -m "fix(tutorial): corriger les regles de Poison, Brulure et Electrocution"
```

---

## Task 11: Étape 11 — Intentions ennemies sur le vrai panneau

**Files:**
- Modify: `lib/tutorial/widgets/tutorial_enemy_intents_widget.dart`
- Modify: `lib/tutorial/tutorial_data.dart` (entrée `enemies`)

**Interfaces:**
- Consumes: `EnemyIntentsPanel`, `EnemyInstance`, `EnemyIntent`

- [ ] **Step 1: Corriger le texte de l'étape**

```dart
  TutorialStep(
    titleEn: 'Enemy Intentions',
    titleFr: 'Les Intentions Ennemies',
    bodyEn:
        'Enemies announce what they will do before you play. Their intent is '
        'not shown above them — read it in the **Enemy Intentions panel, '
        'bottom-right**.\n\n'
        'There are three: attack, defend, and buff. Attacks change icon and '
        'colour with their size — Quick, Attack, Heavy, Devastating — so a '
        'glance is enough to tell a scratch from a threat.\n\n'
        'The number is recalculated live: it grows with the enemy\'s level and '
        'accumulated Strength, and halves while they are Frozen.',
    bodyFr:
        'Les ennemis annoncent leur action avant que vous ne jouiez. Leur '
        'intention n\'est pas affichée au-dessus d\'eux : elle se lit dans le '
        'panneau **Intentions Ennemies, en bas à droite**.\n\n'
        'Il en existe trois : attaque, défense et renforcement. Les attaques '
        'changent d\'icône et de couleur selon leur ampleur — Rapide, Attaque, '
        'Lourde, Dévastatrice — pour distinguer d\'un coup d\'œil l\'égratignure '
        'de la menace.\n\n'
        'Le chiffre est recalculé en direct : il monte avec le niveau de '
        'l\'ennemi et sa Force accumulée, et se divise par deux tant qu\'il est '
        'Gelé.',
    type: TutorialStepType.enemies,
  ),
```

- [ ] **Step 2: Remplacer les 4 vignettes maison par le vrai panneau**

Dans `tutorial_enemy_intents_widget.dart`, supprimer la classe `TutorialIntentInfo` et la liste `_intents` (dont la vignette « Affaiblissement / Malédiction », qui décrit une mécanique inexistante). Les remplacer par quatre `EnemyInstance` construits sur `engine.fixtures.trainingEnemy` avec des intentions de valeurs 4, 8, 15 et 22, rendus par `EnemyIntentsPanel` — ce qui produit les quatre paliers réels avec leurs vraies icônes et couleurs :

```dart
    final data = widget.engine.fixtures.trainingEnemy;

    EnemyInstance sample(int value, IntentType type) => EnemyInstance(
          data: data,
          stats: EntityStats(
            maxPv: data.maxHp,
            currentPv: data.maxHp,
            armure: 0,
            attaque: data.baseDamage,
          ),
          currentIntent: EnemyIntent(type: type, value: value),
        );
```

> **Attention.** `EnemyInstance.effectiveIntent` remet la valeur à l'échelle via `stats.attaque / data.baseDamage`. En passant `attaque: data.baseDamage`, le multiplicateur vaut 1 et les valeurs affichées sont bien 4, 8, 15 et 22.

Ajouter sous le panneau une ligne de légende par palier, en français et en anglais, reprenant les seuils : `< 6`, `6–11`, `12–19`, `≥ 20`.

- [ ] **Step 3: Lancer les tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 4: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/tutorial/
git commit -m "fix(tutorial): brancher le vrai panneau d'intentions et retirer l'intention inventee"
```

---

## Task 12: Étape 12 — Fusion

**Files:**
- Modify: `lib/tutorial/widgets/tutorial_merge_widget.dart`
- Modify: `lib/tutorial/tutorial_data.dart` (entrée `merge`)
- Modify: `lib/tutorial/tutorial_screen.dart` (`_isStepActionComplete` pour `merge`)

- [ ] **Step 1: Corriger le texte de l'étape**

```dart
  TutorialStep(
    titleEn: 'Card Merging',
    titleFr: 'La Fusion de Cartes',
    bodyEn:
        'Merging is **manual**, and only outside combat. Open your Deck: when '
        'you hold three copies of the same card **at the same rarity**, the '
        'group offers a merge. Select exactly three, confirm, and they become '
        'one card of the next rarity up.\n\n'
        'Rarity **never changes a card\'s Mana cost** — it multiplies its '
        'values: ×1.2 uncommon, ×1.4 rare, ×1.6 epic, ×2.0 legendary.\n\n'
        'Forge upgrades carried by the three copies are inherited and merged, '
        'capped by the new rarity\'s capacity. Your class cards are unique, and '
        'unique cards never merge.',
    bodyFr:
        'La fusion est **manuelle**, et seulement hors combat. Ouvrez votre '
        'Deck : lorsque vous détenez trois exemplaires d\'une même carte **de '
        'même rareté**, le groupe propose une fusion. Sélectionnez-en exactement '
        'trois, confirmez, et elles deviennent une carte de la rareté '
        'supérieure.\n\n'
        'La rareté **ne change jamais le coût en Mana** — elle multiplie les '
        'valeurs : ×1,2 peu commun, ×1,4 rare, ×1,6 épique, ×2,0 légendaire.\n\n'
        'Les améliorations de forge des trois exemplaires sont héritées et '
        'consolidées, dans la limite de la capacité de la nouvelle rareté. Vos '
        'cartes de classe sont uniques, et une carte unique ne fusionne jamais.',
    type: TutorialStepType.merge,
  ),
```

- [ ] **Step 2: Rendre la démo conforme**

Dans `tutorial_merge_widget.dart` :

- Les trois cartes sont `widget.engine.mockState.hand` (peuplée par `prepareStep`), rendues par `UiCard.fromInstance`. Leur libellé de rareté vient du modèle, plus de `'Lvl 1'`.
- Le bouton devient `'Sélectionner les 3 et fusionner'` / `'Select all 3 and merge'`, pour rappeler que le geste est délibéré.
- La carte résultat est `engine.mockState.hand.first` après `mergeCards()` : rareté supérieure, **même coût**, valeurs multipliées par le modèle.
- Ajouter sous le résultat : `'Même coût. Valeurs ×1,2.'` / `'Same cost. Values ×1.2.'`

- [ ] **Step 3: Mettre à jour la condition de complétion**

Dans `tutorial_screen.dart` :

```dart
      case TutorialStepType.merge:
        return engine.mockState.hand.length == 1 &&
            engine.mockState.hand.first.rarity != CardRarity.common;
```

Ajouter l'import de `card_data.dart` pour `CardRarity`.

- [ ] **Step 4: Lancer les tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 5: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/tutorial/
git commit -m "fix(tutorial): corriger les regles de fusion (manuelle, rarete, cout inchange)"
```

---

## Task 13: Étape 13 — XP & passage de niveau

**Files:**
- Modify: `lib/tutorial/tutorial_engine.dart` (`gainXp:276`)
- Modify: `lib/tutorial/widgets/tutorial_xp_widget.dart`
- Modify: `lib/tutorial/tutorial_data.dart` (entrée `xp`)
- Modify: `test/tutorial/tutorial_engine_test.dart`

**Interfaces:**
- Produces: `TutorialEngine.pendingDrafts` (getter `int`)

- [ ] **Step 1: Écrire le test qui échoue**

```dart
  group('Progression d\'XP', () {
    test('le palier suit 100 x 1,5^(niveau-1)', () {
      expect(engine.mockState.xpToNextLevel, 100);

      engine.gainXp(100);

      expect(engine.mockState.playerLevel, 2);
      expect(engine.mockState.xpToNextLevel, 150);
    });

    test('l\'XP excédentaire est reportée et les drafts s\'empilent', () {
      engine.gainXp(260); // 100 -> niv.2, 150 -> niv.3, reste 10

      expect(engine.mockState.playerLevel, 3);
      expect(engine.mockState.playerXp, 10);
      expect(engine.pendingDrafts, 2);
    });
  });
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

Run: `flutter test test/tutorial/tutorial_engine_test.dart`
Expected: FAIL — le palier reste à 100 et `pendingDrafts` n'existe pas.

- [ ] **Step 3: Aligner `gainXp` sur `PlayerStatsManager`**

```dart
  int _pendingDrafts = 0;

  int get pendingDrafts => _pendingDrafts;

  /// Même formule que `PlayerStatsManager.gainXp` : report de l'excédent et
  /// palier géométrique `100 × 1,5^(niveau-1)`.
  void gainXp(int amount) {
    if (amount <= 0) return;

    var xp = mockState.playerXp + amount;
    var level = mockState.playerLevel;
    var threshold = mockState.xpToNextLevel;

    while (xp >= threshold) {
      xp -= threshold;
      level++;
      threshold = (100 * pow(1.5, level - 1)).round();
      _pendingDrafts++;
    }

    mockState.playerXp = xp;
    mockState.playerLevel = level;
    mockState.xpToNextLevel = threshold;
    notifyListeners();
  }
```

Ajouter `import 'dart:math';` en tête du fichier.

- [ ] **Step 4: Corriger le texte de l'étape**

```dart
  TutorialStep(
    titleEn: 'Experience & Leveling Up',
    titleFr: 'L\'Expérience & le Level Up',
    bodyEn:
        'Defeating enemies grants XP. Each level costs more than the last: '
        '100, then 150, then 225, and so on.\n\n'
        'Overflow XP carries into the next level, and if you gain several '
        'levels at once the rewards stack — **the world map stays locked until '
        'you have drafted them all**.\n\n'
        'A level-up refills your Mana and clears your skill cooldowns. Note '
        'that your hero\'s XP level and the "Level" shown next to the Act are '
        'two different counters: the second tracks your progress across the map.',
    bodyFr:
        'Vaincre des ennemis rapporte de l\'XP. Chaque niveau coûte plus cher '
        'que le précédent : 100, puis 150, puis 225, et ainsi de suite.\n\n'
        'L\'XP excédentaire est reportée sur le niveau suivant, et si vous '
        'gagnez plusieurs niveaux d\'un coup les récompenses s\'empilent — **la '
        'carte du monde reste verrouillée tant que vous ne les avez pas toutes '
        'draftées**.\n\n'
        'Un passage de niveau restaure votre Mana et réinitialise vos temps de '
        'recharge. Attention : le niveau d\'XP de votre héros et le « Niveau » '
        'affiché à côté de l\'Acte sont deux compteurs distincts, le second '
        'suivant votre progression sur la carte.',
    type: TutorialStepType.xp,
  ),
```

- [ ] **Step 5: Afficher le compteur de drafts en attente**

Dans `tutorial_xp_widget.dart`, sous la barre d'XP, ajouter quand `engine.pendingDrafts > 0` : `'Drafts en attente : N'` / `'Pending drafts: N'`, et remplacer le libellé du bouton par `'Battre un Gobelin (+35 XP)'` / `'Defeat a Goblin (+35 XP)'` — 35 est bien l'XP du Gobelin dans `enemies.json`, mais lire la valeur depuis `engine.fixtures.registry.enemies` plutôt que la coder.

- [ ] **Step 6: Lancer les tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 7: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/tutorial/ test/tutorial/
git commit -m "fix(tutorial): aligner la courbe d'XP et empiler les drafts en attente"
```

---

## Task 14: Étape 14 — Draft de récompenses sur le vrai service

**Files:**
- Modify: `lib/tutorial/widgets/tutorial_draft_widget.dart`
- Modify: `lib/tutorial/tutorial_data.dart` (entrée `draft`)

**Interfaces:**
- Consumes: `LevelUpRewardService.generateChoices()`, `DraftChoice`, `RewardRarity`, `DraftChoiceCard`

- [ ] **Step 1: Corriger le texte de l'étape**

```dart
  TutorialStep(
    titleEn: 'Reward Draft',
    titleFr: 'Le Draft de Récompenses',
    bodyEn:
        'Each level grants a draft. Three options are rolled from six kinds — '
        'Vitality, Sharpening, Steel Forge, Wisdom, Precision, Ferocity — and '
        'up to two **Mythic** options can appear on top: the Four-Leaf Clover '
        'and the Mirror.\n\n'
        'Rarity decides how much you get. Luck raises your odds on every roll, '
        'which makes the Clover the option that improves all the others.\n\n'
        'Careful with Steel Forge: it grants **Armor Mastery**, added to the '
        'Armor your passive and relics produce — not a flat block of Armor.',
    bodyFr:
        'Chaque niveau donne droit à un draft. Trois options sont tirées parmi '
        'six types — Vitalité, Aiguisage, Forge d\'Acier, Sagesse, Précision, '
        'Férocité — et jusqu\'à deux options **Mythiques** peuvent s\'y ajouter : '
        'le Trèfle à 4 feuilles et le Miroir.\n\n'
        'La rareté décide de l\'ampleur du gain. La Chance améliore vos '
        'probabilités à chaque tirage, ce qui fait du Trèfle l\'option qui '
        'améliore toutes les autres.\n\n'
        'Attention à la Forge d\'Acier : elle donne de la **Maîtrise d\'Armure**, '
        'ajoutée à l\'Armure que produisent votre passif et vos reliques — pas '
        'un bloc d\'Armure directe.',
    type: TutorialStepType.draft,
  ),
```

- [ ] **Step 2: Alimenter le widget par le vrai service**

Dans `tutorial_draft_widget.dart`, supprimer la liste `_choices` codée en dur (lignes 19-42) et la remplacer, dans `initState`, par :

```dart
    _choices = LevelUpRewardService.generateChoices(luck: 0);
```

Le titre, la description et le libellé de rareté de chaque `DraftChoice` se dérivent ensuite exactement comme dans `DraftScreen._getChoiceTitle` / `_getChoiceDescription` / `_rarityToString` — reprendre ces trois `switch` tels quels plutôt que de les réinventer.

> **Pourquoi `luck: 0`.** Le tutoriel n'a pas de stat de Chance : 0 est la valeur d'un héros au niveau 1, donc les probabilités montrées sont celles d'un vrai premier draft.

- [ ] **Step 3: Lancer les tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 4: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/tutorial/
git commit -m "feat(tutorial): tirer les recompenses de draft via LevelUpRewardService"
```

---

## Task 15: Étape 15 — Reliques

**Files:**
- Modify: `lib/tutorial/widgets/tutorial_relics_widget.dart`
- Modify: `lib/tutorial/tutorial_data.dart` (entrée `relics`)

- [ ] **Step 1: Corriger le texte de l'étape**

```dart
  TutorialStep(
    titleEn: 'Relics',
    titleFr: 'Les Reliques',
    bodyEn:
        'Relics grant passive bonuses for the rest of your run. You get them '
        'from **Elite** fights, from the **improved-relic Boss** — only that '
        'one of the three — and from the **Relic Shrine**, which trades several '
        'sacrificed relics for a better one. The Shop sells none.\n\n'
        'Each relic fires on a specific trigger: start of run, start of combat, '
        'start or end of turn, when you play a card, when you play an attack, '
        'or when an enemy dies. Reading the trigger matters as much as reading '
        'the effect.',
    bodyFr:
        'Les Reliques accordent des bonus passifs pour le reste de votre run. '
        'Vous les obtenez en combat **Élite**, auprès du **Boss à relique '
        'améliorée** — celui-là seulement sur les trois — et à l\'**Autel des '
        'Reliques**, qui échange plusieurs reliques sacrifiées contre une '
        'meilleure. La Boutique n\'en vend aucune.\n\n'
        'Chaque relique se déclenche sur un moment précis : début de run, début '
        'de combat, début ou fin de tour, quand vous jouez une carte, quand vous '
        'jouez une attaque, ou quand un ennemi meurt. Lire le déclencheur compte '
        'autant que lire l\'effet.',
    type: TutorialStepType.relics,
  ),
```

- [ ] **Step 2: Rendre la relique et les raretés depuis le registre**

Dans `tutorial_relics_widget.dart` :

- Remplacer le nom et la description codés en dur par `engine.fixtures.sampleRelic.getName(locale)` et `.getDescription(locale)`, et l'icône par son `emoji`.
- Compléter la légende des raretés : ajouter **Peu commun** / **Uncommon** entre Commun et Rare, en vert `Color(0xFF34C759)` pour rester cohérent avec `DraftChoiceCard`.
- Ajouter une ligne de compte lue depuis le registre : `'25 reliques, 7 déclencheurs.'` doit être **calculé** (`engine.fixtures.registry.relics.length`), pas écrit.

- [ ] **Step 3: Lancer les tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 4: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/tutorial/
git commit -m "fix(tutorial): corriger les sources de reliques et la legende des raretes"
```

---

## Task 16: Étapes 04, 05 et 06 — Carte, rencontres, vue d'ensemble

**Files:**
- Modify: `lib/tutorial/tutorial_data.dart` (entrées `map`, `nodeTypes`, `combatOverview`)
- Modify: `lib/tutorial/widgets/tutorial_map_widget.dart`
- Modify: `lib/tutorial/widgets/tutorial_node_types_widget.dart`
- Modify: `lib/tutorial/widgets/tutorial_combat_overview_widget.dart`

- [ ] **Step 1: Étape 04 — Carte du Monde**

Texte :

```dart
  TutorialStep(
    titleEn: 'The World Map',
    titleFr: 'La Carte du Monde',
    bodyEn:
        'Your journey climbs a map of ten floors, two to five nodes each. You '
        'start at the bottom and choose your path upward.\n\n'
        '**Touching a node commits you to it immediately** — there is no '
        'preview and no confirmation. Read the legend before you touch.\n\n'
        'The layout is not fully random: floor 1 is always a fight, floor 6 '
        'narrows to a single Elite you cannot avoid, floor 9 is a guaranteed '
        'Rest, and the summit offers three Bosses side by side.',
    bodyFr:
        'Votre voyage gravit une carte de dix planchers, de deux à cinq nœuds '
        'chacun. Vous partez du bas et choisissez votre chemin vers le haut.\n\n'
        '**Toucher un nœud vous y engage immédiatement** — aucun aperçu, aucune '
        'confirmation. Lisez la légende avant de toucher.\n\n'
        'Le tracé n\'est pas entièrement aléatoire : le plancher 1 est toujours '
        'un combat, le plancher 6 se resserre sur une Élite unique qu\'on ne '
        'peut éviter, le plancher 9 est un Repos garanti, et le sommet propose '
        'trois Boss côte à côte.',
    type: TutorialStepType.map,
  ),
```

Widget : remplacer la bulle descriptive au toucher par un libellé d'engagement — `'Vous y allez.'` / `'You are going there.'` — et ajouter un rappel textuel de la structure en dix planchers sous la mini-carte.

- [ ] **Step 2: Étape 05 — Types de rencontres**

Texte :

```dart
  TutorialStep(
    titleEn: 'Types of Encounters',
    titleFr: 'Types de Rencontres',
    bodyEn:
        'Eight kinds of node share the map:\n'
        '• ⚔️ Combat: a standard fight, for gold and XP.\n'
        '• 👑 Elite: a hard fight that rewards a Relic.\n'
        '• 🏪 Shop: buy cards, reroll the stock, buy a potion, purge a card, '
        'expand the stock or clone a card. No relics.\n'
        '• 🏕️ Rest: heal 30% of your max HP, forge a card, **or remove one '
        'from your deck**.\n'
        '• 🎭 Event: narrative choices with real consequences.\n'
        '• 🔄 Relic Shrine: sacrifice relics for a better one.\n'
        '• 🧩 Fusion Forge: merge a card\'s duplicate upgrades, for gold.\n'
        '• 💀 Boss: three at the summit, one reward each — cards, triple XP '
        'and gold, or an improved relic. Choosing the Boss is choosing the '
        'reward.',
    bodyFr:
        'Huit types de nœuds se partagent la carte :\n'
        '• ⚔️ Combat : affrontement standard, pour l\'or et l\'XP.\n'
        '• 👑 Élite : combat difficile qui récompense par une Relique.\n'
        '• 🏪 Boutique : acheter des cartes, relancer le stock, prendre une '
        'potion, purger une carte, agrandir le stock ou cloner. Aucune relique.\n'
        '• 🏕️ Repos : soigner 30 % de vos PV max, forger une carte, **ou en '
        'retirer une de votre deck**.\n'
        '• 🎭 Événement : choix narratifs aux conséquences réelles.\n'
        '• 🔄 Autel des Reliques : sacrifier des reliques pour une meilleure.\n'
        '• 🧩 Forge de Fusion : fusionner les améliorations dupliquées d\'une '
        'carte, contre de l\'or.\n'
        '• 💀 Boss : trois au sommet, une récompense chacun — des cartes, le '
        'triple d\'XP et d\'or, ou une relique améliorée. Choisir le Boss, '
        'c\'est choisir la récompense.',
    type: TutorialStepType.nodeTypes,
  ),
```

Widget : ajouter les deux vignettes manquantes — Autel des Reliques (emoji `🔄`) et Forge de Fusion (`Icons.layers_rounded`, `Colors.deepPurpleAccent`), en reprenant les icônes et couleurs de `map_legend.dart:108-120` — et corriger la vignette « Boss (XP x2) » en « Boss (XP & Or ×3) » / « Boss (3× XP & Gold) ».

- [ ] **Step 3: Étape 06 — Vue d'ensemble du combat**

Texte : ajouter au corps existant la mention des deux boutons du haut. Widget : déplacer le bloc « Fin de Tour » + « Tour 1 » au centre vertical de la colonne droite, ajouter deux pictogrammes « Mon Deck » et « Pause » en haut à droite, et remplacer le `'80 / 80 PV'` codé en dur par `engine.mockState.heroStats.currentPv / maxPv`.

- [ ] **Step 4: Lancer les tests**

Run: `flutter test`
Expected: PASS

- [ ] **Step 5: Vérifier l'analyse statique**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/tutorial/
git commit -m "fix(tutorial): corriger la carte, les huit types de noeuds et la vue de combat"
```

---

## Task 17: Correctif de légende et documentation

**Files:**
- Modify: `lib/ui/widgets/map/map_legend.dart:128-131`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb` (clé `legendBossXp`)
- Create: `.obsidian_vault/_adr/ADR-081-*.md`
- Modify: `.obsidian_vault/_rules/08-00-systeme-de-tutoriel-autonome.md`
- Modify: `.obsidian_vault/_memory_bank/decisionLog.md`, `productContext.md`
- Modify: `docs/ROADMAP.md`
- Modify: `assets/data/patch_notes.json`, `pubspec.yaml`, `site/_site/versions.json`

- [ ] **Step 1: Corriger la légende**

Dans `lib/ui/widgets/map/map_legend.dart`, la vignette du Boss XP :

```dart
            label: Localizations.localeOf(context).languageCode == 'fr'
                ? "Boss (XP & Or x3)"
                : "Boss (3x XP & Gold)",
```

- [ ] **Step 2: Aligner la clé ARB**

Dans `lib/l10n/app_fr.arb`, `legendBossXp` → `"Boss (XP x3)"`. Dans `app_en.arb`, → `"Boss (3x XP)"`.

- [ ] **Step 3: Régénérer les localisations et vérifier**

Run: `flutter gen-l10n`
Puis: `flutter test test/unit/localization_test.dart`
Expected: PASS

- [ ] **Step 4: Lancer la suite complète**

Run: `flutter test`
Expected: PASS — toute la suite, pas seulement le tutoriel.

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 5: Commit du correctif**

```bash
git add lib/ui/widgets/map/map_legend.dart lib/l10n/
git commit -m "fix(map): aligner la legende du boss XP sur le x3 applique par le code"
```

- [ ] **Step 6: Passe documentaire**

Invoquer le skill `memory-bank-sync`. Il doit produire :

- **ADR-081** — « Amendement de la règle d'autonomie du tutoriel : zéro provider d'état ». Contexte : 50 écarts nés d'une recopie manuelle. Décision : `gameDataLoaderProvider` autorisé en un point unique, `tutorial_loader.dart` ; les neuf providers d'état restent interdits ; critère vérifiable par `tutorial_isolation_test.dart`. Conséquences : les valeurs de démonstration ne peuvent plus diverger ; le tutoriel dépend désormais du chargement des assets.
- **`_rules/08-00`** réécrite — 15 étapes au lieu de 13, contrat de données, tranche persistante et verrou 02/03. Corriger au passage les deux erreurs de la fiche actuelle : l'étape des reliques n'est pas un carrousel mais une carte statique, et l'étape de vue d'ensemble ne montre pas de Compétences.
- **`decisionLog.md`** — entrée ADR-081.
- **`productContext.md`** — pointeur vers la fiche 08-00 réécrite.
- **`docs/ROADMAP.md`** — chantier **P-45** coché comme livré.

- [ ] **Step 7: Patch note**

Invoquer le skill `patch-notes-writer`. Le note joueur porte sur ce qui se voit : le tutoriel couvre désormais le choix de classe et la composition du deck de départ, ses règles de combat sont exactes, et il montre les vraies cartes du jeu. Ne pas mentionner Riverpod, le registre ni les tests.

- [ ] **Step 8: Vérifier la cohérence de version**

Run: `bash verify_version.sh`
Expected: succès — `patch_notes.json`, `pubspec.yaml` et `site/_site/versions.json` concordent.

- [ ] **Step 9: Commit documentaire**

```bash
git add .obsidian_vault/ docs/ROADMAP.md assets/data/patch_notes.json pubspec.yaml site/_site/versions.json
git commit -m "docs(vault): consigner ADR-081 et cloturer P-45"
```

---

## Vérification finale

- [ ] `flutter test` — suite complète verte, y compris `test/tutorial/tutorial_isolation_test.dart`
- [ ] `dart analyze` — zéro problème
- [ ] `grep -rn "flutter_riverpod" lib/tutorial/` — une seule occurrence, dans `tutorial_loader.dart`
- [ ] `grep -rn "TutorialCard\|TutorialEnemy\|TutorialUiCard\|resetMockState" lib/` — aucune occurrence
- [ ] Parcourir le tutoriel en français **et** en anglais, de l'étape 01 à l'étape 15, en vérifiant qu'aucune chaîne ne manque dans l'une des deux langues
- [ ] Choisir successivement les trois classes et vérifier que l'étape 09 affiche bien trois passifs différents
