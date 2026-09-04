# Réorganisation des données — lot 3 — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Éclater les huit catalogues JSON monolithiques en 71 fichiers d'entité, dans des dossiers auto-suffisants par classe et par ennemi, chargés par un mécanisme générique piloté par des motifs de chemin.

**Architecture:** Un `GameDataLoader` lit le manifeste d'assets une fois, sélectionne les fichiers par motif de chemin (`*` = un segment), injecte l'appartenance déduite du répertoire, trie par `id`, vérifie l'unicité et agrège les erreurs de toutes les catégories avant de lever une seule fois. La migration se fait en **deux temps qui restent verts chacun** : d'abord créer l'arbre neuf à côté de l'ancien et prouver leur équivalence sur le JSON brut, ensuite basculer les lecteurs et supprimer l'ancien monde.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, Flame 1.37.0, Riverpod 2.x (`Notifier`/`NotifierProvider`), `flutter_test`, `dart:io` pour les deux scripts de `tool/`.

**Spec:** [`docs/superpowers/specs/2026-09-04-reorganisation-donnees-un-fichier-par-entite-design.md`](../specs/2026-09-04-reorganisation-donnees-un-fichier-par-entite-design.md) — lire §4 (architecture cible), §5 (le mécanisme de chargement), §6 (le contrat de données), §7 (la synchronisation du pubspec) et §8 (la migration et son filet de sécurité).

**Plan amont :** [`2026-09-04-reorganisation-donnees-lots-1-2.md`](2026-09-04-reorganisation-donnees-lots-1-2.md) — **livré**, PR [#34](https://github.com/Hex-Umbra/hero-s-draft/pull/34). Le lot 3 en dépend : les cinq ordres d'affichage sont déjà explicites, donc le tri par `id` de ce lot n'a aucune conséquence observable.

**Effort : 5,4 j** — somme des dix tâches. La spec §14 et `docs/ROADMAP.md:257` budgètent 4,5 j : l'écart de 0,9 j vient de la tâche 1 (le préfixe Flame sorti en amont, §D-P4) et du découpage de la migration en deux temps, qui ajoute une tâche de bascule. Corriger les deux documents à la tâche 10, ou assumer l'écart en le disant.

---

## Global Constraints

- **Branche de départ** : `main` après fusion de la PR #34. Tous les numéros de ligne de ce plan s'y réfèrent. Si la PR n'est pas fusionnée, partir de `feat/reorganisation-donnees-lots-1-2`.
- **Après chaque tâche** : `dart analyze` doit rendre `No issues found!` — règle de `CLAUDE.md`, pas une préférence. La CI lance `dart analyze --fatal-infos`.
- **Référence de tests** : **388 au vert** au départ. Chaque tâche indique le compte attendu après elle. **Aucun test existant ne doit disparaître** sans que la tâche le justifie explicitement.
- **Chaque tâche se termine au vert.** La migration est découpée pour que ce soit vrai même au milieu : la tâche 5 crée l'arbre neuf **sans rien supprimer**, la tâche 7 bascule et supprime.
- **Bilinguisme** : toute entrée JSON à texte visible garde ses variantes `_fr` et `_en` (`CLAUDE.md`).
- **Ids en `snake_case` ASCII minuscule** — déjà vrai depuis le lot 2, et `test/unit/entity_id_convention_test.dart` le garde. Le poste de dev est Windows (NTFS insensible à la casse), la CI est `ubuntu-latest` : une divergence de casse passerait en local et casserait en CI.
- **Ne jamais confondre `HeroData.skills` avec la chaîne `SkillData` supprimée par P-40.** `HeroData.skills` (`lib/models/data/hero_data.dart:14`) porte les ids des deux cartes de signature d'une classe et est bien vivante.
- **Ne jamais toucher `applyLifestealBuff`** (`lib/game/controllers/run/player_stats_manager.dart:475`). Sans appelant depuis P-40, réservée à P-41.
- **`patch_notes.json` ne se modifie jamais à la main** — il est géré par la skill `patch-notes-writer`. Il reste à plat, comme `audio.json`.
- **Aucun code mort, aucun import inutilisé, aucun bloc commenté** dans le code commité (`CLAUDE.md`).
- Messages de commit en français, conventional commits, **sans accents dans le sujet** (convention du dépôt).
- **Aucune modification d'équilibrage.** Les seuls changements de valeur autorisés par ce plan sont les chemins d'images (`iconPath`, `spritePath`), tâches 1 et 5.

---

## Décisions prises à l'écriture du plan

La spec laissait quatre points ouverts. Ils sont tranchés ici, et les tâches en dépendent.

**D-P1 — `GameDataRegistry` garde des `List<T>`, pas des `Map<String, T>`.**
La note de §5.1 proposait de produire des `Map` pour supprimer les recherches linéaires des quatre `getById`. **Non** : c'est le périmètre de la fiche **P-26**, et le convertir ici toucherait les **25 sites répartis dans 21 fichiers** de `test/` qui construisent `GameDataRegistry(...)` — mesuré par `grep -ro 'GameDataRegistry(' test/ | wc -l`, la spec §5.5 en annonce 18, un chiffre périmé —, pour un gain de performance qui n'a jamais été mesuré comme un problème. Le chargeur rend une `List<T>` triée par `id` ; P-26 pourra la transformer sans rien changer au chargeur.

**D-P2 — L'`id` est injecté depuis le nom de fichier, sous la même règle de conflit que le reste.**
§6.1 pose « le nom du fichier **est** l'`id` » et §10 demande un test « Nom de fichier = `id` ». Plutôt que d'ajouter un contrôle séparé — impossible à écrire génériquement, puisque le chargeur ne connaît pas le type `T` et ne peut pas lire `.id` —, l'`id` est **injecté depuis le segment capturé**, exactement comme `heroClass` et `category`. La règle D5 (« le répertoire injecte, le JSON peut confirmer, la contradiction échoue ») fait alors tout le travail : `cards/strike.json` déclarant `"id": "strke"` échoue en nommant le fichier, le champ, l'attendu et le trouvé.
Conséquence : deux classes de champ injecté, distinguées par `EntitySource.redundantFields` — voir D-P3.

**D-P3 — `id` reste déclaré dans les fichiers après le durcissement ; `heroClass` et `category` non.**
§5.2 prévoit qu'après la migration, déclarer un champ injecté devienne une erreur. Appliquer ça à l'`id` obligerait à dépouiller les 71 fichiers de leur identifiant, ce qui les rendrait illisibles hors contexte et casserait toute inspection en masse (`jq -s '.' assets/data/relics/*.json`). L'`id` est donc **redondant à titre permanent** : autorisé, mais obligatoirement identique. `heroClass` et `category` sont redondants **à titre temporaire**, le temps de la migration, et la tâche 9 les interdit.

**D-P4 — Le préfixe Flame est vidé *avant* le découpage, pas pendant.**
§6.2 range la conversion des chemins d'images dans le lot 3 sans préciser où. La faire **en premier** (tâche 1), pendant que les images sont encore dans `assets/images/`, la rend à comportement constant et testable isolément. Le découpage n'a plus alors qu'à changer la *valeur* des chemins, pas le mécanisme de chargement.

---

## File Structure

| Fichier | Responsabilité après ce plan |
|:---|:---|
| `lib/services/game_data_loader.dart` | **Créé** — `EntitySource<T>` et `GameDataLoader` : motif de chemin, injection, tri, unicité, agrégation d'erreurs. Ne connaît aucun modèle du jeu |
| `lib/services/game_data_service.dart` | **Modifié** — `_loadJsonList` et `_mapList` supprimés ; expose `loadGameDataRegistry(bundle)`, **unique déclaration des huit sources**, et le provider qui l'appelle. `loadAudioData` inchangée |
| `lib/game/heros_draft_game.dart` | **Modifié** — instance `Images(prefix: '')` propre au jeu ; chemins d'images complets |
| `assets/data/heroes.json` → `assets/data/classes/<id>/class.json` | **Déplacé** — un dossier par classe, `icon.png` compris |
| `assets/data/hero_cards.json` → `assets/data/classes/<id>/cards/<id>.json` | **Déplacé** — l'appartenance est portée par le répertoire |
| `assets/data/enemies.json` → `assets/data/enemies/<id>/enemy.json` | **Déplacé** — un dossier par ennemi, `sprite.png` compris |
| `assets/data/{cards,relics,events,forge_upgrades,passives}.json` → `<cat>/<id>.json` | **Éclatés** — un fichier par entité |
| `assets/images/` | **Réduit** à `bg_dungeon.png`, la seule image qui n'appartient à aucune entité |
| `pubspec.yaml` | **Modifié** — section `assets:` générée et triée, 4 → 19 lignes |
| `tool/sync_assets.dart` | **Créé** — régénère la section `assets:` ; `--check` sort en 1 si le pubspec diverge du disque |
| `tool/split_catalogues.dart` | **Créé puis supprimé** — script de découpage à usage unique, commité pour être auditable, supprimé en tâche 10 |
| `test/tutorial/tutorial_test_registry.dart` | **Modifié** — délègue au vrai chargeur ; devient asynchrone |
| `test/unit/entity_id_convention_test.dart` | **Modifié** — parcourt l'arborescence au lieu des huit catalogues nommés |
| `test/unit/asset_path_convention_test.dart` | **Créé** — tout `iconPath`/`spritePath` est un chemin complet vers un fichier existant |
| `test/unit/flame_image_prefix_test.dart` | **Créé** — le jeu a son propre cache d'images, préfixe vide, et ne touche pas `Flame.images` |
| `test/unit/game_data_loader_test.dart` | **Créé** — sélection, tri, fusion, unicité, agrégation, catégorie vide |
| `test/unit/game_data_loader_injection_test.dart` | **Créé** — autorité du répertoire, confirmation tolérée, contradiction fatale |
| `test/unit/sync_assets_test.dart` | **Créé** — le pubspec est synchronisé avec le disque |
| `test/unit/real_bundle_load_test.dart` | **Créé** — l'application voit bien les fichiers, par le vrai bundle |
| `test/unit/referential_integrity_test.dart` | **Créé** — aucun dossier de classe ou d'ennemi incomplet |
| `test/migration/` | **Créé puis supprimé** — l'oracle d'équivalence et sa référence figée, supprimés en tâche 10 |

---

# Tâche 1 — Vider le préfixe Flame et donner aux images des chemins complets

*Effort : 0,5 j. Objectif : que le chemin d'une image soit son chemin réel depuis la racine du projet, de sorte que le déplacement des images en tâche 5 ne soit plus qu'un changement de valeur.*

Flame stocke les images sous une clé qui **n'inclut pas le préfixe** (`flame-1.37.0/lib/src/cache/images.dart:29-32`). Une fois les icônes rangées dans `assets/data/classes/<id>/icon.png`, un préfixe par classe ferait que l'`icon.png` du mage **écraserait** celui du paladin dans le cache. Le préfixe vide n'est donc pas un confort : c'est la seule option qui rend la collision structurellement impossible, puisque le chemin devient la clé.

Et il faut une instance `Images` **propre au jeu**, jamais `Flame.images` : `FlameGame.images` vaut par défaut le singleton global (`flame-1.37.0/lib/src/game/game.dart:28`), et le muter en place changerait le préfixe pour tout le processus — **y compris d'un test widget à l'autre dans le même isolate**, rendant les tests dépendants de leur ordre.

**Files:**
- Modify: `lib/game/heros_draft_game.dart:80-96` (le constructeur, qui n'a pas de corps aujourd'hui), `:140`, `:145`
- Modify: `assets/data/heroes.json` — les 3 `iconPath`
- Modify: `assets/data/enemies.json` — les 4 `spritePath`
- Test: `test/unit/flame_image_prefix_test.dart` (create)
- Test: `test/unit/asset_path_convention_test.dart` (create)

**Interfaces:**
- Consumes: rien
- Produces: `HerosDraftGame.images` est une instance dédiée de préfixe `''`. Toute valeur de `iconPath`/`spritePath` dans les données est un chemin complet depuis la racine du projet (`assets/images/hero_paladin.png`). `HerosDraftGame` conserve exactement la même signature de constructeur.

> **Aucun risque de sauvegarde.** `EnemyInstance.toJson` (`lib/models/enemy_instance.dart:88`) sérialise bien `spritePath`, mais n'atteint jamais le fichier de sauvegarde : `SaveService.save` (`lib/services/save_service.dart:31-37`) n'écrit que `RunState`, `DeckState` et `InventoryState`, et `RunState.toJson` (`run_controller.dart:118-135`) ne porte aucun état de combat. Vérifié.

- [ ] **Step 1: Écrire les tests qui échouent**

Créer `test/unit/asset_path_convention_test.dart` :

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le cache d'images de Flame n'inclut pas le prefixe dans ses cles
/// (`flame/lib/src/cache/images.dart:29-32`). Le jeu tourne donc avec un
/// prefixe vide et des chemins complets : le chemin EST la cle, et deux
/// `icon.png` de classes differentes ne peuvent plus se marcher dessus.
void main() {
  test('tout chemin d image des donnees est complet et designe un fichier existant', () {
    final offenders = <String>[];

    void check(String catalogue, String field) {
      final raw = File('assets/data/$catalogue').readAsStringSync();
      for (final entry in jsonDecode(raw) as List) {
        final path = (entry as Map<String, dynamic>)[field] as String;
        final id = entry['id'] as String;
        if (!path.startsWith('assets/')) {
          offenders.add('$catalogue → $id : "$path" n est pas un chemin complet');
        } else if (!File(path).existsSync()) {
          offenders.add('$catalogue → $id : "$path" ne designe aucun fichier');
        }
      }
    }

    check('heroes.json', 'iconPath');
    check('enemies.json', 'spritePath');

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
```

Créer `test/unit/flame_image_prefix_test.dart` :

```dart
import 'package:flame/flame.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/heros_draft_game.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/silent_audio_backend.dart';

HerosDraftGame _buildGame() => HerosDraftGame(
      audio: AudioDirector(
        backend: const SilentAudioBackend(),
        data: const AudioData.disabled(),
        settings: () => const AudioSettings(),
      ),
      imagesToPreload: const [],
      onEnemiesDead: () {},
      onPhaseChanged: (_) {},
      onShowTooltip: (_, __, ___) {},
      onHideTooltip: () {},
      onPlayCard: (_, __) => false,
      onEnemyKilled: () {},
      onResolveEnemyIntent: (_) {},
      onStartEnemyTurn: () {},
      onEndEnemyTurn: () {},
      onSelectEnemy: (_) {},
      onUpdateEnemyStats: (_, __) {},
    );

void main() {
  test('le jeu charge ses images sous un prefixe vide', () {
    expect(_buildGame().images.prefix, isEmpty);
  });

  test('le jeu n emprunte pas le cache global de Flame', () {
    // Muter `Flame.images` en place changerait le prefixe pour tout le
    // processus — et la mutation survivrait d un test widget a l autre dans
    // le meme isolate, rendant les tests dependants de leur ordre.
    final game = _buildGame();
    expect(identical(game.images, Flame.images), isFalse);
    expect(Flame.images.prefix, 'assets/images/');

    // Deux jeux ne partagent pas non plus leur cache entre eux.
    expect(identical(game.images, _buildGame().images), isFalse);
  });
}
```

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

```bash
flutter test test/unit/asset_path_convention_test.dart test/unit/flame_image_prefix_test.dart
```

Attendu : **les deux fichiers échouent**. Le premier parce que `heroes.json` porte `hero_paladin.png`, sans préfixe. Le second parce que `HerosDraftGame` hérite encore de `Flame.images`, dont le préfixe vaut `assets/images/`.

- [ ] **Step 3: Donner au jeu son propre cache d'images**

Dans `lib/game/heros_draft_game.dart`, ajouter l'import :

```dart
import 'package:flame/cache.dart';
```

Puis donner un corps au constructeur (`:80-96`), qui n'en a pas aujourd'hui :

```dart
  HerosDraftGame({
    required this.audio,
    required this.imagesToPreload,
    required this.onEnemiesDead,
    required this.onPhaseChanged,
    required this.onShowTooltip,
    required this.onHideTooltip,
    required this.onPlayCard,
    required this.onEnemyKilled,
    required this.onResolveEnemyIntent,
    required this.onStartEnemyTurn,
    required this.onEndEnemyTurn,
    required this.onSelectEnemy,
    required this.onUpdateEnemyStats,
    this.onEnemiesSpawned,
    this.onAnimationStateChanged,
  }) {
    // Cache propre au jeu, jamais le singleton `Flame.images` : le muter en
    // place changerait le prefixe pour tout le processus, et la mutation
    // survivrait d un test widget a l autre dans le meme isolate.
    //
    // Prefixe vide parce que le prefixe ne fait PAS partie des cles du cache
    // (`flame/lib/src/cache/images.dart:29-32`) : avec un prefixe par
    // dossier, l `icon.png` du mage ecraserait celui du paladin. Avec des
    // chemins complets, le chemin est la cle.
    images = Images(prefix: '');
  }
```

- [ ] **Step 4: Passer les chemins internes en complet**

Toujours dans `lib/game/heros_draft_game.dart`, `onLoad()` (`:139-145`) :

```dart
    final uniqueImages = <String>{
      'assets/images/bg_dungeon.png',
      ...imagesToPreload,
    }.toList();
    await images.loadAll(uniqueImages);

    final bgSprite = Sprite(images.fromCache('assets/images/bg_dungeon.png'));
```

- [ ] **Step 5: Passer les chemins des données en complet**

Dans `assets/data/heroes.json`, les trois `iconPath` :

| id | avant | après |
|:---|:---|:---|
| `paladin` | `hero_paladin.png` | `assets/images/hero_paladin.png` |
| `berserker` | `hero_berserker.png` | `assets/images/hero_berserker.png` |
| `mage` | `hero_mage.png` | `assets/images/hero_mage.png` |

Dans `assets/data/enemies.json`, les quatre `spritePath` :

| id | avant | après |
|:---|:---|:---|
| `slime` | `enemy_slime.png` | `assets/images/enemy_slime.png` |
| `gobelin` | `enemy_goblin.png` | `assets/images/enemy_goblin.png` |
| `squelette` | `enemy_skeleton.png` | `assets/images/enemy_skeleton.png` |
| `orc` | `enemy_orc.png` | `assets/images/enemy_orc.png` |

**Ne rien changer d'autre dans ces deux fichiers.** Les noms de fichiers d'images restent tels quels : c'est la tâche 5 qui les renommera, en même temps qu'elle les déplacera.

- [ ] **Step 6: Lancer les tests pour vérifier qu'ils passent**

```bash
flutter test test/unit/asset_path_convention_test.dart test/unit/flame_image_prefix_test.dart
```

Attendu : **4 tests au vert**.

- [ ] **Step 7: Prouver que le test de préfixe mord**

Remettre temporairement `images = Images();` (préfixe par défaut) dans le constructeur, relancer `flutter test test/unit/flame_image_prefix_test.dart` : le test *« le jeu charge ses images sous un prefixe vide »* **doit** échouer. Rétablir ensuite `Images(prefix: '')`.

Un test qui passe dans les deux cas ne garde rien. Ne pas sauter cette étape.

- [ ] **Step 8: Suite complète et analyse**

```bash
flutter test
```

Attendu : **391 au vert** — 388 plus les 3 tests créés ici (1 dans `asset_path_convention_test.dart`, 2 dans `flame_image_prefix_test.dart`), aucun supprimé.

```bash
dart analyze
```

Attendu : `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add lib/game/heros_draft_game.dart assets/data/heroes.json assets/data/enemies.json test/unit/flame_image_prefix_test.dart test/unit/asset_path_convention_test.dart
git commit -m "refactor(images): vider le prefixe Flame et passer aux chemins complets"
```

---

# Tâche 2 — `GameDataLoader` : sélection, tri, fusion, unicité, agrégation

*Effort : 0,6 j. Objectif : un chargeur générique, entièrement testable sur un bundle factice, qui ne connaît aucun modèle du jeu.*

Ce qui manquait aux tentatives naïves : `startsWith('assets/data/classes/')` capterait à la fois `paladin/class.json` et `paladin/cards/holy_shield.json`. Le **comptage de segments** les sépare — et filtre du même coup les assets de paquets, qui vivent sous `packages/<nom>/…`.

Ce chargeur n'est encore branché nulle part à la fin de cette tâche : c'est du code neuf, exercé par ses seuls tests. L'injection arrive en tâche 3.

**Files:**
- Create: `lib/services/game_data_loader.dart`
- Test: `test/unit/game_data_loader_test.dart` (create)

**Interfaces:**
- Consumes: rien
- Produces:
  - `class EntitySource<T>` — constructeur `EntitySource(String pattern, T Function(Map<String, dynamic>) fromJson, {Map<String, dynamic> Function(List<String> captures)? inject, Set<String> redundantFields = const {'id'}})`
  - `class GameDataLoader` — `GameDataLoader(AssetBundle bundle)`, `Future<void> prepare()`, `Future<List<T>> loadAll<T>(List<EntitySource<T>> sources)`, `void throwIfFailed()`
  - Les entités rendues sont **triées par `id` croissant**. Les erreurs s'accumulent dans l'objet et ne sortent que par `throwIfFailed()`.

> **Le `bundle` est un paramètre, et c'est le seul point qui rend cette tâche testable.** `AssetManifest.loadFromAssetBundle` accepte n'importe quel `AssetBundle` : une sous-classe de `CachingAssetBundle` qui sert un `AssetManifest.bin` encodé au `StandardMessageCodec` suffit. Vérifié sur cette version de Flutter.

- [ ] **Step 1: Écrire les tests qui échouent**

Créer `test/unit/game_data_loader_test.dart` :

```dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/game_data_loader.dart';

// `ByteData` et `Uint8List` viennent de `package:flutter/services.dart`, qui
// les reexporte : pas d import `dart:typed_data`, comme dans
// `test/unit/audio/load_audio_data_test.dart`.

/// Bundle factice : sert un `AssetManifest.bin` construit a la volee depuis
/// les cles de [files]. C est le seul moyen d exercer le chargeur sur une
/// arborescence choisie sans fabriquer un vrai bundle ni polluer celui de
/// l application.
class FakeBundle extends CachingAssetBundle {
  FakeBundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final manifest = <String, Object>{
        for (final path in files.keys) path: <Object>[],
      };
      return const StandardMessageCodec().encodeMessage(manifest)!;
    }
    final content = files[key];
    if (content == null) throw Exception('asset introuvable : $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }
}

/// Modele de test minimal : le chargeur ne doit connaitre aucun modele du jeu.
class Thing {
  Thing(this.id, this.label);
  final String id;
  final String label;

  static Thing fromJson(Map<String, dynamic> json) =>
      Thing(json['id'] as String, json['label'] as String);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameDataLoader — selection par motif', () {
    test('un motif a un segment ne prend que les fichiers de ce repertoire', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/a.json': '{"id":"a","label":"A"}',
        'assets/data/things/b.json': '{"id":"b","label":"B"}',
        'assets/data/others/c.json': '{"id":"c","label":"C"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);

      loader.throwIfFailed();
      expect(things.map((t) => t.id), ['a', 'b']);
    });

    test('le comptage de segments separe class.json de cards/*.json', () async {
      // `startsWith('assets/data/classes/')` capterait les deux. C est
      // precisement ce que le motif resout.
      final bundle = FakeBundle({
        'assets/data/classes/paladin/class.json': '{"id":"paladin","label":"Paladin"}',
        'assets/data/classes/paladin/cards/smite.json': '{"id":"smite","label":"Chatiment"}',
        'assets/data/classes/mage/class.json': '{"id":"mage","label":"Mage"}',
      });

      final shallow = GameDataLoader(bundle);
      final classes = await shallow.loadAll<Thing>([
        EntitySource('assets/data/classes/*/class.json', Thing.fromJson),
      ]);
      shallow.throwIfFailed();
      expect(classes.map((t) => t.id), ['mage', 'paladin']);

      final deep = GameDataLoader(bundle);
      final cards = await deep.loadAll<Thing>([
        EntitySource('assets/data/classes/*/cards/*.json', Thing.fromJson),
      ]);
      deep.throwIfFailed();
      expect(cards.map((t) => t.id), ['smite']);
    });

    test('les assets de paquets sont ignores', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/a.json': '{"id":"a","label":"A"}',
        'packages/flame/assets/data/things/x.json': '{"id":"x","label":"X"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);

      loader.throwIfFailed();
      expect(things.map((t) => t.id), ['a']);
    });

    test('une categorie absente du manifeste rend une liste vide sans lever', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/a.json': '{"id":"a","label":"A"}',
      }));

      final empty = await loader.loadAll<Thing>([
        EntitySource('assets/data/nothing/*.json', Thing.fromJson),
      ]);

      expect(empty, isEmpty);
      loader.throwIfFailed(); // ne doit pas lever
    });
  });

  group('GameDataLoader — ordre et fusion', () {
    test('le resultat est trie par id, quel que soit l ordre du manifeste', () async {
      // `listAssets()` n offre AUCUNE garantie d ordre
      // (`asset_manifest.dart:115, 122-124` deplace les cles entre deux
      // structures). Le tri par id est la seule regle qui donne le meme
      // resultat depuis le bundle et depuis le disque.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/zebre.json': '{"id":"zebre","label":"Z"}',
        'assets/data/things/abeille.json': '{"id":"abeille","label":"A"}',
        'assets/data/things/mouette.json': '{"id":"mouette","label":"M"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);

      loader.throwIfFailed();
      expect(things.map((t) => t.id), ['abeille', 'mouette', 'zebre']);
    });

    test('deux sources sont fusionnees puis triees ensemble', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/mouette.json': '{"id":"mouette","label":"M"}',
        'assets/data/classes/paladin/things/abeille.json': '{"id":"abeille","label":"A"}',
        'assets/data/classes/paladin/things/zebre.json': '{"id":"zebre","label":"Z"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
        EntitySource('assets/data/classes/*/things/*.json', Thing.fromJson),
      ]);

      loader.throwIfFailed();
      expect(things.map((t) => t.id), ['abeille', 'mouette', 'zebre']);
    });

    test('un id duplique entre deux sources echoue en nommant les deux fichiers', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/smite.json': '{"id":"smite","label":"neutre"}',
        'assets/data/classes/paladin/things/smite.json': '{"id":"smite","label":"paladin"}',
      }));

      await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
        EntitySource('assets/data/classes/*/things/*.json', Thing.fromJson),
      ]);

      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) {
          final message = e.toString();
          return message.contains('smite') &&
              message.contains('assets/data/things/smite.json') &&
              message.contains('assets/data/classes/paladin/things/smite.json');
        })),
      );
    });
  });

  group('GameDataLoader — agregation des erreurs', () {
    test('deux fichiers fautifs produisent UN rapport listant les deux', () async {
      // `_mapList` levait a la premiere entree fautive. Avec 72 fichiers,
      // corriger une faute par cycle de rebuild serait invivable.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/bon.json': '{"id":"bon","label":"B"}',
        'assets/data/things/casse1.json': '{ ceci n est pas du json',
        'assets/data/things/casse2.json': '{"id":"casse2"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);

      // Les entites fautives sont exclues ; le chargement va au bout.
      expect(things.map((t) => t.id), ['bon']);

      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) {
          final message = e.toString();
          return message.contains('casse1.json') && message.contains('casse2.json');
        })),
      );
    });

    test('le rapport est tronque a 10 fichiers, suivis du reste en nombre', () async {
      // `gameDataLoaderProvider` est un FutureProvider dont l erreur atterrit
      // dans des `Text('Erreur de chargement: $err')` non scrollables
      // (`relic_exchange_screen.dart:118`) : 72 lignes y seraient illisibles.
      final loader = GameDataLoader(FakeBundle({
        for (var i = 0; i < 13; i++)
          'assets/data/things/casse$i.json': '{ pas du json',
      }));

      await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);

      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) {
          final message = e.toString();
          final lines = message.split('\n').where((l) => l.contains('casse')).length;
          return lines == 10 && message.contains('et 3 autres');
        })),
      );
    });

    test('un fichier contenant un tableau est rejete, pas un objet', () async {
      // §6.1 : « Un JSON d entite contient un objet, pas un tableau. » C est
      // la faute la plus probable pendant la migration — recopier un
      // catalogue entier au lieu d une de ses entrees.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/a.json': '[{"id":"a","label":"A"}]',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);

      expect(things, isEmpty);
      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) =>
            e.toString().contains('a.json') &&
            e.toString().contains('objet JSON'))),
      );
    });

    test('sans erreur, throwIfFailed ne leve pas', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/a.json': '{"id":"a","label":"A"}',
      }));
      await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);
      loader.throwIfFailed();
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

