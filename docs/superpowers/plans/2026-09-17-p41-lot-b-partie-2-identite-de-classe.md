# P-41 lot B, partie 2 — L'identité de classe — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Donner aux trois classes une identité réelle : chacune oriente sa Puissance (le Paladin vers tout, le Berserker vers ses Attaques, le Mage vers ses Compétences et ses altérations), l'armure du Berserker devient de la Puissance d'un tour, les neuf passifs remplacent les trois existants, et les stats de départ diffèrent.

**Architecture:** L'orientation est déjà lue par `PowerRules` depuis la partie 1 : la partie 2 ne fait que la déclarer dans les `class.json`. Une seule règle reste à appliquer **au gain** — la conversion d'armure —, portée par `StatRule` que `HeroData` lit, que `RunState` porte pour la run et que `StatGains.apply` reçoit en paramètre obligatoire. Les neuf passifs sont du contenu sur le modèle de P-49 : neuf fichiers sous `assets/data/passives/` et neuf stratégies, servis par un `PassiveEvent` enrichi (dégâts encaissés, armure survivante, ennemi ciblé), deux nouveaux points de dispatch et des compteurs portés par des statuts.

**Tech Stack:** Flutter / Dart 3.11, Flame, Riverpod 2 (`Notifier`), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md` — lire le §0.3, puis les §6 et §7 en entier ; le périmètre de cette partie est listé au §7.6. La partie 1 (la stat `might`, `MightTarget`, `PowerRules`, les textes) est **fusionnée dans `main`** (PR #40) : ce plan part du code renommé et ne le renomme plus.

## Global Constraints

- **Le jeu change, et c'est le but** (spec §7.6, partie 2). Ce qui change est borné à ceci : les trois orientations, la conversion d'armure du Berserker, les neuf passifs, la Maîtrise de départ du Paladin, le `critChance` de départ du Berserker, et les icônes de la Puissance. Rien d'autre — aucun chiffre de carte, de relique, d'ennemi ou de récompense.
- **Les valeurs chiffrées des neuf passifs sont des valeurs d'équilibrage, pas de conception** (spec §6.3). Celles de ce plan sont posées pour que le mécanisme soit jouable et testable ; les changer ne demande aucun code. Chaque fichier porte la sienne, et chaque formule vit dans une seule stratégie.
- **Sauvegarde : aucune étape de migration, aucun test de compatibilité entre versions** (spec §7.5). `SaveMigrator.currentVersion` reste à 2. Avant la `1.0.0`, une sauvegarde n'a pas à survivre à un changement de version.
- `dart analyze` doit afficher `No issues found!` à la fin de **chaque** tâche.
- `flutter test` doit être **entièrement** vert à la fin de chaque tâche. Point de départ **mesuré le 2026-09-17 sur `main`** (commit `e2cc24b`) : **938 tests**, `dart analyze` propre. Les totaux annoncés tâche par tâche sont une **prévision arithmétique** (938 + les tests ajoutés − ceux supprimés), **non un rejeu** : un écart signale un test oublié ou dupliqué, à comprendre avant de continuer — jamais un nombre à réajuster à l'aveugle.
- **Ne jamais lancer `dart format`** : le dépôt ne l'utilise pas.
- Créer et modifier les fichiers avec les outils Write / Edit. **Jamais par heredoc bash** pour du contenu : les heredocs de cet environnement mangent les antislashs, et le code Dart et les JSON de ce plan en contiennent (`'Éveil d\'Attaque'`, `\n`).
- Tout texte joueur d'un JSON porte ses variantes `_fr` **et** `_en` (`CLAUDE.md`). Les neuf passifs en portent quatre : `name_fr`, `name_en`, `description_fr`, `description_en`, plus `description_fr`/`description_en` dans leur bloc `mastery`.
- **Un fichier supprimé d'`assets/` reste dans `build/unit_test_assets/`**, que `flutter test` ne purge jamais : après la suppression d'un fichier de données, supprimer sa copie sous `build/unit_test_assets/assets/data/`, sinon `test/unit/real_bundle_load_test.dart` continue de le compter.
- Le tutoriel ne référence aucun provider d'état (ADR-081), vérifié par `test/tutorial/tutorial_isolation_test.dart`. Les règles qu'il applique viennent des mêmes fonctions pures que le jeu : `StatGains.apply` et `PowerRules`. **Aucune recopie** de `statRules` ni de l'orientation dans `lib/tutorial/`.
- Ne pas toucher `assets/data/patch_notes.json` ni le champ `version:` de `pubspec.yaml` : ils appartiennent au skill `patch-notes-writer`.
- Aucune clé ARB n'est ajoutée ni modifiée par cette partie : les textes de la Puissance ont été écrits à la partie 1, et la forme longue de l'orientation appartient au lot C (spec §7.4, §8.3). **Ne pas lancer `flutter gen-l10n`.**
- Le code va sur la branche `feat/p41-lot-b-identite`, jamais sur `main`. La documentation de cette partie est déjà commitée sur `main`, avant l'exécution. **Pas de worktree** (décision du propriétaire) : la branche est créée dans le checkout principal, même si le skill d'exécution en propose un.
- Messages de commit en français, forme `type(portee): message`, **sans accents ni apostrophes**, terminés par la ligne `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- Les commandes `flutter` peuvent réécrire des fichiers générés sans en changer le contenu, fins de ligne seulement : `macos/Flutter/GeneratedPluginRegistrant.swift` et, dans un checkout neuf, ceux de `linux/flutter/` et de `windows/flutter/`. S'ils apparaissent dans `git status`, les restaurer (`git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`) ; ne jamais les commiter.

## Décisions prises à la rédaction du plan

La spec tranche la conception ; six points d'implémentation restaient ouverts. Ils sont tranchés ici, et l'exécutant n'a pas à les rouvrir.

| # | Question | Décision | Pourquoi |
|:---|:---|:---|:---|
| **1** | Où vivent les `statRules` de la run ? | `RunState.statRules`, **redérivées de la classe au chargement**, jamais sérialisées | Précédent explicite : `cardsPerTurn` est sur `RunState` et non sur `EntityStats` « partagé avec les ennemis » (`run_controller.dart:37`). Une règle est du **contenu** : la relire du registre par `heroClassId`, comme `fromJsonWithReport` relit déjà le passif actif (`:154`), évite de figer dans les sauvegardes une donnée que le JSON peut changer |
| **2** | Comment *Bénédiction* lit-elle l'armure avant `armure: 0` ? | `startTurn()` **capture** l'armure avant la remise à zéro et la passe dans `PassiveEvent.survivingArmor` ; le dispatch ne bouge pas | Déplacer le dispatch avant la remise à zéro ferait disparaître en silence l'armure de tout passif `startOfTurn` qui en donne — `berserker_armor` aujourd'hui, n'importe lequel demain. La charge utile satisfait la contrainte de la spec (« sinon il n'a rien à convertir ») sans créer ce piège, et se teste directement sur la stratégie |
| **3** | Comment un passif compte-t-il « la 1ʳᵉ attaque du tour » ou « N Compétences » ? | Un statut caché du héros, `<id>_count` : durée 1 pour le tour, 99 pour le combat | C'est l'idiome déjà en place pour les charges de reliques (`shuriken_charge`, `pen_nib_charge`, `incense_charge`). Les statuts sont décrémentés à chaque début de tour et vidés à la fin de chaque combat : la portée vient de la durée, et **aucun état nouveau n'est à sérialiser** |
| **4** | Quel passif le joueur obtient-il, puisque le **choix** est au lot C ? | `PassiveData.displayOrder`, et `availablePassivesFor` trie par `(displayOrder, id)`. Le premier de chaque classe est celui qui **remplace le passif d'aujourd'hui** : `regen_armor`, `rage`, `channeling` | Sans lui, l'ordre alphabétique déciderait — le Berserker démarrerait sur *Soif de Sang*, le plus intriqué des neuf. `displayOrder` est le précédent de `HeroData` (`:36`) et de `CardData.compareByDisplayOrder` ; c'est aussi ce dont le lot C aura besoin pour ranger ses trois choix |
| **5** | Le tutoriel hérite-t-il du `critChance` du Berserker ? | Non : `TutorialMockState.baseStatsForHero` **ne recopie pas** `critChance`, avec un commentaire et un test | La spec assigne ce point au lot D (§9.1) mais c'est la partie 2 qui crée le problème : livrer un tutoriel aux dégâts aléatoires serait une régression, et l'exception est d'une ligne. Les autres points du lot D restent au lot D |
| **6** | L'éditeur de contenu sait-il écrire `statRules` ? | Non, et c'est la spec qui le dit (§9.2, lot D). Seule la vue JSON brute l'atteint ; le descripteur le documente | Valider `stat`, `mode` et `to` demande le langage de chemins imbriqués sur une **liste** et son test ; c'est un lot à part. `mightTargets` reste validé depuis la partie 1 |

## Conséquences assumées, à annoncer plutôt qu'à découvrir

