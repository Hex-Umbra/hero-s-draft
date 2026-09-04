# Réorganisation des données — lots 1 et 2 — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Supprimer les quatre replis codés en dur qui masquent les défaillances de chargement, puis rendre explicite tout ordre d'affichage aujourd'hui hérité par accident de l'ordre des catalogues JSON.

**Architecture:** Deux lots de correctifs, livrables indépendamment et **avant** la migration des données (lot 3, planifié séparément). Le lot 1 fait porter au registre la liste des images à précharger, ce qui supprime un second chargeur de JSON en doublon et trois replis d'images en dur, plus `PassiveData.fallback()`. Le lot 2 rend explicites quatre ordres d'affichage et supprime quatre replis silencieux, ce qui retire au tri par `id` du lot 3 toute conséquence observable.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11.4, Flame 1.37.0, Riverpod 2.x (`Notifier`/`NotifierProvider`), `flutter_test`.

**Spec:** [`docs/superpowers/specs/2026-09-04-reorganisation-donnees-un-fichier-par-entite-design.md`](../specs/2026-09-04-reorganisation-donnees-un-fichier-par-entite-design.md) — lire §2 (le problème), §3.2 (le découpage en lots), §5.3 (les surfaces sensibles à l'ordre) et §3.3 (la casse de sauvegarde assumée).

## Global Constraints

- **Branche de départ** : `refactor/p40-purge-chaine-skills` (commit `ced306e`). Tous les numéros de ligne de ce plan s'y réfèrent. Ne pas partir de `main` : P-40 bloc 1 est un prérequis.
- **Après chaque tâche** : `dart analyze` doit rendre `No issues found!` — c'est une règle de `CLAUDE.md`, pas une préférence.
- **Référence de tests** : **377 au vert** au départ. Chaque tâche indique le compte attendu après elle.
- **Aucun code mort, aucun import inutilisé, aucun bloc commenté** dans le code commité (`CLAUDE.md`).
- **Ne jamais toucher `applyLifestealBuff`** (`lib/game/controllers/run/player_stats_manager.dart:475`, `lib/game/controllers/run_controller.dart:442`). Elle est sans appelant depuis P-40 et réservée à P-41. La supprimer est une régression.
- **Ne jamais confondre `HeroData.skills` avec la chaîne `SkillData` supprimée par P-40.** `HeroData.skills` (`lib/models/data/hero_data.dart:14`) porte les ids des cartes de signature d'une classe et est bien vivante.
- **Bilinguisme** : toute entrée JSON à texte visible porte ses variantes `_fr` et `_en`.
- Messages de commit en français, conventional commits, **sans accents dans le sujet** (convention du dépôt).

---

## File Structure

| Fichier | Responsabilité après ce plan |
|:---|:---|
| `lib/models/data/game_data_registry.dart` | **Modifié** — expose `imagesToPreload`, seule source de la liste d'images du jeu |
| `lib/game/heros_draft_game.dart` | **Modifié** — reçoit la liste au constructeur ; ne lit plus jamais de JSON |
| `lib/game/systems/state_sync_system.dart` | **Modifié** — ne fabrique plus de héros de repli |
| `lib/game/components/entities/enemy_card.dart` | **Modifié** — ne fabrique plus de sprite de repli |
| `lib/models/data/passive_data.dart` | **Modifié** — `fallback()` supprimé ; `getById()` reste la seule voie de résolution |
| `lib/game/systems/trait_system.dart` | **Modifié** — un passif absent n'applique aucun effet |
| `lib/models/data/hero_data.dart` | **Modifié** — gagne `displayOrder` |
| `lib/ui/screens/card_dictionary_screen.dart` | **Modifié** — ordre d'affichage explicite, indépendant du catalogue |
| `lib/ui/screens/class_selection_screen.dart` | **Modifié** — trie par `displayOrder` |
| `lib/ui/screens/starter_deck_draft_screen.dart` | **Modifié** — pool trié explicitement |
| `lib/models/data/hero_skills_link.dart` | **Modifié** — une carte de signature absente n'est plus avalée |
| `assets/data/heroes.json`, `assets/data/passives.json` | **Modifiés** — `displayOrder`, ids en `snake_case` |
| `test/unit/game_data_registry_preload_test.dart` | **Créé** — garantit la complétude de la liste de préchargement |
| `test/unit/passive_absent_test.dart` | **Créé** — garantit qu'un passif absent est inerte |
| `test/unit/entity_id_convention_test.dart` | **Créé** — garantit la convention `snake_case` sur tous les ids |
| `test/widget/card_dictionary_order_test.dart` | **Créé** — garantit un ordre d'affichage indépendant du catalogue |
| `test/unit/hero_display_order_test.dart` | **Créé** — garantit que chaque classe a un `displayOrder` distinct |
| `test/unit/hero_skills_link_test.dart` | **Créé** — garantit qu'une carte de signature absente lève |

---

# LOT 1 — Supprimer les quatre replis codés en dur

*Effort : 1 jour. Objectif : plus aucun chemin de code ne fabrique une donnée par défaut pour masquer une donnée manquante.*

---

### Task 1: Exposer la liste de préchargement sur le registre

`HerosDraftGame` relit aujourd'hui `enemies.json` et `heroes.json` **une seconde fois** juste pour collecter les chemins d'images. Le registre a déjà ces données ; il doit les exposer.

**Files:**
- Modify: `lib/models/data/game_data_registry.dart`
- Test: `test/unit/game_data_registry_preload_test.dart` (create)

**Interfaces:**
- Consumes: rien
- Produces: `List<String> GameDataRegistry.imagesToPreload` — getter calculé, jamais un champ de constructeur (18 sites de `test/` construisent `GameDataRegistry(...)` ; un champ requis les casserait tous). Rend les `iconPath` des héros et les `spritePath` des ennemis, sans doublon, hors chaînes vides.

- [ ] **Step 1: Write the failing test**

Créer `test/unit/game_data_registry_preload_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  group('GameDataRegistry.imagesToPreload', () {
    test('collects hero icons and enemy sprites without duplicates', () {
      final registry = GameDataRegistry(
        enemies: const [
          EnemyData(
            id: 'slime',
            maxHp: 18,
            baseDamage: 4,
            spritePath: 'enemy_slime.png',
          ),
          EnemyData(
            id: 'slime_clone',
            maxHp: 18,
            baseDamage: 4,
            spritePath: 'enemy_slime.png',
          ),
        ],
        heroes: const [
          HeroData(
            id: 'paladin',
            iconPath: 'hero_paladin.png',
            maxHp: 100,
            maxMana: 3,
            baseDamage: 5,
          ),
        ],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [],
      );

      expect(
        registry.imagesToPreload,
        unorderedEquals(['hero_paladin.png', 'enemy_slime.png']),
      );
    });

    test('skips empty paths', () {
      final registry = GameDataRegistry(
        enemies: const [
          EnemyData(id: 'ghost', maxHp: 1, baseDamage: 1, spritePath: ''),
        ],
        heroes: const [
          HeroData(
            id: 'nobody',
            iconPath: '',
            maxHp: 1,
            maxMana: 1,
            baseDamage: 1,
          ),
        ],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [],
      );

      expect(registry.imagesToPreload, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/game_data_registry_preload_test.dart`
Expected: FAIL — `The getter 'imagesToPreload' isn't defined for the type 'GameDataRegistry'`.

- [ ] **Step 3: Write minimal implementation**

Dans `lib/models/data/game_data_registry.dart`, ajouter le getter juste après le champ `audio` :

```dart
  /// Les chemins d'images référencés par les entités chargées.
  ///
  /// Unique source de la liste de préchargement de Flame : avant, la couche
  /// de rendu relisait `enemies.json` et `heroes.json` pour la reconstituer.
  /// C'est un getter calculé et non un champ de constructeur, pour ne pas
  /// casser les dizaines de `GameDataRegistry(...)` construits par les tests.
  List<String> get imagesToPreload => <String>{
        ...heroes.map((h) => h.iconPath),
        ...enemies.map((e) => e.spritePath),
      }.where((path) => path.isNotEmpty).toList();
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/game_data_registry_preload_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Vérifier l'analyseur et la suite complète**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: **379 tests** au vert (377 + les 2 nouveaux).

- [ ] **Step 6: Commit**

```bash
git add lib/models/data/game_data_registry.dart test/unit/game_data_registry_preload_test.dart
git commit -m "feat(data): exposer la liste des images a precharger sur le registre"
```

---

### Task 2: Supprimer le chargeur de JSON en doublon dans la couche Flame

**Files:**
- Modify: `lib/game/heros_draft_game.dart` (bloc `133-172`, champ + constructeur, imports)
- Modify: `lib/ui/screens/game_screen.dart:254`

**Interfaces:**
- Consumes: `GameDataRegistry.imagesToPreload` (Task 1)
- Produces: `HerosDraftGame({required List<String> imagesToPreload, ...})` — nouveau paramètre nommé requis, à placer juste après `audio`.

> **Pourquoi le constructeur et pas un champ affecté plus tard.** `_game.availableEnemies` et `_game.availableHeroes` sont affectés dans `build()` (`game_screen.dart:417-418`), soit **après** que `onLoad()` a déjà préchargé — c'est très exactement la raison d'être du chargeur en doublon. La donnée est en revanche disponible dès `initState` : `SplashScreen` a résolu `gameDataLoaderProvider`, qui n'est pas `autoDispose`, et `game_screen.dart:73, 150, 236` lisent déjà le registre ainsi.

- [ ] **Step 1: Ajouter le paramètre au constructeur**

Dans `lib/game/heros_draft_game.dart`, à côté du champ `audio`, ajouter :

```dart
  /// Les images à charger avant le premier rendu. Fournie par le registre
  /// (`GameDataRegistry.imagesToPreload`) : la couche de rendu ne lit jamais
  /// de JSON elle-même.
  final List<String> imagesToPreload;
```

et dans la liste des paramètres du constructeur, juste après `required this.audio,` :

```dart
    required this.imagesToPreload,
```

- [ ] **Step 2: Remplacer le bloc de chargement**

Toujours dans `lib/game/heros_draft_game.dart`, remplacer **tout** le bloc des lignes 133 à 171 (de `final List<String> imagesToPreload = ['bg_dungeon.png'];` jusqu'à `await images.loadAll(uniqueImages);` inclus) par :

```dart
    final uniqueImages = <String>{
      'bg_dungeon.png',
      ...imagesToPreload,
    }.toList();
    await images.loadAll(uniqueImages);
```

- [ ] **Step 3: Nettoyer les imports devenus inutiles**

`rootBundle` et `jsonDecode` n'étaient utilisés que par le bloc supprimé. Retirer de `lib/game/heros_draft_game.dart` :

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
```

Vérifier **dans l'arbre de travail**, après l'édition du Step 2 : `grep -n "jsonDecode\|rootBundle" lib/game/heros_draft_game.dart` ne doit renvoyer aucune ligne. (Ne pas interroger `git show ced306e:` — ce serait la version d'avant l'édition.)

- [ ] **Step 4: Brancher l'appelant**

Dans `lib/ui/screens/game_screen.dart`, à la construction du jeu (ligne 254, `_game = HerosDraftGame(`), ajouter le paramètre juste après `audio:` :

```dart
      imagesToPreload:
          ref.read(gameDataLoaderProvider).requireValue.imagesToPreload,
```

- [ ] **Step 5: Vérifier**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: **379 tests** au vert. Aucun test ne construit `HerosDraftGame` ni `GameScreen`, donc le compte ne bouge pas.

- [ ] **Step 6: Commit**

```bash
git add lib/game/heros_draft_game.dart lib/ui/screens/game_screen.dart
git commit -m "refactor(game): supprimer le second chargeur de JSON de la couche Flame

La liste de prechargement vient desormais du registre, passee au
constructeur. Supprime avec le bloc son catch qui retombait sur une liste
d'images codee en dur : toute evolution du format cassait ce chargeur sans
la moindre erreur visible, et le jeu demarrait avec des sprites manquants."
```

---

### Task 3: Supprimer les deux replis d'images codés en dur

**Files:**
- Modify: `lib/game/systems/state_sync_system.dart:41-50`
- Modify: `lib/game/components/entities/enemy_card.dart:72-73`

**Interfaces:**
- Consumes: rien
- Produces: rien

> **Écart assumé avec la spec.** §9 range `state_sync_system.dart:42` (repli d'image) au lot 1 et `:46` (repli `.first`) au lot 2. Les deux lignes sont dans le **même bloc `if`, à quatre lignes d'écart** : les séparer imposerait d'éditer ce bloc deux fois et laisserait un état intermédiaire incohérent. Les deux sont donc traitées ici.

- [ ] **Step 1: Réécrire le bloc de `state_sync_system.dart`**

Remplacer les lignes 41 à 50 (de `if (game.heroCard == null) {` jusqu'à la fermeture du `if (game.availableHeroes.isNotEmpty)`) par :

```dart
    if (game.heroCard == null) {
      // Pas de repli : un héros introuvable est un bug de données, pas un cas
      // à masquer. Le lot 3 ajoutera un test d'intégrité référentielle qui
      // rend la situation impossible.
      final heroData = game.availableHeroes.firstWhere(
        (h) => h.id == state.heroClassId,
      );

      game.heroCard = HeroCard(
        state.heroStats,
        bonusAttack: bonusAtt,
        imagePath: heroData.iconPath,
      );
```

Ne pas toucher aux lignes suivantes (`game.heroCard!.position = ...` et la suite).

- [ ] **Step 2: Supprimer le repli de `enemy_card.dart`**

Remplacer les lignes 72-73 :

```dart
    String spriteName = data.spritePath;
    if (spriteName.isEmpty) spriteName = 'enemy_goblin.png';
```

par :

```dart
    final spriteName = data.spritePath;
```

- [ ] **Step 3: Vérifier**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: **379 tests** au vert.

- [ ] **Step 4: Commit**

```bash
git add lib/game/systems/state_sync_system.dart lib/game/components/entities/enemy_card.dart
git commit -m "refactor(game): supprimer les replis d'images codes en dur

Un heros ou un sprite introuvable est un bug de donnees. Le masquer par un
'hero_paladin.png' ou un 'enemy_goblin.png' code en dur transformait une
erreur de contenu en mauvais rendu silencieux."
```

---

### Task 4: Rendre un passif absent inerte — côté moteur

`PassiveData.fallback()` duplique les trois passifs **en dur en Dart** (`passive_data.dart:67-120`), en plus de `passives.json`. C'est le même anti-pattern que les replis d'images, avec **7 points d'appel dans 5 fichiers**.

**Files:**
- Modify: `lib/game/systems/trait_system.dart` (3 sites : lignes 10-12, 36-38, 52-54)
- Modify: `lib/game/controllers/run_controller.dart` (3 sites : lignes 169, 216, 250)
- Test: `test/unit/passive_absent_test.dart` (create)

**Interfaces:**
- Consumes: `RunState.activePassive` — déjà de type `PassiveData?` (`run_controller.dart:27`), aucun changement de type nécessaire
- Produces: garantie que `TraitSystem.onTurnStart/onTurnEnd/onCardPlayed` ne fait rien quand `activePassive` est `null`

- [ ] **Step 1: Write the failing test**

Créer `test/unit/passive_absent_test.dart` :

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/trait_system.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  test('un passif absent n applique aucun effet', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Un héros dont le passiveTrait ne désigne aucun passif chargé.
    const orphan = HeroData(
      id: 'orphan',
      iconPath: 'hero_paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      passiveTrait: 'inexistant',
    );

    final controller = container.read(runProvider.notifier);
    controller.startNewRun(orphan);

    final armorBefore = controller.currentState.heroStats.armure;
    TraitSystem.onTurnStart(controller);
    TraitSystem.onTurnEnd(controller);

    expect(controller.currentState.activePassive, isNull);
    expect(controller.currentState.heroStats.armure, armorBefore);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/passive_absent_test.dart`
Expected: FAIL — `activePassive` n'est pas `null` : `startNewRun` le remplit avec `PassiveData.fallback('inexistant')`, qui rend le passif dégradé `id: 'none'`.

- [ ] **Step 3: Supprimer les replis de `trait_system.dart`**

Aux **trois** endroits (`onTurnStart`, `onTurnEnd`, `onCardPlayed`), remplacer :

```dart
    final passive =
        controller.currentState.activePassive ??
        PassiveData.fallback(controller.currentState.passiveTrait ?? '');
    final stats = controller.currentState.heroStats;
```

par :

```dart
    final passive = controller.currentState.activePassive;
    if (passive == null) return;
    final stats = controller.currentState.heroStats;
```

- [ ] **Step 4: Supprimer les replis de `run_controller.dart`**

Trois substitutions :

1. Ligne 169, dans le chemin de chargement de sauvegarde — supprimer les trois lignes :
   ```dart
        activePassive = PassiveData.fallback(
          json['passiveTrait'] as String? ?? '',
        );
   ```
   Le `MissingSaveItem` de catégorie `passive` est déjà ajouté juste au-dessus : la sauvegarde signale la perte, elle ne la maquille plus.

2. Ligne 216, dans `build()` (l'état par défaut avant toute partie) :
   ```dart
      activePassive: PassiveData.fallback('regenArmor'),
   ```
   devient :
   ```dart
      activePassive: null,
   ```

3. Ligne 249-250, dans `startNewRun` :
   ```dart
      activePassive:
          activePassive ?? PassiveData.fallback(chosenClass.passiveTrait ?? ''),
   ```
   devient :
   ```dart
      activePassive: activePassive,
   ```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/unit/passive_absent_test.dart`
Expected: PASS.

- [ ] **Step 6: Vérifier**

Run: `dart analyze`
Expected: `No issues found!` — si un import `passive_data.dart` devient inutilisé dans `trait_system.dart`, le retirer.

Run: `flutter test`
Expected: **380 tests** au vert.

- [ ] **Step 7: Commit**

```bash
git add lib/game/systems/trait_system.dart lib/game/controllers/run_controller.dart test/unit/passive_absent_test.dart
git commit -m "refactor(passifs): rendre un passif absent inerte cote moteur

Plus de repli vers un passif fabrique en dur : quand activePassive est nul,
aucun effet n'est applique. Le chargement de sauvegarde signalait deja la
perte par un MissingSaveItem, il ne la maquille plus."
```

---

### Task 5: Supprimer `PassiveData.fallback()` — côté UI puis la méthode

**Files:**
- Modify: `lib/ui/widgets/map/dialogs/stats_dialog.dart:58-62`
- Modify: `lib/ui/screens/class_selection_screen.dart:153-156`
- Modify: `lib/models/data/passive_data.dart:67-120` (suppression de la méthode)

**Interfaces:**
- Consumes: la nullabilité de `RunState.activePassive` établie en Task 4
- Produces: `PassiveData.getById(String)` reste la seule voie de résolution d'un passif

> Les deux écrans canalisent le passif vers **deux chaînes locales** (`traitName`, `traitDesc`)
> consommées plus bas. Il suffit donc de rendre ces deux chaînes tolérantes au `null` : aucun widget
> n'est à restructurer. Le tiret cadratin évite d'inventer une clé ARB pour un cas qui ne doit pas
> se produire.

- [ ] **Step 1: `stats_dialog.dart` (lignes 59-62)**

Remplacer :

```dart
    final passive =
        runState.activePassive ??
        PassiveData.fallback(runState.passiveTrait ?? '');
    final traitName = passive.getName(locale);
    final traitDesc = passive.getDescription(locale);
```

par :

```dart
    final passive = runState.activePassive;
    final traitName = passive?.getName(locale) ?? '—';
    final traitDesc = passive?.getDescription(locale) ?? '';
```

Les deux points de rendu (lignes 256 et 270, `'${l10n.classPassive.toUpperCase()} : $traitName'` et
`traitDesc`) restent inchangés : ils affichent `PASSIF : —` et une description vide.

- [ ] **Step 2: `class_selection_screen.dart` (lignes 153-156 puis 169-170)**

Remplacer le lookup :

```dart
    final passive = gameData.passives.firstWhere(
      (p) => p.id == playerClass.passiveTrait,
      orElse: () => PassiveData.fallback(playerClass.passiveTrait ?? ''),
    );
```

par :

```dart
    final matchingPassives =
        gameData.passives.where((p) => p.id == playerClass.passiveTrait);
    final passive = matchingPassives.isEmpty ? null : matchingPassives.first;
```

*(Ne pas utiliser `firstOrNull` : `package:collection` n'est pas une dépendance directe du projet.)*

Puis les deux chaînes :

```dart
    final String traitName = passive.getName(locale);
    final String traitDesc = passive.getDescription(locale);
```

deviennent :

```dart
    final String traitName = passive?.getName(locale) ?? '—';
    final String traitDesc = passive?.getDescription(locale) ?? '';
```

- [ ] **Step 3: Supprimer la méthode**

Dans `lib/models/data/passive_data.dart`, supprimer intégralement `static PassiveData fallback(String id) { ... }` (lignes 67 à 120, du `static PassiveData fallback` jusqu'à sa dernière accolade fermante).

- [ ] **Step 4: Vérifier qu'il ne reste aucun appelant**

Run: `grep -rn "PassiveData.fallback" lib/ test/`
Expected: aucune sortie.

- [ ] **Step 5: Vérifier**

Run: `dart analyze`
Expected: `No issues found!` — retirer tout import `passive_data.dart` devenu inutilisé.

Run: `flutter test`
Expected: **380 tests** au vert.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets/map/dialogs/stats_dialog.dart lib/ui/screens/class_selection_screen.dart lib/models/data/passive_data.dart
git commit -m "refactor(passifs): supprimer PassiveData.fallback

Cette methode dupliquait les trois passifs en dur en Dart, en plus de
passives.json : le meme anti-pattern que les replis d'images du lot 1, avec
sept points d'appel. Les deux ecrans concernes n'affichent plus rien plutot
qu'un passif fabrique."
```

---

# LOT 2 — Rendre explicite tout ordre d'affichage

*Effort : 1 jour. Objectif : plus aucun ordre visible par le joueur ne dépend de l'ordre des tableaux JSON, pour que le tri par `id` du lot 3 n'ait aucune conséquence observable.*

---

### Task 6: `displayOrder` sur les classes

L'écran de sélection indexe `gameData.heroes` directement : l'ordre paladin/berserker/mage est celui de `heroes.json`, et aucun tri des données existantes ne le reproduit.

**Files:**
- Modify: `lib/models/data/hero_data.dart`
- Modify: `assets/data/heroes.json`
- Modify: `lib/ui/screens/class_selection_screen.dart:24`

**Interfaces:**
- Consumes: rien
- Produces: `int HeroData.displayOrder` — défaut `0`, lu depuis la clé JSON `displayOrder`

> C'est le **seul schéma d'entité modifié** par tout le chantier (spec §6.3, décision D10). Une liste d'ids codée en dur dans l'écran serait l'anti-pattern que le lot 1 vient de supprimer, et exigerait une édition de code à chaque classe ajoutée par P-42.

- [ ] **Step 1: Write the failing test**

Créer `test/unit/hero_display_order_test.dart` :

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  test('chaque classe declare un displayOrder distinct et non nul', () {
    final raw = File('assets/data/heroes.json').readAsStringSync();
    final heroes = (jsonDecode(raw) as List)
        .map((e) => HeroData.fromJson(e as Map<String, dynamic>))
        .toList();

    expect(heroes, isNotEmpty);
    for (final hero in heroes) {
      expect(
        hero.displayOrder,
        greaterThan(0),
        reason: 'la classe "${hero.id}" n a pas de displayOrder',
      );
    }
    final orders = heroes.map((h) => h.displayOrder).toList();
    expect(orders.toSet(), hasLength(orders.length), reason: 'doublon');
  });

  test('le tri par displayOrder rend paladin, berserker, mage', () {
    final raw = File('assets/data/heroes.json').readAsStringSync();
    final heroes = (jsonDecode(raw) as List)
        .map((e) => HeroData.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    expect(
      heroes.map((h) => h.id).toList(),
      ['paladin', 'berserker', 'mage'],
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/hero_display_order_test.dart`
Expected: FAIL — `The getter 'displayOrder' isn't defined for the type 'HeroData'`.

- [ ] **Step 3: Ajouter le champ au modèle**

Dans `lib/models/data/hero_data.dart`, après le champ `skills` :

```dart
  /// Rang d'affichage à la sélection de classe. Donnée de présentation :
  /// l'ordre ne doit pas dépendre de l'ordre du catalogue.
  final int displayOrder;
```

dans le constructeur, après `this.skills = const [],` :

```dart
    this.displayOrder = 0,
```

et dans `fromJson`, après la lecture de `skills` :

```dart
      displayOrder: json['displayOrder'] as int? ?? 0,
```

- [ ] **Step 4: Renseigner les données**

Dans `assets/data/heroes.json`, ajouter la clé à chaque entrée, après `"passiveTrait"` :
- `paladin` → `"displayOrder": 1,`
- `berserker` → `"displayOrder": 2,`
- `mage` → `"displayOrder": 3,`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/unit/hero_display_order_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Trier à l'affichage**

Dans `lib/ui/screens/class_selection_screen.dart`, remplacer :

```dart
    final classes = gameData.heroes;
```

par :

```dart
    final classes = [...gameData.heroes]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
```

- [ ] **Step 7: Vérifier**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test test/widget/class_selection_screen_test.dart`
Expected: PASS.

Run: `flutter test`
Expected: **382 tests** au vert.

- [ ] **Step 8: Commit**

```bash
git add lib/models/data/hero_data.dart assets/data/heroes.json lib/ui/screens/class_selection_screen.dart test/unit/hero_display_order_test.dart
git commit -m "feat(classes): ordonner la selection par displayOrder

L'ecran indexait gameData.heroes, donc l'ordre d'affichage etait celui du
fichier JSON. Une donnee de presentation a sa place dans la donnee, pas dans
une liste d'ids codee en dur qu'il faudrait editer a chaque classe ajoutee."
```

---

### Task 7: Renommer les ids de passifs en `snake_case`

Trois ids sont en camelCase (`regenArmor`, `berserkerArmor`, `spellArmor`). Le poste de développement est Windows (NTFS insensible à la casse), la CI est `ubuntu-latest`, et le lot 3 fera du nom de fichier l'`id` : un fichier commité avec une casse divergente passerait en local et échouerait en CI.

**Files:**
- Modify: `assets/data/passives.json`, `assets/data/heroes.json`
- Modify: tous les fichiers de `test/` portant ces ids en dur
- Test: `test/unit/entity_id_convention_test.dart` (create)

**Interfaces:**
- Consumes: rien
- Produces: tous les ids d'entités sont `^[a-z0-9_]+$`

> **La casse de sauvegarde est assumée** (spec §3.3, décision D9) : une run sauvegardée avant ce commit perd son passif au rechargement, signalée par un `MissingSaveItem`. Le jeu est en alpha ; aucune migration de schéma n'est écrite. **Ne pas bumper `SaveService._schemaVersion`.**

- [ ] **Step 1: Write the failing test**

Créer `test/unit/entity_id_convention_test.dart` :

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les ids d'entités deviendront des noms de fichiers au lot 3 de la
/// réorganisation des données. Le poste de dev est insensible à la casse,
/// la CI ne l'est pas : une divergence passerait en local et casserait en CI.
void main() {
  test('tous les ids d entites sont en snake_case ASCII minuscule', () {
    final pattern = RegExp(r'^[a-z0-9_]+$');
    final offenders = <String>[];

    const catalogues = [
      'cards.json',
      'hero_cards.json',
      'relics.json',
      'events.json',
      'enemies.json',
      'heroes.json',
      'passives.json',
      'forge_upgrades.json',
    ];

    for (final name in catalogues) {
      final raw = File('assets/data/$name').readAsStringSync();
      for (final entry in jsonDecode(raw) as List) {
        final id = (entry as Map<String, dynamic>)['id'] as String;
        if (!pattern.hasMatch(id)) offenders.add('$name → $id');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/entity_id_convention_test.dart`
Expected: FAIL — trois contrevenants : `passives.json → regenArmor`, `berserkerArmor`, `spellArmor`.

- [ ] **Step 3: Renommer dans les données**

Dans `assets/data/passives.json`, les trois `"id"` :
- `"regenArmor"` → `"regen_armor"`
- `"berserkerArmor"` → `"berserker_armor"`
- `"spellArmor"` → `"spell_armor"`

Dans `assets/data/heroes.json`, les trois `"passiveTrait"` correspondants, à l'identique.

- [ ] **Step 4: Renommer dans les tests**

Run: `grep -rln "regenArmor\|berserkerArmor\|spellArmor" test/ lib/`

Pour chaque fichier retourné, appliquer les trois mêmes substitutions. Attention à `lib/game/controllers/run_controller.dart:215` (`passiveTrait: 'regenArmor'` dans `build()`), qui doit devenir `'regen_armor'`.

Run à nouveau : `grep -rn "regenArmor\|berserkerArmor\|spellArmor" lib/ test/ assets/`
Expected: aucune sortie.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/unit/entity_id_convention_test.dart`
Expected: PASS.

- [ ] **Step 6: Vérifier**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: **383 tests** au vert.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "refactor(data): passer les ids de passifs en snake_case

Le lot 3 fera du nom de fichier l'id de l'entite. Le poste de dev est
insensible a la casse, la CI ne l'est pas : un id camelCase deviendrait un
fichier qui passe en local et casse en CI. Les runs sauvegardees perdent leur
passif au rechargement, signale par un MissingSaveItem — casse assumee, le
jeu est en alpha (spec 3.3)."
```

---

### Task 8: Ordre d'affichage explicite dans le dictionnaire

Dans l'onglet cartes, **l'ordre des groupes** vient de la première apparition de chaque type dans le catalogue (`putIfAbsent` sur une `Map` non pré-amorcée), et l'ordre **dans** un groupe est celui du catalogue. L'onglet reliques pré-amorce bien ses groupes par `RelicRarity.values`, mais pas l'intra-groupe.

**Files:**
- Modify: `lib/ui/screens/card_dictionary_screen.dart` (`_buildCardsTab` et `_buildRelicsTab`)
- Test: `test/widget/card_dictionary_order_test.dart` (create)

**Interfaces:**
- Consumes: rien
- Produces: rien

- [ ] **Step 1: Write the failing test**

Créer `test/widget/card_dictionary_order_test.dart`. Le test rend l'écran **deux fois**, avec le même catalogue rangé dans les deux sens, et exige la même séquence d'en-têtes de type. C'est la seule formulation qui prouve l'indépendance vis-à-vis du catalogue — une assertion sur une fonction locale au test ne prouverait rien du code de production.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/card_dictionary_screen.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

const _skill = CardData(
  id: 'defend',
  nameEn: 'Defend',
  nameFr: 'Défense',
  cost: 1,
  type: CardType.skill,
  category: CardCategory.global,
  rarity: CardRarity.common,
  target: CardTarget.self,
  effects: [],
);

const _attack = CardData(
  id: 'strike',
  nameEn: 'Strike',
  nameFr: 'Frappe',
  cost: 1,
  type: CardType.attack,
  category: CardCategory.global,
  rarity: CardRarity.common,
  target: CardTarget.singleEnemy,
  effects: [],
);

Future<List<String>> _renderedGroupHeaders(
  WidgetTester tester,
  List<CardData> cards,
) async {
  final registry = GameDataRegistry(
    enemies: const [],
    heroes: const [],
    cards: cards,
    events: const [],
    passives: const [],
    relics: const [],
    forgeUpgrades: const [],
  );
  final container = ProviderContainer(
    overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
  );
  addTearDown(container.dispose);
  await container.read(gameDataLoaderProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en', ''), Locale('fr', '')],
        locale: Locale('en', ''),
        home: CardDictionaryScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  // Les en-têtes de groupe sont les seuls Text en amber/24.
  return tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => t.style?.fontSize == 24)
      .map((t) => t.data ?? '')
      .toList();
}

void main() {
  testWidgets(
    'l ordre des groupes ne depend pas de l ordre du catalogue',
    (tester) async {
      final forward = await _renderedGroupHeaders(tester, const [_attack, _skill]);
      final reversed = await _renderedGroupHeaders(tester, const [_skill, _attack]);

      expect(forward, isNotEmpty);
      expect(reversed, equals(forward));
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/card_dictionary_order_test.dart`
Expected: FAIL — les deux rendus produisent des séquences d'en-têtes inversées, parce que `putIfAbsent` suit l'ordre d'apparition dans le catalogue.

- [ ] **Step 3: Appliquer la règle dans `_buildCardsTab`**

Remplacer :

```dart
    final Map<CardType, List<CardData>> groupedCards = {};
    for (var card in allCards) {
      groupedCards.putIfAbsent(card.type, () => []).add(card);
    }
```

par :

```dart
    // L'ordre des groupes vient de l'enum, jamais de l'ordre du catalogue ;
    // l'ordre dans un groupe est explicite. Sans cela, insérer une carte au
    // milieu de cards.json changerait ce que voit le joueur.
    final Map<CardType, List<CardData>> groupedCards = {
      for (final type in CardType.values) type: <CardData>[],
    };
    for (var card in allCards) {
      groupedCards[card.type]!.add(card);
    }
    for (final group in groupedCards.values) {
      group.sort((a, b) {
        final byRarity = a.rarity.index.compareTo(b.rarity.index);
        if (byRarity != 0) return byRarity;
        final byCost = a.cost.compareTo(b.cost);
        if (byCost != 0) return byCost;
        return a.id.compareTo(b.id);
      });
    }
    groupedCards.removeWhere((_, cards) => cards.isEmpty);
```

- [ ] **Step 4: Trier l'intra-groupe de `_buildRelicsTab`**

Après la boucle `for (var relic in allRelics) { groupedRelics[relic.rarity]?.add(relic); }`, ajouter :

```dart
    for (final group in groupedRelics.values) {
      group.sort((a, b) => a.id.compareTo(b.id));
    }
```

- [ ] **Step 5: Vérifier**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test test/widget/card_dictionary_screen_test.dart test/widget/card_dictionary_order_test.dart`
Expected: PASS.

Run: `flutter test`
Expected: **384 tests** au vert.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/screens/card_dictionary_screen.dart test/widget/card_dictionary_order_test.dart
git commit -m "fix(dictionnaire): rendre l ordre d affichage independant du catalogue

L'ordre des groupes venait de la premiere apparition de chaque type dans
cards.json, et l'ordre interne de l'ordre du fichier. Inserer une carte au
milieu du catalogue changeait donc ce que voit le joueur."
```

---

### Task 9: Trier explicitement le pool du draft de départ

`_generateDraftPool` filtre `gameData.cards` **sans mélange** et l'affiche par index : l'ordre du tout premier choix d'une run est celui du fichier.

**Files:**
- Modify: `lib/ui/screens/starter_deck_draft_screen.dart:53-59`

**Interfaces:**
- Consumes: rien
- Produces: rien

- [ ] **Step 1: Trier le pool**

Remplacer :

```dart
    final globalCards = gameData.cards
        .where(
          (c) => c.category == CardCategory.global && c.type != CardType.status,
        )
        .toList();
```

par :

```dart
    final globalCards = gameData.cards
        .where(
          (c) => c.category == CardCategory.global && c.type != CardType.status,
        )
        .toList()
      // Le pool est affiché et sélectionné par index, sans mélange : sans tri
      // explicite, le premier choix d'une run suivrait l'ordre de cards.json.
      ..sort((a, b) {
        final byRarity = a.rarity.index.compareTo(b.rarity.index);
        if (byRarity != 0) return byRarity;
        final byCost = a.cost.compareTo(b.cost);
        if (byCost != 0) return byCost;
        return a.id.compareTo(b.id);
      });
```

- [ ] **Step 2: Vérifier**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test test/widget/starter_deck_draft_screen_test.dart`
Expected: PASS.

Run: `flutter test`
Expected: **384 tests** au vert.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/screens/starter_deck_draft_screen.dart
git commit -m "fix(draft): trier explicitement le pool du deck de depart

Le pool etait filtre sans melange puis selectionne par index : l'ordre du
premier choix d'une run venait de l'ordre de cards.json."
```

---

### Task 10: Supprimer les derniers replis silencieux

Trois `orElse: () => liste.first` sur des listes du registre, et un `matches.first` suivi d'un `whereType` qui avale l'absence.

**Files:**
- Modify: `lib/ui/widgets/map/dialogs/stats_dialog.dart:43`
- Modify: `lib/ui/screens/relic_exchange_screen.dart:144`
- Modify: `lib/models/data/hero_skills_link.dart:7-13`

**Interfaces:**
- Consumes: rien
- Produces: `HeroSkillsLink.getHeroCards` lève une `StateError` si une carte de signature est introuvable, au lieu de la retirer du deck

> Le repli de `state_sync_system.dart:46` a été traité en Task 3, avec le repli d'image du même bloc.

- [ ] **Step 1: Write the failing test**

Créer `test/unit/hero_skills_link_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/hero_skills_link.dart';

void main() {
  test('une carte de signature introuvable leve au lieu d etre avalee', () {
    final registry = GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: const [],
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: const [],
    );

    const hero = HeroData(
      id: 'paladin',
      iconPath: 'hero_paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      skills: ['carte_absente'],
    );

    expect(() => hero.getHeroCards(registry), throwsStateError);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/hero_skills_link_test.dart`
Expected: FAIL — la méthode rend une liste vide au lieu de lever : le `whereType<CardData>()` retire le `null`.

- [ ] **Step 3: `stats_dialog.dart`**

Remplacer :

```dart
      orElse: () => gameData.heroes.first,
```

Supprimer l'argument `orElse` en entier, en laissant le `firstWhere` sur son seul prédicat. La classe du run est nécessairement dans le registre ; si elle ne l'est pas, c'est un bug de données que ce dialogue n'a pas à masquer par les stats d'un autre héros.

- [ ] **Step 4: `relic_exchange_screen.dart`**

Remplacer :

```dart
              _offeredRelic = gameData.relics.firstWhere((r) => r.rarity != RelicRarity.common, orElse: () => gameData.relics.first);
```

par :

```dart
              _offeredRelic = gameData.relics
                  .firstWhere((r) => r.rarity != RelicRarity.common);
```

- [ ] **Step 5: `hero_skills_link.dart`**

Remplacer le corps de `getHeroCards` :

```dart
    return skills
        .map((skillId) {
          final matches = gameData.cards.where((c) => c.id == skillId);
          return matches.isNotEmpty ? matches.first : null;
        })
        .whereType<CardData>()
        .toList();
```

par :

```dart
    // Pas de filtrage silencieux : une carte de signature introuvable est un
    // bug de données. L'avaler produisait un deck de départ amputé sans la
    // moindre trace.
    return skills
        .map((skillId) => gameData.cards.firstWhere((c) => c.id == skillId))
        .toList();
```

- [ ] **Step 6: Vérifier**

Run: `dart analyze`
Expected: `No issues found!` — retirer l'import `card_data.dart` de `hero_skills_link.dart` s'il est devenu inutilisé (il ne l'est pas : `List<CardData>` reste le type de retour).

Run: `flutter test`
Expected: **385 tests** au vert. Si `test/widget/starter_deck_draft_screen_test.dart` échoue, c'est que son héros de fixture (`skills: ['holy_shield']`, ligne 179) référence une carte absente de son registre de test : ajouter la carte à la fixture plutôt que de rétablir le repli.

- [ ] **Step 7: Commit**

```bash
git add lib/ui/widgets/map/dialogs/stats_dialog.dart lib/ui/screens/relic_exchange_screen.dart lib/models/data/hero_skills_link.dart test/unit/hero_skills_link_test.dart
git commit -m "refactor(data): supprimer les derniers replis silencieux

Trois orElse vers liste.first, dont la valeur changeait au retri des
catalogues, et un whereType qui retirait du deck de depart toute carte de
signature introuvable, sans erreur."
```

---

## Fin des lots 1 et 2 — vérification de sortie

- [x] `dart analyze` → `No issues found!`
- [x] `flutter test` → **388 tests au vert** *(385 à la fin de la tâche 10, +2 par la vague de correction de la revue finale, +1 par la vérification avant PR — tri intra-groupe des reliques)*
- [x] `grep -rn "PassiveData.fallback\|hero_paladin.png\|enemy_goblin.png" lib/` → aucune sortie
- [x] `grep -rn "orElse: () => .*\.first" lib/ --include=*.dart` → 4 restants, tous sur `runState.mapNodes`/`nodes`, jamais `gameData.*`
- [x] `grep -rn "regenArmor\|berserkerArmor\|spellArmor" lib/ test/ assets/` → 2 lignes restantes, toutes deux des **noms de variables Dart locales** (`test/unit/run_controller_test.dart:90`, `test/unit/run_state_persistence_test.dart:12`) dont le champ `id:` est bien en `snake_case`. Les identifiants Dart restent en lowerCamelCase (lint `constant_identifier_names`) ; seule la **valeur** de l'id est normalisée.
- [ ] **(non fait)** Lancer le jeu et vérifier à l'œil : sélection de classe dans l'ordre paladin/berserker/mage, dictionnaire groupé par type dans l'ordre de l'enum, un combat qui démarre avec les bons sprites

**Spec mise à jour** : §1 (377 sur `ced306e` → 388 après les lots), §5.3 (la septième surface, manquée par la table et retrouvée en revue finale), §9, §10 et §11 alignés sur la livraison.

Le **lot 3** (migration proprement dite) fera l'objet de son propre plan, écrit une fois ces deux lots fusionnés : ses références de ligne dépendent de l'état que ce plan produit.