```bash
flutter test test/unit/game_data_loader_test.dart
```

Attendu : échec de compilation — `game_data_loader.dart` n'existe pas.

- [ ] **Step 3: Écrire le chargeur**

Créer `lib/services/game_data_loader.dart` :

```dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Une categorie d entites : ou les trouver, comment les construire, et ce
/// que leur emplacement dit d elles.
///
/// Le motif de chemin porte a la fois la **selection** et l **injection** :
/// les segments captures alimentent [inject]. C est ce qui permet a
/// `classes/paladin/cards/smite.json` d etre, par construction, une carte du
/// paladin — sans qu aucun champ du fichier n ait a le dire.
class EntitySource<T> {
  const EntitySource(
    this.pattern,
    this.fromJson, {
    this.inject,
    this.redundantFields = const {'id'},
  });

  /// Motif de chemin d asset. Chaque segment est soit un litteral, soit `*`
  /// (un segment quelconque, capture tel quel), soit `*.json` (un segment
  /// finissant par `.json`, capture sans son extension).
  ///
  /// Le nombre de segments doit correspondre exactement : c est ce qui
  /// separe `classes/*/class.json` de `classes/*/cards/*.json`, et ce qui
  /// ecarte les assets de paquets, sous `packages/<nom>/...`.
  final String pattern;

  final T Function(Map<String, dynamic>) fromJson;

  /// Les champs que le repertoire impose, calcules depuis les segments
  /// captures par [pattern], dans l ordre ou ils apparaissent.
  final Map<String, dynamic> Function(List<String> captures)? inject;

  /// Les champs injectes qu un fichier a le droit de redeclarer, a condition
  /// que la valeur soit identique. Tout autre champ injecte present dans le
  /// JSON fait echouer le chargement.
  ///
  /// `id` y figure a titre permanent : le porter dans le fichier le rend
  /// lisible hors contexte et inspectable en masse. `heroClass` et
  /// `category` n y sont que le temps de la migration.
  final Set<String> redundantFields;
}

class _Match {
  const _Match(this.key, this.captures);
  final String key;
  final List<String> captures;
}

class _Entry<T> {
  const _Entry(this.key, this.id, this.raw, this.fromJson);
  final String key;
  final String id;
  final Map<String, dynamic> raw;
  final T Function(Map<String, dynamic>) fromJson;
}

/// Charge les entites du jeu depuis un [AssetBundle], une categorie a la fois,
/// en accumulant les erreurs plutot qu en levant a la premiere.
///
/// Le [bundle] est un parametre et non `rootBundle` en dur : c est le seul
/// point qui rend le chargeur testable sur une arborescence choisie.
class GameDataLoader {
  GameDataLoader(this.bundle);

  final AssetBundle bundle;

  AssetManifest? _manifest;
  Future<void>? _preparing;
  final List<String> _errors = [];

  /// Charge le manifeste d assets. Idempotent : les appels suivants rendent
  /// le meme futur. [loadAll] l appelle lui-meme, de sorte qu aucun appelant
  /// ne puisse l oublier.
  Future<void> prepare() {
    return _preparing ??= () async {
      _manifest = await AssetManifest.loadFromAssetBundle(bundle);
    }();
  }

  /// Charge, fusionne, trie par `id` et deduplique les entites de [sources].
  ///
  /// Une entite dont le JSON est illisible ou dont `fromJson` leve est
  /// **exclue** du resultat : le chargement va jusqu au bout pour collecter
  /// toutes les fautes, que [throwIfFailed] remonte en une fois.
  Future<List<T>> loadAll<T>(List<EntitySource<T>> sources) async {
    await prepare();

    final entries = <_Entry<T>>[];

    for (final source in sources) {
      final matches = _match(source.pattern);
      final raws = await Future.wait(matches.map(_read));

      for (var i = 0; i < matches.length; i++) {
        final raw = raws[i];
        if (raw == null) continue;

        final merged = _applyInjection(source, matches[i], raw);
        if (merged == null) continue;

        final id = merged['id'];
        if (id is! String || id.isEmpty) {
          _errors.add('${matches[i].key} : champ "id" absent ou non textuel');
          continue;
        }
        entries.add(_Entry<T>(matches[i].key, id, merged, source.fromJson));
      }
    }

    entries.sort((a, b) => a.id.compareTo(b.id));

    final result = <T>[];
    final seen = <String, String>{};
    for (final entry in entries) {
      final previous = seen[entry.id];
      if (previous != null) {
        _errors.add('id "${entry.id}" declare deux fois : $previous et ${entry.key}');
        continue;
      }
      seen[entry.id] = entry.key;
      try {
        result.add(entry.fromJson(entry.raw));
      } catch (e) {
        _errors.add('${entry.key} : ${e.toString().replaceAll('\n', ' ')}');
      }
    }

    return result;
  }

  /// Leve une fois, a la fin, si une seule faute a ete collectee — toutes
  /// categories confondues.
  void throwIfFailed() {
    if (_errors.isEmpty) return;

    debugPrint(
      '[data] ${_errors.length} erreur(s) de chargement :\n${_errors.join('\n')}',
    );

    final shown = _errors.take(10).join('\n');
    final rest = _errors.length > 10
        ? '\n… et ${_errors.length - 10} autres (liste complete en debug)'
        : '';
    throw Exception(
      'Chargement des donnees : ${_errors.length} erreur(s).\n$shown$rest',
    );
  }

  Future<Map<String, dynamic>?> _read(_Match match) async {
    try {
      final decoded = jsonDecode(await bundle.loadString(match.key));
      if (decoded is! Map<String, dynamic>) {
        _errors.add(
          '${match.key} : le fichier doit contenir un objet JSON, pas un ${decoded.runtimeType}',
        );
        return null;
      }
      return decoded;
    } catch (e) {
      _errors.add('${match.key} : ${e.toString().replaceAll('\n', ' ')}');
      return null;
    }
  }

  /// Fusionne les champs imposes par le repertoire dans [raw].
  ///
  /// Regle de conflit (option C de la spec) : le repertoire injecte, le JSON
  /// a le droit de confirmer a l identique s il figure dans
  /// [EntitySource.redundantFields], et la contradiction echoue en nommant le
  /// fichier, le champ, l attendu et le trouve.
  Map<String, dynamic>? _applyInjection<T>(
    EntitySource<T> source,
    _Match match,
    Map<String, dynamic> raw,
  ) {
    final injected = source.inject?.call(match.captures);
    if (injected == null) return raw;

    final merged = Map<String, dynamic>.of(raw);
    var ok = true;

    injected.forEach((field, value) {
      if (!raw.containsKey(field)) {
        merged[field] = value;
        return;
      }
      if (!source.redundantFields.contains(field)) {
        _errors.add(
          '${match.key} : le champ "$field" est impose par le repertoire et '
          'ne doit pas figurer dans le fichier (trouve : "${raw[field]}")',
        );
        ok = false;
        return;
      }
      if (raw[field] != value) {
        _errors.add(
          '${match.key} : champ "$field" — le repertoire impose "$value", '
          'le fichier declare "${raw[field]}"',
        );
        ok = false;
      }
    });

    return ok ? merged : null;
  }

  List<_Match> _match(String pattern) {
    final patternSegments = pattern.split('/');
    final matches = <_Match>[];

    for (final key in _manifest!.listAssets()) {
      final keySegments = key.split('/');
      if (keySegments.length != patternSegments.length) continue;

      final captures = <String>[];
      var ok = true;

      for (var i = 0; i < patternSegments.length; i++) {
        final p = patternSegments[i];
        final s = keySegments[i];

        if (p == '*') {
          captures.add(s);
        } else if (p.startsWith('*.')) {
          final extension = p.substring(1);
          if (!s.endsWith(extension) || s.length <= extension.length) {
            ok = false;
            break;
          }
          captures.add(s.substring(0, s.length - extension.length));
        } else if (p != s) {
          ok = false;
          break;
        }
      }

      if (ok) matches.add(_Match(key, captures));
    }

    return matches;
  }
}
```

- [ ] **Step 4: Lancer le test pour vérifier qu'il passe**

```bash
flutter test test/unit/game_data_loader_test.dart
```

Attendu : **11 tests au vert**.

- [ ] **Step 5: Prouver que le test de tri mord**

Remplacer temporairement `entries.sort((a, b) => a.id.compareTo(b.id));` par `entries.sort((a, b) => b.id.compareTo(a.id));` et relancer. Le test *« le resultat est trie par id »* **doit** échouer sur les trois ids, et *« deux sources sont fusionnees puis triees ensemble »* aussi. Rétablir.

- [ ] **Step 6: Suite complète et analyse**

```bash
flutter test
dart analyze
```

Attendu : **402 au vert** (391 + 11) et `No issues found!`.

- [ ] **Step 7: Commit**

```bash
git add lib/services/game_data_loader.dart test/unit/game_data_loader_test.dart
git commit -m "feat(data): chargeur generique pilote par motifs de chemin"
```

---

# Tâche 3 — L'autorité du répertoire : injection et règle de conflit

*Effort : 0,4 j. Objectif : qu'une carte rangée dans `classes/paladin/cards/` **soit** une carte du paladin, et qu'un JSON qui prétendrait le contraire fasse échouer le chargement.*

Le code de `_applyInjection` a été écrit en tâche 2 — il est indissociable de `loadAll`. Cette tâche lui donne ses tests, qui sont le cœur de la décision D5 et n'ont pas d'équivalent ailleurs.

**Files:**
- Test: `test/unit/game_data_loader_injection_test.dart` (create)
- Modify: `lib/services/game_data_loader.dart` — seulement si un test révèle un écart

**Interfaces:**
- Consumes: `EntitySource`, `GameDataLoader` de la tâche 2
- Produces: rien de neuf ; la garantie que la règle de conflit tient

> **Les passifs sont volontairement exclus de l'injection** (décision D4 de la spec). `PassiveData` n'a pas de champ `heroClass` : une injection y serait silencieusement jetée par `fromJson`, un no-op qu'aucun test ne pourrait détecter. `passives/` reste à plat.

- [ ] **Step 1: Écrire les tests qui échouent**

Créer `test/unit/game_data_loader_injection_test.dart` :

```dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/game_data_loader.dart';

// `ByteData` et `Uint8List` viennent de `package:flutter/services.dart`, qui
// les reexporte : pas d import `dart:typed_data`, comme dans
// `test/unit/audio/load_audio_data_test.dart`.

class FakeBundle extends CachingAssetBundle {
  FakeBundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final manifest = <String, Object>{
        for (final path in files.keys) path: <Object>[],
      };
      return const StandardMessageCodec().encodeMessage(manifest)!;
    }
    final content = files[key];
    if (content == null) throw Exception('asset introuvable : $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }
}

/// Modele de test portant exactement les champs que le repertoire injecte.
class Thing {
  Thing(this.id, this.owner, this.category);
  final String id;
  final String? owner;
  final String category;

  static Thing fromJson(Map<String, dynamic> json) => Thing(
        json['id'] as String,
        json['owner'] as String?,
        json['category'] as String? ?? 'global',
      );
}

EntitySource<Thing> _ownedSource() => EntitySource(
      'assets/data/classes/*/things/*.json',
      Thing.fromJson,
      inject: (c) => {'id': c[1], 'owner': c[0], 'category': 'owned'},
      redundantFields: const {'id', 'owner', 'category'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Autorite du repertoire', () {
    test('le repertoire injecte l appartenance, meme si le fichier se tait', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/classes/paladin/things/smite.json': '{"label":"Chatiment"}',
      }));

      final things = await loader.loadAll<Thing>([_ownedSource()]);

      loader.throwIfFailed();
      expect(things.single.id, 'smite');
      expect(things.single.owner, 'paladin');
      expect(things.single.category, 'owned');
    });

    test('le fichier a le droit de confirmer un champ injecte a l identique', () async {
      // Tolerance a expiration : elle sert pendant la migration, ou elle
      // laisse passer tels quels les `category` et `heroClass` des fichiers
      // issus du decoupage. La tache 9 la retire.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/classes/paladin/things/smite.json':
            '{"id":"smite","owner":"paladin","category":"owned"}',
      }));

      final things = await loader.loadAll<Thing>([_ownedSource()]);

      loader.throwIfFailed();
      expect(things.single.owner, 'paladin');
    });

    test('un champ injecte contredit fait echouer, en nommant tout', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/classes/paladin/things/smite.json': '{"owner":"mage"}',
      }));

      await loader.loadAll<Thing>([_ownedSource()]);

      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) {
          final message = e.toString();
          return message.contains('assets/data/classes/paladin/things/smite.json') &&
              message.contains('owner') &&
              message.contains('paladin') &&
              message.contains('mage');
        })),
      );
    });

    test('l entite contredite est exclue, les autres passent', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/classes/paladin/things/smite.json': '{"owner":"mage"}',
        'assets/data/classes/paladin/things/shield.json': '{"label":"Bouclier"}',
      }));

      final things = await loader.loadAll<Thing>([_ownedSource()]);

      expect(things.map((t) => t.id), ['shield']);
      expect(() => loader.throwIfFailed(), throwsException);
    });
  });

  group('Origine de l id', () {
    test('pour un fichier nomme, l id vient du nom de fichier', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/iron_talisman.json': '{"label":"Talisman"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource(
          'assets/data/things/*.json',
          Thing.fromJson,
          inject: (c) => {'id': c[0]},
        ),
      ]);

      loader.throwIfFailed();
      expect(things.single.id, 'iron_talisman');
    });

    test('pour class.json et enemy.json, l id vient du repertoire parent', () async {
      // Derogation assumee de §6.1 : ces deux fichiers portent un nom fixe,
      // donc leur identite est celle de leur dossier.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/classes/paladin/class.json': '{"label":"Paladin"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource(
          'assets/data/classes/*/class.json',
          Thing.fromJson,
          inject: (c) => {'id': c[0]},
        ),
      ]);

      loader.throwIfFailed();
      expect(things.single.id, 'paladin');
    });

    test('un id de fichier contredit par le JSON fait echouer', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/iron_talisman.json': '{"id":"iron_talismn"}',
      }));

      await loader.loadAll<Thing>([
        EntitySource(
          'assets/data/things/*.json',
          Thing.fromJson,
          inject: (c) => {'id': c[0]},
        ),
      ]);

      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) {
          final message = e.toString();
          return message.contains('iron_talisman.json') &&
              message.contains('iron_talismn');
        })),
      );
    });
  });
}
```

- [ ] **Step 2: Lancer le test**

```bash
flutter test test/unit/game_data_loader_injection_test.dart
```

Attendu : **7 tests au vert** — le code de `_applyInjection` écrit en tâche 2 doit déjà les satisfaire. **Si l'un échoue, c'est le chargeur qui est faux, pas le test** : corriger `lib/services/game_data_loader.dart`.

- [ ] **Step 3: Prouver que le test de contradiction mord**

Remplacer temporairement, dans `_applyInjection`, la branche de comparaison par `if (false)` et relancer. Les tests *« un champ injecte contredit fait echouer »* et *« un id de fichier contredit par le JSON fait echouer »* **doivent** échouer. Rétablir.

- [ ] **Step 4: Suite complète et analyse**

```bash
flutter test
dart analyze
```

Attendu : **409 au vert** (402 + 7) et `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add test/unit/game_data_loader_injection_test.dart lib/services/game_data_loader.dart
git commit -m "test(data): epingler l autorite du repertoire et la regle de conflit"
```

---

# Tâche 4 — `tool/sync_assets.dart` : le pubspec généré

*Effort : 0,75 j. Objectif : que l'ajout d'un dossier de classe ou d'ennemi ne demande jamais d'éditer le pubspec à la main, et qu'un oubli ne puisse pas passer.*

**Les déclarations d'assets ne sont récursives à aucun niveau** (`flutter_tools/lib/src/asset.dart:1178-1180` : `.listSync()` sans `recursive: true`). Chaque dossier de classe et d'ennemi exige donc sa ligne. Et le mode de défaillance est asymétrique — c'est le pire des deux qui est probable :

- **Répertoire déclaré mais absent** → `asset.dart:1173-1176` journalise `Error: unable to find directory entry in pubspec.yaml` puis `return`. **Bruyant, non fatal.**
- **Répertoire présent mais non déclaré** → aucun message. Le contenu **se charge en développement** et **disparaît en build**. C'est celui-là qu'il faut couvrir.

Cette tâche vient **avant** le découpage exprès : sur l'arbre actuel, le script doit reproduire les quatre lignes existantes, ce qui le valide sans rien risquer.

**Files:**
- Create: `tool/sync_assets.dart` (et le répertoire `tool/`, qui n'existe pas)
- Modify: `pubspec.yaml:30-34` — la section `assets:` passe en ordre trié
- Test: `test/unit/sync_assets_test.dart` (create)

**Interfaces:**
- Consumes: rien
- Produces: `dart run tool/sync_assets.dart` réécrit la section `assets:` de `pubspec.yaml` ; `dart run tool/sync_assets.dart --check` sort en **0** si elle est déjà à jour, en **1** sinon, en affichant les lignes en trop et manquantes. Le script n'émet que les répertoires **existants et contenant au moins un fichier**, chemins triés, terminés par `/`.

> **Le script préserve le terminateur de ligne du fichier.** `pubspec.yaml` est en CRLF dans ce dépôt (34 lignes, 34 CRLF), et `.gitattributes` ne couvre que `.github/`. Un script qui écrirait en LF réécrirait le fichier entier à chaque exécution.

- [ ] **Step 1: Écrire le test qui échoue**

Créer `test/unit/sync_assets_test.dart` :

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `tool/sync_assets.dart` vit hors de `lib/`, donc n est pas importable par
/// `package:`. On l invoque comme le ferait un humain ou la CI.
///
/// `runInShell: true` est INDISPENSABLE. L hote de `flutter test` est
/// `flutter_tester.exe`, dont l environnement ne resout pas `dart` : sans le
/// shell, `Process.run` leve `ProcessException: Le fichier specifie est
/// introuvable`. Sur `ubuntu-latest` ca passerait — `dart` y est un script a
/// shebang — donc l omission produirait exactement l asymetrie local/CI que
/// ce chantier traque ailleurs, mais inversee : rouge en local, vert en CI.
Future<ProcessResult> _run(List<String> args, {String? cwd}) {
  return Process.run(
    'dart',
    ['run', 'tool/sync_assets.dart', ...args],
    workingDirectory: cwd,
    runInShell: true,
  );
}