1. **Un seul des trois passifs d'une classe est atteignable** avant le lot C : l'écran de sélection affiche `passives.first` et le passe au draft de départ (`class_selection_screen.dart:157-158`, `:473`). Les neuf sont livrés, testés et jouables ; six attendent l'écran de choix du lot C (spec §8.3). C'est le découpage voulu, pas un oubli.
2. **Le Mage ne renforce plus aucun de ses dégâts** (spec §7.1, « conséquence assumée, confirmée par le propriétaire le 2026-09-17 ») : toutes les cartes de dégâts du jeu sont de type Attaque, y compris *Projectile Magique*. Sa Puissance renforce l'intensité de ses brûlures, gels, poisons et chocs, jusqu'à ce que P-42 écrive des Compétences offensives.
3. **Le Berserker n'a plus jamais d'armure** : toute source — carte, rune, passif, relique, statut `armor_regen` — devient de la Puissance d'un tour. *Mur de Fer* (10 armure, carte neutre présente dans tous les decks) lui donne donc 10 de Puissance pour un tour. C'est exactement l'échange que la spec décrit (§7.2) ; son réglage est de l'équilibrage.
4. **L'étape « Armure » du tutoriel enseigne au Berserker une règle qu'il ne suit pas** : le gain est converti, donc la barre d'armure reste à 0. L'étape reste franchissable (son drapeau se lève sur le gain, pas sur son résultat — `tutorial_engine.dart:360`), mais la prose devient fausse pour cette classe. La spec l'assigne au lot D (§9.1) ; ce plan ne la réécrit pas et le note en suite.
5. **_Flux de Mana_ se déclenche sur 9 des 23 cartes du pool (39 %)**, le même compte que `spell_armor` dont la spec dit que « R4 formalise un défaut existant » (§6.2). R4 sera satisfaite par les Compétences de S3 (P-42) ; le passif ne dépend d'aucune carte de classe pour fonctionner.

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/models/data/stat_rule.dart` *(nouveau)* | `StatRule`, `RuleStat`, `RuleMode`, `RuleTarget` et leur lecture JSON | 1 |
| `lib/models/data/hero_data.dart` | `statRules`, `critChance`, `HeroData.getById` | 1 |
| `lib/game/systems/stat_gains.dart` | `apply(stats, gain, rules)` : la conversion d'une ressource | 2 |
| `lib/game/controllers/run_controller.dart` | `RunState.statRules` ; la capture de l'armure survivante ; les dispatches `onEnemyKilled` et `onDamageTaken` ; la copie de `critChance` | 2, 3, 4 |
| `lib/game/controllers/run/player_stats_manager.dart` | `grant` passe les règles ; `removeStatus` ; `applyLifestealBuff` porte une valeur | 2, 4, 7 |
| `lib/game/controllers/combat/status_effect_processor.dart`, `combat/turn_phase_manager.dart` | Reçoivent les règles, ou la liste vide pour un ennemi | 2 |
| `lib/tutorial/tutorial_engine.dart` | Applique les règles de la classe choisie ; ne recopie pas `critChance` | 2, 3 |
| `assets/data/classes/*/class.json` | Orientations, `statRules` du Berserker, stats de départ | 3 |
| `lib/services/content_editor/entity_descriptor.dart` | `critChance` au gabarit de classe ; les quatre paramètres de passif | 3, 5 |
| `lib/models/data/relic_data.dart` | `RelicTrigger.onDamageTaken` | 4 |
| `lib/ui/screens/card_dictionary_screen.dart`, `lib/ui/widgets/map/dialogs/relics_dialog.dart`, `lib/ui/widgets/relic_carousel/relic_carousel_card.dart` | Le libellé du nouveau déclencheur | 4 |
| `lib/game/systems/passives/passive_strategy.dart` | `PassiveEvent` : `absorbedDamage`, `survivingArmor`, `enemyId` | 4 |
| `lib/game/systems/passives/passive_counters.dart` *(nouveau)* | Les compteurs par tour et par combat | 4 |
| `lib/game/controllers/combat_controller.dart` | Dispatch des passifs par type de carte | 4 |
| `lib/models/data/passive_data.dart` | `duration`, `threshold`, `draw`, `displayOrder` ; `PassiveMastery.fields` | 5 |
| `lib/game/systems/passive_availability.dart` | Tri par `(displayOrder, id)` | 5 |
| `lib/game/systems/passives/passive_strategies.dart` | Les neuf stratégies ; retrait des deux remplacées | 6, 7, 8 |
| `assets/data/passives/*.json` | Les neuf passifs ; suppression de `berserker_armor` et `spell_armor` | 6, 7, 8 |
| `lib/game/services/effects/strategies.dart` | Le hook de Vol de vie | 7 |
| `lib/ui/widgets/hud/player_health_bar.dart`, `map/dialogs/stats_dialog.dart`, `map/hero_mini_stats_panel.dart`, `game/components/entities/stat_badge.dart`, `status_indicator.dart` | L'éclair de la Puissance, en Flutter comme en Flame | 9 |
| `lib/game/components/widgets/flame_sword_icon.dart` *(supprimé)* | Sans usage une fois l'éclair posé. `lib/ui/widgets/sword_icon.dart` **reste** : l'écran de sélection s'en sert jusqu'au lot C | 9 |

---

### Task 0: La branche, depuis la documentation déjà commitée

**À faire dans le checkout principal, avant toute tâche de code.**

**Files:**
- Aucun. La documentation de cette partie est **déjà commitée sur `main`** : l'index (`docs/INDEX.md`) et la feuille de route (`docs/ROADMAP.md`) relient ce plan, le statut de la spec annonce la partie 2 en cours, et la consignation de la fusion de la partie 1 (`3bb5a65`) est enregistrée.

**Interfaces:**
- Consumes: ce plan, commité sur `main`.
- Produces: la branche `feat/p41-lot-b-identite`, créée depuis le commit du plan.

- [ ] **Step 1: Vérifier l'état de départ**

Run: `git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift` (fins de ligne seulement), puis `git status --short`
Expected: **aucune sortie** — l'arbre de travail est propre.

Run: `git log --oneline -5`
Expected: on y trouve le commit `docs(P-41): plan de la partie 2 du lot B` et, juste avant, `3bb5a65 docs(memoire): partie 1 du lot B de P-41 fusionnee dans main` — une passe de correction de ce plan a pu en ajouter un par-dessus. Si l'arbre n'est pas propre, ou si ces deux commits manquent, **s'arrêter et le signaler** : ce plan part de cet état.

- [ ] **Step 2: Créer la branche**

Run: `git switch -c feat/p41-lot-b-identite` — depuis `main`, dans le checkout principal. **Pas de worktree**, même si le skill d'exécution en propose un.

- [ ] **Step 3: Mesurer la base**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+938: All tests passed!`

---

### Task 1: `StatRule`, et ce que la classe déclare

Modèle et lecture seuls, sans lecteur encore : rien du jeu ne change.

**Files:**
- Create: `lib/models/data/stat_rule.dart`
- Modify: `lib/models/data/hero_data.dart`
- Test: `test/unit/stat_rule_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: rien.
- Produces:
  - `enum RuleStat { armor, mana }`, `enum RuleMode { convert }`, `enum RuleTarget { statusMight }` dans `lib/models/data/stat_rule.dart`.
  - `class StatRule` : champs `RuleStat stat`, `RuleMode mode`, `RuleTarget to`, `int duration` (1 par défaut) ; constructeur `const StatRule({required this.stat, required this.mode, required this.to, this.duration = 1})`.
  - `StatRule.fromJson(Map<String, dynamic>)` : lève `FormatException` sur une clé absente, une valeur inconnue et sur `"stat": "might"`.
  - `static List<StatRule> StatRule.parseAll(Object? json)` : `const []` si la clé est absente (`null`), lève sur autre chose qu'une liste.
  - `HeroData.statRules` (`List<StatRule>`, `const []` par défaut) et `HeroData.critChance` (`int`, 0 par défaut), lus par `fromJson`.
  - `static HeroData? HeroData.getById(String id)`, sur le modèle de `PassiveData.getById` : le registre, ou `null`.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/stat_rule_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';

/// Ce qui reste à `statRules` : convertir une ressource (spec P-41, §7.1).
void main() {
  Map<String, dynamic> ruleJson() => {
        'stat': 'armor',
        'mode': 'convert',
        'to': 'status:might',
        'duration': 1,
      };

  group('StatRule.fromJson', () {
    test('lit la conversion de l armure en Puissance temporaire', () {
      final rule = StatRule.fromJson(ruleJson());
      expect(rule.stat, RuleStat.armor);
      expect(rule.mode, RuleMode.convert);
      expect(rule.to, RuleTarget.statusMight);
      expect(rule.duration, 1);
    });

    test('la duree vaut 1 par defaut', () {
      final rule = StatRule.fromJson(ruleJson()..remove('duration'));
      expect(rule.duration, 1);
    });

    // La Puissance n'est jamais une `stat` de `statRules` : la convertir au
    // gain rouvrirait les deux problemes que l'orientation regle (spec §7.1).
    test('la Puissance en stat est refusee', () {
      expect(
        () => StatRule.fromJson(ruleJson()..['stat'] = 'might'),
        throwsFormatException,
      );
    });

    test('une valeur inconnue est refusee', () {
      for (final bad in const [
        {'stat': 'pv'},
        {'mode': 'convrt'},
        {'to': 'might'},
      ]) {
        expect(
          () => StatRule.fromJson({...ruleJson(), ...bad}),
          throwsFormatException,
          reason: 'valeur refusee : $bad',
        );
      }
    });

    test('une cle de mecanique absente est refusee', () {
      for (final key in const ['stat', 'mode', 'to']) {
        expect(
          () => StatRule.fromJson(ruleJson()..remove(key)),
          throwsFormatException,
          reason: 'cle absente : $key',
        );
      }
    });
  });

  group('StatRule.parseAll', () {
    test('une cle absente : aucune regle', () {
      expect(StatRule.parseAll(null), isEmpty);
    });

    test('une liste : les regles declarees', () {
      expect(StatRule.parseAll([ruleJson()]), hasLength(1));
    });

    test('autre chose qu une liste est refuse', () {
      expect(() => StatRule.parseAll(ruleJson()), throwsFormatException);
    });
  });

  group('HeroData', () {
    Map<String, dynamic> heroJson() => {
          'id': 'berserker',
          'classCard': 'assets/data/classes/berserker/berserker.png',
          'maxHp': 80,
          'maxMana': 3,
          'baseDamage': 15,
          'mightTargets': ['attack'],
        };

    test('sans statRules ni critChance : aucune regle, aucun critique', () {
      final hero = HeroData.fromJson(heroJson());
      expect(hero.statRules, isEmpty);
      expect(hero.critChance, 0);
    });

    test('les deux sont lus quand ils sont declares', () {
      final hero = HeroData.fromJson({
        ...heroJson(),
        'critChance': 10,
        'statRules': [ruleJson()],
      });
      expect(hero.critChance, 10);
      expect(hero.statRules.single.stat, RuleStat.armor);
    });

    // Sans champ ni lecture, une cle serait chargee et jetee en silence — le
    // mode d'echec le plus couteux a diagnostiquer (spec §7.1).
    test('une regle malformee fait echouer le chargement de la classe', () {
      expect(
        () => HeroData.fromJson({
          ...heroJson(),
          'statRules': [ruleJson()..['mode'] = 'block'],
        }),
        throwsFormatException,
      );
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/stat_rule_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:roguelike_card_game/models/data/stat_rule.dart'`.

- [ ] **Step 3: Écrire `StatRule`**

Create `lib/models/data/stat_rule.dart`:

```dart
import 'package:meta/meta.dart';

/// La ressource qu'une règle de classe convertit. La Puissance n'en est pas :
/// la classe l'oriente à la lecture, elle ne la convertit pas au gain
/// (spec P-41, §7.1).
enum RuleStat { armor, mana }

/// Ce que la règle fait de la ressource. `block`, avec `cap` et `decay`, reste
/// une extension possible sans changement de forme : son seul usage prévu — les
/// Compétences du Berserker — est devenu une orientation, et livré sans lecteur
/// ce serait du code mort (spec §7.1).
enum RuleMode { convert }

/// Vers quoi la ressource est convertie.
enum RuleTarget {
  /// Le statut `might`, la Puissance temporaire. Une ressource éphémère ne
  /// devient jamais une ressource permanente (règle R5, spec §7.2).
  statusMight,
}

/// Une règle de stat déclarée par une classe dans son `class.json`
/// (spec P-41, §7.1).
///
/// Une **liste** et non une table : le langage de chemins de l'éditeur de
/// contenu sait désigner un élément de liste (`statRules[].mode`), pas une clé
/// arbitraire d'une table.
@immutable
class StatRule {
  final RuleStat stat;
  final RuleMode mode;
  final RuleTarget to;

  /// La durée du statut produit, en tours.
  final int duration;

  const StatRule({
    required this.stat,
    required this.mode,
    required this.to,
    this.duration = 1,
  });

  static const Map<String, RuleStat> _stats = {
    'armor': RuleStat.armor,
    'mana': RuleStat.mana,
  };

  static const Map<String, RuleMode> _modes = {'convert': RuleMode.convert};

  /// `status:might` ne peut pas être un nom d'énumération : la correspondance
  /// est déclarée ici, avec le vocabulaire que le fichier de classe écrit.
  static const Map<String, RuleTarget> _targets = {
    'status:might': RuleTarget.statusMight,
  };

  static T _read<T>(Map<String, dynamic> json, String key, Map<String, T> by) {
    final value = json[key];
    final parsed = value is String ? by[value] : null;
    if (parsed == null) {
      throw FormatException(
        'statRules.$key : valeur "$value" inconnue — attendu : '
        '${by.keys.join(', ')}',
      );
    }
    return parsed;
  }

  factory StatRule.fromJson(Map<String, dynamic> json) => StatRule(
        stat: _read(json, 'stat', _stats),
        mode: _read(json, 'mode', _modes),
        to: _read(json, 'to', _targets),
        duration: json['duration'] as int? ?? 1,
      );

  /// Lit la clé `statRules` d'une classe. Absente : aucune règle — c'est le
  /// cas du Paladin et du Mage.
  static List<StatRule> parseAll(Object? json) {
    if (json == null) return const [];
    if (json is! List) {
      throw FormatException('statRules doit être une liste — reçu : $json');
    }
    return json
        .map((e) => StatRule.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
```

- [ ] **Step 4: `HeroData` lit les règles, le critique, et sait se retrouver par son id**

In `lib/models/data/hero_data.dart`, replace:
```dart
import '../might_target.dart';

class HeroData {
```
with:
```dart
import 'package:flutter/foundation.dart';

import '../might_target.dart';
import 'game_data_registry.dart';
import 'stat_rule.dart';

class HeroData {
```

In the same file, replace:
```dart
  final int luck;
  final int mastery;
```
with:
```dart
  final int luck;
  final int mastery;

  /// Le critique de départ de la classe, en pourcentage (spec P-41, §7.3).
  /// `EntityStats` le porte déjà : la classe pouvait seulement ne pas le dire.
  final int critChance;

  /// Les règles de stat de la classe : ce qu'elle convertit **au gain**, ce que
  /// l'orientation de la Puissance ne peut pas faire (spec P-41, §7.1). Vide
  /// pour le Paladin et le Mage.
  final List<StatRule> statRules;
```

In the same file, replace:
```dart
    this.luck = 0,
    this.mastery = 0,
    this.mightTargets = const {MightTarget.attack},
```
with:
```dart
    this.luck = 0,
    this.mastery = 0,
    this.critChance = 0,
    this.statRules = const [],
    this.mightTargets = const {MightTarget.attack},
```

In the same file, replace:
```dart
      luck: json['luck'] as int? ?? 0,
      mastery: json['mastery'] as int? ?? 0,
      mightTargets: MightTarget.parseAll(json['mightTargets']),
```
with:
```dart
      luck: json['luck'] as int? ?? 0,
      mastery: json['mastery'] as int? ?? 0,
      critChance: json['critChance'] as int? ?? 0,
      statRules: StatRule.parseAll(json['statRules']),
      mightTargets: MightTarget.parseAll(json['mightTargets']),
```

At the end of the class, after `_parseHexColor`, add:
```dart
  /// La classe d'identifiant [id] dans le registre chargé, `null` si le
  /// registre n'est pas là ou ne la connaît pas — sur le modèle de
  /// `PassiveData.getById`. C'est par ici qu'une run rechargée retrouve les
  /// règles de sa classe, plutôt que de les relire d'une sauvegarde.
  static HeroData? getById(String id) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return null;
    try {
      return registry.heroes.firstWhere((h) => h.id == id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HeroData.getById: no class found for id "$id" ($e)');
      }
      return null;
    }
  }
```

- [ ] **Step 5: Lancer le test pour le voir passer**

Run: `flutter test test/unit/stat_rule_test.dart`
Expected: `+11: All tests passed!`

- [ ] **Step 6: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+949: All tests passed!` (938 + 11)

- [ ] **Step 7: Commit**

```bash
git add lib/models/data/stat_rule.dart lib/models/data/hero_data.dart test/unit/stat_rule_test.dart
git commit -F- <<'EOF'
feat(classes): les regles de stat et le critique de depart, declares

StatRule lit la seule regle qui ne peut s appliquer qu au gain : la
conversion d une ressource. La Puissance en stat est refusee, et
HeroData sait se retrouver par son id pour qu une run rechargee
retrouve les regles de sa classe sans les relire d une sauvegarde.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 2: Les règles en paramètre obligatoire, et la conversion

Le mécanisme, sans son porteur : aucune classe ne déclare encore de règle, donc le jeu ne change pas. Le compilateur désigne chaque site de gain, qui décide explicitement — les règles de la classe pour le héros, une liste vide pour un ennemi.

**Files:**
- Modify: `lib/game/systems/stat_gains.dart` ; `lib/game/controllers/run_controller.dart` (`RunState`, `startNewRun`, `startTurn`) ; `lib/game/controllers/run/player_stats_manager.dart:56`, `:149` ; `lib/game/controllers/combat/status_effect_processor.dart:8`, `:39`, `:50`, `:87` ; `lib/game/controllers/combat/turn_phase_manager.dart:133` ; `lib/tutorial/tutorial_engine.dart:356`
- Test: `test/unit/stat_rule_conversion_test.dart` *(nouveau)* ; `test/unit/stat_gains_test.dart` ; `test/unit/stat_gains_characterization_test.dart:138`

**Interfaces:**
- Consumes: `StatRule`, `RuleStat`, `RuleTarget`, `HeroData.statRules`, `HeroData.getById` (Task 1).
- Produces:
  - `StatGains.apply(EntityStats stats, StatGain gain, List<StatRule> rules)` — troisième paramètre **positionnel obligatoire**.
  - `RunState.statRules` (`List<StatRule>`, `const []` par défaut), présent au constructeur et à `copyWith`, **non sérialisé** : `fromJsonWithReport` le redérive de `heroClassId`.
  - `StatusEffectProcessor.processPlayerStatuses(EntityStats stats, List<StatRule> rules)`.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/stat_rule_conversion_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat/status_effect_processor.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/stat_gains.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

/// La conversion d'une ressource au gain, et la règle R5 qui la borne
/// (spec P-41, §7.1, §7.2).
void main() {
  const armorToMight = StatRule(
    stat: RuleStat.armor,
    mode: RuleMode.convert,
    to: RuleTarget.statusMight,
    duration: 1,
  );

  EntityStats stats() => EntityStats(
        maxPv: 80,
        currentPv: 80,
        maxMana: 3,
        currentMana: 3,
        armure: 2,
        might: 1,
      );

  // `firstOrNull` n'est pas disponible : `package:collection` n'est pas une
  // dependance du projet.
  StatusEffect? mightOf(EntityStats s) {
    final found = s.statuses.where((st) => st.id == 'might');
    return found.isEmpty ? null : found.first;
  }

  group('StatGains.apply', () {
    test('sans regle : l armure s ajoute a l armure', () {
      const gain = StatGain(GainResource.armor, 5, GainSource.card);
      final after = StatGains.apply(stats(), gain, const []);
      expect(after.armure, 2 + 5);
      expect(after.statuses, isEmpty);
    });

    // R5 : une ressource ephemere ne devient jamais permanente. L'armure d'un
    // tour devient de la Puissance d'un tour, jamais de la Puissance de run.
    test('avec la regle : l armure devient de la Puissance temporaire', () {
      const gain = StatGain(GainResource.armor, 5, GainSource.card);
      final after = StatGains.apply(stats(), gain, const [armorToMight]);

      expect(after.armure, 2, reason: 'aucune armure ecrite');
      expect(after.might, 1, reason: 'aucune Puissance permanente');
      expect(mightOf(after)!.value, 5);
      expect(mightOf(after)!.duration, 1);
    });

    test('toute source d armure y passe', () {
      for (final source in GainSource.values) {
        final after = StatGains.apply(
          stats(),
          StatGain(GainResource.armor, 3, source),
          const [armorToMight],
        );
        expect(after.armure, 2, reason: 'source ${source.name}');
        expect(mightOf(after)!.value, 3, reason: 'source ${source.name}');
      }
    });

    test('une regle qui ne vise pas la ressource ne fait rien', () {
      const gain = StatGain(GainResource.mana, 2, GainSource.card);
      final after = StatGains.apply(stats(), gain, const [armorToMight]);
      expect(after.currentMana, 3 + 2);
      expect(after.statuses, isEmpty);
    });

    test('un gain nul ou negatif ne cree aucun statut', () {
      for (final amount in const [0, -3]) {
        final after = StatGains.apply(
          stats(),
          StatGain(GainResource.armor, amount, GainSource.card),
          const [armorToMight],
        );
        expect(after.statuses, isEmpty, reason: 'gain de $amount');
      }
    });

    test('deux gains convertis s empilent en un seul statut', () {
      const gain = StatGain(GainResource.armor, 4, GainSource.card);
      final once = StatGains.apply(stats(), gain, const [armorToMight]);
      final twice = StatGains.apply(once, gain, const [armorToMight]);
      expect(mightOf(twice)!.value, 8);
    });
  });

  group('le statut armor_regen du heros', () {
    const metallicize = StatusEffect(
      id: 'armor_regen',
      name: 'Metallisation',
      type: StatusType.buff,
      value: 3,
      duration: 2,
    );

    // Une liste vide par defaut aurait laisse `metallicize` donner de
    // l'armure a une classe qui la convertit (spec §4.1).
    test('passe par les regles que son appelant lui donne', () {
      final converted = StatusEffectProcessor.processPlayerStatuses(
        stats().addStatus(metallicize),
        const [armorToMight],
      );
      expect(converted.armure, 2);
      expect(mightOf(converted)!.value, 3);
    });
  });

  group('RunState', () {
    const rulebound = HeroData(
      id: 'berserker',
      classCard: 'berserker.png',
      maxHp: 80,
      maxMana: 3,
      baseDamage: 15,
      statRules: [armorToMight],
    );

    late ProviderContainer container;
    late RunController run;

    setUp(() {
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('startNewRun porte les regles de la classe', () {
      run.startNewRun(rulebound);
      expect(run.currentState.statRules, [armorToMight]);
    });

    test('un gain de carte du heros les traverse', () {
      run.startNewRun(rulebound);
      run.grant(const StatGain(GainResource.armor, 6, GainSource.card));

      expect(run.currentState.heroStats.armure, 0);
      expect(mightOf(run.currentState.heroStats)!.value, 6);
    });

    // Les regles sont du contenu : une run rechargee les relit de sa classe,
    // et non d'une sauvegarde qui les figerait (decision 1 du plan).
    test('elles ne sont pas serialisees', () {
      run.startNewRun(rulebound);
      expect(run.currentState.toJson().containsKey('statRules'), isFalse);
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/stat_rule_conversion_test.dart`
Expected: FAIL — `2 positional arguments expected by 'apply', but 3 found`, et `The named parameter 'statRules' isn't defined`.

- [ ] **Step 3: `StatGains` applique les règles**

In `lib/game/systems/stat_gains.dart`, replace:
```dart
import '../../models/entity_stats.dart';
```
with:
```dart
import '../../models/data/stat_rule.dart';
import '../../models/entity_stats.dart';
import '../../models/status_effect.dart';
```

In the same file, replace:
```dart
abstract final class StatGains {
  static EntityStats apply(EntityStats stats, StatGain gain) {
    return switch (gain.resource) {
```
with:
```dart
abstract final class StatGains {
  /// Applique [gain] à [stats] sous les [rules] de son porteur : celles de la
  /// classe pour le héros, `const []` pour un ennemi.
  ///
  /// Le paramètre est obligatoire à dessein (spec P-41, §4.1) : une valeur par
  /// défaut laisserait un site de gain oublié échapper aux règles sans que
  /// rien ne le dise, et c'est exactement ce qui est arrivé à la Maîtrise
  /// d'Armure (§1.3).
  static EntityStats apply(
    EntityStats stats,
    StatGain gain,
    List<StatRule> rules,
  ) {
    final converted = _convert(stats, gain, rules);
    if (converted != null) return converted;

    return switch (gain.resource) {
```

In the same file, replace:
```dart
      GainResource.might => stats.copyWith(
          might: stats.might + gain.amount,
        ),
    };
  }
}
```
with:
```dart
      GainResource.might => stats.copyWith(
          might: stats.might + gain.amount,
        ),
    };
  }

  /// Le gain converti par une règle qui le vise, ou `null` s'il n'y en a pas.
  ///
  /// Un gain nul ou négatif n'est jamais converti : il n'y a rien à
  /// transformer, et un statut de valeur négative n'a pas de sens.
  static EntityStats? _convert(
    EntityStats stats,
    StatGain gain,
    List<StatRule> rules,
  ) {
    if (gain.amount <= 0) return null;
    final stat = switch (gain.resource) {
      GainResource.armor => RuleStat.armor,
      GainResource.mana => RuleStat.mana,
      // La Puissance n'est jamais une `stat` de `statRules` : `HeroData` le
      // refuse au chargement (spec §7.1).
      GainResource.might => null,
    };
    if (stat == null) return null;

    for (final rule in rules) {
      if (rule.stat != stat || rule.mode != RuleMode.convert) continue;
      return switch (rule.to) {
        // R5 (spec §7.2) : la cible est la Puissance **temporaire**. Convertir
        // en Puissance permanente ferait gagner de la puissance définitive à
        // chaque `iron_wall` jouée, et casserait le jeu au troisième combat.
        RuleTarget.statusMight => stats.addStatus(
            StatusEffect(
              id: 'might',
              name: 'Puissance',
              type: StatusType.buff,
              value: gain.amount,
              duration: rule.duration,
            ),
          ),
      };
    }
    return null;
  }
}
```

- [ ] **Step 4: `RunState` porte les règles de la run**

In `lib/game/controllers/run_controller.dart`, replace:
```dart
  /// Cartes piochées au début de chaque tour, et taille de la main d'ouverture.
  /// Règle de run propre au joueur : elle n'a pas sa place sur `EntityStats`,
  /// qui est partagé avec les ennemis.
  final int cardsPerTurn;
```
with:
```dart
  /// Cartes piochées au début de chaque tour, et taille de la main d'ouverture.
  /// Règle de run propre au joueur : elle n'a pas sa place sur `EntityStats`,
  /// qui est partagé avec les ennemis.
  final int cardsPerTurn;

  /// Les règles de stat de la classe (spec P-41, §7.1), pour la même raison
  /// que `cardsPerTurn` : un ennemi n'en a jamais.
  ///
  /// **Jamais sérialisées.** Une règle est du contenu : `fromJsonWithReport`
  /// la relit de la classe, comme il relit déjà le passif actif. Les figer
  /// dans une sauvegarde ferait survivre à une modification du `class.json`
  /// une run qui n'en tiendrait pas compte.
  final List<StatRule> statRules;
```

In the same file, replace:
```dart
    this.pendingDrafts = 0,
    this.cardsPerTurn = 5,
  });
```
with:
```dart
    this.pendingDrafts = 0,
    this.cardsPerTurn = 5,
    this.statRules = const [],
  });
```

In `copyWith`, replace:
```dart
    int? pendingDrafts,
    int? cardsPerTurn,
  }) {
```
with:
```dart
    int? pendingDrafts,
    int? cardsPerTurn,
    List<StatRule>? statRules,
  }) {
```
and replace:
```dart
      pendingDrafts: pendingDrafts ?? this.pendingDrafts,
      cardsPerTurn: cardsPerTurn ?? this.cardsPerTurn,
    );
  }
```
with:
```dart
      pendingDrafts: pendingDrafts ?? this.pendingDrafts,
      cardsPerTurn: cardsPerTurn ?? this.cardsPerTurn,
      statRules: statRules ?? this.statRules,
    );
  }
```

In `fromJsonWithReport`, replace:
```dart
      pendingDrafts: json['pendingDrafts'] as int? ?? 0,
      cardsPerTurn: json['cardsPerTurn'] as int? ?? 5,
    );
```
with:
```dart
      pendingDrafts: json['pendingDrafts'] as int? ?? 0,
      cardsPerTurn: json['cardsPerTurn'] as int? ?? 5,
      // Relues de la classe, jamais de la sauvegarde. Registre absent ou
      // classe inconnue : aucune règle — `state_sync_system.dart` traite déjà
      // un `heroClassId` inconnu comme un bug de sauvegarde, pas comme un cas
      // à masquer.
      statRules:
          HeroData.getById(json['heroClassId'] as String)?.statRules ??
              const [],
    );
```

Add the import at the top of the file, next to the other model imports:
```dart
import '../../models/data/stat_rule.dart';
```

In `startNewRun`, replace:
```dart
      mapNodes: generatedMap,
      currentNodeId: null,
      pendingDrafts: 0,
    );
```
with:
```dart
      mapNodes: generatedMap,
      currentNodeId: null,
      pendingDrafts: 0,
      statRules: chosenClass.statRules,
    );
```

In `startTurn`, replace:
```dart
    final updatedStats = StatusEffectProcessor.processPlayerStatuses(state.heroStats);
```
with:
```dart
    final updatedStats = StatusEffectProcessor.processPlayerStatuses(
      state.heroStats,
      state.statRules,
    );
```

- [ ] **Step 5: Les six sites de gain décident**

In `lib/game/controllers/run/player_stats_manager.dart`, replace:
```dart
        heroStats: StatGains.apply(
          modifiedStats,
          StatGain(GainResource.might, mightAcc, GainSource.progression),
        ),
```
with:
```dart
        heroStats: StatGains.apply(
          modifiedStats,
          StatGain(GainResource.might, mightAcc, GainSource.progression),
          controller.currentState.statRules,
        ),
```
and replace:
```dart
        heroStats: StatGains.apply(controller.currentState.heroStats, gain),
```
with:
```dart
        heroStats: StatGains.apply(
          controller.currentState.heroStats,
          gain,
          controller.currentState.statRules,
        ),
```

In `lib/game/controllers/combat/status_effect_processor.dart`, replace:
```dart
import '../../../models/entity_stats.dart';
import '../../../models/status_effect.dart';
import '../../systems/stat_gains.dart';

class StatusEffectProcessor {
  /// Applique les effets de statut de début de tour sur le joueur.
  /// Retourne les nouvelles statistiques du joueur.
  static EntityStats processPlayerStatuses(EntityStats stats) {
```
with:
```dart
import '../../../models/data/stat_rule.dart';
import '../../../models/entity_stats.dart';
import '../../../models/status_effect.dart';
import '../../systems/stat_gains.dart';

class StatusEffectProcessor {
  /// Applique les effets de statut de début de tour sur le joueur.
  /// Retourne les nouvelles statistiques du joueur.
  ///
  /// [rules] vient de l'appelant, `RunController.startTurn` : cette méthode ne
  /// reçoit que des stats et ne peut pas les deviner (spec P-41, §4.1).
  static EntityStats processPlayerStatuses(
    EntityStats stats,
    List<StatRule> rules,
  ) {
```

In the same file, in `processPlayerStatuses`, replace:
```dart
      updatedStats = StatGains.apply(
        updatedStats,
        StatGain(GainResource.armor, armorGain, GainSource.status),
      );
    }

    return updatedStats.tickStatuses();
  }

  /// Applique les effets de statut de début de tour sur un ennemi.
```
with:
```dart
      updatedStats = StatGains.apply(
        updatedStats,
        StatGain(GainResource.armor, armorGain, GainSource.status),
        rules,
      );
    }

    return updatedStats.tickStatuses();
  }

  /// Applique les effets de statut de début de tour sur un ennemi.
```

In the same file, in `processEnemyStatuses`, replace:
```dart
      updatedStats = StatGains.apply(
        updatedStats,
        StatGain(GainResource.armor, armorGain, GainSource.status),
      );
    }

    return updatedStats.tickStatuses();
  }
}
```
with:
```dart
      updatedStats = StatGains.apply(
        updatedStats,
        StatGain(GainResource.armor, armorGain, GainSource.status),
        // Un ennemi ne porte aucune règle de classe : il ne joue pas de carte
        // et n'a pas d'identité à orienter (spec P-41, §7.1).
        const [],
      );
    }

    return updatedStats.tickStatuses();
  }
}
```

In `lib/game/controllers/combat/turn_phase_manager.dart`, replace:
```dart
          stats: StatGains.apply(
            enemy.stats,
            StatGain(GainResource.armor, intent.value, GainSource.enemyIntent),
          ),
```
with:
```dart
          stats: StatGains.apply(
            enemy.stats,
            StatGain(GainResource.armor, intent.value, GainSource.enemyIntent),
            const [],
          ),
```

In `lib/tutorial/tutorial_engine.dart`, replace:
```dart
        mockState.heroStats = StatGains.apply(
          mockState.heroStats,
          StatGain(GainResource.armor, scaled, GainSource.card),
        );
```
with:
```dart
        mockState.heroStats = StatGains.apply(
          mockState.heroStats,
          StatGain(GainResource.armor, scaled, GainSource.card),
          // Les règles viennent de la classe choisie, jamais d'une recopie
          // (ADR-081, spec P-41, §9.1). Une classe qui convertit son armure
          // la convertit donc aussi au tutoriel.
          mockState.chosenHero?.statRules ?? const [],
        );
```

- [ ] **Step 6: Lancer le test pour le voir passer**

Run: `flutter test test/unit/stat_rule_conversion_test.dart`
Expected: `+10: All tests passed!`

- [ ] **Step 7: Les tests qui appellent les deux fonctions**

In `test/unit/stat_gains_test.dart`, replace:
```dart
      test('armure de source ${source.name} : la valeur seule', () {
        final gain = StatGain(GainResource.armor, 2, source);
        expect(StatGains.apply(stats(), gain).armure, 1 + 2);
      });
    }

    test('mana : aucun plafond', () {
      const gain = StatGain(GainResource.mana, 2, GainSource.card);
      expect(StatGains.apply(stats(), gain).currentMana, 3 + 2);
    });

    test('Puissance : un gain ajoute, un gain negatif retire', () {
      final s = stats();
      expect(
        StatGains.apply(s, const StatGain(GainResource.might, 4, GainSource.progression)).might,
        2 + 4,
      );
      expect(
        StatGains.apply(s, const StatGain(GainResource.might, -2, GainSource.progression)).might,
        0,
      );
    });

    test('un gain ne touche a rien d autre', () {
      const gain = StatGain(GainResource.armor, 2, GainSource.card);
      final after = StatGains.apply(stats(), gain);
```
with:
```dart
      test('armure de source ${source.name} : la valeur seule', () {
        final gain = StatGain(GainResource.armor, 2, source);
        expect(StatGains.apply(stats(), gain, const []).armure, 1 + 2);
      });
    }

    test('mana : aucun plafond', () {
      const gain = StatGain(GainResource.mana, 2, GainSource.card);
      expect(StatGains.apply(stats(), gain, const []).currentMana, 3 + 2);
    });

    test('Puissance : un gain ajoute, un gain negatif retire', () {
      final s = stats();
      expect(
        StatGains.apply(s, const StatGain(GainResource.might, 4, GainSource.progression), const []).might,
        2 + 4,
      );
      expect(
        StatGains.apply(s, const StatGain(GainResource.might, -2, GainSource.progression), const []).might,
        0,
      );
    });

    test('un gain ne touche a rien d autre', () {
      const gain = StatGain(GainResource.armor, 2, GainSource.card);
      final after = StatGains.apply(stats(), gain, const []);
```

In `test/unit/stat_gains_characterization_test.dart`, replace:
```dart
      final stats = StatusEffectProcessor.processPlayerStatuses(
        heroStats().addStatus(metallicize),
      );
```
with:
```dart
      final stats = StatusEffectProcessor.processPlayerStatuses(
        heroStats().addStatus(metallicize),
        const [],
      );
```

- [ ] **Step 8: Vérifier qu'aucun site n'a été oublié**

Run: `git grep -n "StatGains.apply" -- lib`
Expected: six occurrences, chacune avec son troisième argument — `statRules` de la run pour les deux de `player_stats_manager.dart`, la classe choisie pour `tutorial_engine.dart`, `rules` pour le joueur et `const []` pour l'ennemi dans `status_effect_processor.dart`, `const []` dans `turn_phase_manager.dart`.

- [ ] **Step 9: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+959: All tests passed!` (949 + 10)

- [ ] **Step 10: Commit**

```bash
git add lib/game/systems/stat_gains.dart lib/game/controllers lib/tutorial/tutorial_engine.dart test/unit/stat_rule_conversion_test.dart test/unit/stat_gains_test.dart test/unit/stat_gains_characterization_test.dart
git commit -F- <<'EOF'
feat(classes): les regles de stat en parametre obligatoire des gains

StatGains.apply recoit les regles de son porteur : celles de la classe
pour le heros, une liste vide pour un ennemi, et le compilateur a
designe les six sites. La conversion vise la Puissance temporaire, pas
la permanente (regle R5) : l armure d un tour devient de la Puissance
d un tour. Aucune classe n en declare encore.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 3: L'identité des trois classes

**C'est la tâche où le jeu change.** Trois fichiers de données, une ligne de code pour le critique, une ligne de non-code pour le tutoriel.

**Files:**
- Modify: `assets/data/classes/paladin/class.json`, `berserker/class.json`, `mage/class.json` ; `lib/game/controllers/run_controller.dart` (`startNewRun`) ; `lib/tutorial/tutorial_engine.dart` (`baseStatsForHero`) ; `lib/services/content_editor/entity_descriptor.dart` (gabarit de classe)
- Test: `test/unit/class_identity_test.dart` *(nouveau)* ; `test/unit/content_editor/entity_descriptor_test.dart:148`, `:236`

**Interfaces:**
- Consumes: `HeroData.statRules`, `HeroData.critChance` (Task 1) ; `RunState.statRules` (Task 2).
- Produces: les trois classes déclarent leur identité ; `EntityStats.critChance` du héros vient de sa classe. Aucune nouvelle signature.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/class_identity_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';
import 'package:roguelike_card_game/models/might_target.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';

/// L'identité des trois classes, lue sur les vrais `class.json`
/// (spec P-41, §7.1 et §7.3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;

  // `setUpAll` : `GameDataRegistry` écrit un singleton statique dans son
  // constructeur, donc un seul registre par fichier de test.
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  HeroData hero(String id) => registry.heroes.firstWhere((h) => h.id == id);

  group('l orientation de la Puissance', () {
    test('le Paladin renforce tout : c est son identite de generaliste', () {
      expect(hero('paladin').mightTargets, {
        MightTarget.attack,
        MightTarget.skill,
        MightTarget.alteration,
      });
    });

    test('le Berserker frappe en direct, et seulement ainsi', () {
      expect(hero('berserker').mightTargets, {MightTarget.attack});
    });

    test('le Mage frappe par ses Competences et ses alterations', () {
      expect(hero('mage').mightTargets, {
        MightTarget.skill,
        MightTarget.alteration,
      });
    });
  });

  group('les regles de stat', () {
    test('le Berserker convertit son armure en Puissance d un tour', () {
      final rule = hero('berserker').statRules.single;
      expect(rule.stat, RuleStat.armor);
      expect(rule.mode, RuleMode.convert);
      expect(rule.to, RuleTarget.statusMight);
      expect(rule.duration, 1);
    });

    test('le Paladin et le Mage n en declarent aucune', () {
      expect(hero('paladin').statRules, isEmpty);
      expect(hero('mage').statRules, isEmpty);
    });
  });

  group('les stats de depart', () {
    test('le Paladin part avec de la Maitrise, qui amplifie son passif', () {
      expect(hero('paladin').mastery, greaterThan(0));
      expect(hero('paladin').critChance, 0);
    });

    test('le Berserker part avec du critique, sans toucher a la Puissance', () {
      expect(hero('berserker').critChance, greaterThan(0));
      expect(hero('berserker').mastery, 0);
    });

    test('le Mage ne part avec aucune stat : son identite est ailleurs', () {
      expect(hero('mage').mastery, 0);
      expect(hero('mage').critChance, 0);
    });

    // P-16 : un point de mana vaut environ +33 % d'actions par tour, le
    // levier le plus explosif du jeu. Differencier le mana avant
    // l'assainissement de son economie coulerait le defaut dans le beton des
    // classes (spec §7.3).
    test('maxMana reste a 3 partout, et luck a 0', () {
      for (final h in registry.heroes) {
        expect(h.maxMana, 3, reason: h.id);
        expect(h.luck, 0, reason: h.id);
      }
    });
  });

  group('ce que la run et le tutoriel en font', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('startNewRun copie le critique de la classe', () {
      final run = container.read(runProvider.notifier);
      run.startNewRun(hero('berserker'));

      final stats = run.currentState.heroStats;
      expect(stats.critChance, hero('berserker').critChance);
      expect(stats.mastery, 0);
      expect(run.currentState.statRules, hero('berserker').statRules);
    });

    // Un tutoriel dont les degats varient ne peut pas annoncer ce que fera
    // une carte : exception explicite et testee a la fidelite d'ADR-081
    // (spec §9.1, decision 5 du plan).
    test('le tutoriel ne recopie pas le critique de la classe', () {
      final mock = TutorialMockState()..chosenHero = hero('berserker');
      expect(hero('berserker').critChance, greaterThan(0));
      expect(mock.baseStatsForHero().critChance, 0);
      expect(
        mock.baseStatsForHero().mightTargets,
        hero('berserker').mightTargets,
        reason: 'l orientation, elle, est fidele',
      );
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/class_identity_test.dart`
Expected: FAIL — le Paladin n'oriente sa Puissance que vers `attack`, et aucune classe ne déclare `statRules`, `mastery` ni `critChance`.

- [ ] **Step 3: Les trois fichiers de classe**

In `assets/data/classes/paladin/class.json`, replace:
```json
  "luck": 0,
  "mightTargets": ["attack"],
```
with:
```json
  "luck": 0,
  "mastery": 1,
  "mightTargets": ["attack", "skill", "alteration"],
```

In `assets/data/classes/berserker/class.json`, replace:
```json
  "luck": 0,
  "mightTargets": ["attack"],
```
with:
```json
  "luck": 0,
  "critChance": 10,
  "mightTargets": ["attack"],
  "statRules": [
    { "stat": "armor", "mode": "convert", "to": "status:might", "duration": 1 }
  ],
```

In `assets/data/classes/mage/class.json`, replace:
```json
  "luck": 0,
  "mightTargets": ["attack"],
```
with:
```json
  "luck": 0,
  "mightTargets": ["skill", "alteration"],
```

- [ ] **Step 4: La run copie le critique de la classe**

In `lib/game/controllers/run_controller.dart`, in `startNewRun`, replace:
```dart
        mightTargets: chosenClass.mightTargets,
        luck: chosenClass.luck,
      ),
```
with:
```dart
        mightTargets: chosenClass.mightTargets,
        critChance: chosenClass.critChance,
        luck: chosenClass.luck,
      ),
```

- [ ] **Step 5: Le tutoriel garde ses dégâts déterministes**

In `lib/tutorial/tutorial_engine.dart`, in `baseStatsForHero`, replace:
```dart
    return EntityStats(
      maxPv: hero.maxHp,
      currentPv: hero.maxHp,
      maxMana: hero.maxMana,
      currentMana: hero.maxMana,
      armure: 0,
      mastery: hero.mastery,
      might: 0,
      mightTargets: hero.mightTargets,
      luck: hero.luck,
    );
```
with:
```dart
    // `critChance` est volontairement absent : le tutoriel le force à 0.
    // Ses démonstrations annoncent les dégâts d'une carte avant de la jouer
    // (`DamagePipeline` tire le critique au hasard), et un Berserker à
    // `critChance` > 0 les rendrait faux une fois sur dix. C'est l'unique
    // exception, explicite et testée, à la fidélité au jeu d'ADR-081
    // (spec P-41, §9.1) : tout le reste de l'identité de la classe est copié,
    // orientation de la Puissance et règles de stat comprises.
    return EntityStats(
      maxPv: hero.maxHp,
      currentPv: hero.maxHp,
      maxMana: hero.maxMana,
      currentMana: hero.maxMana,
      armure: 0,
      mastery: hero.mastery,
      might: 0,
      mightTargets: hero.mightTargets,
      luck: hero.luck,
    );
```

- [ ] **Step 6: Le gabarit de classe de l'éditeur de contenu**

Le gabarit doit exposer toute stat que le modèle lit, sans quoi le champ n'existe pas dans le formulaire — `entity_descriptor_test.dart:148` l'exige.

In `lib/services/content_editor/entity_descriptor.dart`, in the `heroClass` descriptor, replace:
```dart
    // Ni `classCard` ni `skills` ne figurent au gabarit : l'ecrivain calcule
    // le premier, et `_registerSignatureCard` remplit le second a chaque carte
    // de classe ecrite. `themeColor` y figure au magenta : une classe dont la
    // couleur n'a pas ete choisie doit se voir.
    template: '''
{
  "maxHp": 100,
  "maxMana": 3,
  "baseDamage": 5,
  "luck": 0,
  "mastery": 0,
  "mightTargets": ["attack"],
  "displayOrder": 99,
  "themeColor": "#FF00FF"
}''',
```
with:
```dart
    // Ni `classCard` ni `skills` ne figurent au gabarit : l'ecrivain calcule
    // le premier, et `_registerSignatureCard` remplit le second a chaque carte
    // de classe ecrite. `themeColor` y figure au magenta : une classe dont la
    // couleur n'a pas ete choisie doit se voir.
    //
    // `statRules` n'y figure pas non plus, et n'est pas valide : la spec de
    // P-41 place l'edition des regles de stat au lot D (§9.2), avec la
    // validation d'une liste de valeurs bornees imbriquee. Seule la vue JSON
    // brute l'atteint d'ici la. `mightTargets` l'est depuis la partie 1.
    template: '''
{
  "maxHp": 100,
  "maxMana": 3,
  "baseDamage": 5,
  "luck": 0,
  "mastery": 0,
  "critChance": 0,
  "mightTargets": ["attack"],
  "displayOrder": 99,
  "themeColor": "#FF00FF"
}''',
```

In `test/unit/content_editor/entity_descriptor_test.dart`, in the list of keys the class template must expose, replace:
```dart
      'luck',
      'mastery',
      'mightTargets',
      'displayOrder',
      'themeColor',
    ]) {
```
with:
```dart
      'luck',
      'mastery',
      'critChance',
      'mightTargets',
      'displayOrder',
      'themeColor',
    ]) {
```
and in the exact-set table, replace:
```dart
      EntityCategory.heroClass: {
        'maxHp',
        'maxMana',
        'baseDamage',
        'luck',
        'mastery',
        'mightTargets',
        'displayOrder',
        'themeColor',
      },
```
with:
```dart
      EntityCategory.heroClass: {
        'maxHp',
        'maxMana',
        'baseDamage',
        'luck',
        'mastery',
        'critChance',
        'mightTargets',
        'displayOrder',
        'themeColor',
      },
```

- [ ] **Step 7: Lancer le test pour le voir passer**

Run: `flutter test test/unit/class_identity_test.dart`
Expected: `+11: All tests passed!`

- [ ] **Step 8: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+970: All tests passed!` (959 + 11)

Si un test **autre** que ceux de cette tâche rougit, c'est un test qui mesurait le jeu sans identité de classe : le lire, comprendre ce que l'identité change pour lui, et mettre l'attente à jour en le disant dans le commit. Ne jamais retirer l'assertion.

- [ ] **Step 9: Commit**

```bash
git add assets/data/classes lib/game/controllers/run_controller.dart lib/tutorial/tutorial_engine.dart lib/services/content_editor/entity_descriptor.dart test/unit/class_identity_test.dart test/unit/content_editor/entity_descriptor_test.dart
git commit -F- <<'EOF'
feat(classes): les trois classes orientent leur Puissance

Le Paladin renforce tout, le Berserker ses seules Attaques et convertit
son armure en Puissance d un tour, le Mage ses Competences et ses
alterations. Le Paladin part avec de la Maitrise, le Berserker avec du
critique. Le tutoriel garde ses degats deterministes : il ne recopie
pas le critique, seule exception a sa fidelite au jeu.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 4: Ce qui déclenche les neuf passifs

Les passifs ne reçoivent aujourd'hui que quatre événements sur huit, et un événement ne porte que la carte jouée. Cette tâche pose le déclencheur manquant, les trois charges utiles, les trois points de dispatch absents et les compteurs. **Aucun passif livré ne les utilise encore** : le jeu ne change pas.

**Files:**
- Create: `lib/game/systems/passives/passive_counters.dart`
- Modify: `lib/models/data/relic_data.dart:5-15` ; `lib/game/systems/passives/passive_strategy.dart` ; `lib/game/controllers/run_controller.dart` (`startTurn`, `takeDamage`, `onEnemyKilled`, `removeStatus`) ; `lib/game/controllers/run/player_stats_manager.dart` ; `lib/game/controllers/combat_controller.dart:226-232` ; `lib/ui/screens/card_dictionary_screen.dart:264`, `lib/ui/widgets/map/dialogs/relics_dialog.dart:164`, `lib/ui/widgets/relic_carousel/relic_carousel_card.dart:24`
- Test: `test/unit/passive_triggers_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: rien de Task 1-3.
- Produces:
  - `RelicTrigger.onDamageTaken`, ajouté **en fin d'énumération**.
  - `PassiveEvent(RelicTrigger trigger, {CardInstance? card, String? enemyId, int? absorbedDamage, int? survivingArmor})` — toujours `const`-constructible.
  - `enum CounterScope { turn, combat }` et `PassiveCounters` (`idOf`, `valueOf`, `bump`, `clear`) dans `lib/game/systems/passives/passive_counters.dart`.
  - `RunController.removeStatus(String id)` → `PlayerStatsManager.removeStatus`.
  - Dispatches ajoutés : `onAttackPlayed` / `onSkillPlayed` / `onPowerPlayed` (`CombatController.applyPlayerCardPlay`), `onEnemyKilled` (`RunController.onEnemyKilled`), `onDamageTaken` (`RunController.takeDamage`).
  - `PassiveEvent.survivingArmor`, rempli par `startTurn`, n'a pas de lecteur avant Task 6 : il y est testé par *Bénédiction*.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/passive_triggers_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/passives/passive_counters.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';

/// Ce qui déclenche un passif (spec P-41, §6.4) : les déclencheurs que le
/// lot B pose, et les compteurs par tour et par combat.
void main() {
  const hero = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
  );

  /// Un passif observable : deux points d'armure, quel que soit l'événement.
  PassiveData armorOn(RelicTrigger trigger) => PassiveData(
        id: 'test_passive',
        trigger: trigger,
        effectType: 'gain_armor',
        value: 2,
      );

  final slime = EnemyData(
    id: 'slime',
    nameEn: 'Slime',
    nameFr: 'Slime',
    maxHp: 10,
    baseDamage: 1,
    spritePath: 'slime.png',
    tier: 1,
    intents: [EnemyIntent(type: IntentType.attack, value: 1)],
  );

  late ProviderContainer container;
  late RunController run;
  late CombatController combat;

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
    combat = container.read(combatProvider.notifier);
  });

  tearDown(() => container.dispose());

  int armor() => run.currentState.heroStats.armure;

  /// Pose un ennemi vivant et le sélectionne.
  String seedEnemy({int hp = 10}) {
    final enemy = EnemyInstance(
      data: slime,
      stats: EntityStats(maxPv: 10, currentPv: hp, armure: 0, might: 0),
    );
    combat.state = CombatState(
      enemies: [enemy],
      selectedEnemyId: enemy.id,
      turnPhase: TurnPhase.player,
    );
    return enemy.id;
  }

  CardInstance card(CardType type) => CardInstance(
        data: CardData(
          id: 'test_card',
          cost: 0,
          type: type,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: const [CardEffect(type: 'damage', value: 1)],
        ),
      );

  group('les declencheurs par type de carte', () {
    test('onAttackPlayed atteint le passif', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onAttackPlayed));
      seedEnemy();
      combat.applyPlayerCardPlay(card(CardType.attack));
      expect(armor(), 2);
    });

    test('onSkillPlayed atteint le passif', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onSkillPlayed));
      seedEnemy();
      combat.applyPlayerCardPlay(card(CardType.skill));
      expect(armor(), 2);
    });

    test('le type d une carte ne declenche pas celui d une autre', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onSkillPlayed));
      seedEnemy();
      combat.applyPlayerCardPlay(card(CardType.attack));
      expect(armor(), 0);
    });

    // `onCardPlayed` reste servi : c'est le declencheur de P-49.
    test('onCardPlayed reste servi, quel que soit le type', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onCardPlayed));
      seedEnemy();
      combat.applyPlayerCardPlay(card(CardType.attack));
      expect(armor(), 2);
    });
  });

  group('onEnemyKilled', () {
    test('atteint le passif', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onEnemyKilled));
      run.onEnemyKilled();
      expect(armor(), 2);
    });
  });

  group('onDamageTaken', () {
    test('se declenche sur ce que l armure a encaisse', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onDamageTaken));
      run.updateState(
        run.currentState.copyWith(
          heroStats: run.currentState.heroStats.copyWith(armure: 10),
        ),
      );

      run.takeDamage(4);

      // 10 d'armure, 4 encaisses, puis les 2 du passif.
      expect(armor(), 10 - 4 + 2);
      expect(run.currentState.heroStats.currentPv, 100);
    });

    test('sans armure, rien n est encaisse et rien ne se declenche', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onDamageTaken));
      run.takeDamage(4);

      expect(armor(), 0);
      expect(run.currentState.heroStats.currentPv, 100 - 4);
    });
  });

  group('les compteurs', () {
    final counted = armorOn(RelicTrigger.onAttackPlayed);

    test('un compteur de tour disparait au tour suivant', () {
      run.startNewRun(hero);
      expect(
        PassiveCounters.bump(run, counted, scope: CounterScope.turn),
        1,
      );
      expect(
        PassiveCounters.bump(run, counted, scope: CounterScope.turn),
        2,
      );

      run.startTurn();
      expect(PassiveCounters.valueOf(run, counted), 0);
    });

    test('un compteur de combat traverse les tours, et clear le vide', () {
      run.startNewRun(hero);
      PassiveCounters.bump(run, counted, scope: CounterScope.combat);

      run.startTurn();
      expect(PassiveCounters.valueOf(run, counted), 1);

      PassiveCounters.clear(run, counted);
      expect(PassiveCounters.valueOf(run, counted), 0);
    });
  });
}
```

**Note d'écriture :** l'armure du premier test de `onDamageTaken` est posée par `updateState` / `copyWith` et non par `run.grant`, parce que le Paladin de fixture n'a aucune règle de stat mais qu'un `grant` ferait passer le test par toute la chaîne de Task 2 : ici, seul le dispatch est en cause.

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/passive_triggers_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../passive_counters.dart'` et `RelicTrigger.onDamageTaken` inconnu.

- [ ] **Step 3: Le déclencheur, et ses trois libellés**

In `lib/models/data/relic_data.dart`, replace:
```dart
enum RelicTrigger {
  startOfRun,
  startOfCombat,
  startOfTurn,
  endOfTurn,
  onCardPlayed,
  onEnemyKilled,
  onAttackPlayed,
  onSkillPlayed,
  onPowerPlayed,
}
```
with:
```dart
enum RelicTrigger {
  startOfRun,
  startOfCombat,
  startOfTurn,
  endOfTurn,
  onCardPlayed,
  onEnemyKilled,
  onAttackPlayed,
  onSkillPlayed,
  onPowerPlayed,

  /// Le héros vient de subir des dégâts. Posé par le lot B de P-41 (spec §6.4)
  /// pour le passif *Ferveur* ; aucune relique ne l'emploie. Les `switch` de
  /// l'énumération étant exhaustifs, le compilateur désigne ses trois lecteurs
  /// d'affichage.
  onDamageTaken,
}
```

Then, in each of the three files below, add the case at the end of the `switch (relic.trigger)`, after `RelicTrigger.onPowerPlayed`. Les libellés suivent le précédent posé par `onAttackPlayed` : écrits en ligne, faute de clé ARB — aucune relique ne porte ce déclencheur, et la partie 2 n'ajoute aucune clé.

In `lib/ui/screens/card_dictionary_screen.dart`, `lib/ui/widgets/map/dialogs/relics_dialog.dart` and `lib/ui/widgets/relic_carousel/relic_carousel_card.dart`, replace (in each file, once):
```dart
      case RelicTrigger.onPowerPlayed:
        triggerText = locale == 'fr' ? 'Pouvoir Joué' : 'Power Played';
        triggerColor = Colors.pinkAccent;
        break;
```
with:
```dart
      case RelicTrigger.onPowerPlayed:
        triggerText = locale == 'fr' ? 'Pouvoir Joué' : 'Power Played';
        triggerColor = Colors.pinkAccent;
        break;
      case RelicTrigger.onDamageTaken:
        triggerText = locale == 'fr' ? 'Dégâts Subis' : 'Damage Taken';
        triggerColor = Colors.deepOrangeAccent;
        break;
```

- [ ] **Step 4: Ce qu'un événement porte**

In `lib/game/systems/passives/passive_strategy.dart`, replace:
```dart
/// Ce qui déclenche un passif : le moment, et la carte jouée s'il y en a une.
class PassiveEvent {
  final RelicTrigger trigger;

  /// Renseignée pour `onCardPlayed`, `null` sinon.
  final CardInstance? card;

  const PassiveEvent(this.trigger, {this.card});
}
```
with:
```dart
/// Ce qui déclenche un passif : le moment, et ce que ce moment seul sait.
///
/// Une charge utile plutôt qu'une lecture par la stratégie, à chaque fois pour
/// la même raison : la valeur n'existe plus quand la stratégie s'exécute.
/// L'armure survivante a été remise à zéro, les dégâts encaissés ont été
/// absorbés, et la cible d'une carte n'est connue que de l'écran de combat.
class PassiveEvent {
  final RelicTrigger trigger;

  /// Renseignée pour `onCardPlayed` et les déclencheurs par type de carte,
  /// `null` sinon.
  final CardInstance? card;

  /// L'ennemi que visait la carte jouée, `null` s'il n'y en avait pas ou si la
  /// carte visait tout le monde.
  final String? enemyId;

  /// Ce que l'armure a réellement absorbé, pour `onDamageTaken`. Jamais
  /// renseigné pour des dégâts qui sont allés droit aux PV.
  final int? absorbedDamage;

  /// L'armure que le tour précédent a laissée, capturée par `startTurn` avant
  /// sa remise à zéro (spec §1.1, §6.3).
  final int? survivingArmor;

  const PassiveEvent(
    this.trigger, {
    this.card,
    this.enemyId,
    this.absorbedDamage,
    this.survivingArmor,
  });
}
```

- [ ] **Step 5: Les compteurs**

Create `lib/game/systems/passives/passive_counters.dart`:

```dart
import '../../../models/data/passive_data.dart';
import '../../../models/status_effect.dart';
import '../../controllers/run_controller.dart';

/// La portée d'un compteur de passif.
enum CounterScope {
  /// Remis à zéro au début du tour suivant : « la 1ʳᵉ attaque du tour ».
  turn,

  /// Tenu jusqu'à la fin du combat : « toutes les N Compétences ».
  combat,
}

/// Les compteurs d'un passif (spec P-41, §6.4).
///
/// Portés par un statut caché du héros, comme les charges de reliques
/// (`shuriken_charge`, `pen_nib_charge`, `incense_charge`) : la portée vient de
/// la durée du statut — 1 tour, ou 99 pour le combat entier —, les statuts sont
/// décrémentés au début de chaque tour et vidés à la fin de chaque combat
/// (`map_progression_manager.dart`). **Aucun état nouveau n'est à sérialiser**,
/// et un compteur ne survit jamais à son combat.
abstract final class PassiveCounters {
  /// L'identifiant du statut compteur d'un passif. Un passif par run étant
  /// actif, il n'y a jamais deux compteurs à distinguer, mais le nom porte
  /// l'id : une sauvegarde chargée avec un autre passif ne relit pas le
  /// compteur d'un précédent.
  static String idOf(PassiveData passive) => '${passive.id}_count';

  /// La valeur du compteur, 0 s'il n'y en a pas.
  static int valueOf(RunController run, PassiveData passive) {
    final id = idOf(passive);
    var total = 0;
    for (final status in run.currentState.heroStats.statuses) {
      if (status.id == id) total += status.value;
    }
    return total;
  }

  /// Incrémente le compteur de 1 et rend sa nouvelle valeur.
  static int bump(
    RunController run,
    PassiveData passive, {
    required CounterScope scope,
  }) {
    run.addStatus(
      StatusEffect(
        id: idOf(passive),
        name: 'Compteur',
        type: StatusType.buff,
        value: 1,
        duration: scope == CounterScope.turn ? 1 : 99,
      ),
    );
    return valueOf(run, passive);
  }

  /// Remet le compteur à zéro — ce que fait un passif à seuil quand il se
  /// déclenche.
  static void clear(RunController run, PassiveData passive) {
    run.removeStatus(idOf(passive));
  }
}
```

In `lib/game/controllers/run/player_stats_manager.dart`, after `addStatus`, add:
```dart
  /// Retire tout statut portant [id]. Les charges de reliques font aujourd'hui
  /// ce filtrage en ligne (`charge_might_combat` et ses voisins) ; les
  /// compteurs de passifs passent par ici.
  void removeStatus(String id) {
    final stats = controller.currentState.heroStats;
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: stats.copyWith(
          statuses: stats.statuses.where((s) => s.id != id).toList(),
        ),
      ),
    );
  }
```

In `lib/game/controllers/run_controller.dart`, after the `addStatus` façade, add:
```dart
  /// Retire tout statut portant [id]
  void removeStatus(String id) {
    _playerStatsManager.removeStatus(id);
  }
```

- [ ] **Step 6: Les trois points de dispatch manquants**

In `lib/game/controllers/run_controller.dart`, replace:
```dart
  /// Subit des dégâts
  void takeDamage(int amount, {bool isCrit = false}) {
    _playerStatsManager.takeDamage(amount, isCrit: isCrit);
  }
```
with:
```dart
  /// Subit des dégâts
  void takeDamage(int amount, {bool isCrit = false}) {
    final armorBefore = state.heroStats.armure;
    _playerStatsManager.takeDamage(amount, isCrit: isCrit);

    // Ce que l'armure a réellement absorbé : de quoi nourrir *Ferveur*, chez
    // qui encaisser devient une ressource offensive (spec §6.3). Les dégâts
    // de poison n'arrivent pas ici — ils sont appliqués par
    // `StatusEffectProcessor`, fonction pure sans controller — et ne
    // déclenchent donc pas le passif.
    final absorbed = amount <= 0
        ? 0
        : (amount < armorBefore ? amount : armorBefore);
    if (absorbed > 0) {
      TraitSystem.dispatch(
        this,
        PassiveEvent(RelicTrigger.onDamageTaken, absorbedDamage: absorbed),
      );
    }
  }
```

In the same file, replace:
```dart
  /// Déclenche les reliques d'élimination d'ennemi
  void onEnemyKilled() {
    _playerStatsManager.onEnemyKilled();
  }
```
with:
```dart
  /// Déclenche les reliques et le passif d'élimination d'ennemi. Appelé une
  /// fois par ennemi abattu (`CombatController.cleanDeadEnemies`), ce qui fait
  /// de *Frénésie* une boule de neige (spec §6.3).
  void onEnemyKilled() {
    _playerStatsManager.onEnemyKilled();
    TraitSystem.dispatch(this, const PassiveEvent(RelicTrigger.onEnemyKilled));
  }
```

In the same file, in `startTurn`, replace:
```dart
  void startTurn() {
    // 1. Restaurer le Mana à sa valeur maximale (ne se cumule pas d'un tour à l'autre) et reset l'armure
    state = state.copyWith(
```
with:
```dart
  void startTurn() {
    // L'armure que le tour précédent a laissée, avant sa remise à zéro : c'est
    // la seule valeur que *Bénédiction* peut convertir, et elle n'existe plus
    // une ligne plus bas (spec §1.1, §6.3).
    //
    // Capturée ici plutôt que le dispatch déplacé avant la remise à zéro :
    // là, tout passif `startOfTurn` qui donne de l'armure la verrait effacée
    // en silence — et cela vaudrait pour le prochain écrit comme pour
    // `berserker_armor` hier.
    final survivingArmor = state.heroStats.armure;

    // 1. Restaurer le Mana à sa valeur maximale (ne se cumule pas d'un tour à l'autre) et reset l'armure
    state = state.copyWith(
```
and, at the end of the same method, replace:
```dart
    // 4. Déclencher les traits passifs
    TraitSystem.dispatch(this, const PassiveEvent(RelicTrigger.startOfTurn));
  }
```
with:
```dart
    // 4. Déclencher les traits passifs
    TraitSystem.dispatch(
      this,
      PassiveEvent(RelicTrigger.startOfTurn, survivingArmor: survivingArmor),
    );
  }
```

In `lib/game/controllers/combat_controller.dart`, replace:
```dart
      // 3. Déclencher les traits passifs
      TraitSystem.dispatch(
        runController,
        PassiveEvent(RelicTrigger.onCardPlayed, card: card),
      );
```
with:
```dart
      // 3. Déclencher les traits passifs : l'événement générique, puis celui
      // du type de la carte — les mêmes que les reliques reçoivent juste
      // après. Un passif choisit son déclencheur par sa donnée, et n'a pas à
      // retester le type dans sa stratégie.
      final event = PassiveEvent(
        RelicTrigger.onCardPlayed,
        card: card,
        enemyId: state.selectedEnemyId,
      );
      TraitSystem.dispatch(runController, event);

      final typedTrigger = switch (card.data.type) {
        CardType.attack => RelicTrigger.onAttackPlayed,
        CardType.skill => RelicTrigger.onSkillPlayed,
        CardType.power => RelicTrigger.onPowerPlayed,
        // Une carte Statut ne se joue pas (`EffectResolver.canPlayCard`).
        CardType.status => null,
      };
      if (typedTrigger != null) {
        TraitSystem.dispatch(
          runController,
          PassiveEvent(
            typedTrigger,
            card: card,
            enemyId: state.selectedEnemyId,
          ),
        );
      }
```

- [ ] **Step 7: Lancer le test pour le voir passer**

Run: `flutter test test/unit/passive_triggers_test.dart`
Expected: `+9: All tests passed!`

- [ ] **Step 8: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+979: All tests passed!` (970 + 9)

- [ ] **Step 9: Commit**

```bash
git add lib/models/data/relic_data.dart lib/game/systems/passives lib/game/controllers lib/ui/screens/card_dictionary_screen.dart lib/ui/widgets/map/dialogs/relics_dialog.dart lib/ui/widgets/relic_carousel/relic_carousel_card.dart test/unit/passive_triggers_test.dart
git commit -F- <<'EOF'
feat(passifs): les declencheurs et les compteurs du lot B

onDamageTaken est pose, les passifs recoivent enfin les declencheurs
par type de carte et l elimination d un ennemi, et un evenement porte
ce que le moment seul sait : les degats encaisses, l armure survivante
avant sa remise a zero, l ennemi vise. Les compteurs par tour et par
combat sont portes par un statut cache, comme les charges de reliques.
Aucun passif livre ne les utilise encore.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 5: Ce qu'un passif déclare, et dans quel ordre il se présente

Quatre paramètres, parce que les neuf passifs en ont besoin : une durée (trois d'entre eux posent un statut temporaire), un seuil (*Flux de Mana*), une pioche (*Frénésie*) et un rang d'affichage (le lot C rangera trois choix ; d'ici là le premier est celui que le joueur obtient). Toujours aucun passif nouveau : le jeu ne change pas.

**Files:**
- Modify: `lib/models/data/passive_data.dart` ; `lib/game/systems/passive_availability.dart` ; `lib/services/content_editor/entity_descriptor.dart` (gabarit de passif)
- Test: `test/unit/passive_data_test.dart` ; `test/unit/passive_availability_test.dart` ; `test/unit/content_editor/entity_descriptor_test.dart:216`

**Interfaces:**
- Consumes: rien.
- Produces:
  - `PassiveData.duration` (int, 1 par défaut), `.threshold` (int, 0), `.draw` (int, 0), `.displayOrder` (int, 0), lus par `fromJson`, propagés par `_withValue` → renommé `_copyWith`.
  - `PassiveMastery.fields` = `['value', 'duration', 'threshold']` ; `withMastery` sait augmenter les trois.
  - `availablePassivesFor` trie par `(displayOrder, id)`.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/passive_data_test.dart`, before the final closing `}` of `main`, add:

```dart
  // Les quatre parametres du lot B de P-41 : ce dont les neuf passifs ont
  // besoin, et rien de plus.
  group('les parametres du lot B', () {
    test('absents : une duree de 1, aucun seuil, aucune pioche, rang 0', () {
      final passive = PassiveData.fromJson(passiveJson());
      expect(passive.duration, 1);
      expect(passive.threshold, 0);
      expect(passive.draw, 0);
      expect(passive.displayOrder, 0);
    });

    test('lus quand ils sont declares', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'duration': 2,
        'threshold': 3,
        'draw': 1,
        'displayOrder': 2,
      });
      expect(passive.duration, 2);
      expect(passive.threshold, 3);
      expect(passive.draw, 1);
      expect(passive.displayOrder, 2);
    });

    test('la Maitrise sait allonger une duree', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'duration': 2,
        'mastery': {
          'field': 'duration',
          'perPoint': 1,
          'description_en': '+{amount} turn',
          'description_fr': '+{amount} tour',
        },
      });
      expect(passive.withMastery(2).duration, 4);
      expect(passive.withMastery(2).value, passive.value);
    });

    // `perPoint` negatif : un seuil baisse quand la Maitrise monte. Borner le
    // resultat est l'affaire de la strategie qui le lit (spec P-49, §6.2).
    test('la Maitrise sait faire baisser un seuil', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'threshold': 3,
        'mastery': {
          'field': 'threshold',
          'perPoint': -1,
          'description_en': '-{amount} Skill to gather',
          'description_fr': '-{amount} Competence a reunir',
        },
      });
      expect(passive.withMastery(2).threshold, 1);
      expect(passive.mastery!.describe('fr', 2), '-2 Competence a reunir');
    });

    test('les trois parametres que la Maitrise peut viser sont declares', () {
      expect(PassiveMastery.fields, ['value', 'duration', 'threshold']);
    });
  });
```

In the same file, le test existant qui refuse un champ de Maîtrise inconnu **choisissait `duration` comme exemple**, qui devient valide : remplacer son exemple par `draw`, qui reste hors de la liste. Replace:
```dart
    test('un field inconnu est refuse', () {
      expect(
        () => PassiveData.fromJson({
          ...passiveJson(),
          'mastery': {...masteryJson(), 'field': 'duration'},
        }),
        throwsFormatException,
      );
    });
```
with:
```dart
    // `draw` est un parametre de `PassiveData` que la Maitrise ne vise pas :
    // l'exemple reste donc hors de `PassiveMastery.fields` (spec P-49, §6.2).
    test('un field inconnu est refuse', () {
      expect(
        () => PassiveData.fromJson({
          ...passiveJson(),
          'mastery': {...masteryJson(), 'field': 'draw'},
        }),
        throwsFormatException,
      );
    });
```

In `test/unit/passive_availability_test.dart`, replace:
```dart
  PassiveData passive(String id, {List<String>? classes}) => PassiveData(
        id: id,
        trigger: RelicTrigger.startOfTurn,
        effectType: 'gain_armor',
        value: 1,
        classes: classes,
      );
```
with:
```dart
  PassiveData passive(
    String id, {
    List<String>? classes,
    int displayOrder = 0,
  }) =>
      PassiveData(
        id: id,
        trigger: RelicTrigger.startOfTurn,
        effectType: 'gain_armor',
        value: 1,
        classes: classes,
        displayOrder: displayOrder,
      );
```
and, before the final closing `}` of `main`, add:

```dart
  // Le lot C offrira le choix entre les trois passifs d'une classe ; d'ici la,
  // l'ecran de selection prend le premier (`class_selection_screen.dart:158`).
  // Ce rang est donc ce qui decide du passif de depart : il est declare, pas
  // subi de l'ordre alphabetique.
  test('le rang d affichage passe avant l id', () {
    final registry = registryOf([
      passive('aegis', displayOrder: 3),
      passive('zeal', displayOrder: 1),
      passive('mind', displayOrder: 2),
    ]);
    expect(idsFor(paladin, registry), ['zeal', 'mind', 'aegis']);
  });

  test('a rang egal, l id tranche : l ordre reste deterministe', () {
    final registry = registryOf([
      passive('zeal', displayOrder: 1),
      passive('aegis', displayOrder: 1),
    ]);
    expect(idsFor(paladin, registry), ['aegis', 'zeal']);
  });
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/passive_data_test.dart test/unit/passive_availability_test.dart`
Expected: FAIL — `The named parameter 'displayOrder' isn't defined`, et `PassiveMastery.fields` vaut encore `['value']`.

- [ ] **Step 3: Les quatre paramètres**

In `lib/models/data/passive_data.dart`, replace:
```dart
  /// Les paramètres qu'un point de Maîtrise peut augmenter. Le lot B de P-41
  /// en ajoute un par paramètre qu'il crée sur [PassiveData] ; l'éditeur de
  /// contenu lit cette liste.
  static const List<String> fields = ['value'];
```
with:
```dart
  /// Les paramètres qu'un point de Maîtrise peut augmenter ; l'éditeur de
  /// contenu lit cette liste.
  ///
  /// `draw` n'en est pas : aucun des neuf passifs ne fait piocher une carte de
  /// plus par point de Maîtrise, et un champ que rien ne vise serait du code
  /// mort dans `withMastery`.
  static const List<String> fields = ['value', 'duration', 'threshold'];
```

In the same file, replace:
```dart
  final String effectType; // ex: 'gain_armor', 'berserker_armor', 'spell_armor'
  final int value;
```
with:
```dart
  final String effectType; // ex: 'gain_armor', 'rage', 'channeling'

  /// Le chiffre principal du passif : ce que sa stratégie en fait lui
  /// appartient — des points d'armure, de Puissance, de mana, de PV.
  final int value;

  /// La durée, en tours, du statut que le passif pose. Sans objet pour un
  /// passif qui n'en pose pas.
  final int duration;

  /// Le nombre d'occurrences à réunir avant que le passif agisse — le seuil de
  /// *Flux de Mana*. 0 : aucun seuil, le passif agit à chaque déclenchement.
  final int threshold;

  /// Les cartes que le passif fait piocher — *Frénésie*.
  final int draw;

  /// Rang d'affichage parmi les passifs d'une classe. Donnée de présentation,
  /// comme `HeroData.displayOrder` : l'ordre ne doit pas dépendre de l'ordre du
  /// catalogue ni de l'alphabet. Le lot C en fera trois choix rangés ; d'ici
  /// là, le premier est le passif que la classe obtient.
  final int displayOrder;
```

In the same file, replace:
```dart
    required this.effectType,
    required this.value,
    this.classes,
    this.mastery,
  });
```
with:
```dart
    required this.effectType,
    required this.value,
    this.duration = 1,
    this.threshold = 0,
    this.draw = 0,
    this.displayOrder = 0,
    this.classes,
    this.mastery,
  });
```

In the same file, replace:
```dart
    return switch (m.field) {
      'value' => _withValue(value + m.perPoint * points),
      // `fromJson` refuse tout autre champ ; un passif construit en code avec
      // un champ inconnu ignore sa Maîtrise plutôt que de lever en combat.
      _ => this,
    };
  }

  PassiveData _withValue(int newValue) => PassiveData(
        id: id,
        nameEn: nameEn,
        nameFr: nameFr,
        descriptionEn: descriptionEn,
        descriptionFr: descriptionFr,
        trigger: trigger,
        effectType: effectType,
        value: newValue,
        classes: classes,
        mastery: mastery,
      );
```
with:
```dart
    final delta = m.perPoint * points;
    return switch (m.field) {
      'value' => _copyWith(value: value + delta),
      'duration' => _copyWith(duration: duration + delta),
      'threshold' => _copyWith(threshold: threshold + delta),
      // `fromJson` refuse tout autre champ ; un passif construit en code avec
      // un champ inconnu ignore sa Maîtrise plutôt que de lever en combat.
      _ => this,
    };
  }

  PassiveData _copyWith({int? value, int? duration, int? threshold}) =>
      PassiveData(
        id: id,
        nameEn: nameEn,
        nameFr: nameFr,
        descriptionEn: descriptionEn,
        descriptionFr: descriptionFr,
        trigger: trigger,
        effectType: effectType,
        value: value ?? this.value,
        duration: duration ?? this.duration,
        threshold: threshold ?? this.threshold,
        draw: draw,
        displayOrder: displayOrder,
        classes: classes,
        mastery: mastery,
      );
```

In the same file, in `fromJson`, replace:
```dart
      effectType: json['effectType'] as String,
      value: json['value'] as int,
      classes: classesJson?.map((e) => e as String).toList(),
```
with:
```dart
      effectType: json['effectType'] as String,
      value: json['value'] as int,
      duration: json['duration'] as int? ?? 1,
      threshold: json['threshold'] as int? ?? 0,
      draw: json['draw'] as int? ?? 0,
      displayOrder: json['displayOrder'] as int? ?? 0,
      classes: classesJson?.map((e) => e as String).toList(),
```

- [ ] **Step 4: L'ordre de présentation**

In `lib/game/systems/passive_availability.dart`, replace:
```dart
/// Triés par `id`, pour ne pas dépendre de l'ordre de lecture des fichiers.
/// Fonction pure, sans provider : le tutoriel l'appelle comme le jeu (ADR-081).
```
with:
```dart
/// Triés par `displayOrder` puis par `id` : le rang est déclaré par la donnée,
/// et l'`id` tranche à rang égal — pour ne dépendre ni de l'ordre de lecture
/// des fichiers ni de l'alphabet (spec P-41, §8.3).
/// Fonction pure, sans provider : le tutoriel l'appelle comme le jeu (ADR-081).
```
and replace:
```dart
    ..sort((a, b) => a.id.compareTo(b.id));
```
with:
```dart
    ..sort((a, b) {
      final byOrder = a.displayOrder.compareTo(b.displayOrder);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
```

- [ ] **Step 5: Le gabarit de passif de l'éditeur de contenu**

In `lib/services/content_editor/entity_descriptor.dart`, in the `passive` descriptor, replace:
```dart
    template: '''
{
  "trigger": "startOfTurn",
  "effectType": "gain_armor",
  "value": 2,
  "mastery": {
    "field": "value",
    "perPoint": 1,
    "description_fr": "+{amount} Armure en debut de tour",
    "description_en": "+{amount} Block at start of turn"
  }
}''',
```
with:
```dart
    template: '''
{
  "trigger": "startOfTurn",
  "effectType": "gain_armor",
  "value": 2,
  "duration": 1,
  "threshold": 0,
  "draw": 0,
  "displayOrder": 0,
  "mastery": {
    "field": "value",
    "perPoint": 1,
    "description_fr": "+{amount} Armure en debut de tour",
    "description_en": "+{amount} Block at start of turn"
  }
}''',
```

In `test/unit/content_editor/entity_descriptor_test.dart`, replace:
```dart
      EntityCategory.passive: {'trigger', 'effectType', 'value', 'mastery'},
```
with:
```dart
      EntityCategory.passive: {
        'trigger',
        'effectType',
        'value',
        'duration',
        'threshold',
        'draw',
        'displayOrder',
        'mastery',
      },
```

- [ ] **Step 6: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/passive_data_test.dart test/unit/passive_availability_test.dart test/unit/content_editor/entity_descriptor_test.dart`
Expected: tout vert, avec 7 tests de plus qu'avant la tâche.

- [ ] **Step 7: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+986: All tests passed!` (979 + 7)

- [ ] **Step 8: Commit**

```bash
git add lib/models/data/passive_data.dart lib/game/systems/passive_availability.dart lib/services/content_editor/entity_descriptor.dart test/unit/passive_data_test.dart test/unit/passive_availability_test.dart test/unit/content_editor/entity_descriptor_test.dart
git commit -F- <<'EOF'
feat(passifs): duree, seuil, pioche et rang d affichage

Les quatre parametres dont les neuf passifs ont besoin. La Maitrise
sait desormais viser une duree et un seuil, avec un perPoint negatif
pour un seuil qui baisse. Le rang d affichage decide du passif de
depart tant que le lot C n offre pas le choix : declare, et non subi
de l ordre alphabetique.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 6: Les trois passifs du Paladin

*Régénération d'Armure* est reprise telle quelle et gagne son rang. *Ferveur* referme une boucle propre — chez le Paladin, encaisser devient une ressource offensive. *Bénédiction* convertit l'armure survivante en PV, et c'est le seul passif du jeu dont l'ordre d'exécution est contraignant : son test est celui qui le couvre.

**Files:**
- Create: `assets/data/passives/fervor.json`, `assets/data/passives/blessing.json`
- Modify: `assets/data/passives/regen_armor.json` ; `lib/game/systems/passives/passive_strategies.dart`
- Test: `test/unit/passives_paladin_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `PassiveEvent.absorbedDamage`, `PassiveEvent.survivingArmor` (Task 4) ; `PassiveData.duration`, `.displayOrder` (Task 5).
- Produces: les `effectType` `fervor` et `blessing` dans `PassiveStrategies.byEffectType`, servis par `FervorPassive` et `BlessingPassive`.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/passives_paladin_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les trois passifs du Paladin (spec P-41, §6.3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const paladin = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
  );

  const master = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
    mastery: 2,
  );

  PassiveData fervor({int value = 1, int duration = 2}) => PassiveData(
        id: 'fervor',
        trigger: RelicTrigger.onDamageTaken,
        effectType: 'fervor',
        value: value,
        duration: duration,
        mastery: const PassiveMastery(
          field: 'value',
          perPoint: 1,
          descriptionEn: '+{amount} Might',
          descriptionFr: '+{amount} Puissance',
        ),
      );

  PassiveData blessing({int value = 1}) => PassiveData(
        id: 'blessing',
        trigger: RelicTrigger.startOfTurn,
        effectType: 'blessing',
        value: value,
        mastery: const PassiveMastery(
          field: 'value',
          perPoint: 1,
          descriptionEn: '+{amount} HP per tranche',
          descriptionFr: '+{amount} PV par tranche',
        ),
      );

  late ProviderContainer container;
  late RunController run;

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
  });

  tearDown(() => container.dispose());

  EntityStats stats() => run.currentState.heroStats;

  int temporaryMight() {
    var total = 0;
    for (final status in stats().statuses) {
      if (status.id == 'might') total += status.value;
    }
    return total;
  }

  /// Pose l'état du héros sans passer par un gain : ces tests mesurent le
  /// passif, pas la chaîne de gains.
  void setHero({int armure = 0, int? currentPv}) {
    run.updateState(
      run.currentState.copyWith(
        heroStats: stats().copyWith(
          armure: armure,
          currentPv: currentPv ?? stats().currentPv,
        ),
      ),
    );
  }

  group('Ferveur', () {
    test('l armure qui encaisse octroie de la Puissance temporaire', () {
      run.startNewRun(paladin, fervor());
      setHero(armure: 10);

      run.takeDamage(4);

      expect(temporaryMight(), 1);
      expect(stats().might, 0, reason: 'jamais de Puissance permanente');
      expect(
        stats().statuses.singleWhere((s) => s.id == 'might').duration,
        2,
      );
    });

    test('des degats qui vont droit aux PV ne donnent rien', () {
      run.startNewRun(paladin, fervor());
      run.takeDamage(4);

      expect(temporaryMight(), 0);
      expect(stats().currentPv, 100 - 4);
    });

    test('la Maitrise augmente la Puissance accordee', () {
      run.startNewRun(master, fervor());
      setHero(armure: 10);

      run.takeDamage(1);

      expect(temporaryMight(), 1 + 2);
    });
  });

  group('Benediction', () {
    // Le seul passif du jeu dont l'ordre d'execution est contraignant : sans
    // la capture de `startTurn`, il n'a rien a convertir (spec §1.1, §6.3).
    test('l armure survivante devient des PV, malgre la remise a zero', () {
      run.startNewRun(paladin, blessing());
      setHero(armure: 12, currentPv: 50);

      run.startTurn();

      // 12 d'armure, une tranche de 5 par point de vie : 2 PV.
      expect(stats().currentPv, 50 + 2);
      expect(stats().armure, 0, reason: 'la remise a zero a bien eu lieu');
    });

    test('sans armure au tour precedent, rien', () {
      run.startNewRun(paladin, blessing());
      setHero(currentPv: 50);

      run.startTurn();

      expect(stats().currentPv, 50);
    });

    test('la conversion ne depasse jamais les PV max', () {
      run.startNewRun(paladin, blessing());
      setHero(armure: 60, currentPv: 99);

      run.startTurn();

      expect(stats().currentPv, 100);
    });

    test('la Maitrise augmente les PV par tranche', () {
      run.startNewRun(master, blessing());
      setHero(armure: 10, currentPv: 50);

      run.startTurn();

      // 2 tranches de 5, et (1 + 2) PV par tranche.
      expect(stats().currentPv, 50 + 2 * 3);
    });
  });

  group('le catalogue', () {
    test('le Paladin garde la Regeneration d Armure en premier choix', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final hero = registry.heroes.firstWhere((h) => h.id == 'paladin');
      final available = availablePassivesFor(hero, registry).map((p) => p.id);

      expect(available, ['regen_armor', 'fervor', 'blessing']);
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/passives_paladin_test.dart`
Expected: FAIL — aucune Puissance temporaire, aucun PV gagné : `fervor` et `blessing` n'ont pas de stratégie, et `TraitSystem` laisse passer un `effectType` inconnu sans lever.

- [ ] **Step 3: Les deux stratégies**

In `lib/game/systems/passives/passive_strategies.dart`, replace:
```dart
import '../../../models/data/card_data.dart';
import '../../../models/data/passive_data.dart';
import '../../controllers/run_controller.dart';
import '../stat_gains.dart';
import 'passive_strategy.dart';
```
with:
```dart
import '../../../models/data/card_data.dart';
import '../../../models/data/passive_data.dart';
import '../../../models/status_effect.dart';
import '../../controllers/run_controller.dart';
import '../stat_gains.dart';
import 'passive_strategy.dart';

/// La Puissance temporaire qu'un passif accorde. Le nom est celui que voient
/// le panneau des statuts et la carte du héros ; l'identifiant `might` est ce
/// que lit `effectiveMight`.
StatusEffect _temporaryMight(int value, int duration) => StatusEffect(
      id: 'might',
      name: 'Puissance',
      type: StatusType.buff,
      value: value,
      duration: duration,
    );
```

In the same file, before the `PassiveStrategies` table, add:
```dart
/// `fervor` : l'armure qui encaisse des dégâts octroie `value` de Puissance
/// temporaire, pendant `duration` tours.
///
/// Chez le Paladin, encaisser devient une ressource offensive : il tape parce
/// qu'il tient, là où le Berserker tape parce qu'il meurt (spec §6.3). Le gain
/// est temporaire, comme l'exige R5 (§7.2) : l'armure est éphémère.
class FervorPassive extends PassiveStrategy {
  const FervorPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    if ((event.absorbedDamage ?? 0) <= 0) return;
    run.addStatus(_temporaryMight(passive.value, passive.duration));
  }
}

/// `blessing` : chaque tranche de 5 points d'armure survivante devient `value`
/// PV.
///
/// L'armure est remise à zéro au début de chaque tour (spec §1.1) : la valeur
/// vient de `PassiveEvent.survivingArmor`, que `RunController.startTurn`
/// capture avant cette remise à zéro. La stratégie ne lit donc jamais
/// `heroStats.armure`, qui vaut 0 quand elle s'exécute.
class BlessingPassive extends PassiveStrategy {
  const BlessingPassive();

  /// L'armure qu'il faut pour une tranche. Valeur d'équilibrage : les gains
  /// d'armure du jeu vont de 5 à 15 points.
  static const int _armorPerTranche = 5;

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final tranches = (event.survivingArmor ?? 0) ~/ _armorPerTranche;
    if (tranches <= 0) return;
    // `heal` borne déjà le résultat aux PV max.
    run.heal(tranches * passive.value);
  }
}
```

In the same file, replace:
```dart
  static const Map<String, PassiveStrategy> byEffectType = {
    'gain_armor': GainArmorPassive(),
    'berserker_armor': BerserkerArmorPassive(),
    'spell_armor': SpellArmorPassive(),
  };
```
with:
```dart
  static const Map<String, PassiveStrategy> byEffectType = {
    'gain_armor': GainArmorPassive(),
    'berserker_armor': BerserkerArmorPassive(),
    'spell_armor': SpellArmorPassive(),
    // Paladin (spec P-41, §6.3)
    'fervor': FervorPassive(),
    'blessing': BlessingPassive(),
  };
```

- [ ] **Step 4: Les deux fichiers de passif, et le rang du troisième**

Create `assets/data/passives/fervor.json`:
```json
{
  "id": "fervor",
  "name_en": "Fervor",
  "name_fr": "Ferveur",
  "description_en": "When your Block absorbs damage, gain 1 Might for 2 turns.",
  "description_fr": "Quand votre Armure encaisse des dégâts, gagne 1 Puissance pendant 2 tours.",
  "classes": ["paladin"],
  "trigger": "onDamageTaken",
  "effectType": "fervor",
  "value": 1,
  "duration": 2,
  "displayOrder": 2,
  "mastery": {
    "field": "value",
    "perPoint": 1,
    "description_en": "+{amount} Might absorbed",
    "description_fr": "+{amount} Puissance par absorption"
  }
}
```

Create `assets/data/passives/blessing.json`:
```json
{
  "id": "blessing",
  "name_en": "Blessing",
  "name_fr": "Bénédiction",
  "description_en": "At the start of your turn, every 5 points of surviving Block becomes 1 HP.",
  "description_fr": "Au début du tour, chaque tranche de 5 points d'Armure survivante devient 1 PV.",
  "classes": ["paladin"],
  "trigger": "startOfTurn",
  "effectType": "blessing",
  "value": 1,
  "displayOrder": 3,
  "mastery": {
    "field": "value",
    "perPoint": 1,
    "description_en": "+{amount} HP per tranche",
    "description_fr": "+{amount} PV par tranche"
  }
}
```

In `assets/data/passives/regen_armor.json`, replace:
```json
  "effectType": "gain_armor",
  "value": 2,
```
with:
```json
  "effectType": "gain_armor",
  "value": 2,
  "displayOrder": 1,
```

- [ ] **Step 5: Déclarer les deux fichiers**

Run: `dart run tool/sync_assets.dart`
Expected: aucun changement à `pubspec.yaml` — `assets/data/passives/` est déjà déclaré comme répertoire (`pubspec.yaml:49`), et un fichier ajouté à un répertoire plat n'ajoute pas de ligne. Lancer la commande quand même : c'est elle qui le prouve.

Run: `git diff --stat pubspec.yaml`
Expected: aucune sortie.

- [ ] **Step 6: Lancer le test pour le voir passer**

Run: `flutter test test/unit/passives_paladin_test.dart`
Expected: `+8: All tests passed!`

- [ ] **Step 7: Les compteurs du bundle**

`test/unit/real_bundle_load_test.dart` compte les fichiers d'entité et les passifs : deux fichiers de plus ici, et il en comptera neuf en fin de Task 8, une fois les suppressions faites. **À faire avant la vérification complète**, sinon c'est ce test qui rougit.

In `test/unit/real_bundle_load_test.dart`, replace:
```dart
  test('le manifeste declare les 71 fichiers d entite, par categorie', () async {
```
with:
```dart
  test('le manifeste declare les 73 fichiers d entite, par categorie', () async {
```
and replace:
```dart
    expect(countUnder('assets/data/passives/', 4), 3, reason: 'passifs');
```
with:
```dart
    expect(countUnder('assets/data/passives/', 4), 5, reason: 'passifs');
```
and replace:
```dart
    expect(registry.passives, hasLength(3));
```
with:
```dart
    expect(registry.passives, hasLength(5));
```

- [ ] **Step 8: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+994: All tests passed!` (986 + 8)

- [ ] **Step 9: Commit**

```bash
git add assets/data/passives lib/game/systems/passives/passive_strategies.dart test/unit/passives_paladin_test.dart test/unit/real_bundle_load_test.dart
git commit -F- <<'EOF'
feat(passifs): Ferveur et Benediction, les deux passifs du Paladin

Ferveur fait de l armure qui encaisse une ressource offensive.
Benediction convertit l armure survivante en PV : elle lit l armure
que startTurn capture avant sa remise a zero, seul passif du jeu dont
l ordre d execution est contraignant, couvert par un test dedie. La
Regeneration d Armure garde le premier rang, donc le passif de depart.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 7: Les trois passifs du Berserker

*Rage* est la formule de `berserker_armor` redirigée vers la Puissance temporaire, avec le plancher qui corrige son défaut de diagnostic : elle n'est plus muette à pleine vie. *Soif de Sang* est **le passif le plus cher des neuf** — `lifesteal` est orphelin trois fois (spec §1.2), et elle doit créer sa source, son hook de soin et son axe de croissance. *Frénésie* est la boule de neige.

`berserker_armor` disparaît, fichier et stratégie : ses deux tests de caractérisation partent avec, et deux tests de `run_controller_test.dart` qui s'en servaient comme passif observable passent à `gain_armor`.

**Files:**
- Create: `assets/data/passives/rage.json`, `bloodthirst.json`, `frenzy.json`
- Delete: `assets/data/passives/berserker_armor.json`, et sa copie sous `build/unit_test_assets/assets/data/passives/`
- Modify: `lib/game/systems/passives/passive_strategies.dart` ; `lib/game/services/effects/strategies.dart` (`DamageEffectStrategy`) ; `lib/game/controllers/run/player_stats_manager.dart` (`applyLifestealBuff`) ; `lib/game/controllers/run_controller.dart` (sa façade)
- Test: `test/unit/passives_berserker_test.dart` *(nouveau)* ; `test/unit/stat_gains_characterization_test.dart:172-190` ; `test/unit/run_controller_test.dart:66-117`, `:299-330`
- Test: `test/unit/real_bundle_load_test.dart` (compteurs)

**Interfaces:**
- Consumes: `PassiveData.duration`, `.draw` (Task 5) ; `RelicTrigger.onAttackPlayed`, `onEnemyKilled` (Task 4).
- Produces:
  - `effectType` `rage`, `bloodthirst`, `frenzy` dans `PassiveStrategies.byEffectType` ; `berserker_armor` retiré.
  - `RunController.applyLifestealBuff({required int value, required int duration})` — la signature change, elle n'avait aucun appelant (spec §1.2).
  - Le hook de Vol de vie dans `DamageEffectStrategy` : après la résolution des dégâts, `min(valeur du statut, dégâts infligés)` PV, **une fois par carte**.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/passives_berserker_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les trois passifs du Berserker (spec P-41, §6.3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const berserker = HeroData(
    id: 'berserker',
    classCard: 'berserker.png',
    maxHp: 80,
    maxMana: 3,
    baseDamage: 15,
  );

  PassiveData rage({int value = 1}) => PassiveData(
        id: 'rage',
        trigger: RelicTrigger.startOfTurn,
        effectType: 'rage',
        value: value,
        duration: 1,
      );

  PassiveData bloodthirst({int value = 1}) => PassiveData(
        id: 'bloodthirst',
        trigger: RelicTrigger.onAttackPlayed,
        effectType: 'bloodthirst',
        value: value,
        duration: 2,
      );

  PassiveData frenzy({int value = 2, int draw = 1}) => PassiveData(
        id: 'frenzy',
        trigger: RelicTrigger.onEnemyKilled,
        effectType: 'frenzy',
        value: value,
        duration: 1,
        draw: draw,
      );

  final slime = EnemyData(
    id: 'slime',
    nameEn: 'Slime',
    nameFr: 'Slime',
    maxHp: 40,
    baseDamage: 1,
    spritePath: 'slime.png',
    tier: 1,
    intents: [EnemyIntent(type: IntentType.attack, value: 1)],
  );

  late ProviderContainer container;
  late RunController run;
  late CombatController combat;

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
    combat = container.read(combatProvider.notifier);
  });

  tearDown(() => container.dispose());

  EntityStats stats() => run.currentState.heroStats;

  int temporaryMight() {
    var total = 0;
    for (final status in stats().statuses) {
      if (status.id == 'might') total += status.value;
    }
    return total;
  }

  String seedEnemy({int hp = 40}) {
    final enemy = EnemyInstance(
      data: slime,
      stats: EntityStats(maxPv: 40, currentPv: hp, armure: 0, might: 0),
    );
    combat.state = CombatState(
      enemies: [enemy],
      selectedEnemyId: enemy.id,
      turnPhase: TurnPhase.player,
    );
    return enemy.id;
  }

  CardInstance attack(int damage) => CardInstance(
        data: CardData(
          id: 'test_attack',
          cost: 0,
          type: CardType.attack,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: [CardEffect(type: 'damage', value: damage)],
        ),
      );

  group('Rage', () {
    // Le defaut releve au diagnostic (§I.3.2) : le passif ne doit plus etre
    // muet a pleine vie.
    test('a pleine vie, le plancher tient', () {
      run.startNewRun(berserker, rage());
      run.startTurn();
      expect(temporaryMight(), 1);
    });

    test('la Puissance monte par tranche de 10 PV manquants', () {
      run.startNewRun(berserker, rage());
      run.takeDamage(30);
      run.startTurn();

      // Le plancher, plus 3 tranches.
      expect(temporaryMight(), 1 + 3);
    });

    test('la Puissance accordee est temporaire, jamais permanente', () {
      run.startNewRun(berserker, rage());
      run.startTurn();

      expect(stats().might, 0);
      expect(
        stats().statuses.singleWhere((s) => s.id == 'might').duration,
        1,
      );
    });
  });

  group('Soif de Sang', () {
    test('jouer une Attaque arme le Vol de vie', () {
      run.startNewRun(berserker, bloodthirst());
      seedEnemy();
      combat.applyPlayerCardPlay(attack(5));

      final buff = stats().statuses.singleWhere((s) => s.id == 'lifesteal');
      expect(buff.value, 1, reason: 'a pleine vie, la valeur de base');
      expect(buff.duration, 2);
    });

    test('la valeur monte a mesure que les PV baissent', () {
      run.startNewRun(berserker, bloodthirst());
      run.takeDamage(40); // la moitie des PV
      seedEnemy();
      combat.applyPlayerCardPlay(attack(5));

      // 50 % de PV manquants, un quart par point : 1 + 2.
      expect(
        stats().statuses.singleWhere((s) => s.id == 'lifesteal').value,
        3,
      );
    });

    // Le statut arme le soin ; c'est la resolution des degats qui le paie
    // (spec §1.2). La premiere Attaque arme, les suivantes drainent.
    test('l Attaque suivante soigne des degats infliges', () {
      run.startNewRun(berserker, bloodthirst());
      run.takeDamage(20);
      seedEnemy();

      combat.applyPlayerCardPlay(attack(5));
      expect(stats().currentPv, 60, reason: 'la premiere arme seulement');

      // 25 % de PV manquants : le statut vaut 2, et les degats infliges (5)
      // ne le plafonnent pas.
      combat.applyPlayerCardPlay(attack(5));
      expect(stats().currentPv, 60 + 2);
    });

    test('le soin ne depasse jamais les degats infliges', () {
      run.startNewRun(berserker, bloodthirst(value: 9));
      run.takeDamage(20);
      seedEnemy();

      combat.applyPlayerCardPlay(attack(1));
      combat.applyPlayerCardPlay(attack(1));

      expect(stats().currentPv, 60 + 1);
    });
  });

  group('Frenesie', () {
    test('un ennemi abattu donne de la Puissance et fait piocher', () {
      run.startNewRun(berserker, frenzy());

      // Une pioche garnie et une main vide : la carte que le passif tire est
      // la seule qui puisse arriver en main.
      final deck = container.read(deckProvider.notifier);
      deck.initializeStarterDeck([attack(1), attack(1), attack(1)]);
      deck.startCombat(handSize: 0, maxHandSize: 10);
      expect(container.read(deckProvider).hand, isEmpty);

      seedEnemy(hp: 1);
      combat.applyPlayerCardPlay(attack(5));

      expect(combat.currentState.enemies, isEmpty);
      expect(temporaryMight(), 2);
      expect(container.read(deckProvider).hand, hasLength(1));
    });
  });

  group('le catalogue', () {
    test('le Berserker garde Rage en premier choix', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final hero = registry.heroes.firstWhere((h) => h.id == 'berserker');
      final available = availablePassivesFor(hero, registry).map((p) => p.id);

      expect(available, ['rage', 'bloodthirst', 'frenzy']);
    });

    test('berserker_armor n existe plus, ni en donnee ni en strategie', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      expect(
        registry.passives.map((p) => p.id),
        isNot(contains('berserker_armor')),
      );
    });
  });
}
```

**Note d'écriture :** la pioche du test de *Frénésie* est semée par `initializeStarterDeck` puis `startCombat(handSize: 0, ...)` — les deux seuls points d'entrée de `DeckNotifier` qui garnissent la pile de pioche sans remplir la main. `DeckNotifier.playCard` tolère une carte absente de la main (`deck_controller.dart:263` : `indexWhere` puis `if (index != -1)`), ce dont tous ces tests dépendent : ils jouent une carte fabriquée sur place, jamais tirée.

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/passives_berserker_test.dart`
Expected: FAIL — aucune Puissance temporaire, aucun statut `lifesteal` : les trois `effectType` n'ont pas de stratégie.

- [ ] **Step 3: Le Vol de vie a une valeur**

In `lib/game/controllers/run/player_stats_manager.dart`, replace:
```dart
  /// Applique un effet de Vol de vie pour une durée donnée
  void applyLifestealBuff(int duration) {
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: controller.currentState.heroStats.addStatus(
          StatusEffect(
            id: 'lifesteal',
            name: 'Vol de Vie',
            type: StatusType.buff,
            value: 1,
            duration: duration,
          ),
        ),
      ),
    );
  }
```
with:
```dart
  /// Arme le Vol de vie : [value] PV drainés par carte de dégâts résolue,
  /// pendant [duration] tours.
  ///
  /// Le statut ne fait rien par lui-même — c'est `DamageEffectStrategy` qui le
  /// paie, après la résolution des dégâts. Il était affiché et sans effet
  /// depuis P-40 (spec P-41, §1.2) ; *Soif de Sang* lui donne son appelant.
  /// Le statut n'est pas cumulable : deux Attaques dans le tour rafraîchissent
  /// la durée et gardent la plus forte valeur, elles ne l'additionnent pas.
  void applyLifestealBuff({required int value, required int duration}) {
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: controller.currentState.heroStats.addStatus(
          StatusEffect(
            id: 'lifesteal',
            name: 'Vol de Vie',
            type: StatusType.buff,
            value: value,
            duration: duration,
            isStackable: false,
          ),
        ),
      ),
    );
  }
```

In `lib/game/controllers/run_controller.dart`, replace:
```dart
  /// Applique un effet de Vol de vie pour une durée donnée
  void applyLifestealBuff(int duration) {
    _playerStatsManager.applyLifestealBuff(duration);
  }
```
with:
```dart
  /// Arme le Vol de vie pour une valeur et une durée données
  void applyLifestealBuff({required int value, required int duration}) {
    _playerStatsManager.applyLifestealBuff(value: value, duration: duration);
  }
```

- [ ] **Step 4: Le hook qui paie le Vol de vie**

In `lib/game/services/effects/strategies.dart`, replace the whole body of `DamageEffectStrategy.resolve`:
```dart
    if (card.data.target == CardTarget.singleEnemy && selectedEnemyId != null) {
      final enemyIndex = combatController.currentState.enemies.indexWhere(
        (e) => e.id == selectedEnemyId,
      );
      if (enemyIndex != -1) {
        final enemy = combatController.currentState.enemies[enemyIndex];
        final (finalDmg, isCrit) = DamagePipeline.calculate(
          initialDamage: scaledValue + runController.currentState.heroStats.damageBonusFor(card.data.type),
          attackerStats: runController.currentState.heroStats,
          defenderStats: enemy.stats,
        );
        combatController.updateEnemyStats(
          selectedEnemyId,
          enemy.stats.takeDamage(finalDmg, isCrit: isCrit),
        );
      }
    } else if (card.data.target == CardTarget.allEnemies) {
      for (var enemy in combatController.currentState.enemies) {
        final (individualDmg, isCrit) = DamagePipeline.calculate(
          initialDamage: scaledValue + runController.currentState.heroStats.damageBonusFor(card.data.type),
          attackerStats: runController.currentState.heroStats,
          defenderStats: enemy.stats,
        );
        combatController.updateEnemyStats(
          enemy.id,
          enemy.stats.takeDamage(individualDmg, isCrit: isCrit),
        );
      }
    }
  }
```
with:
```dart
    int dealt = 0;

    if (card.data.target == CardTarget.singleEnemy && selectedEnemyId != null) {
      final enemyIndex = combatController.currentState.enemies.indexWhere(
        (e) => e.id == selectedEnemyId,
      );
      if (enemyIndex != -1) {
        final enemy = combatController.currentState.enemies[enemyIndex];
        final (finalDmg, isCrit) = DamagePipeline.calculate(
          initialDamage: scaledValue + runController.currentState.heroStats.damageBonusFor(card.data.type),
          attackerStats: runController.currentState.heroStats,
          defenderStats: enemy.stats,
        );
        combatController.updateEnemyStats(
          selectedEnemyId,
          enemy.stats.takeDamage(finalDmg, isCrit: isCrit),
        );
        dealt += finalDmg;
      }
    } else if (card.data.target == CardTarget.allEnemies) {
      for (var enemy in combatController.currentState.enemies) {
        final (individualDmg, isCrit) = DamagePipeline.calculate(
          initialDamage: scaledValue + runController.currentState.heroStats.damageBonusFor(card.data.type),
          attackerStats: runController.currentState.heroStats,
          defenderStats: enemy.stats,
        );
        combatController.updateEnemyStats(
          enemy.id,
          enemy.stats.takeDamage(individualDmg, isCrit: isCrit),
        );
        dealt += individualDmg;
      }
    }

    _payLifesteal(runController, dealt);
  }

  /// Le soin du Vol de vie, après la résolution des dégâts (spec P-41, §1.2).
  ///
  /// Une fois par carte et jamais plus que les dégâts réellement infligés : sur
  /// une carte qui frappe tout le monde, le total sert de plafond, sinon le
  /// même statut soignerait autant de fois qu'il y a d'ennemis.
  void _payLifesteal(RunController runController, int dealt) {
    if (dealt <= 0) return;
    final buffs = runController.currentState.heroStats.statuses
        .where((s) => s.id == 'lifesteal');
    if (buffs.isEmpty) return;
    runController.heal(min(buffs.first.value, dealt));
  }
```

- [ ] **Step 5: Les trois stratégies, et le retrait de la quatrième**

In `lib/game/systems/passives/passive_strategies.dart`, replace:
```dart
/// `berserker_armor` : `value` d'armure par tranche de 10 PV manquants, rien à
/// pleine vie.
class BerserkerArmorPassive extends PassiveStrategy {
  const BerserkerArmorPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final stats = run.currentState.heroStats;
    final tranches = (stats.maxPv - stats.currentPv) ~/ 10;
    final armorGain = tranches * passive.value;
    if (armorGain > 0) {
      run.grant(StatGain(GainResource.armor, armorGain, GainSource.passive));
    }
  }
}
```
with:
```dart
/// `rage` : `value` de Puissance temporaire, plus `value` par tranche de 10 PV
/// manquants.
///
/// La formule de `berserker_armor`, que ce passif remplace, redirigée vers la
/// Puissance — avec le plancher qui corrige son défaut de diagnostic
/// (spec §6.3) : à pleine vie, le passif n'est plus muet.
class RagePassive extends PassiveStrategy {
  const RagePassive();

  /// Les PV manquants qu'il faut pour une tranche. Valeur d'équilibrage,
  /// reprise de `berserker_armor`.
  static const int _pvPerTranche = 10;

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final stats = run.currentState.heroStats;
    final tranches = (stats.maxPv - stats.currentPv) ~/ _pvPerTranche;
    run.addStatus(
      _temporaryMight(passive.value * (1 + tranches), passive.duration),
    );
  }
}

/// `bloodthirst` : jouer une Attaque arme le Vol de vie pour `duration` tours,
/// d'autant plus fort que les PV sont bas.
///
/// Le passif crée la **source** du statut ; son **hook** de soin vit dans
/// `DamageEffectStrategy` (spec §1.2). La première Attaque du tour arme, les
/// suivantes drainent.
class BloodthirstPassive extends PassiveStrategy {
  const BloodthirstPassive();

  /// Le pourcentage de PV manquants qui vaut un point de plus. En pourcentage
  /// et non en PV absolus : les trois classes n'ont pas le même maximum.
  static const int _percentPerStep = 25;

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final stats = run.currentState.heroStats;
    final missingPercent =
        (stats.maxPv - stats.currentPv) * 100 ~/ stats.maxPv;
    run.applyLifestealBuff(
      value: passive.value + missingPercent ~/ _percentPerStep,
      duration: passive.duration,
    );
  }
}

/// `frenzy` : chaque ennemi abattu donne `value` de Puissance temporaire et
/// fait piocher `draw` cartes.
///
/// Déclenché une fois par ennemi (`CombatController.cleanDeadEnemies`) : c'est
/// ce qui en fait une boule de neige (spec §6.3).
class FrenzyPassive extends PassiveStrategy {
  const FrenzyPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    run.addStatus(_temporaryMight(passive.value, passive.duration));
    if (passive.draw > 0) {
      run.ref
          .read(deckProvider.notifier)
          .drawCards(passive.draw, maxHandSize: GameConstants.maxHandSize);
    }
  }
}
```

In the same file, add the two imports the draw needs:
```dart
import '../../controllers/deck_controller.dart';
import '../../game_constants.dart';
```

In the same file, replace:
```dart
    'gain_armor': GainArmorPassive(),
    'berserker_armor': BerserkerArmorPassive(),
    'spell_armor': SpellArmorPassive(),
    // Paladin (spec P-41, §6.3)
    'fervor': FervorPassive(),
    'blessing': BlessingPassive(),
```
with:
```dart
    'gain_armor': GainArmorPassive(),
    'spell_armor': SpellArmorPassive(),
    // Paladin (spec P-41, §6.3)
    'fervor': FervorPassive(),
    'blessing': BlessingPassive(),
    // Berserker
    'rage': RagePassive(),
    'bloodthirst': BloodthirstPassive(),
    'frenzy': FrenzyPassive(),
```

- [ ] **Step 6: Les trois fichiers de passif**

Create `assets/data/passives/rage.json`:
```json
{
  "id": "rage",
  "name_en": "Rage",
  "name_fr": "Rage",
  "description_en": "At the start of your turn, gain 1 Might for the turn, plus 1 per 10 missing HP.",
  "description_fr": "Au début du tour, gagne 1 Puissance pour le tour, plus 1 par tranche de 10 PV manquants.",
  "classes": ["berserker"],
  "trigger": "startOfTurn",
  "effectType": "rage",
  "value": 1,
  "duration": 1,
  "displayOrder": 1,
  "mastery": {
    "field": "value",
    "perPoint": 1,
    "description_en": "+{amount} Might per tranche",
    "description_fr": "+{amount} Puissance par tranche"
  }
}
```

Create `assets/data/passives/bloodthirst.json`:
```json
{
  "id": "bloodthirst",
  "name_en": "Bloodthirst",
  "name_fr": "Soif de Sang",
  "description_en": "Playing an Attack arms Lifesteal for 2 turns: 1 HP per damaging card, plus 1 per quarter of missing HP.",
  "description_fr": "Jouer une Attaque arme le Vol de Vie pendant 2 tours : 1 PV par carte de dégâts, plus 1 par quart de PV manquants.",
  "classes": ["berserker"],
  "trigger": "onAttackPlayed",
  "effectType": "bloodthirst",
  "value": 1,
  "duration": 2,
  "displayOrder": 2,
  "mastery": {
    "field": "value",
    "perPoint": 1,
    "description_en": "+{amount} HP drained",
    "description_fr": "+{amount} PV drainé"
  }
}
```

Create `assets/data/passives/frenzy.json`:
```json
{
  "id": "frenzy",
  "name_en": "Frenzy",
  "name_fr": "Frénésie",
  "description_en": "Each enemy killed grants 2 Might for the turn and draws 1 card.",
  "description_fr": "Chaque ennemi abattu donne 2 Puissance pour le tour et fait piocher 1 carte.",
  "classes": ["berserker"],
  "trigger": "onEnemyKilled",
  "effectType": "frenzy",
  "value": 2,
  "duration": 1,
  "draw": 1,
  "displayOrder": 3,
  "mastery": {
    "field": "value",
    "perPoint": 1,
    "description_en": "+{amount} Might per kill",
    "description_fr": "+{amount} Puissance par ennemi abattu"
  }
}
```

- [ ] **Step 7: Supprimer `berserker_armor`, des données comme du bundle de test**

```bash
rm assets/data/passives/berserker_armor.json
rm -f build/unit_test_assets/assets/data/passives/berserker_armor.json
dart run tool/sync_assets.dart
git diff --stat pubspec.yaml
```
Expected: `git diff --stat pubspec.yaml` ne produit rien — `assets/data/passives/` reste déclaré comme répertoire.

La seconde ligne est celle qui compte : `flutter test` ne purge jamais `build/unit_test_assets/`, et un fichier laissé là continue d'être compté par `real_bundle_load_test.dart`.

- [ ] **Step 8: Les tests qui se servaient de `berserker_armor`**

In `test/unit/stat_gains_characterization_test.dart`, delete the two tests whose subject no longer exists, et dire pourquoi. Replace:
```dart
    test('berserker_armor : la Maitrise compte a chaque tranche (P-49)', () {
      run.startNewRun(
        paladin,
        passive(RelicTrigger.startOfTurn, 'berserker_armor', 1),
      );
      run.takeDamage(25);
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.startOfTurn));
      // Avant P-49 : 2 tranches × 1 + 3 = 5.
      expect(heroStats().armure, 2 * (1 + 3));
    });

    test('berserker_armor a pleine vie : rien, pas meme la Maitrise', () {
      run.startNewRun(
        paladin,
        passive(RelicTrigger.startOfTurn, 'berserker_armor', 1),
      );
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.startOfTurn));
      expect(heroStats().armure, 0);
    });

```
with:
```dart
    // Les deux tests de `berserker_armor` ont ete retires avec le passif : il
    // ne donne plus d'armure mais de la Puissance temporaire, sous le nom de
    // *Rage* (spec P-41, §6.3). Sa formule et son plancher sont couverts par
    // `test/unit/passives_berserker_test.dart`.

```

In `test/unit/run_controller_test.dart`, le passif n'y sert que de **témoin observable** : le sujet des deux tests est l'ordre de déclenchement, pas la formule de `berserker_armor`. Replace:
```dart
        // activePassive n'est déduit d'aucun repli codé en dur : on le
        // fournit explicitement, comme le ferait le vrai chargement depuis
        // assets/data/passives/ via PassiveData.getById.
        const berserkerArmor = PassiveData(
          id: 'berserker_armor',
          nameEn: 'Berserker Armor',
          nameFr: 'Armure du Berserker',
          trigger: RelicTrigger.startOfTurn,
          effectType: 'berserker_armor',
          value: 1,
          mastery: PassiveMastery(field: 'value', perPoint: 1),
        );

        runController.startNewRun(berserkerHero, berserkerArmor);

        // Set missing HP: 80 max HP, set current to 60 (20 missing HP)
        runController.takeDamage(20);

        // Travel to a node to have currentNodeId set
        runController.travelToNode('node_1');

        // At the start of combat, the passive should trigger:
        // Missing HP = 20, i.e. 2 tranches. Mastery raises the passive's
        // value first (spec P-49, §6.4): 2 × (1 + 1) = 4 armor.
        runController.startCombat();

        expect(runController.state.heroStats.armure, 4);
```
with:
```dart
        // activePassive n'est déduit d'aucun repli codé en dur : on le
        // fournit explicitement, comme le ferait le vrai chargement depuis
        // assets/data/passives/ via PassiveData.getById. `gain_armor` sert
        // de témoin : ce test mesure le déclenchement au début du combat et
        // la Maîtrise, pas la formule d'un passif en particulier.
        const startOfTurnArmor = PassiveData(
          id: 'test_passive',
          nameEn: 'Test Passive',
          nameFr: 'Passif de test',
          trigger: RelicTrigger.startOfTurn,
          effectType: 'gain_armor',
          value: 1,
          mastery: PassiveMastery(field: 'value', perPoint: 1),
        );

        runController.startNewRun(berserkerHero, startOfTurnArmor);

        // Set missing HP: 80 max HP, set current to 60 (20 missing HP)
        runController.takeDamage(20);

        // Travel to a node to have currentNodeId set
        runController.travelToNode('node_1');

        // At the start of combat, the passive should trigger. Mastery raises
        // the passive's value first (spec P-49, §6.4): 1 + 1 = 2 armor.
        runController.startCombat();

        expect(runController.state.heroStats.armure, 2);
```
Renommer aussi le test, qui ne parle plus du bon passif. Replace:
```dart
      'Berserker armor passive triggers at start of combat when player has missing HP and resets at end of combat',
```
with:
```dart
      'a start-of-turn passive triggers at start of combat and its armor resets at end of combat',
```

In the same file, replace:
```dart
      const berserkerArmor = PassiveData(
        id: 'berserker_armor',
        trigger: RelicTrigger.endOfTurn,
        effectType: 'berserker_armor',
        value: 1,
      );
      runController.startNewRun(hero, berserkerArmor);
      runController.takeDamage(30);
```
with:
```dart
      // `gain_armor` en temoin : le sujet est l'ordre — le passif, puis les
      // reliques —, pas la formule du passif.
      const endOfTurnArmor = PassiveData(
        id: 'test_passive',
        trigger: RelicTrigger.endOfTurn,
        effectType: 'gain_armor',
        value: 3,
      );
      runController.startNewRun(hero, endOfTurnArmor);
      runController.takeDamage(30);
```
and replace:
```dart
      // Passif d'abord : 30 PV manquants, 3 d'armure. Les reliques d'abord
      // auraient soigné avant, et laissé 10 PV manquants, 1 d'armure.
      expect(runController.state.heroStats.armure, 3);
      expect(runController.state.heroStats.currentPv, 90);
```
with:
```dart
      // Le passif d'abord, la relique de soin ensuite : l'armure du passif est
      // là, et les 30 PV manquants ont été soignés de 20.
      expect(runController.state.heroStats.armure, 3);
      expect(runController.state.heroStats.currentPv, 90);
```

- [ ] **Step 9: Les compteurs du bundle**

In `test/unit/real_bundle_load_test.dart`, replace `73` by `75` in the test name, `5` by `7` in `countUnder('assets/data/passives/', 4)`, and `hasLength(5)` by `hasLength(7)` for `registry.passives`.

- [ ] **Step 10: Lancer le test pour le voir passer**

Run: `flutter test test/unit/passives_berserker_test.dart`
Expected: `+10: All tests passed!`

- [ ] **Step 11: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1002: All tests passed!` (994 + 10 nouveaux − 2 retirés)

- [ ] **Step 12: Commit**

```bash
git add -A assets/data/passives lib/game test/unit/passives_berserker_test.dart test/unit/stat_gains_characterization_test.dart test/unit/run_controller_test.dart test/unit/real_bundle_load_test.dart
git commit -F- <<'EOF'
feat(passifs): Rage, Soif de Sang et Frenesie remplacent l Armure du Berserker

Rage est la formule de l Armure du Berserker redirigee vers la
Puissance temporaire, avec le plancher qui la rend utile a pleine vie.
Soif de Sang donne enfin au statut lifesteal sa source et son hook :
la resolution des degats paie le soin, une fois par carte et jamais
plus que les degats infliges. Frenesie fait boule de neige.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 8: Les trois passifs du Mage

*Canalisation* reprend la fonction de survie de `spell_armor` — survivre à 60 PV — mais en la faisant **payer** : le Mage ne se protège que s'il accepte de jouer moins. *Flux de Mana* récompense l'inverse, vider sa main : le même deck ne peut pas viser les deux, et c'est ce qui fera du choix du lot C une vraie décision. *Marque du Mage* est celle qui compte : elle donne à `vulnerable` sa première source du jeu.

`spell_armor` disparaît, fichier et stratégie.

**Files:**
- Create: `assets/data/passives/channeling.json`, `mage_mark.json`, `mana_flux.json`
- Delete: `assets/data/passives/spell_armor.json`, et sa copie sous `build/unit_test_assets/assets/data/passives/`
- Modify: `lib/game/systems/passives/passive_strategies.dart`
- Test: `test/unit/passives_mage_test.dart` *(nouveau)* ; `test/unit/stat_gains_characterization_test.dart:192-215` ; `test/tutorial/tutorial_fixtures_test.dart:28-38` ; `test/widget/tutorial_class_step_test.dart:65` ; `test/unit/real_bundle_load_test.dart`

**Interfaces:**
- Consumes: `PassiveCounters`, `CounterScope`, `PassiveEvent.enemyId` (Task 4) ; `PassiveData.threshold`, `.duration` (Task 5).
- Produces: `effectType` `channeling`, `mage_mark`, `mana_flux` ; `spell_armor` retiré. Les neuf passifs sont livrés.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/passives_mage_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les trois passifs du Mage (spec P-41, §6.3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mage = HeroData(
    id: 'mage',
    classCard: 'mage.png',
    maxHp: 60,
    maxMana: 3,
    baseDamage: 10,
  );

  const master = HeroData(
    id: 'mage',
    classCard: 'mage.png',
    maxHp: 60,
    maxMana: 3,
    baseDamage: 10,
    mastery: 2,
  );

  PassiveData channeling({int value = 1}) => PassiveData(
        id: 'channeling',
        trigger: RelicTrigger.endOfTurn,
        effectType: 'channeling',
        value: value,
        mastery: const PassiveMastery(
          field: 'value',
          perPoint: 1,
          descriptionEn: '+{amount} Block per Mana',
          descriptionFr: '+{amount} Armure par Mana',
        ),
      );

  PassiveData mageMark() => const PassiveData(
        id: 'mage_mark',
        trigger: RelicTrigger.onAttackPlayed,
        effectType: 'mage_mark',
        value: 1,
        duration: 2,
      );

  PassiveData manaFlux({int threshold = 3}) => PassiveData(
        id: 'mana_flux',
        trigger: RelicTrigger.onSkillPlayed,
        effectType: 'mana_flux',
        value: 1,
        threshold: threshold,
        mastery: const PassiveMastery(
          field: 'threshold',
          perPoint: -1,
          descriptionEn: '-{amount} Skill to gather',
          descriptionFr: '-{amount} Competence a reunir',
        ),
      );

  final slime = EnemyData(
    id: 'slime',
    nameEn: 'Slime',
    nameFr: 'Slime',
    maxHp: 40,
    baseDamage: 1,
    spritePath: 'slime.png',
    tier: 1,
    intents: [EnemyIntent(type: IntentType.attack, value: 1)],
  );

  late ProviderContainer container;
  late RunController run;
  late CombatController combat;

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
    combat = container.read(combatProvider.notifier);
  });

  tearDown(() => container.dispose());

  EntityStats stats() => run.currentState.heroStats;

  void seedEnemy() {
    final enemy = EnemyInstance(
      data: slime,
      stats: EntityStats(maxPv: 40, currentPv: 40, armure: 0, might: 0),
    );
    combat.state = CombatState(
      enemies: [enemy],
      selectedEnemyId: enemy.id,
      turnPhase: TurnPhase.player,
    );
  }

  int vulnerableOnEnemy() {
    final statuses = combat.currentState.enemies.single.stats.statuses
        .where((s) => s.id == 'vulnerable');
    return statuses.isEmpty ? 0 : statuses.first.value;
  }

  CardInstance card(CardType type) => CardInstance(
        data: CardData(
          id: 'test_card',
          cost: 0,
          type: type,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: const [CardEffect(type: 'damage', value: 1)],
        ),
      );

  group('Canalisation', () {
    test('le mana non depense devient de l armure', () {
      run.startNewRun(mage, channeling());
      run.endTurn();

      // 3 de mana au depart, 1 point d'armure par mana.
      expect(stats().armure, 3);
    });

    test('sans mana, rien', () {
      run.startNewRun(mage, channeling());
      expect(run.consumeResource(mana: 3), isTrue);
      run.endTurn();

      expect(stats().armure, 0);
    });

    test('la Maitrise augmente l armure par mana', () {
      run.startNewRun(master, channeling());
      run.endTurn();

      expect(stats().armure, 3 * (1 + 2));
    });
  });

  group('Marque du Mage', () {
    test('la premiere Attaque du tour rend la cible Vulnerable', () {
      run.startNewRun(mage, mageMark());
      seedEnemy();

      combat.applyPlayerCardPlay(card(CardType.attack));

      expect(vulnerableOnEnemy(), 1);
      expect(
        combat.currentState.enemies.single.stats.statuses
            .singleWhere((s) => s.id == 'vulnerable')
            .duration,
        2,
      );
    });

    test('la deuxieme Attaque du meme tour ne marque rien', () {
      run.startNewRun(mage, mageMark());
      seedEnemy();

      combat.applyPlayerCardPlay(card(CardType.attack));
      combat.applyPlayerCardPlay(card(CardType.attack));

      expect(vulnerableOnEnemy(), 1, reason: 'une seule marque posee');
    });

    test('au tour suivant, la marque revient', () {
      run.startNewRun(mage, mageMark());
      seedEnemy();

      combat.applyPlayerCardPlay(card(CardType.attack));
      run.startTurn();
      combat.applyPlayerCardPlay(card(CardType.attack));

      expect(vulnerableOnEnemy(), 2, reason: 'une seconde marque empilee');
    });

    test('une Competence ne marque jamais', () {
      run.startNewRun(mage, mageMark());
      seedEnemy();

      combat.applyPlayerCardPlay(card(CardType.skill));

      expect(vulnerableOnEnemy(), 0);
    });
  });

  group('Flux de Mana', () {
    /// Joue [count] Compétences, sans passer par le coût en mana.
    void playSkills(int count) {
      for (var i = 0; i < count; i++) {
        run.updateState(
          run.currentState.copyWith(
            heroStats: stats().copyWith(currentMana: 3),
          ),
        );
        combat.applyPlayerCardPlay(card(CardType.skill));
      }
    }

    test('le mana arrive au seuil, pas avant', () {
      run.startNewRun(mage, manaFlux(threshold: 3));
      seedEnemy();

      playSkills(2);
      expect(stats().currentMana, 3, reason: 'rien avant le seuil');

      playSkills(1);
      expect(stats().currentMana, 3 + 1);
    });

    test('le compteur repart de zero apres le declenchement', () {
      run.startNewRun(mage, manaFlux(threshold: 2));
      seedEnemy();

      playSkills(2);
      expect(stats().currentMana, 3 + 1);

      playSkills(1);
      expect(stats().currentMana, 3, reason: 'le compteur a ete vide');
    });

    test('la Maitrise fait baisser le seuil', () {
      run.startNewRun(master, manaFlux(threshold: 3));
      seedEnemy();

      // 3 − 2 points de Maitrise : une Compétence suffit.
      playSkills(1);
      expect(stats().currentMana, 3 + 1);
    });

    test('le seuil ne descend jamais sous une Competence', () {
      const veryMasterful = HeroData(
        id: 'mage',
        classCard: 'mage.png',
        maxHp: 60,
        maxMana: 3,
        baseDamage: 10,
        mastery: 9,
      );
      run.startNewRun(veryMasterful, manaFlux(threshold: 3));
      seedEnemy();

      playSkills(1);
      expect(stats().currentMana, 3 + 1);
    });
  });

  group('le catalogue', () {
    test('le Mage garde Canalisation en premier choix', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final hero = registry.heroes.firstWhere((h) => h.id == 'mage');
      final available = availablePassivesFor(hero, registry).map((p) => p.id);

      expect(available, ['channeling', 'mage_mark', 'mana_flux']);
    });

    test('les neuf passifs sont livres, et spell_armor n y est plus', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      expect(registry.passives, hasLength(9));
      expect(
        registry.passives.map((p) => p.id),
        isNot(contains('spell_armor')),
      );
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/passives_mage_test.dart`
Expected: FAIL — aucune armure en fin de tour, aucun `vulnerable` posé, aucun mana gagné.

- [ ] **Step 3: Les trois stratégies, et le retrait de la quatrième**

In `lib/game/systems/passives/passive_strategies.dart`, replace:
```dart
/// `spell_armor` : accorde `value` d'armure quand la carte jouée est une
/// Compétence.
class SpellArmorPassive extends PassiveStrategy {
  const SpellArmorPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    if (event.card?.data.type == CardType.skill) {
      run.grant(
        StatGain(GainResource.armor, passive.value, GainSource.passive),
      );
    }
  }
}
```
with:
```dart
/// `channeling` : à la fin du tour, chaque point de mana non dépensé devient
/// `value` d'armure.
///
/// Le mana n'est pas consommé : il est remis au maximum au début du tour
/// suivant de toute façon. Le coût du passif est de **ne pas avoir joué**
/// (spec §6.3) — l'exact opposé de `mana_flux`, et c'est voulu.
class ChannelingPassive extends PassiveStrategy {
  const ChannelingPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final mana = run.currentState.heroStats.currentMana;
    if (mana <= 0) return;
    run.grant(
      StatGain(GainResource.armor, mana * passive.value, GainSource.passive),
    );
  }
}

/// `mage_mark` : la première Attaque de chaque tour rend sa cible
/// `vulnerable`, pendant `duration` tours.
///
/// Première source de `vulnerable` du jeu : le statut était pleinement
/// consommé par `DamagePipeline` sans qu'aucune donnée ne l'applique
/// (spec §6.3). Le passif ne dépend d'aucune carte : R4 est satisfaite dès
/// aujourd'hui.
///
/// L'intensité n'est pas lue par le pipeline, qui applique `vulnerable` en
/// tout ou rien (+50 %) : c'est la **durée** qui grandit avec la Maîtrise, et
/// `value` reste l'intensité pour le jour où le pipeline la lira.
class MageMarkPassive extends PassiveStrategy {
  const MageMarkPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final enemyId = event.enemyId;
    if (enemyId == null) return;
    if (PassiveCounters.bump(run, passive, scope: CounterScope.turn) > 1) {
      return;
    }

    final status = EffectResolver.createStatus(
      'vulnerable',
      passive.value,
      passive.duration,
    );
    if (status == null) return;

    final combat = run.ref.read(combatProvider.notifier);
    final index =
        combat.currentState.enemies.indexWhere((e) => e.id == enemyId);
    // La cible peut être morte de la carte qui vient d'être jouée.
    if (index == -1) return;
    combat.updateEnemyStats(
      enemyId,
      combat.currentState.enemies[index].stats.addStatus(status),
    );
  }
}

/// `mana_flux` : toutes les `threshold` Compétences jouées dans un combat,
/// `value` de mana pour le tour en cours.
class ManaFluxPassive extends PassiveStrategy {
  const ManaFluxPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    // La Maîtrise fait baisser le seuil (`perPoint` négatif) : le borner est
    // l'affaire de la stratégie qui le lit (spec P-49, §6.2). Une Compétence
    // sur une, jamais moins.
    final threshold = passive.threshold < 1 ? 1 : passive.threshold;
    final count =
        PassiveCounters.bump(run, passive, scope: CounterScope.combat);
    if (count < threshold) return;

    PassiveCounters.clear(run, passive);
    run.grant(StatGain(GainResource.mana, passive.value, GainSource.passive));
  }
}
```

In the same file, add the imports the two new readers need:
```dart
import '../../controllers/combat_controller.dart';
import '../../services/effect_resolver.dart';
import 'passive_counters.dart';
```
`CardType` n'est plus lu par aucune stratégie : retirer `import '../../../models/data/card_data.dart';` si `dart analyze` le signale comme inutilisé.

In the same file, replace:
```dart
    'gain_armor': GainArmorPassive(),
    'spell_armor': SpellArmorPassive(),
    // Paladin (spec P-41, §6.3)
```
with:
```dart
    'gain_armor': GainArmorPassive(),
    // Paladin (spec P-41, §6.3)
```
and replace:
```dart
    'rage': RagePassive(),
    'bloodthirst': BloodthirstPassive(),
    'frenzy': FrenzyPassive(),
  };
```
with:
```dart
    'rage': RagePassive(),
    'bloodthirst': BloodthirstPassive(),
    'frenzy': FrenzyPassive(),
    // Mage
    'channeling': ChannelingPassive(),
    'mage_mark': MageMarkPassive(),
    'mana_flux': ManaFluxPassive(),
  };
```

- [ ] **Step 4: Les trois fichiers de passif**

Create `assets/data/passives/channeling.json`:
```json
{
  "id": "channeling",
  "name_en": "Channeling",
  "name_fr": "Canalisation",
  "description_en": "At the end of your turn, each unspent Mana becomes 1 Block.",
  "description_fr": "À la fin du tour, chaque point de Mana non dépensé devient 1 point d'Armure.",
  "classes": ["mage"],
  "trigger": "endOfTurn",
  "effectType": "channeling",
  "value": 1,
  "displayOrder": 1,
  "mastery": {
    "field": "value",
    "perPoint": 1,
    "description_en": "+{amount} Block per unspent Mana",
    "description_fr": "+{amount} Armure par Mana non dépensé"
  }
}
```

Create `assets/data/passives/mage_mark.json`:
```json
{
  "id": "mage_mark",
  "name_en": "Mage's Mark",
  "name_fr": "Marque du Mage",
  "description_en": "The first Attack each turn makes its target Vulnerable for 2 turns.",
  "description_fr": "La première Attaque de chaque tour rend sa cible Vulnérable pendant 2 tours.",
  "classes": ["mage"],
  "trigger": "onAttackPlayed",
  "effectType": "mage_mark",
  "value": 1,
  "duration": 2,
  "displayOrder": 2,
  "mastery": {
    "field": "duration",
    "perPoint": 1,
    "description_en": "+{amount} turn of Vulnerable",
    "description_fr": "+{amount} tour de Vulnérable"
  }
}
```

Create `assets/data/passives/mana_flux.json`:
```json
{
  "id": "mana_flux",
  "name_en": "Mana Flux",
  "name_fr": "Flux de Mana",
  "description_en": "Every 3 Skills played in a combat, gain 1 Mana for the current turn.",
  "description_fr": "Toutes les 3 Compétences jouées dans un combat, gagne 1 Mana pour le tour en cours.",
  "classes": ["mage"],
  "trigger": "onSkillPlayed",
  "effectType": "mana_flux",
  "value": 1,
  "threshold": 3,
  "displayOrder": 3,
  "mastery": {
    "field": "threshold",
    "perPoint": -1,
    "description_en": "-{amount} Skill to gather",
    "description_fr": "-{amount} Compétence à réunir"
  }
}
```

- [ ] **Step 5: Supprimer `spell_armor`, des données comme du bundle de test**

```bash
rm assets/data/passives/spell_armor.json
rm -f build/unit_test_assets/assets/data/passives/spell_armor.json
dart run tool/sync_assets.dart
git diff --stat pubspec.yaml
```
Expected: aucune sortie de la dernière commande.

- [ ] **Step 6: Les tests qui se servaient de `spell_armor`**

In `test/unit/stat_gains_characterization_test.dart`, replace:
```dart
    test('spell_armor : sur une Competence seulement', () {
      run.startNewRun(
        paladin,
        passive(RelicTrigger.onCardPlayed, 'spell_armor', 1),
      );

      TraitSystem.dispatch(
        run,
        PassiveEvent(
          RelicTrigger.onCardPlayed,
          card: card(CardType.attack, const []),
        ),
      );
      expect(heroStats().armure, 0);

      TraitSystem.dispatch(
        run,
        PassiveEvent(
          RelicTrigger.onCardPlayed,
          card: card(CardType.skill, const []),
        ),
      );
      expect(heroStats().armure, 1 + 3);
    });
```
with:
```dart
    // Le test de `spell_armor` a ete retire avec le passif : la survie du Mage
    // passe desormais par *Canalisation*, qui la fait payer (spec P-41, §6.3).
    // Le filtrage par type de carte est couvert par les declencheurs
    // `onAttackPlayed` / `onSkillPlayed` (`passive_triggers_test.dart`), qui
    // le font en amont de toute strategie.
```

In `test/tutorial/tutorial_fixtures_test.dart`, replace:
```dart
      const attendus = {
        'paladin': 'regen_armor',
        'berserker': 'berserker_armor',
        'mage': 'spell_armor',
      };
```
with:
```dart
      // Le premier passif de chaque classe, par rang d'affichage : celui qui
      // remplace le passif d'avant la partie 2 du lot B de P-41.
      const attendus = {
        'paladin': 'regen_armor',
        'berserker': 'rage',
        'mage': 'channeling',
      };
```

In `test/widget/tutorial_class_step_test.dart`, replace:
```dart
    expect(engine.mockState.activePassive?.id, 'spell_armor');
```
with:
```dart
    expect(engine.mockState.activePassive?.id, 'channeling');
```

- [ ] **Step 7: Les compteurs du bundle, pour de bon**

In `test/unit/real_bundle_load_test.dart`, replace `75` by `77` in the test name, `7` by `9` in `countUnder('assets/data/passives/', 4)`, and `hasLength(7)` by `hasLength(9)` for `registry.passives`.

- [ ] **Step 8: Lancer le test pour le voir passer**

Run: `flutter test test/unit/passives_mage_test.dart`
Expected: `+13: All tests passed!`

- [ ] **Step 9: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1014: All tests passed!` (1002 + 13 nouveaux − 1 retiré)

- [ ] **Step 10: Commit**

```bash
git add -A assets/data/passives lib/game/systems/passives test/unit/passives_mage_test.dart test/unit/stat_gains_characterization_test.dart test/tutorial/tutorial_fixtures_test.dart test/widget/tutorial_class_step_test.dart test/unit/real_bundle_load_test.dart
git commit -F- <<'EOF'
feat(passifs): Canalisation, Marque du Mage et Flux de Mana

Les neuf passifs sont livres. Canalisation reprend la survie de l
Armure Magique en la faisant payer, Flux de Mana recompense l inverse
et les deux ne peuvent pas cohabiter dans un meme deck. Marque du Mage
donne au statut Vulnerable sa premiere source du jeu.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 9: L'éclair de la Puissance

L'épée et le 💪 disaient l'attaque physique, ce que D10 a écarté pour le nom (spec §7.4). Ils restaient justes tant que les trois classes orientaient leur Puissance vers `attack` ; depuis Task 3, ils ne le sont plus. Ils deviennent l'éclair qui marque déjà le statut dans le panneau des statuts et sur les cartes.

`SwordIcon` **reste** : l'écran de sélection de classe s'en sert encore pour `baseDamage`, champ que le lot C retirera (spec §8.3). `FlameSwordIcon`, sans autre usage, disparaît.

**Files:**
- Delete: `lib/game/components/widgets/flame_sword_icon.dart`
- Modify: `lib/ui/widgets/map/dialogs/stats_dialog.dart:175` ; `lib/ui/widgets/map/hero_mini_stats_panel.dart:99` ; `lib/ui/widgets/hud/player_health_bar.dart:128` ; `lib/game/components/entities/stat_badge.dart:9`, `:79-85` ; `lib/game/components/entities/status_indicator.dart:146`
- Test: `test/unit/might_icon_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: rien.
- Produces: aucune signature. `FlameSwordIcon` n'existe plus.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/might_icon_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// L'icône de la Puissance (spec P-41, §7.4).
///
/// Un garde-fou de source, comme `stat_gain_single_passage_test.dart` : ce
/// qu'on vérifie ici n'est pas un rendu mais une **absence** — celle de l'épée
/// partout où la Puissance est affichée. Un test de widget ne la verrait pas
/// revenir dans un écran qu'il ne monte pas.
void main() {
  Iterable<File> dartFilesOf(String directory) => Directory(directory)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  String normalized(File file) => file.path.replaceAll(r'\', '/');

  test('l epee ne sert plus qu a l ecran de selection de classe', () {
    final users = <String>[];
    for (final file in dartFilesOf('lib')) {
      final path = normalized(file);
      if (path.endsWith('lib/ui/widgets/sword_icon.dart')) continue;
      if (file.readAsStringSync().contains('SwordIcon(')) users.add(path);
    }

    // `baseDamage`, et donc cette derniere epee, partent au lot C (spec §8.3).
    expect(users, ['lib/ui/screens/class_selection_screen.dart']);
  });

  test('FlameSwordIcon n existe plus', () {
    expect(
      File('lib/game/components/widgets/flame_sword_icon.dart').existsSync(),
      isFalse,
    );
    for (final file in dartFilesOf('lib')) {
      expect(
        file.readAsStringSync().contains('FlameSwordIcon'),
        isFalse,
        reason: normalized(file),
      );
    }
  });

  test('le statut de Puissance porte l eclair', () {
    final source =
        File('lib/game/components/entities/status_indicator.dart')
            .readAsStringSync();
    expect(source.contains('⚡'), isTrue);
    expect(source.contains('💪'), isFalse);
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/might_icon_test.dart`
Expected: FAIL — quatre fichiers emploient encore l'épée, et `status_indicator.dart` le 💪.

- [ ] **Step 3: Les trois icônes Flutter**

In `lib/ui/widgets/map/dialogs/stats_dialog.dart`, replace:
```dart
                    icon: SwordIcon(size: 16, color: Colors.orangeAccent),
```
with:
```dart
                    icon: const Icon(
                      Icons.flash_on,
                      size: 16,
                      color: Colors.orangeAccent,
                    ),
```

In `lib/ui/widgets/map/hero_mini_stats_panel.dart`, replace:
```dart
            icon: SwordIcon(size: 16, color: Colors.orangeAccent),
```
with:
```dart
            icon: const Icon(
              Icons.flash_on,
              size: 16,
              color: Colors.orangeAccent,
            ),
```

In `lib/ui/widgets/hud/player_health_bar.dart`, replace:
```dart
                      SwordIcon(size: iconSize, color: Colors.white),
```
with:
```dart
                      Icon(
                        Icons.bolt_rounded,
                        size: iconSize,
                        color: Colors.white,
                      ),
```

Retirer ensuite l'import de `sword_icon.dart` de ces trois fichiers, que `dart analyze` signalera comme inutilisé.

- [ ] **Step 4: L'icône Flame, et le 💪**

In `lib/game/components/entities/stat_badge.dart`, replace:
```dart
      // 1. Dessine la Puissance : Épée + Valeur
      add(
        FlameSwordIcon(
          position: Vector2(0, size.y / 2),
          size: Vector2(10, 10),
          color: const Color(0xFFFF3B30),
          anchor: Anchor.centerLeft,
        ),
      );
```
with:
```dart
      // 1. Dessine la Puissance : Éclair + Valeur. L'épée disait l'attaque
      // physique, ce que la Puissance n'est plus (spec P-41, §7.4) ; l'éclair
      // est celui du panneau des statuts et des cartes.
      add(
        TextComponent(
          text: '⚡',
          position: Vector2(0, size.y / 2),
          anchor: Anchor.centerLeft,
          textRenderer: TextPaint(
            style: const TextStyle(fontSize: 10),
          ),
        ),
      );
```
and remove the now-unused import:
```dart
import '../widgets/flame_sword_icon.dart';
```

In `lib/game/components/entities/status_indicator.dart`, replace:
```dart
      case 'might':
        return '💪';
```
with:
```dart
      case 'might':
        return '⚡';
```

**Attention :** `might_regen` garde son ✊ — le §7.4 ne change que l'icône de la Puissance elle-même. Ne pas toucher aux autres branches.

- [ ] **Step 5: Supprimer l'épée Flame**

```bash
git rm lib/game/components/widgets/flame_sword_icon.dart
```

- [ ] **Step 6: Lancer le test pour le voir passer**

Run: `flutter test test/unit/might_icon_test.dart`
Expected: `+3: All tests passed!`

- [ ] **Step 7: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1017: All tests passed!` (1014 + 3)

- [ ] **Step 8: Commit**

```bash
git add -A lib test/unit/might_icon_test.dart
git commit -F- <<'EOF'
feat(ui): la Puissance porte l eclair, plus l epee

L epee et le 💪 disaient l attaque physique : justes tant que les trois
classes orientaient leur Puissance vers leurs Attaques, faux depuis que
le Mage frappe par ses alterations. FlameSwordIcon disparait, sans
autre usage ; SwordIcon reste a l ecran de selection, le temps que le
lot C retire baseDamage.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 10: Vérification finale et livraison

**Files:**
- Modify: `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md:4`
- Géré par skills : `.obsidian_vault/`, `docs/ROADMAP.md`, `assets/data/patch_notes.json`

**Interfaces:**
- Consumes: toute la partie 2.
- Produces: une branche prête à la PR.

- [ ] **Step 1: Vérifications propres au lot**

Aucun fichier de `lib/`, `test/` ni `assets/` n'a changé depuis la vérification complète de Task 9 Step 7 : ne relancer ni `dart analyze` ni la suite, reprendre le total qu'elle a affiché.

Run: `git grep -nw -e berserker_armor -e spell_armor -- lib test assets`
Expected: aucune sortie. Les deux passifs remplacés ne subsistent que dans la documentation et l'historique.

Run: `ls assets/data/passives/`
Expected: neuf fichiers — `blessing.json`, `bloodthirst.json`, `channeling.json`, `fervor.json`, `frenzy.json`, `mage_mark.json`, `mana_flux.json`, `rage.json`, `regen_armor.json`.

Run: `git grep -c description_fr -- assets/data/passives`
Expected: `2` pour chacun des neuf fichiers — celui du passif, et celui de son bloc `mastery`.

Run: `git grep -n "statRules" -- assets/data`
Expected: une seule occurrence, dans `assets/data/classes/berserker/class.json`.

- [ ] **Step 2: Voir les trois identités dans le vrai jeu**

C'est la première livraison de P-41 qui change ce que le joueur voit : la suite de tests ne remplace pas de l'avoir regardée.

Invoke the `run` skill, et vérifier, une classe après l'autre :
- **Berserker** — jouer *Mur de Fer* ou *Défense* : l'armure reste à 0 et un statut ⚡ *Puissance* apparaît pour un tour, du montant de l'armure. Au début du tour, *Rage* donne de la Puissance même à pleine vie.
- **Mage** — la fiche des stats (carte « Puissance ») annonce *Compétences · Altérations*. Jouer une carte Attaque avec de la Puissance : les dégâts n'augmentent pas. Jouer une carte qui pose une altération : son intensité, si.
- **Paladin** — la fiche annonce les trois cibles. Encaisser un coup avec de l'armure fait apparaître la Puissance de *Ferveur* si c'est le passif actif ; sinon c'est *Régénération d'Armure*, le passif de départ.

Le choix du passif n'existe pas encore (lot C) : pour voir un autre passif que le premier de la classe, passer par la console de debug ou modifier temporairement le `displayOrder` d'un fichier — **sans commiter ce changement**.

- [ ] **Step 3: Mettre à jour le statut de la spec**

In `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md`, replace:
```markdown
Statut : **Lot A implémenté** (fusionné dans `main`, PR #38) — **lot B, partie 1 implémentée** (fusionnée dans `main`, PR #40) ; partie 2 en cours (branche `feat/p41-lot-b-identite`), lots C et D non implémentés ; lot B reconçu le 2026-09-17 (§0.3) ; chantier frère P-49 implémenté (fusionné dans `main`, PR #39), voir sa [spec](2026-09-16-p49-passifs-partages-design.md)
```
with:
```markdown
Statut : **Lot A implémenté** (fusionné dans `main`, PR #38) — **lot B implémenté en entier** : partie 1 fusionnée (PR #40), partie 2 sur la branche `feat/p41-lot-b-identite` ; lots C et D non implémentés ; lot B reconçu le 2026-09-17 (§0.3) ; chantier frère P-49 implémenté (fusionné dans `main`, PR #39), voir sa [spec](2026-09-16-p49-passifs-partages-design.md)
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md
git commit -F- <<'EOF'
docs(P-41): partie 2 du lot B implementee

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

- [ ] **Step 5: Synchroniser la mémoire du projet**

Invoke the `memory-bank-sync` skill. Ce qu'il doit consigner :
- **[ADR-097](../../../.obsidian_vault/_adr/ADR-097-puissance-unique-orientee-par-la-classe.md) est complété, pas remplacé** : la Puissance orientée par la classe y est déjà décidée, la partie 2 en livre les orientations. À ajouter : les six décisions d'implémentation du présent plan, et surtout **où vivent les règles de stat** — `RunState`, redérivées de la classe au chargement — qui est la seule de portée architecturale ;
- `_rules/02-2-systeme-de-heros.md` : les trois identités, les stats de départ, les neuf passifs et leurs déclencheurs ;
- `_patterns/03-3-traitsystem-passifs-de-heros.md` : la charge utile d'un `PassiveEvent`, les compteurs portés par un statut, et le fait qu'un passif choisit son déclencheur par sa donnée ;
- `docs/ROADMAP.md`, tableau des lots de P-41 : **P-41 B livré en entier**, le lot C devient le prochain et son périmètre gagne le choix du passif ;
- les métriques de `progress.md`, que le skill re-mesure lui-même — dont le compte de passifs, passé de 3 à 9.

- [ ] **Step 6: Note de version — avec l'accord du propriétaire**

**Ne pas invoquer `patch-notes-writer` sans l'accord explicite du propriétaire**, qui décide aussi du numéro : la note `0.5.2` a déjà été rouverte en place trois fois, et son tag attend P-42 (`docs/ROADMAP.md` §4). Contenu à proposer, en *Nouveautés* — c'est la première livraison de P-41 que le joueur ressent :

> Les trois classes ne jouent plus de la même manière. La Puissance du Paladin renforce tout ce qu'il joue ; le Berserker ne garde plus son armure, elle devient de la Puissance pour un tour ; le Mage frappe par ses Compétences et par ses altérations, plus par ses Attaques. Chaque classe a trois nouveaux passifs et une stat de départ qui lui est propre.

**À dire au propriétaire avant qu'il tranche** : le joueur n'accède pour l'instant qu'au premier passif de sa classe — le choix arrive au lot C. Annoncer « trois nouveaux passifs » est donc en avance d'un lot ; à lui de décider s'il préfère attendre le lot C pour la note, ou l'écrire maintenant sans le mot « choisir ».

- [ ] **Step 7: Terminer la branche**

Invoke the `superpowers:finishing-a-development-branch` skill.

---

## Suites relevées, hors de la partie 2

1. **Six passifs sur neuf sont inatteignables** : l'écran de sélection n'affiche que le premier de la classe (`class_selection_screen.dart:157-158`). → Le **choix du passif** est au lot C (spec §8.3), avec la forme longue de l'orientation et le retrait de `baseDamage`. C'est la suite immédiate de ce plan.
2. **L'étape « Armure » du tutoriel enseigne au Berserker une règle qu'il ne suit pas** (spec §9.1) : le gain est converti, la barre d'armure reste à 0, la prose reste celle d'avant. → Lot D, avec le reste de la mise à jour du tutoriel.
3. **`statRules` n'est pas éditable** : ni gabarit, ni validation de `stat`, `mode` et `to`. L'éditeur laisserait écrire `"mode": "convrt"`, exactement le cas qu'il existe pour refuser. → Lot D (spec §9.2), qui doit étendre le validateur à une liste de valeurs bornées imbriquée.
4. **Les compteurs de passif s'affichent dans le panneau des statuts**, via la branche `default` qui rend `'${status.name} : ${status.value}'` — donc « Compteur : 1 », en français quelle que soit la langue. C'est le défaut exact des charges de reliques qui les précèdent (`Charge Kunaï`, `Charge Shuriken`, `Charge Plume`, `Charge Encensoir`). → Un nettoyage à part : un drapeau `isHidden` sur `StatusEffect`, honoré par `status_effects_panel.dart` et `status_indicator.dart`, réglerait les cinq d'un coup.
5. **Les trois charges de reliques filtrent leurs statuts en ligne** (`player_stats_manager.dart:286-378`) alors que `removeStatus` existe depuis Task 4. → Trois remplacements mécaniques, hors périmètre ici.
6. **R4 n'est pas satisfaite par *Flux de Mana*** : 9 cartes `skill` sur 23, soit 39 %, le même compte que celui de `spell_armor`, dont la spec dit que « R4 formalise un défaut existant » (§6.2). → Les Compétences de S3 (P-42) la satisfont ; rien à faire d'ici là.
7. **Le cumul altération + rune devient réel** : une carte qui pose une altération et sa rune d'altération reçoivent chacune le bonus de Puissance (spec §7.1, relevé à la revue du lot A). Sans effet jusqu'ici, puisqu'aucune classe n'orientait vers `alteration` ; le Paladin et le Mage le rendent observable. → À trancher à l'équilibrage, pas ici : c'est une décision de conception, pas un bug.
8. **`StatBadge` porte trois branches que rien ne construit** — relevé au plan de la partie 1 et toujours ouvert. Il n'est instancié qu'en `StatType.hp` (`enemy_card.dart:123`) : ses branches `attack`, `armor` et `mana` sont du code mort, avec l'`iconText = 'ATK'` et les clés `tooltipAttackTitle` / `tooltipAttackDesc`. → Un nettoyage à part, hors de P-41.
9. **Cinq classes écrites sur disque par `test/widget/content_editor_screen_test.dart` n'ont ni `mightTargets` ni `critChance`** (`:85`, `:432`, `:827`, `:1032`, `:1375`) — relevé au plan de la partie 1. Aucun de ces tests ne les construit ; elles ne décrivent plus une classe valide. → À compléter si un test vient à les charger.