void main() {
  test('--check sort en 0 : le pubspec du depot est synchronise', () async {
    final result = await _run(['--check']);
    expect(
      result.exitCode,
      0,
      reason: 'pubspec.yaml a derive du disque :\n${result.stdout}${result.stderr}',
    );
  });

  group('sur une arborescence de test', () {
    late Directory sandbox;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('sync_assets_');
      // Le script est invoque depuis le sandbox : il lui faut une copie.
      Directory('${sandbox.path}/tool').createSync(recursive: true);
      File('tool/sync_assets.dart').copySync('${sandbox.path}/tool/sync_assets.dart');
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    void write(String relative, String content) {
      final file = File('${sandbox.path}/$relative');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    // `environment:` evite l avertissement « has no lower-bound SDK
    // constraint » que `dart run` ecrirait sur stdout a chaque invocation.
    String pubspecWith(String assetsBlock) =>
        'name: sandbox\r\n'
        'environment:\r\n'
        '  sdk: ^3.11.4\r\n'
        'flutter:\r\n'
        '  uses-material-design: true\r\n'
        '  assets:\r\n'
        '$assetsBlock'
        '  fonts: []\r\n';

    test('seuls les repertoires contenant au moins un fichier sont emis', () async {
      write('assets/data/audio.json', '{}');
      write('assets/data/cards/strike.json', '{}');
      write('assets/images/bg.png', 'x');
      // `assets/data/classes/` ne contient que des dossiers : pas de ligne.
      write('assets/data/classes/paladin/class.json', '{}');
      // Un dossier vide n a rien a declarer.
      Directory('${sandbox.path}/assets/data/vide').createSync(recursive: true);
      write('pubspec.yaml', pubspecWith(''));

      final result = await _run([], cwd: sandbox.path);
      expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');

      final written = File('${sandbox.path}/pubspec.yaml').readAsStringSync();
      expect(
        written,
        pubspecWith(
          '    - assets/data/\r\n'
          '    - assets/data/cards/\r\n'
          '    - assets/data/classes/paladin/\r\n'
          '    - assets/images/\r\n',
        ),
      );
    });

    test('--check sort en 1 et nomme la ligne manquante', () async {
      write('assets/data/audio.json', '{}');
      write('assets/data/cards/strike.json', '{}');
      write('pubspec.yaml', pubspecWith('    - assets/data/\r\n'));

      final result = await _run(['--check'], cwd: sandbox.path);
      expect(result.exitCode, 1);
      expect(result.stdout.toString(), contains('assets/data/cards/'));
    });

    test('le fichier n est pas reecrit quand il est deja a jour', () async {
      write('assets/images/bg.png', 'x');
      write('pubspec.yaml', pubspecWith('    - assets/images/\r\n'));
      final before = File('${sandbox.path}/pubspec.yaml').readAsStringSync();

      final result = await _run([], cwd: sandbox.path);
      expect(result.exitCode, 0);
      expect(File('${sandbox.path}/pubspec.yaml').readAsStringSync(), before);
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

```bash
flutter test test/unit/sync_assets_test.dart
```

Attendu : **les 4 tests échouent** — `tool/sync_assets.dart` n'existe pas.

- [ ] **Step 3: Écrire le script**

Créer `tool/sync_assets.dart` :

```dart
// Regenere la section `assets:` de pubspec.yaml depuis le contenu reel de
// `assets/`.
//
// Raison d etre : les declarations d assets de Flutter ne sont recursives a
// aucun niveau (`flutter_tools/lib/src/asset.dart:1178-1180`). Chaque dossier
// de classe et d ennemi exige donc sa propre ligne, et le nombre de lignes
// devient variable. Un dossier present mais non declare ne produit AUCUN
// message : son contenu se charge en developpement et disparait en build.
//
// Usage :
//   dart run tool/sync_assets.dart           regenere la section
//   dart run tool/sync_assets.dart --check   sort en 1 si elle a derive

import 'dart:io';

void main(List<String> args) {
  final checkOnly = args.contains('--check');

  final expected = _directoriesWithFiles(Directory('assets'));
  final pubspec = File('pubspec.yaml');
  final content = pubspec.readAsStringSync();
  final eol = content.contains('\r\n') ? '\r\n' : '\n';

  final lines = content.split(eol);
  final start = lines.indexWhere((l) => l == '  assets:');
  if (start == -1) {
    stderr.writeln('pubspec.yaml : section "  assets:" introuvable.');
    exit(2);
  }

  var end = start + 1;
  while (end < lines.length && lines[end].startsWith('    - ')) {
    end++;
  }

  final current = lines
      .sublist(start + 1, end)
      .map((l) => l.substring('    - '.length))
      .toList();

  if (checkOnly) {
    final missing = expected.where((d) => !current.contains(d)).toList();
    final extra = current.where((d) => !expected.contains(d)).toList();
    if (missing.isEmpty && extra.isEmpty && _sameOrder(current, expected)) {
      exit(0);
    }
    stdout.writeln('pubspec.yaml a derive du contenu de assets/ :');
    for (final d in missing) {
      stdout.writeln('  manquant : $d');
    }
    for (final d in extra) {
      stdout.writeln('  en trop  : $d');
    }
    if (missing.isEmpty && extra.isEmpty) {
      stdout.writeln('  (memes entrees, ordre different — la section doit etre triee)');
    }
    stdout.writeln('Corriger avec : dart run tool/sync_assets.dart');
    exit(1);
  }

  if (_sameOrder(current, expected)) {
    stdout.writeln('pubspec.yaml deja a jour (${expected.length} entrees).');
    exit(0);
  }

  final rebuilt = <String>[
    ...lines.sublist(0, start + 1),
    ...expected.map((d) => '    - $d'),
    ...lines.sublist(end),
  ];
  pubspec.writeAsStringSync(rebuilt.join(eol));
  stdout.writeln('pubspec.yaml regenere : ${expected.length} entrees.');
}

bool _sameOrder(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Tout repertoire sous [root] contenant au moins un fichier *direct*, chemin
/// relatif a la racine du projet, termine par `/`, trie.
///
/// Un repertoire ne contenant que des sous-repertoires n a rien a declarer :
/// la declaration n etant pas recursive, elle n apporterait aucun asset.
List<String> _directoriesWithFiles(Directory root) {
  if (!root.existsSync()) return const [];

  final result = <String>[];

  void walk(Directory directory) {
    final entities = directory.listSync();
    if (entities.whereType<File>().isNotEmpty) {
      result.add('${directory.path.replaceAll(r'\', '/')}/');
    }
    for (final child in entities.whereType<Directory>()) {
      walk(child);
    }
  }

  walk(root);
  result.sort();
  return result;
}
```

- [ ] **Step 4: Régénérer le pubspec du dépôt**

```bash
dart run tool/sync_assets.dart
```

La section passe de l'ordre historique à l'ordre trié — **quatre lignes, mêmes valeurs** :

```yaml
  assets:
    - assets/audio/music/
    - assets/audio/sfx/
    - assets/data/
    - assets/images/
```

C'est le seul changement de contenu attendu du pubspec dans cette tâche. Vérifier avec `git diff pubspec.yaml` que rien d'autre n'a bougé, **et en particulier que le fichier n'a pas été réécrit en LF** : `git diff --stat pubspec.yaml` doit annoncer 4 lignes modifiées, pas 34.

- [ ] **Step 5: Lancer le test pour vérifier qu'il passe**

```bash
flutter test test/unit/sync_assets_test.dart
```

Attendu : **4 tests au vert**.

- [ ] **Step 6: Prouver que `--check` mord**

Ajouter à la main une ligne bidon `    - assets/inexistant/` dans le pubspec, lancer `dart run tool/sync_assets.dart --check` : sortie **1**, avec `en trop  : assets/inexistant/`. Retirer la ligne.

- [ ] **Step 7: Suite complète et analyse**

```bash
flutter test
dart analyze
```

Attendu : **413 au vert** (409 + 4) et `No issues found!`. `dart analyze` couvre `tool/` : le script doit être propre lui aussi.

- [ ] **Step 8: Commit**

```bash
git add tool/sync_assets.dart pubspec.yaml test/unit/sync_assets_test.dart
git commit -m "feat(build): generer la section assets du pubspec depuis le disque"
```

---

# Tâche 5 — Découper les catalogues, sans rien supprimer

*Effort : 1 j. Objectif : créer les 71 fichiers d'entité et prouver, sur le JSON brut, qu'ils disent exactement ce que disaient les huit catalogues.*

**C'est le point le plus important du chantier.** Le découpage est mécanique, mais une perte silencieuse d'entité ou de champ serait invisible et définitive.

À la fin de cette tâche, **l'ancien et le nouveau monde coexistent** : les catalogues sont toujours là, toujours lus par le provider, et le jeu se comporte exactement comme avant. Le nouvel arbre n'est encore lu que par l'oracle. C'est ce qui permet à la tâche de se terminer au vert.

**Files:**
- Create: `tool/split_catalogues.dart` (supprimé en tâche 10)
- Create: `assets/data/{cards,relics,events,forge_upgrades,passives}/<id>.json` — 58 fichiers
- Create: `assets/data/classes/<id>/{class.json,icon.png,cards/<id>.json}` — 3 classes, 9 fichiers
- Create: `assets/data/enemies/<id>/{enemy.json,sprite.png}` — 4 ennemis, 8 fichiers
- Modify: `pubspec.yaml` — régénéré par `tool/sync_assets.dart`, 4 → 19 lignes
- Create: `test/migration/reference/*.json` — copie figée des 8 catalogues (supprimée en tâche 10)
- Test: `test/migration/data_equivalence_test.dart` (create, supprimé en tâche 10)

**Interfaces:**
- Consumes: `tool/sync_assets.dart` de la tâche 4
- Produces: l'arborescence cible de §4 de la spec. `iconPath` vaut `assets/data/classes/<id>/icon.png`, `spritePath` vaut `assets/data/enemies/<id>/sprite.png`. Tous les autres champs sont recopiés **à l'identique**.

> **Les images sont copiées, pas déplacées.** L'original de `assets/images/hero_paladin.png` reste en place tant que `heroes.json` le désigne. C'est la tâche 7 qui le supprimera. Un commit avec les octets en double vaut mieux qu'une tâche qui se termine cassée.

> **Le nom du dossier d'ennemi suit l'`id`, qui est français** (`gobelin`, `squelette`), **alors que le sprite est anglais** (`enemy_goblin.png`). Le nom fixe `sprite.png` efface l'incohérence : le script **renomme** en copiant, il ne fait pas que déplacer.

- [ ] **Step 1: Figer la référence de l'oracle**

```bash
mkdir -p test/migration/reference/images
cp assets/data/cards.json assets/data/hero_cards.json assets/data/relics.json assets/data/events.json assets/data/enemies.json assets/data/heroes.json assets/data/passives.json assets/data/forge_upgrades.json test/migration/reference/
cp assets/images/hero_paladin.png assets/images/hero_berserker.png assets/images/hero_mage.png assets/images/enemy_slime.png assets/images/enemy_goblin.png assets/images/enemy_skeleton.png assets/images/enemy_orc.png test/migration/reference/images/
```

La référence est prise **maintenant**, après les deux changements de contenu du lot 2 (ids de passifs en `snake_case`, `displayOrder`) et après la tâche 1 (chemins d'images complets). L'oracle apparie les entités par `id` : les avoir faits avant est ce qui permet l'appariement.

> **Les 7 images sont figées elles aussi, et c'est indispensable.** L'oracle compare les octets de chaque image copiée à ceux de son original — or la tâche 7 **supprime** les originaux de `assets/images/`. Sans copie figée, l'oracle deviendrait rouge à la tâche 7, et l'implémenteur serait tenté d'affaiblir le seul filet de sécurité du chantier pour le faire taire. Même raison que pour les huit catalogues : la référence doit survivre à la disparition de ce qu'elle décrit. Tout `test/migration/` part ensemble à la tâche 9.

- [ ] **Step 2: Écrire l'oracle d'équivalence, qui échoue**

Créer `test/migration/data_equivalence_test.dart` :

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// L oracle de la migration. Son sujet est le **JSON brut**, jamais un modele
/// Dart.
///
/// Comparer des Map produites par `toJson()` serait auto-referentiel : un
/// champ lu par `fromJson` et omis par `toJson` serait invisible des DEUX
/// cotes du diff. Ce n est pas theorique — `CardData.toJson()`
/// (`card_data.dart:134-151`) omet deja `sfx`, que `fromJson:123` lit. Aucune
/// carte ne porte `sfx` aujourd hui, mais P-47 « seconde passe audio » est le
/// chantier ouvert, et son objet est precisement de sonoriser du contenu.
///
/// Ce fichier et son repertoire sont supprimes une fois la migration fusionnee.
List<Map<String, dynamic>> _reference(String catalogue) =>
    (jsonDecode(File('test/migration/reference/$catalogue').readAsStringSync())
            as List)
        .cast<Map<String, dynamic>>();

Map<String, dynamic> _file(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Les seuls champs que la migration a le droit de changer, et la regle
/// exacte qu ils doivent suivre.
const _transformed = {'iconPath', 'spritePath'};

void _expectSameEntities(
  List<Map<String, dynamic>> reference,
  Map<String, Map<String, dynamic>> migrated,
  String label,
) {
  final referenceIds = reference.map((e) => e['id'] as String).toSet();
  expect(
    migrated.keys.toSet(),
    referenceIds,
    reason: '$label : la liste des entites a change entre les deux mondes',
  );
}

void _expectSameFields(
  List<Map<String, dynamic>> reference,
  Map<String, Map<String, dynamic>> migrated,
  String label,
  List<String> injected,
) {
  final differences = <String>[];

  for (final before in reference) {
    final id = before['id'] as String;
    final after = migrated[id]!;

    for (final entry in before.entries) {
      if (_transformed.contains(entry.key)) continue;
      if (!after.containsKey(entry.key)) {
        differences.add('$label/$id : champ "${entry.key}" perdu');
        continue;
      }
      if (jsonEncode(after[entry.key]) != jsonEncode(entry.value)) {
        differences.add(
          '$label/$id : champ "${entry.key}" — avant ${jsonEncode(entry.value)}, '
          'apres ${jsonEncode(after[entry.key])}',
        );
      }
    }

    for (final key in after.keys) {
      if (before.containsKey(key)) continue;
      if (injected.contains(key)) continue;
      differences.add('$label/$id : champ "$key" apparu de nulle part');
    }
  }

  expect(differences, isEmpty, reason: differences.join('\n'));
}

Map<String, Map<String, dynamic>> _flatCategory(String directory) {
  final files = Directory('assets/data/$directory')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'));
  return {
    for (final f in files)
      f.uri.pathSegments.last.replaceAll('.json', ''): _file(f.path),
  };
}

void main() {
  group('Equivalence de la migration — categories a plat', () {
    const plain = {
      'cards.json': 'cards',
      'relics.json': 'relics',
      'events.json': 'events',
      'forge_upgrades.json': 'forge_upgrades',
      'passives.json': 'passives',
    };

    test('meme population, memes champs, memes valeurs', () {
      plain.forEach((catalogue, directory) {
        final reference = _reference(catalogue);
        final migrated = _flatCategory(directory);
        _expectSameEntities(reference, migrated, directory);
        _expectSameFields(reference, migrated, directory, const []);
      });
    });
  });

  group('Equivalence de la migration — dossiers auto-suffisants', () {
    test('les classes : class.json plus le pool de cartes de la classe', () {
      final reference = _reference('heroes.json');
      final migrated = <String, Map<String, dynamic>>{
        for (final d in Directory('assets/data/classes').listSync().whereType<Directory>())
          d.uri.pathSegments[d.uri.pathSegments.length - 2]:
              _file('${d.path}/class.json'),
      };
      _expectSameEntities(reference, migrated, 'classes');
      _expectSameFields(reference, migrated, 'classes', const []);
    });

    test('les cartes de classe sont rangees sous leur classe', () {
      final reference = _reference('hero_cards.json');
      final migrated = <String, Map<String, dynamic>>{};
      final owner = <String, String>{};

      for (final d in Directory('assets/data/classes').listSync().whereType<Directory>()) {
        final className = d.uri.pathSegments[d.uri.pathSegments.length - 2];
        for (final f in Directory('${d.path}/cards').listSync().whereType<File>()) {
          final id = f.uri.pathSegments.last.replaceAll('.json', '');
          migrated[id] = _file(f.path);
          owner[id] = className;
        }
      }

      _expectSameEntities(reference, migrated, 'hero_cards');
      _expectSameFields(reference, migrated, 'hero_cards', const []);

      // Le repertoire doit dire la meme chose que le champ qu il remplacera.
      for (final before in reference) {
        final id = before['id'] as String;
        expect(owner[id], before['heroClass'],
            reason: '$id est range sous ${owner[id]} mais declare ${before['heroClass']}');
      }
    });

    test('les ennemis : enemy.json dans son dossier', () {
      final reference = _reference('enemies.json');
      final migrated = <String, Map<String, dynamic>>{
        for (final d in Directory('assets/data/enemies').listSync().whereType<Directory>())
          d.uri.pathSegments[d.uri.pathSegments.length - 2]:
              _file('${d.path}/enemy.json'),
      };
      _expectSameEntities(reference, migrated, 'enemies');
      _expectSameFields(reference, migrated, 'enemies', const []);
    });
  });

  group('Equivalence de la migration — les chemins d images', () {
    test('les images sont renommees selon la regle, et les fichiers existent', () {
      for (final before in _reference('heroes.json')) {
        final id = before['id'] as String;
        final after = _file('assets/data/classes/$id/class.json');
        expect(after['iconPath'], 'assets/data/classes/$id/icon.png');
        expect(File('assets/data/classes/$id/icon.png').existsSync(), isTrue);
      }
      for (final before in _reference('enemies.json')) {
        final id = before['id'] as String;
        final after = _file('assets/data/enemies/$id/enemy.json');
        expect(after['spritePath'], 'assets/data/enemies/$id/sprite.png');
        expect(File('assets/data/enemies/$id/sprite.png').existsSync(), isTrue);
      }
    });

    test('les octets de l image copiee sont identiques a l original', () {
      // La comparaison porte sur la copie figee de `reference/images/`, pas
      // sur `assets/images/` : la tache 7 y supprime les originaux, et un
      // oracle qui lirait la source qu on est en train de retirer deviendrait
      // rouge pour une raison qui n a rien a voir avec l equivalence.
      const icons = {
        'paladin': 'hero_paladin.png',
        'berserker': 'hero_berserker.png',
        'mage': 'hero_mage.png',
      };
      icons.forEach((id, original) {
        expect(
          File('assets/data/classes/$id/icon.png').readAsBytesSync(),
          File('test/migration/reference/images/$original').readAsBytesSync(),
        );
      });

      const sprites = {
        'slime': 'enemy_slime.png',
        'gobelin': 'enemy_goblin.png',
        'squelette': 'enemy_skeleton.png',
        'orc': 'enemy_orc.png',
      };
      sprites.forEach((id, original) {
        expect(
          File('assets/data/enemies/$id/sprite.png').readAsBytesSync(),
          File('test/migration/reference/images/$original').readAsBytesSync(),
        );
      });
    });
  });
}
```

- [ ] **Step 3: Lancer l'oracle pour vérifier qu'il échoue**

```bash
flutter test test/migration/data_equivalence_test.dart
```

Attendu : **les 6 tests échouent** — aucun des répertoires cibles n'existe.

- [ ] **Step 4: Écrire le script de découpage**

Créer `tool/split_catalogues.dart` :

```dart
// Script de decoupage, a usage UNIQUE. Commite pour etre auditable en revue,
// supprime une fois la migration fusionnee (§8.1 de la spec).
//
// Il ne transforme qu une seule chose : les chemins d images, qui suivent
// leur fichier. Tout le reste est recopie a l identique — c est ce que
// `test/migration/data_equivalence_test.dart` verifie, sur le JSON brut.
//
// Usage : dart run tool/split_catalogues.dart

import 'dart:convert';
import 'dart:io';

const _encoder = JsonEncoder.withIndent('  ');

void main() {
  _splitFlat('cards.json', 'cards');
  _splitFlat('relics.json', 'relics');
  _splitFlat('events.json', 'events');
  _splitFlat('forge_upgrades.json', 'forge_upgrades');
  _splitFlat('passives.json', 'passives');

  _splitClasses();
  _splitClassCards();
  _splitEnemies();

  stdout.writeln('Decoupage termine. Lancer maintenant :');
  stdout.writeln('  dart run tool/sync_assets.dart');
  stdout.writeln('  flutter clean && flutter test');
}

List<Map<String, dynamic>> _read(String catalogue) =>
    (jsonDecode(File('assets/data/$catalogue').readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

void _write(String path, Map<String, dynamic> entity) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  // LF et retour a la ligne final : ce sont des fichiers neufs, autant leur
  // donner la forme la plus portable. Le contenu JSON est ce qui compte, et
  // l oracle compare des valeurs parsees, pas des octets.
  file.writeAsStringSync('${_encoder.convert(entity)}\n');
  stdout.writeln('  + $path');
}

void _splitFlat(String catalogue, String directory) {
  for (final entity in _read(catalogue)) {
    _write('assets/data/$directory/${entity['id']}.json', entity);
  }
}

void _splitClasses() {
  for (final hero in _read('heroes.json')) {
    final id = hero['id'] as String;
    final source = hero['iconPath'] as String; // 'assets/images/hero_x.png'
    final destination = 'assets/data/classes/$id/icon.png';

    final copy = Map<String, dynamic>.of(hero)..['iconPath'] = destination;
    _write('assets/data/classes/$id/class.json', copy);

    File(destination).parent.createSync(recursive: true);
    File(source).copySync(destination);
    stdout.writeln('  + $destination (copie de $source)');
  }
}

void _splitClassCards() {
  for (final card in _read('hero_cards.json')) {
    final owner = card['heroClass'] as String;
    _write('assets/data/classes/$owner/cards/${card['id']}.json', card);
  }
}

void _splitEnemies() {
  for (final enemy in _read('enemies.json')) {
    final id = enemy['id'] as String;
    final source = enemy['spritePath'] as String; // 'assets/images/enemy_x.png'
    final destination = 'assets/data/enemies/$id/sprite.png';

    final copy = Map<String, dynamic>.of(enemy)..['spritePath'] = destination;
    _write('assets/data/enemies/$id/enemy.json', copy);

    File(destination).parent.createSync(recursive: true);
    File(source).copySync(destination);
    stdout.writeln('  + $destination (copie de $source)');
  }
}
```

- [ ] **Step 5: Exécuter le découpage et régénérer le pubspec**

```bash
dart run tool/split_catalogues.dart
dart run tool/sync_assets.dart
```

Vérifier les comptes :

```bash
find assets/data -name '*.json' | wc -l
```

Attendu : **81** à ce stade. C'est-à-dire les **73** fichiers de l'arborescence cible — 71 fichiers d'entité (17 cartes neutres + 25 reliques + 5 événements + 8 améliorations de forge + 3 passifs + 3 `class.json` + 6 cartes de classe + 4 `enemy.json`) plus `patch_notes.json` et `audio.json` — **plus les 8 catalogues, encore présents et encore lus**. Ils disparaîtront en tâche 7 et le compte tombera alors à 73.

Vérifier la section `assets:` du pubspec — **19 lignes** :

```yaml
  assets:
    - assets/audio/music/
    - assets/audio/sfx/
    - assets/data/
    - assets/data/cards/
    - assets/data/classes/berserker/
    - assets/data/classes/berserker/cards/
    - assets/data/classes/mage/
    - assets/data/classes/mage/cards/
    - assets/data/classes/paladin/
    - assets/data/classes/paladin/cards/
    - assets/data/enemies/gobelin/
    - assets/data/enemies/orc/
    - assets/data/enemies/slime/
    - assets/data/enemies/squelette/
    - assets/data/events/
    - assets/data/forge_upgrades/
    - assets/data/passives/
    - assets/data/relics/
    - assets/images/
```

**`assets/data/classes/` et `assets/data/enemies/` n'apparaissent pas** : ils ne contiennent que des sous-dossiers, et une déclaration non récursive n'y apporterait aucun asset. C'est voulu, et le test de la tâche 4 l'épingle.

- [ ] **Step 6: Purger le bundle de test, puis lancer l'oracle**

```bash
flutter clean
flutter pub get
flutter test test/migration/data_equivalence_test.dart
```

**`flutter clean` est obligatoire.** `_needsRebuild` (`flutter_tools/lib/src/commands/test.dart:817-843`) **ne détecte pas les suppressions** — TODO explicite dans le code, flutter#128563. Sans purge, un fichier supprimé peut survivre dans `build/unit_test_assets/` et masquer exactement ce que cette tâche doit prouver.

Attendu : **6 tests au vert**.

- [ ] **Step 7: Prouver que l'oracle mord**

Trois mutations, à annuler après chacune :

1. Supprimer `assets/data/relics/iron_talisman.json` → *« meme population »* doit échouer en nommant l'id.
2. Retirer le champ `"value"` d'un fichier de relique → *« memes champs »* doit signaler `champ "value" perdu`.
3. Changer un `cost` de `1` à `2` dans une carte → le diff doit afficher `avant 1, apres 2`.

Un oracle qui passe ces trois mutations n'a rien garanti. Ne pas sauter cette étape : c'est le seul filet de sécurité du chantier.

- [ ] **Step 8: Suite complète et analyse**

```bash
flutter test
dart analyze
```

Attendu : **419 au vert** (413 + 6) et `No issues found!`. Le provider lit toujours les catalogues : **aucun comportement du jeu n'a changé**.

- [ ] **Step 9: Commit**

```bash
git add tool/split_catalogues.dart assets/data pubspec.yaml test/migration
git commit -m "feat(data): decouper les catalogues en un fichier par entite"
```

Le diff est volumineux (71 fichiers créés, 7 images copiées). C'est attendu : le script est commité précisément pour que la revue porte sur **lui** plutôt que sur les 71 fichiers.

---

# Tâche 6 — Brancher le tutoriel sur le vrai chargeur

*Effort : 0,5 j. Objectif : prouver que `GameDataLoader` lit correctement le nouvel arbre **par le vrai bundle**, avant que l'application n'en dépende.*

`buildTutorialTestRegistry` lit aujourd'hui les catalogues par `dart:io`, en dupliquant la logique de fusion des cartes. Le brancher sur le chargeur en fait le **premier consommateur réel du nouvel arbre**, et le fait dans les tests — là où un échec coûte le moins cher.

Cette tâche crée aussi `loadGameDataRegistry(bundle)` : **l'unique endroit où les huit sources sont déclarées**. Le provider l'utilisera en tâche 7.

**Files:**
- Modify: `lib/services/game_data_service.dart` — ajouter `loadGameDataRegistry`
- Modify: `test/tutorial/tutorial_test_registry.dart` — délègue, devient asynchrone
- Modify: `test/tutorial/tutorial_engine_test.dart:13`
- Modify: `test/tutorial/tutorial_fixtures_test.dart:12`
- Modify: `test/widget/tutorial_class_step_test.dart:16`
- Modify: `test/widget/tutorial_starter_draft_test.dart:16`
- Modify: `test/widget/tutorial_merge_transition_test.dart:59`

**Interfaces:**
- Consumes: `GameDataLoader`, `EntitySource` (tâche 2), l'arborescence (tâche 5)
- Produces: `Future<GameDataRegistry> loadGameDataRegistry(AssetBundle bundle)` dans `lib/services/game_data_service.dart` — construit le registre complet, lève via `throwIfFailed()` si une seule entité est fautive. `Future<GameDataRegistry> buildTutorialTestRegistry()` devient asynchrone et n'est plus qu'une délégation.

> **La délégation change aussi le contenu du registre, pas seulement sa forme.** `buildTutorialTestRegistry` rend aujourd'hui `events: const []` et `forgeUpgrades: const []` (`tutorial_test_registry.dart:31, 34`) ; après délégation il rendra les 5 événements et les 8 améliorations réels. **Aucune assertion des cinq fichiers appelants n'en dépend** — vérifié — donc l'étape reste verte, et le registre gagne en fidélité. Conséquence secondaire à connaître : chaque `testWidgets` des deux fichiers de `test/widget/` fait désormais ~72 lectures de bundle au lieu de 6 lectures `dart:io`. Si la durée de ces tests devient gênante, c'est le passage en `setUpAll` de ces deux fichiers qui la réglera — pas un retour en arrière.

> **Piège du singleton.** `GameDataRegistry` fait `_instance = this` dans son constructeur (`game_data_registry.dart:33`), et les quatre `getById` lisent ce global. **Tout test qui construit deux registres écrase silencieusement le premier.** D'où `setUpAll` et non `setUp` : un registre par fichier de test, construit une fois.

- [ ] **Step 1: Déclarer les sources et le constructeur de registre**

Dans `lib/services/game_data_service.dart`, ajouter :

```dart
import 'game_data_loader.dart';
```

**Ne retirer aucun import à cette étape.** `_loadJsonList` et `_mapList` sont encore là — c'est la tâche 7 qui les supprime — et les sept imports de modèles servent tous au nouveau `loadGameDataRegistry`. Le nettoyage appartient à la tâche 7 Step 1.

Puis, avant `gameDataLoaderProvider`, ajouter :

```dart
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
```

**Ne pas encore toucher à `gameDataLoaderProvider`** : il lit toujours les catalogues, et le jeu doit continuer de tourner. C'est la tâche 7 qui bascule.

- [ ] **Step 2: Écrire le registre de test du tutoriel, qui échoue**

Remplacer intégralement `test/tutorial/tutorial_test_registry.dart` :

```dart
import 'package:flutter/services.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Registre bati sur les vraies donnees du depot, par le vrai chargeur.
///
/// Les tests du tutoriel utilisent les vraies donnees plutot que des fixtures
/// inventees : c est precisement la fidelite qu on cherche a garantir. Passer
/// par `loadGameDataRegistry` plutot que par `dart:io` ajoute une garantie —
/// ces tests exercent desormais le meme chemin de chargement que
/// l application, motifs de chemin et injection compris.
///
/// **Asynchrone** parce que le chargeur lit le bundle. Les fichiers appelants
/// construisent le registre dans un `setUpAll`, jamais dans un `setUp` :
/// `GameDataRegistry` ecrit un singleton statique dans son constructeur
/// (`game_data_registry.dart:33`), donc deux registres dans un meme fichier
/// se marcheraient dessus.
Future<GameDataRegistry> buildTutorialTestRegistry() =>
    loadGameDataRegistry(rootBundle);
```

- [ ] **Step 3: Adapter les cinq fichiers appelants**

Chaque site passe d'une construction synchrone à une construction unique dans `setUpAll`. `TestWidgetsFlutterBinding.ensureInitialized()` est requis pour que `rootBundle` réponde ; `testWidgets` l'initialise déjà, mais les deux fichiers de `test/tutorial/` sont des tests unitaires et doivent l'appeler.

Dans `test/tutorial/tutorial_engine_test.dart`, ajouter l'import `package:roguelike_card_game/models/data/game_data_registry.dart` et remplacer le bloc `main()` d'ouverture (lignes 9-15) :

```dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry data;
  late TutorialEngine engine;

  // `setUpAll` et non `setUp` : `GameDataRegistry` ecrit un singleton
  // statique dans son constructeur (`game_data_registry.dart:33`), et deux
  // registres construits dans le meme fichier se marcheraient dessus.
  setUpAll(() async {
    data = await buildTutorialTestRegistry();
  });

  setUp(() {
    engine = TutorialEngine(data: data);
    engine.prepareStep(engine.currentStepIndex);
  });
```

Dans `test/tutorial/tutorial_fixtures_test.dart`, même import et même transformation (lignes 8-13) :

```dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry data;
  late TutorialFixtures fixtures;

  setUpAll(() async {
    data = await buildTutorialTestRegistry();
  });

  setUp(() {
    fixtures = TutorialFixtures(data);
  });
```

> **L'assertion `fixtures.heroes.map((h) => h.id)` vaut toujours `['paladin', 'berserker', 'mage']`, et c'est normal.** `TutorialFixtures.heroes` (`lib/tutorial/tutorial_fixtures.dart:49-51`) résout une liste d'ids codée en dur (`:22`) plutôt que de lire l'ordre du registre. Le tri par `id` du chargeur, qui rendrait `berserker, mage, paladin`, ne l'atteint donc pas. **Ne pas « corriger » ce test** : il vérifie une liste de fixtures, pas un ordre d'affichage. Même raison pour `engine.fixtures.heroes.first` (`tutorial_starter_draft_test.dart:18`), qui reste bien le paladin.

Dans `test/widget/tutorial_class_step_test.dart` et `test/widget/tutorial_starter_draft_test.dart`, la construction est dans le helper `_pump`, lui-même déjà `async` — il suffit d'ajouter `await` :

```dart
  final engine = TutorialEngine(data: await buildTutorialTestRegistry());
```

> **Ces deux fichiers construisent un registre par test.** C'est déjà le cas aujourd'hui et les tests passent : chaque `testWidgets` écrase le singleton avec un registre au contenu identique. Ne pas « corriger » cela ici — le passage en `setUpAll` de ces deux fichiers est un changement de structure qui sort du périmètre, et l'écrasement est inoffensif tant que les registres sont identiques.

Dans `test/widget/tutorial_merge_transition_test.dart:59`, la construction est dans l'arbre de widgets. L'extraire avant le `pumpWidget` :

```dart
      final data = await buildTutorialTestRegistry();
      await tester.pumpWidget(
        MaterialApp(
          // …
          home: TutorialScreen(data: data),
        ),
      );
```

- [ ] **Step 4: Lancer les tests du tutoriel**

```bash
flutter test test/tutorial/ test/widget/tutorial_class_step_test.dart test/widget/tutorial_starter_draft_test.dart test/widget/tutorial_merge_transition_test.dart
```

Attendu : **tout au vert, sans qu'aucune assertion n'ait été modifiée.**

C'est le résultat le plus significatif de la tâche : les tests du tutoriel n'ont pas bougé, ils lisent maintenant l'arbre neuf par le vrai chargeur, et ils voient exactement les mêmes données. Si `test/tutorial/tutorial_isolation_test.dart` passe toujours, l'isolation du tutoriel est intacte aussi.

**En cas d'échec sur une carte introuvable** : vérifier que `assets/data/classes/<classe>/cards/` contient bien les deux ids de `HeroData.skills` pour cette classe. C'est le genre de trou que la tâche 8 rendra impossible.

- [ ] **Step 5: Suite complète et analyse**

```bash
flutter test
dart analyze
```

Attendu : **419 au vert** (compte inchangé : aucun test ajouté ni supprimé) et `No issues found!`.

- [ ] **Step 6: Commit**

```bash
git add lib/services/game_data_service.dart test/tutorial/tutorial_test_registry.dart test/tutorial/tutorial_engine_test.dart test/tutorial/tutorial_fixtures_test.dart test/widget/tutorial_class_step_test.dart test/widget/tutorial_starter_draft_test.dart test/widget/tutorial_merge_transition_test.dart
git commit -m "refactor(tutoriel): brancher le registre de test sur le vrai chargeur"
```

---

# Tâche 7 — Basculer l'application et supprimer l'ancien monde

*Effort : 0,5 j. Objectif : que plus rien ne lise les catalogues, et qu'ils disparaissent.*

Le chargeur est écrit, testé sur un bundle factice, et prouvé sur le vrai bundle par les tests du tutoriel. L'arbre neuf est prouvé équivalent à l'ancien. Cette tâche est donc le simple retrait de l'échafaudage.

**Files:**
- Modify: `lib/services/game_data_service.dart:15-50, 78-116` — `_loadJsonList` et `_mapList` supprimés, provider rebranché
- Delete: `assets/data/{cards,hero_cards,relics,events,enemies,heroes,passives,forge_upgrades}.json`
- Delete: `assets/images/{hero_paladin,hero_berserker,hero_mage,enemy_slime,enemy_goblin,enemy_skeleton,enemy_orc}.png`
- Modify: `test/unit/entity_id_convention_test.dart:14-31` — parcourt l'arborescence
- Modify: `test/unit/asset_path_convention_test.dart` — lit l'arborescence
- Modify: `test/unit/audio/audio_catalogue_test.dart:36-59` — lit les 4 catalogues en `dart:io`
- Modify: `test/unit/hero_display_order_test.dart:9, 27` — lit `heroes.json` en `dart:io`

**Interfaces:**
- Consumes: `loadGameDataRegistry` (tâche 6)
- Produces: `gameDataLoaderProvider` reste l'unique entrée publique et rend le même `FutureProvider<GameDataRegistry>`. **Aucune signature publique ne change.**

> **Quatre fichiers de test lisent les catalogues en `dart:io`, pas deux.** Le balayage qui les trouve tous est `grep -rn "assets/data/" test/` : au-delà des deux tests de convention, `audio_catalogue_test.dart` **et** `hero_display_order_test.dart` les lisent aussi, et ne sont pas passés par le chargeur de la tâche 6. Trois tests deviendraient rouges si on les oubliait — dont le seul garde-fou sur les champs `sfx`, c'est-à-dire précisément l'angle mort que l'oracle de §8.2 invoque pour justifier sa forme.

- [ ] **Step 1: Rebrancher le provider**

Dans `lib/services/game_data_service.dart`, supprimer `_loadJsonList` (`:15-26`) et `_mapList` (`:28-50`) — aucun autre appelant, `loadAudioData` n'en utilise aucun — et remplacer le corps du provider par :

```dart
/// Charge et met en cache toutes les donnees du jeu au demarrage.
///
/// Reste l unique entree publique du chargement : `SplashScreen` le resout
/// avant que le moindre ecran de jeu ne soit atteint.
final gameDataLoaderProvider = FutureProvider<GameDataRegistry>(
  (ref) => loadGameDataRegistry(rootBundle),
);
```

Retirer les imports devenus inutiles. `dart:convert` reste (utilisé par `loadAudioData`), `package:flutter/services.dart` reste (`rootBundle`, `AssetBundle`).

- [ ] **Step 2: Supprimer les catalogues et les images d'origine**

```bash
git rm assets/data/cards.json assets/data/hero_cards.json assets/data/relics.json assets/data/events.json assets/data/enemies.json assets/data/heroes.json assets/data/passives.json assets/data/forge_upgrades.json
git rm assets/images/hero_paladin.png assets/images/hero_berserker.png assets/images/hero_mage.png assets/images/enemy_slime.png assets/images/enemy_goblin.png assets/images/enemy_skeleton.png assets/images/enemy_orc.png
```

`assets/images/` ne garde que `bg_dungeon.png` — la seule image qui n'appartient à aucune entité. Le répertoire reste déclaré au pubspec ; `dart run tool/sync_assets.dart --check` doit toujours sortir en 0.

- [ ] **Step 3: Réécrire le test de convention d'ids**

`test/unit/entity_id_convention_test.dart` nomme les huit catalogues, qui n'existent plus. Le remplacer intégralement :

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le nom de fichier EST l id (§6.1 de la spec), sauf pour `class.json` et
/// `enemy.json`, dont l id vient du repertoire parent.
///
/// La casse compte : le poste de dev est Windows (NTFS insensible a la
/// casse), la CI est `ubuntu-latest`, et les cibles web/Android sont
/// sensibles a la casse. Un fichier commite avec une casse divergente passe
/// en local et echoue en CI — et un renommage de pure casse est invisible
/// pour git sous Windows.
const _pattern = r'^[a-z0-9_]+$';

Iterable<File> _entityFiles() sync* {
  for (final entity in Directory('assets/data').listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.json')) continue;
    final name = entity.uri.pathSegments.last;
    // Les deux documents de configuration ne sont pas des entites.
    if (name == 'patch_notes.json' || name == 'audio.json') continue;
    yield entity;
  }
}

String _idOf(File file) {
  final segments = file.uri.pathSegments;
  final name = segments.last;
  if (name == 'class.json' || name == 'enemy.json') {
    return segments[segments.length - 2];
  }
  return name.substring(0, name.length - '.json'.length);
}

void main() {
  test('tous les ids d entites sont en snake_case ASCII minuscule', () {
    final regex = RegExp(_pattern);
    final offenders = <String>[];

    for (final file in _entityFiles()) {
      final id = _idOf(file);
      if (!regex.hasMatch(id)) offenders.add('${file.path} → $id');
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('le nom de fichier est l id, ou le repertoire parent pour class/enemy', () {
    final offenders = <String>[];

    for (final file in _entityFiles()) {
      final declared =
          (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)['id'];
      if (declared == null) continue; // l injection le fournira
      if (declared != _idOf(file)) {
        offenders.add('${file.path} : declare "$declared", attendu "${_idOf(file)}"');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('il y a bien 71 fichiers d entite', () {
    // 17 cartes neutres + 25 reliques + 5 evenements + 8 ameliorations de
    // forge + 3 passifs + 3 class.json + 6 cartes de classe + 4 enemy.json.
    expect(_entityFiles().length, 71);
  });
}
```

- [ ] **Step 4: Adapter le test de chemins d'images**

`test/unit/asset_path_convention_test.dart` lit `heroes.json` et `enemies.json`. Remplacer le corps du `test(...)` par un parcours de l'arborescence :

```dart
  test('tout chemin d image des donnees est complet et designe un fichier existant', () {
    final offenders = <String>[];

    void check(String directory, String field) {
      for (final file in Directory('assets/data/$directory')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))) {
        final entry = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final path = entry[field] as String?;
        if (path == null) continue;
        if (!path.startsWith('assets/')) {
          offenders.add('${file.path} : "$path" n est pas un chemin complet');
        } else if (!File(path).existsSync()) {
          offenders.add('${file.path} : "$path" ne designe aucun fichier');
        }
      }
    }

    check('classes', 'iconPath');
    check('enemies', 'spritePath');

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
```

- [ ] **Step 5: Adapter le garde-fou des champs `sfx`**

`test/unit/audio/audio_catalogue_test.dart:37-42` liste quatre catalogues en dur. Remplacer cette liste par un parcours de l'arborescence, en gardant le reste du test intact :

```dart
    test('tout champ sfx d un JSON de contenu correspond a un son declare', () {
      // Les catalogues ont ete eclates : on parcourt l arborescence plutot
      // que d enumerer des chemins. Les entites qui peuvent porter un `sfx`
      // sont les cartes (neutres et de classe), les ennemis et les reliques ;
      // `AudioSource` n est implemente que par ces trois modeles.
      final contentFiles = [
        ...Directory('assets/data/cards').listSync().whereType<File>(),
        ...Directory('assets/data/relics').listSync().whereType<File>(),
        ...Directory('assets/data/classes')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.replaceAll(r'\', '/').contains('/cards/')),
        ...Directory('assets/data/enemies')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('enemy.json')),
      ].where((f) => f.path.endsWith('.json'));

      final declared = audio.sounds.keys.toSet();
      final offenders = <String>[];

      for (final file in contentFiles) {
        final map =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final sfx = map['sfx'] as String?;
        if (sfx != null && !declared.contains(sfx)) {
          offenders.add('${file.path} :: ${map['id']} -> "$sfx"');
        }
      }

      expect(offenders, isEmpty,
          reason: 'Champs sfx pointant vers un son non declare :\n${offenders.join('\n')}');
    });
```

Vérifier ensuite que `_readJsonList` n'est plus utilisé par aucun autre test du fichier ; s'il est devenu orphelin, le supprimer (`CLAUDE.md` : aucun code mort).

- [ ] **Step 6: Adapter le test de `displayOrder`**

`test/unit/hero_display_order_test.dart` lit `heroes.json` à ses deux tests. Remplacer la lecture par un parcours des dossiers de classe, en gardant les deux assertions telles quelles :

```dart
List<HeroData> _heroes() => Directory('assets/data/classes')
    .listSync()
    .whereType<Directory>()
    .map((d) {
      final json =
          jsonDecode(File('${d.path}/class.json').readAsStringSync())
              as Map<String, dynamic>;
      // L id vient du repertoire parent (§6.1) ; le chargeur l injecte, mais
      // ce test lit le disque directement et doit donc faire de meme.
      json['id'] ??= d.uri.pathSegments[d.uri.pathSegments.length - 2];
      return HeroData.fromJson(json);
    })
    .toList();
```

Puis, dans les deux tests, remplacer les quatre lignes de lecture/décodage par `final heroes = _heroes();`. **Ne toucher à aucune assertion** : `displayOrder` distinct et non nul, et le tri qui rend `paladin, berserker, mage`. Le second reste vrai — il trie par `displayOrder`, pas par `id`.

- [ ] **Step 7: Purger le bundle et tout relancer**

```bash
flutter clean
flutter pub get
flutter test
```

**`flutter clean` est de nouveau obligatoire** : cette tâche supprime 15 fichiers, et `_needsRebuild` ne détecte pas les suppressions. Sans purge, les catalogues supprimés pourraient survivre dans `build/unit_test_assets/` et faire passer les tests sur des données fantômes.

Attendu : **421 au vert** — 419 plus les 2 tests ajoutés au fichier de convention, qui passe de 1 à 3. Les trois tests des étapes 5 et 6 sont réécrits, pas ajoutés : leur nombre ne bouge pas.

L'oracle de la tâche 5 doit rester vert : il lit sa **référence figée**, catalogues et images comprises — c'est exactement pour survivre à cette étape qu'elle a été prise.

```bash
dart analyze
dart run tool/sync_assets.dart --check
```

Attendu : `No issues found!` et sortie 0.

- [ ] **Step 8: Mesurer le coût de démarrage**

Le chargeur fait désormais **72 lectures de bundle** au lieu de 9 (71 entités + `audio.json`). La spec classe le risque « faible » mais demande une mesure **avant fusion**.

```bash
flutter run --profile
```

Chronométrer, dans `SplashScreen`, la résolution de `gameDataLoaderProvider` — au besoin en encadrant l'appel d'un `Stopwatch` temporaire tracé par `debugPrint`, à retirer avant le commit. Consigner la valeur dans le message de commit.

**Si le temps dépasse 200 ms**, paralléliser les huit catégories dans `loadGameDataRegistry` : garder les futures et les attendre ensemble par `Future.wait<Object?>([...])` avant `throwIfFailed()`. Les lectures d'une même catégorie sont déjà parallèles (`Future.wait` dans `loadAll`) ; seules les catégories sont séquentielles.

- [ ] **Step 9: Vérification manuelle**

Aucun agent ne peut faire celle-ci. **Lancer le jeu et vérifier à l'œil** :

- la sélection de classe affiche les trois classes, dans l'ordre `displayOrder`, avec leurs icônes ;
- un combat démarre et les sprites d'ennemis s'affichent ;
- le dictionnaire de cartes liste bien 23 cartes ;
- le tutoriel se déroule jusqu'au bout.

> **Ce n'est pas du confort : c'est la seule couverture du changement d'espace de clés du cache Flame.** Les trois sites qui chargent une image (`heros_draft_game.dart:143`, `enemy_card.dart:75`, `hero_card.dart:114`) ne sont exercés par aucun test — **aucun fichier de `test/` ne construit `HerosDraftGame`**, et les deux tests de la tâche 1 ne vérifient que `images.prefix` et l'identité du cache, jamais un chargement réel. Or `hero_card.dart:114` appelle `fromCache(imagePath)` : si la clé préchargée et la clé demandée divergeaient, l'échec serait une exception au premier rendu du héros, invisible en CI. À inscrire au risque : **le seul filet sur ce point est l'œil du développeur, ici.**

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "refactor(data): basculer le chargement sur les fichiers par entite"
```

---

# Tâche 8 — Les deux tests qui rendent la structure sûre

*Effort : 0,4 j. Objectif : qu'une ligne de pubspec oubliée et qu'un dossier de classe incomplet deviennent des échecs de test.*

Ce sont les deux modes de défaillance que rien d'autre n'attrape :

- **Le pubspec** — comparer le générateur au pubspec ne prouve rien, les deux parcourent le disque. Seul un test qui charge **par le vrai bundle** prouve que l'application voit les fichiers. Il attrape la ligne oubliée, la faute de frappe de chemin **et** la casse.
- **L'intégrité référentielle** — **sans elle, §2.2 n'est pas résolu.** Un dossier de classe sans son `icon.png`, ou dont `skills` désigne une carte absente, est aussi silencieux qu'une entrée manquante l'était dans l'ancien monde.

**Files:**
- Test: `test/unit/real_bundle_load_test.dart` (create)
- Test: `test/unit/referential_integrity_test.dart` (create)

**Interfaces:**
- Consumes: `loadGameDataRegistry` (tâche 6), l'arborescence (tâches 5 et 7)
- Produces: rien de neuf

- [ ] **Step 1: Écrire le test de chargement par le vrai bundle**

Créer `test/unit/real_bundle_load_test.dart` :

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Le SEUL test qui prouve que l application voit reellement les fichiers.
///
/// Un repertoire present mais NON declare au pubspec ne produit aucun
/// message : son contenu se charge en developpement et disparait en build
/// (`flutter_tools/lib/src/asset.dart` — la declaration n est pas recursive,
/// et rien ne signale l omission). Comparer `tool/sync_assets.dart` au
/// pubspec ne prouve rien : les deux parcourent le disque.
///
/// `flutter test` construit le bundle d assets par defaut
/// (`flutter_tools/lib/src/commands/test.dart:412, 486-489`), ce que
/// `test/unit/audio/audio_ui_and_reel_moments_test.dart:22` exerce deja en
/// lisant `assets/data/audio.json` par `rootBundle`. Hypothese gardee : la CI
/// lance `flutter test` nu — `--no-test-assets` ferait echouer ce fichier.
///
/// (Ne pas citer `load_audio_data_test.dart` comme precedent : celui-la
/// SIMULE le canal `flutter/assets` et n atteint jamais le vrai bundle.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le manifeste declare les 71 fichiers d entite, par categorie', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final json = manifest
        .listAssets()
        .where((a) => a.startsWith('assets/data/') && a.endsWith('.json'))
        .toList();

    int countUnder(String prefix, int depth) => json
        .where((a) => a.startsWith(prefix) && a.split('/').length == depth)
        .length;

    expect(countUnder('assets/data/cards/', 4), 17, reason: 'cartes neutres');
    expect(countUnder('assets/data/relics/', 4), 25, reason: 'reliques');
    expect(countUnder('assets/data/events/', 4), 5, reason: 'evenements');
    expect(countUnder('assets/data/forge_upgrades/', 4), 8, reason: 'forge');
    expect(countUnder('assets/data/passives/', 4), 3, reason: 'passifs');

    expect(json.where((a) => a.endsWith('/class.json')).length, 3);
    expect(json.where((a) => a.endsWith('/enemy.json')).length, 4);
    expect(countUnder('assets/data/classes/', 6), 6, reason: 'cartes de classe');

    // Les deux documents de configuration restent a plat.
    expect(json, contains('assets/data/audio.json'));
    expect(json, contains('assets/data/patch_notes.json'));
  });

  test('les images d entites sont declarees, pas seulement presentes', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();

    for (final id in ['paladin', 'berserker', 'mage']) {
      expect(assets, contains('assets/data/classes/$id/icon.png'));
    }
    for (final id in ['slime', 'gobelin', 'squelette', 'orc']) {
      expect(assets, contains('assets/data/enemies/$id/sprite.png'));
    }
    expect(assets, contains('assets/images/bg_dungeon.png'));
  });

  test('le registre se charge entierement depuis le vrai bundle', () async {
    final registry = await loadGameDataRegistry(rootBundle);

    expect(registry.cards, hasLength(23)); // 17 neutres + 6 de classe
    expect(registry.relics, hasLength(25));
    expect(registry.events, hasLength(5));
    expect(registry.forgeUpgrades, hasLength(8));
    expect(registry.passives, hasLength(3));
    expect(registry.heroes, hasLength(3));
    expect(registry.enemies, hasLength(4));

    // Le tri par id est la seule regle qui donne le meme resultat depuis le
    // bundle et depuis le disque : `listAssets()` n offre aucune garantie
    // d ordre.
    final ids = registry.relics.map((r) => r.id).toList();
    expect(ids, orderedEquals(List<String>.of(ids)..sort()));
  });
}
```

- [ ] **Step 2: Écrire le test d'intégrité référentielle**

Créer `test/unit/referential_integrity_test.dart` :

```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Sans ce fichier, le probleme §2.2 de la spec n est pas resolu : un dossier
/// de classe incomplet serait aussi silencieux qu une entree manquante l etait
/// quand la classe vivait eclatee dans quatre fichiers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;

  // `setUpAll` : `GameDataRegistry` ecrit un singleton statique dans son
  // constructeur, donc un seul registre par fichier de test.
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  test('tout passiveTrait designe un passif existant', () {
    final known = registry.passives.map((p) => p.id).toSet();
    final offenders = <String>[];

    for (final hero in registry.heroes) {
      final trait = hero.passiveTrait;
      if (trait == null) continue;
      if (!known.contains(trait)) {
        offenders.add('${hero.id} → passiveTrait "$trait" introuvable');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('toute carte de signature existe et appartient bien a sa classe', () {
    final offenders = <String>[];

    for (final hero in registry.heroes) {
      for (final skillId in hero.skills) {
        final matches = registry.cards.where((c) => c.id == skillId);
        if (matches.isEmpty) {
          offenders.add('${hero.id} → carte "$skillId" introuvable');
          continue;
        }
        final card = matches.single;
        if (card.heroClass != hero.id) {
          offenders.add(
            '${hero.id} → carte "$skillId" rangee sous "${card.heroClass}"',
          );
        }
        if (!File('assets/data/classes/${hero.id}/cards/$skillId.json')
            .existsSync()) {
          offenders.add(
            '${hero.id} → carte "$skillId" absente du dossier de la classe',
          );
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('chaque dossier de classe et d ennemi porte son image', () {
    final offenders = <String>[];

    for (final hero in registry.heroes) {
      final expected = 'assets/data/classes/${hero.id}/icon.png';
      if (hero.iconPath != expected) {
        offenders.add('${hero.id} → iconPath vaut "${hero.iconPath}"');
      }
      if (!File(expected).existsSync()) {
        offenders.add('${hero.id} → $expected manquant');
      }
    }

    for (final enemy in registry.enemies) {
      final expected = 'assets/data/enemies/${enemy.id}/sprite.png';
      if (enemy.spritePath != expected) {
        offenders.add('${enemy.id} → spritePath vaut "${enemy.spritePath}"');
      }
      if (!File(expected).existsSync()) {
        offenders.add('${enemy.id} → $expected manquant');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('chaque dossier de classe contient exactement ses cartes de signature', () {
    // Un dossier `cards/` qui porterait une carte orpheline — non listee dans
    // `skills` — serait chargee dans le pool de la classe sans que rien ne le
    // dise. P-42 y ajoutera un pool plus large ; ce test devra alors changer
    // de forme, pas disparaitre.
    for (final hero in registry.heroes) {
      final onDisk = Directory('assets/data/classes/${hero.id}/cards')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
          .toSet();
      expect(onDisk, hero.skills.toSet(), reason: 'classe ${hero.id}');
    }
  });
}
```

- [ ] **Step 3: Lancer les deux fichiers**

```bash
flutter test test/unit/real_bundle_load_test.dart test/unit/referential_integrity_test.dart
```

Attendu : **7 tests au vert**.

- [ ] **Step 4: Prouver que le test de pubspec mord**

C'est la garantie centrale de la tâche, et elle est contre-intuitive : il faut vérifier qu'un dossier **non déclaré** est bien détecté.

1. Retirer à la main la ligne `    - assets/data/relics/` du pubspec.
2. `flutter clean && flutter test test/unit/real_bundle_load_test.dart`
3. Le test *« le manifeste declare les 71 fichiers d entite »* **doit** échouer sur `reliques`, avec 0 au lieu de 25.
4. Rétablir la ligne (ou `dart run tool/sync_assets.dart`), puis `flutter clean` de nouveau.

**Si le test passe malgré la ligne retirée, c'est que le bundle de test est périmé** : refaire `flutter clean`. Ne pas conclure avant d'avoir vu l'échec.

- [ ] **Step 5: Prouver que le test d'intégrité mord**

Renommer temporairement `assets/data/classes/paladin/icon.png` en `icon.png.bak`, lancer `flutter test test/unit/referential_integrity_test.dart` : *« chaque dossier de classe et d ennemi porte son image »* **doit** échouer. Rétablir.

- [ ] **Step 6: Suite complète et analyse**

```bash
flutter test
dart analyze
```

Attendu : **428 au vert** (421 + 7) et `No issues found!`.

- [ ] **Step 7: Commit**

```bash
git add test/unit/real_bundle_load_test.dart test/unit/referential_integrity_test.dart
git commit -m "test(data): garantir le pubspec synchronise et l integrite des dossiers"
```

---

# Tâche 9 — Durcir l'autorité du répertoire

*Effort : 0,25 j. Objectif : que le répertoire soit la seule source d'appartenance, pour de bon.*

La tolérance « le JSON peut confirmer » servait **pendant** la migration : elle a laissé passer tels quels les `category` des 17 cartes neutres et les `heroClass` + `category` des 6 cartes de classe. Elle a fait son travail.

**Sans ce durcissement, chaque carte de P-42 porterait deux champs redondants que le chargeur écrase** — et un jour, l'un d'eux divergerait.

L'`id` reste redéclarable (décision D-P3) : le porter dans le fichier le rend lisible hors contexte et inspectable en masse.

**Files:**
- Delete: `test/migration/` — l'oracle et sa référence figée
- Modify: `lib/services/game_data_service.dart` — `redundantFields` des deux sources de cartes
- Modify: 23 fichiers de cartes — `heroClass` et `category` retirés
- Modify: `test/unit/game_data_loader_injection_test.dart` — un test de plus

**Interfaces:**
- Consumes: tout ce qui précède
- Produces: déclarer `heroClass` ou `category` dans un fichier de carte fait échouer le chargement

- [ ] **Step 1: Retirer l'oracle, qui a fini son travail**

```bash
git rm -r test/migration
```

**L'oracle doit partir avant ce durcissement, pas être adapté à lui.** Sa mission était de prouver l'équivalence au moment où elle pouvait encore être fausse : c'est fait en tâche 5, et confirmé vert à travers les tâches 6, 7 et 8, qui n'ont touché à aucun contenu. Cette tâche-ci, elle, **change délibérément le contenu** — elle retire un champ de 23 fichiers. L'oracle le signalerait comme une perte, et l'assouplir pour qu'il se taise reviendrait à affaiblir le filet de sécurité pour arranger le changement qu'il est censé surveiller.

Le garder plus longtemps serait de toute façon un piège : il fait vivre une copie figée des données, qui divergerait au premier ajout de contenu.

```bash
flutter test
```

Attendu : **422 au vert** (428 − les 6 tests de l oracle).

- [ ] **Step 2: Écrire le test qui échoue**

Ajouter à `test/unit/game_data_loader_injection_test.dart`, dans le groupe *« Autorite du repertoire »* :

```dart
    test('un champ hors redundantFields est interdit, meme s il est juste', () {
      // Expiration de la tolerance : pendant la migration, redeclarer
      // `owner: paladin` sous `classes/paladin/` etait tolere. Ce n est plus
      // une confirmation utile, c est une seconde verite en attente de
      // diverger.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/classes/paladin/things/smite.json': '{"owner":"paladin"}',
      }));

      return loader.loadAll<Thing>([
        EntitySource(
          'assets/data/classes/*/things/*.json',
          Thing.fromJson,
          inject: (c) => {'id': c[1], 'owner': c[0], 'category': 'owned'},
          // `id` seul reste redeclarable.
        ),
      ]).then((_) {
        expect(
          () => loader.throwIfFailed(),
          throwsA(predicate((e) {
            final message = e.toString();
            return message.contains('smite.json') &&
                message.contains('impose par le repertoire') &&
                message.contains('owner');
          })),
        );
      });
    });
```

- [ ] **Step 3: Lancer le test**

```bash
flutter test test/unit/game_data_loader_injection_test.dart
```

Attendu : **8 tests au vert** — le code de `_applyInjection` gère déjà ce cas depuis la tâche 2 ; ce test n'a simplement jamais été écrit. Si l'un des 8 échoue, c'est le chargeur qui est faux, pas le test.

- [ ] **Step 4: Dépouiller les 23 fichiers de cartes**

Pas de script : 23 fichiers ne justifient pas un outil, et `tool/` ne doit garder que `sync_assets.dart`. À la main, ou par une boucle jetable non commitée.

- dans les **17** fichiers de `assets/data/cards/`, retirer la ligne `"category": "global",` ;
- dans les **6** fichiers de `assets/data/classes/*/cards/`, retirer `"heroClass": "…",` **et** `"category": "characterSpecific",`.

**Ne rien retirer d'autre.** En particulier, `"id"` reste dans les 23 fichiers.

Vérifier :

```bash
grep -rl '"heroClass"\|"category"' assets/data/cards/ assets/data/classes/
```

Attendu : **aucune sortie**.

- [ ] **Step 5: Retirer la tolérance dans les sources**

Dans `lib/services/game_data_service.dart`, les deux `EntitySource` de cartes perdent leur `redundantFields` explicite et retombent sur la valeur par défaut `const {'id'}` :

```dart
  final cards = await loader.loadAll<CardData>([
    EntitySource(
      'assets/data/cards/*.json',
      CardData.fromJson,
      inject: (c) => {'id': c[0], 'category': 'global'},
    ),
    EntitySource(
      'assets/data/classes/*/cards/*.json',
      CardData.fromJson,
      inject: (c) => {
        'id': c[1],
        'heroClass': c[0],
        'category': 'characterSpecific',
      },
    ),
  ]);
```

Mettre à jour le commentaire qui précède : la tolérance a expiré, `id` seul reste redéclarable.

- [ ] **Step 6: Vérifier que le durcissement mord sur les vraies données**

Remettre `"category": "global",` dans un fichier de `assets/data/cards/`, puis :

```bash
flutter test test/unit/real_bundle_load_test.dart
```

Le test *« le registre se charge entierement depuis le vrai bundle »* **doit** échouer, en nommant le fichier et le champ. Retirer la ligne.

- [ ] **Step 7: Suite complète et analyse**

```bash
flutter clean
flutter pub get
flutter test
dart analyze
```

Attendu : **423 au vert** (422 + le test de durcissement) et `No issues found!`.

`flutter clean` parce que cette étape a modifié 23 fichiers d'assets et supprimé un répertoire de test : le bundle de test ne détecte pas les suppressions.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "refactor(data): faire expirer la tolerance de champ redondant"
```

---

# Tâche 10 — Retirer l'échafaudage et écrire la documentation

*Effort : 0,5 j. Objectif : que la documentation décrive la structure qui existe, et que rien de temporaire ne survive à la fusion.*

`CLAUDE.md` pose « One question, one place ». **Laisser ADR-003 décrire une structure abolie viole cette règle plus sûrement que de ne rien écrire** : il énumère nommément les 8 fichiers JSON, décrit un `GameDataService.loadAll()` qui n'existe déjà plus, et ses comptes sont déjà faux (15 cartes, 2 événements, 12 reliques).

**Files:**
- Delete: `tool/split_catalogues.dart`
- Create: `.obsidian_vault/_adr/ADR-0XX-*` — deux ADR neufs
- Modify: `.obsidian_vault/_adr/ADR-003-architecture-100-data-driven.md`
- Create: `.obsidian_vault/_patterns/` — une fiche pour le chargeur
- Modify: `docs/ROADMAP.md:257, 279-298` — P-48 livré
- Modify: `docs/INDEX.md:45` — l'entrée du plan du lot 3 passe à « livré »
- Modify: `CLAUDE.md` — « Data-Driven Content Workflow » et « Data layer »
- Modify: `.claude/skills/memory-bank-sync/SKILL.md:46` — la métrique
- Modify: `.agents/skills/game_designer.md:12` — la liste des catalogues

**Interfaces:**
- Consumes: tout ce qui précède
- Produces: rien de fonctionnel

- [ ] **Step 1: Supprimer l'échafaudage**

```bash
git rm tool/split_catalogues.dart
```

Le script de découpage était commité pour être auditable en revue — le diff porte sur lui plutôt que sur les 71 fichiers qu'il a produits. Il a fait son travail, et le relancer sur l'arbre migré n'aurait aucun sens : il lirait des catalogues qui n'existent plus.

**`tool/sync_assets.dart` reste.** C'est le seul survivant de `tool/`, et il est appelé par un test. *(L'oracle et sa référence figée sont partis en tâche 9, avant le durcissement qu'ils auraient signalé à tort.)*

- [ ] **Step 2: Suite complète après suppression**

```bash
flutter test
dart analyze
```

Attendu : **423 au vert** (compte inchangé — le script supprimé n'était couvert par aucun test) et `No issues found!`.

- [ ] **Step 3: Amender ADR-003**

Dans `.obsidian_vault/_adr/ADR-003-architecture-100-data-driven.md`, remplacer l'énumération des 8 fichiers et la mention de `GameDataService.loadAll()` par un renvoi à la nouvelle structure et au nouveau chargeur. **Ne pas y recopier les chiffres** : ils vivent dans `_memory_bank/progress.md`, qui les re-mesure. Un ADR dit *pourquoi*, pas *combien*.

- [ ] **Step 4: Écrire les deux ADR neufs, et reporter dans la spec les trois écarts du plan**

**D'abord les écarts, parce que c'est ce qu'on oublie.** Le plan s'écarte de la spec sur trois points, chacun argumenté sur place mais **aucun encore inscrit dans la spec**. Les laisser diverger ferait de la spec et du plan deux vérités contradictoires sur le même sujet — la violation exacte de « One question, one place ».

| Écart | Ce que dit la spec | Ce qu'a fait le plan |
|:---|:---|:---|
| **D-P2** | Le tableau §5.2 n'injecte l'`id` que pour `class.json` et `enemy.json` | L'`id` est injecté pour **toutes** les catégories, depuis le nom de fichier — un chargeur générique ne peut pas lire `.id` sur un `T` inconnu |
| **D-P3** | « Expiration » de §5.2 : déclarer un champ injecté devient une erreur | Vrai pour `heroClass` et `category` ; **`id` reste redéclarable à titre permanent** |
| **§8.1** | Le script « déplace et renomme les images … et supprime les anciens fichiers » | Les images sont **copiées** en tâche 5, supprimées en tâche 7 — c'est ce qui permet à chaque tâche de finir au vert |

Amender §5.2, §6.1 et §8.1 de la spec en conséquence, et mettre son statut à *livré*.

Puis les deux ADR. Numérotation attribuée par la skill `memory-bank-sync` — ne pas l'inventer.

1. **La règle de partage catalogue / configuration.** Un fichier de `assets/data/` est *découpé* s'il est un catalogue d'entités interchangeables ; il *reste à plat* s'il est un document de configuration unique. `patch_notes.json` (l'ordre du tableau **est** la sémantique : index 0 = version courante, et cinq scripts de `.github/scripts/` plus `site/_site/js/model.js` en dépendent) et `audio.json` tombent du second côté.
2. **L'autorité du répertoire, option C, avec expiration.** Le répertoire injecte, le JSON pouvait confirmer, la contradiction échoue — et la tolérance a expiré à la tâche 9. Consigner pourquoi les passifs en sont exclus (décision D4 : `PassiveData` n'a pas de `heroClass`, l'injection serait un no-op indétectable) et pourquoi `id` reste redéclarable (D-P3).

- [ ] **Step 5: Écrire la fiche de pattern**

Créer une fiche dans `.obsidian_vault/_patterns/` décrivant `GameDataLoader`, `EntitySource` et le motif de chemin : le `*` qui vaut un segment, le comptage de segments qui sépare `class.json` de `cards/*.json` et écarte les assets de paquets, l'agrégation d'erreurs, et le `bundle` en paramètre comme seam de test.

L'indexer dans `_memory_bank/systemPatterns.md`. **Ne jamais réinliner le contenu de la fiche dans son index** — c'est la règle des trois index de `CLAUDE.md`.

- [ ] **Step 6: Corriger la métrique de `memory-bank-sync`**

`.claude/skills/memory-bank-sync/SKILL.md:46` mesure « Fichiers de données » par `ls assets/data/*.json | wc -l`. Cette commande rendait 10 ; elle rend maintenant **2**. La skill re-mesure avant d'écrire : **sans correction, elle publiera un chiffre juste et trompeur.**

Remplacer par une commande qui compte ce qu'on veut vraiment savoir :

```bash
find assets/data -name '*.json' | wc -l
```

- [ ] **Step 7: Mettre à jour `CLAUDE.md`**

- **« Data-Driven Content Workflow »** décrit aujourd'hui le fichier unique à éditer. Le remplacer par : créer un fichier dans le bon répertoire, puis lancer `dart run tool/sync_assets.dart`. Mentionner que pour une classe ou un ennemi, c'est un **dossier** qu'on crée, image comprise.
- **« Data layer »** nomme encore `skill_data.dart`, supprimé par le bloc 1 de P-40.
- Ajouter `tool/` à la carte d'architecture : un seul script, générateur de la section `assets:`.

- [ ] **Step 8: Mettre à jour `.agents/skills/game_designer.md`**

Ligne 12 : l'énumération des catalogues, `skills.json` compris. La remplacer par une description de la nouvelle structure.

- [ ] **Step 9: Mettre à jour la ROADMAP et l'INDEX**

Dans `docs/ROADMAP.md` :
- ligne 257 : retirer *« lots 1 et 2 livrés »* et *« ~4,5 j (lot 3 restant) »*, marquer **P-48 livré** ;
- ligne **294** : la ligne du lot 3 passe à ✅ **livré le YYYY-MM-DD** *(289-293 sont l'en-tête du tableau et les lots 1 et 2, déjà à jour)* ;
- noter que **P-42 doit désormais écrire ses cartes directement dans `assets/data/classes/<id>/cards/`**, un fichier par carte, sans `heroClass` ni `category`.

Dans `docs/INDEX.md`, **ligne 45** : le plan du lot 3 y est déjà indexé sous « Héros, classes & cartes » — il ne s'agit que de remplacer la mention *« (la migration ; à exécuter) »* par *« (livré) »*. La ligne 44, celle des lots 1-2, est déjà correcte.

- [ ] **Step 10: Vérification finale complète**

```bash
flutter clean
flutter pub get
dart analyze --fatal-infos
flutter test
dart run tool/sync_assets.dart --check
```

Attendu : `No issues found!`, **423 au vert**, sortie 0.

```bash
find assets/data -name '*.json' | wc -l   # → 73
ls assets/images/                          # → bg_dungeon.png, seul
ls tool/                                   # → sync_assets.dart, seul
git status --short                         # → propre (voir la note l10n plus bas)
```

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "docs(reorg): documenter la nouvelle structure et retirer l echafaudage"
```

---

## Checklist de sortie

À vérifier avant d'ouvrir la PR. Chaque ligne fausse est un motif de ne pas ouvrir.

- [ ] `dart analyze --fatal-infos` → `No issues found!`
- [ ] `flutter test` → **423 au vert**, après un `flutter clean` *(le compte exact est à consigner ; l'invariant est qu'aucun test existant n'a disparu sans justification écrite)*
- [ ] `dart run tool/sync_assets.dart --check` → sortie 0
- [ ] `find assets/data -name '*.json' | wc -l` → **73**
- [ ] `assets/images/` ne contient plus que `bg_dungeon.png`
- [ ] `tool/` ne contient plus que `sync_assets.dart`
- [ ] `test/migration/` n'existe plus
- [ ] `git status --short` est propre. *`lib/l10n/app_localizations*.dart` peuvent apparaître ` M` après un `flutter clean` (`generate: true` les régénère) : confirmer avec `git diff` que le contenu est identique avant de conclure à une dérive.*
- [ ] Aucun fichier de `assets/data/cards/` ou `assets/data/classes/*/cards/` ne porte `heroClass` ou `category`
- [ ] Les **dix** mutations de preuve ont été exécutées et **ont fait échouer** le test visé : préfixe Flame (t.1), tri par id (t.2), contradiction d'injection (t.3), `--check` du pubspec (t.4), les **trois** de l'oracle (t.5), ligne de pubspec retirée (t.8), image de classe manquante (t.8), champ redondant réintroduit (t.9)
- [ ] Le coût de démarrage a été mesuré et consigné (t.7 step 8)
- [ ] **Le jeu a été lancé et vérifié à l'œil** : sélection de classe avec icônes, combat avec sprites, dictionnaire à 23 cartes, tutoriel complet *(aucun agent ne peut faire cette vérification)*
- [ ] ADR-003 ne décrit plus les 8 catalogues
- [ ] `.claude/skills/memory-bank-sync/SKILL.md` ne mesure plus les données par `ls assets/data/*.json`
- [ ] `CLAUDE.md` décrit la création d'un fichier et l'appel au générateur

## Hors périmètre

Rappelé ici parce que ce sont les tentations les plus probables en cours de route.

- **P-26** — `GameDataRegistry` en `Map<String, T>` (décision D-P1).
- **Les cinq `toJson()` manquants** (`RelicData`, `HeroData`, `PassiveData`, `EnemyData`, `EventData`). L'oracle compare du JSON brut précisément pour ne pas en avoir besoin. Ils restent un prérequis du devtool d'édition, qui les paiera avec ses propres tests de round-trip.
- **Le devtool d'édition de contenu** — chantier suivant, `kDebugMode` uniquement.
- **P-30** (menu de triche), **P-41** et **P-42**. Ce chantier construit l'infrastructure des pools par classe ; il n'en écrit pas le contenu.
- **Le correctif « tirer un `id` plutôt qu'un index »** dans `relic_exchange_screen.dart:142` *(le tirage lui-même ; le `Random(seed)` qui l'alimente est à `:125`)*. Conséquence assumée : une run reprise après migration verra une autre relique au même nœud — non parce que la sauvegarde la mémorise, mais parce qu'elle ne la mémorise pas.
- **P-40 blocs 2 et 3** — trois bugs de gameplay et dix dérives documentaires.
- **Toute modification d'équilibrage.**
- **Le patch note** — décision du propriétaire du projet ; si elle est prise, elle passe par la skill `patch-notes-writer`, qui fait bouger ensemble `patch_notes.json`, `pubspec.yaml` et `site/_site/versions.json`.
