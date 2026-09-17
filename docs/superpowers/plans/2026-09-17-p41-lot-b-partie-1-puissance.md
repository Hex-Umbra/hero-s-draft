# P-41 lot B, partie 1 — La Puissance — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Réunir les trois puissances du lot A en une seule, la **Puissance** (`might`), que chaque classe oriente vers ses Attaques, ses Compétences ou ses altérations — **sans rien changer au jeu** : les trois classes l'orientent vers `attack`, ce qui est exactement le jeu d'aujourd'hui.

**Architecture:** L'enum `MightTarget` nomme les trois cibles ; la classe les déclare dans `class.json` (`mightTargets`, obligatoire), et `RunController.startNewRun` en copie l'orientation dans les stats du héros (`EntityStats.mightTargets`, `{attack}` par défaut). `PowerRules` lit cette copie : les huit appels existants ne changent pas de forme. `attackPower` devient `might`, `skillPower` et `alterationPower` disparaissent, le statut `strength` devient `might` (la Puissance temporaire), et tous les textes du joueur disent *Puissance* / *Might*.

**Tech Stack:** Flutter / Dart 3.11, Flame, Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md` — lire le §0.3, puis le §7 en entier ; la partie 1 est décrite au §7.6. La partie 2 (orientations du Mage et du Paladin, conversion d'armure, neuf passifs, stats de départ) aura son propre plan, écrit une fois celui-ci fusionné.

## Global Constraints

- **Comportement de jeu inchangé** (spec §7.6) : les trois classes déclarent `"mightTargets": ["attack"]`, et `skillPower` comme `alterationPower` valent 0 partout aujourd'hui. Aucun dégât, aucune armure, aucune intensité ne change. Changent, voulus : les noms montrés au joueur (*Puissance*, *Might*) et le sous-titre de la carte « Puissance » de la fiche des stats.
- **Sauvegarde : aucune étape de migration, aucun test de compatibilité entre versions** (spec §7.5). `SaveMigrator.currentVersion` reste à 2. L'étape v1 → v2 du lot A et son test **gardent `attackPower`** : c'est le format v2 figé, que la lecture ignore désormais.
- `dart analyze` doit afficher `No issues found!` à la fin de **chaque** tâche.
- `flutter test` doit être **entièrement** vert à la fin de chaque tâche. Point de départ mesuré le 2026-09-17 sur `main` : **923 tests**. Chaque tâche donne le total attendu, mesuré en rejouant le plan sur une copie du dépôt le 2026-09-17.
- **Ne jamais lancer `dart format`** : le dépôt ne l'utilise pas.
- Créer et modifier les fichiers avec les outils Write / Edit. **Jamais par heredoc bash** pour du contenu : les heredocs de cet environnement mangent les antislashs, et le code Dart du plan en contient (`'Éveil d\'Attaque'`, `\n`). Les deux scripts Python du plan (Tasks 2 et 4) n'en contiennent aucun et passent par heredoc, lancés avec `PYTHONUTF8=1` : ils portent des caractères accentués.
- Tout texte joueur d'un JSON porte ses variantes `_fr` **et** `_en` (`CLAUDE.md`).
- Le tutoriel ne référence aucun provider d'état (ADR-081), vérifié par `test/tutorial/tutorial_isolation_test.dart`.
- Ne pas toucher `assets/data/patch_notes.json` ni le champ `version:` de `pubspec.yaml` : ils appartiennent au skill `patch-notes-writer`.
- Les fichiers `lib/l10n/app_localizations.dart`, `app_localizations_en.dart` et `app_localizations_fr.dart` sont générés **et commités** : après toute modification d'un ARB, lancer `flutter gen-l10n` et commiter les trois.
- Le code va sur la branche `feat/p41-lot-b-puissance`, jamais sur `main`. Seule la documentation de Task 0 est commitée sur `main`. **Pas de worktree** (décision du propriétaire) : la branche est créée dans le checkout principal, même si le skill d'exécution en propose un.
- Messages de commit en français, forme `type(portee): message`, **sans accents ni apostrophes**, terminés par la ligne `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- Les commandes `flutter` peuvent réécrire des fichiers générés sans en changer le contenu, fins de ligne seulement : `macos/Flutter/GeneratedPluginRegistrant.swift` et, dans un checkout neuf, ceux de `linux/flutter/` et de `windows/flutter/`. S'ils apparaissent dans `git status`, les restaurer (`git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`) ; ne jamais les commiter.
- Les greps qui vérifient la disparition d'un identifiant cherchent des **mots entiers** (`git grep -w`).

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/models/might_target.dart` *(nouveau)* | `MightTarget`, `MightTarget.parseAll` | 1 |
| `lib/models/data/hero_data.dart`, `assets/data/classes/*/class.json` | `HeroData.mightTargets`, déclaré par les trois classes | 1 |
| `lib/services/content_editor/entity_descriptor.dart` | `mightTargets` éditable en cases à cocher, au gabarit de classe | 1 |
| 41 fichiers de `lib/` et `test/` | `attackPower` → `might`, par script | 2 |
| `lib/models/entity_stats.dart` | `might`, `mightTargets`, `effectiveMight` ; retrait de `skillPower`, `alterationPower` | 2, 3 |
| `lib/game/systems/power_rules.dart` | Lit l'orientation | 3 |
| `lib/game/systems/stat_gains.dart` | `GainResource.might` seule | 2, 3 |
| `lib/game/controllers/run_controller.dart`, `lib/tutorial/tutorial_engine.dart` | Copient l'orientation de la classe | 3 |
| 30 fichiers de `lib/`, `test/` et `assets/data/` | Statut et effets `strength` → `might`, par script | 4 |
| `lib/game/controllers/run/player_stats_manager.dart`, `run_controller.dart` | Retrait d'`applyAttackBuff`, code mort | 4 |
| `lib/l10n/*.arb` et fichiers générés, `lib/models/data/model_extensions.dart` | Textes, libellés abrégés des cibles | 5 |
| `lib/ui/widgets/map/dialogs/stats_dialog.dart`, `hero_mini_stats_panel.dart` | Carte et ligne « Puissance » | 5 |
| `lib/tutorial/tutorial_data.dart`, `lib/tutorial/widgets/tutorial_elements_widget.dart` | Prose et glossaire du tutoriel | 5 |
| `assets/data/cards/`, `relics/`, `events/` (8 fichiers) | Descriptions | 5 |

---

### Task 0: Documentation sur `main`, puis branche

**À faire dans le checkout principal, avant toute tâche de code** : la branche part du commit de documentation.

**Files:**
- Modify: `docs/INDEX.md:49` ; `docs/ROADMAP.md:404`

**Interfaces:**
- Consumes: ce plan, et la spec retouchée pendant sa rédaction, non commités.
- Produces: un commit de documentation sur `main`, puis la branche `feat/p41-lot-b-puissance` créée depuis lui.

- [ ] **Step 1: Vérifier l'état de départ**

Run: `git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift` (fins de ligne seulement), puis `git status --short`
Expected: exactement ces deux lignes, et rien d'autre :
```
 M docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md
?? docs/superpowers/plans/2026-09-17-p41-lot-b-partie-1-puissance.md
```

- [ ] **Step 2: Relier le plan depuis l'index et la feuille de route**

In `docs/INDEX.md`, replace:
```markdown
| 🔨 | [P-41 — Plan du lot A](superpowers/plans/2026-09-16-p41-lot-a-passage-unique-scission-migration.md) *(passage unique, scission des puissances, migration de sauvegarde)* | 16/09/2026 |
```
with:
```markdown
| 🔨 | [P-41 — Plan du lot A](superpowers/plans/2026-09-16-p41-lot-a-passage-unique-scission-migration.md) *(passage unique, scission des puissances, migration de sauvegarde)* | 16/09/2026 |
| 🔨 | [P-41 — Plan du lot B, partie 1](superpowers/plans/2026-09-17-p41-lot-b-partie-1-puissance.md) *(la Puissance, orientée par la classe, à comportement identique)* | 17/09/2026 |
```
and replace `**Dernière mise à jour** : 2026-09-17` with the date of the day if it differs.

In `docs/ROADMAP.md`, replace:
```markdown
[spec, §7](superpowers/specs/2026-08-07-s2-identite-de-classe-design.md), reconçue le 2026-09-17 |
```
with:
```markdown
[spec, §7](superpowers/specs/2026-08-07-s2-identite-de-classe-design.md), reconçue le 2026-09-17 · [plan de la partie 1](superpowers/plans/2026-09-17-p41-lot-b-partie-1-puissance.md) |
```

- [ ] **Step 3: Commiter la documentation sur `main`**

```bash
git add docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md docs/superpowers/plans/2026-09-17-p41-lot-b-partie-1-puissance.md docs/INDEX.md docs/ROADMAP.md
git commit -F- <<'EOF'
docs(P-41): plan de la partie 1 du lot B, spec completee

La redaction du plan releve que l info-bulle de la stat d attaque
n est jamais affichee : la description longue de la Puissance part au
lot C, avec l ecran de selection. Elle releve aussi deux textes ecrits
en dur, le glossaire du tutoriel et le carrousel des recompenses. Plan
rejoue tache par tache sur une copie du depot avant ce commit.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

- [ ] **Step 4: Créer la branche**

Run: `git switch -c feat/p41-lot-b-puissance` — depuis le commit du Step 3, dans le checkout principal.

- [ ] **Step 5: Mesurer la base**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+923: All tests passed!`

---

### Task 1: `MightTarget` et l'orientation déclarée par la classe

Modèle et donnée seuls, sans lecteur encore : rien du jeu ne change.

**Files:**
- Create: `lib/models/might_target.dart`
- Modify: `lib/models/data/hero_data.dart` ; `assets/data/classes/berserker/class.json`, `mage/class.json`, `paladin/class.json` ; `lib/services/content_editor/entity_descriptor.dart:12`, `:347-348`, `:360-361`
- Test: `test/unit/might_target_test.dart` *(nouveau)* ; fixtures de classe dans `test/unit/content_editor/entity_descriptor_test.dart`, `test/unit/content_editor/fixtures.dart`, `test/unit/content_editor/entity_validator_test.dart`, `test/unit/hero_data_identity_test.dart`, `test/widget/content_editor_screen_test.dart`

**Interfaces:**
- Consumes: rien.
- Produces:
  - `enum MightTarget { attack, skill, alteration }` dans `lib/models/might_target.dart` ; l'ordre des valeurs est l'ordre d'affichage.
  - `static Set<MightTarget> MightTarget.parseAll(Object? json)` : lève `FormatException` sur une valeur qui n'est pas une liste, une liste vide ou une cible inconnue.
  - `HeroData.mightTargets` (`Set<MightTarget>`), paramètre nommé optionnel du constructeur `const`, par défaut `const {MightTarget.attack}` ; `HeroData.fromJson` le lit par `MightTarget.parseAll(json['mightTargets'])`, donc lève sur une clé absente.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/might_target_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/might_target.dart';

/// L'orientation de la Puissance, déclarée par la classe (spec P-41, §7.1).
void main() {
  group('MightTarget.parseAll', () {
    test('lit chaque cible nommee', () {
      expect(
        MightTarget.parseAll(['skill', 'alteration']),
        {MightTarget.skill, MightTarget.alteration},
      );
    });

    test('les trois cibles ensemble', () {
      expect(
        MightTarget.parseAll(['attack', 'skill', 'alteration']),
        MightTarget.values.toSet(),
      );
    });

    test('une liste vide est refusee', () {
      expect(() => MightTarget.parseAll(<String>[]), throwsFormatException);
    });

    test('une valeur qui n est pas une liste est refusee', () {
      expect(() => MightTarget.parseAll('attack'), throwsFormatException);
      expect(() => MightTarget.parseAll(null), throwsFormatException);
    });

    test('une cible inconnue est refusee', () {
      expect(
        () => MightTarget.parseAll(['attack', 'defense']),
        throwsFormatException,
      );
    });
  });

  group('HeroData.mightTargets', () {
    Map<String, dynamic> classJson() => {
          'id': 'mage',
          'classCard': 'assets/data/classes/mage/mage.png',
          'maxHp': 60,
          'maxMana': 3,
          'baseDamage': 10,
          'mightTargets': ['skill', 'alteration'],
        };

    test('lue dans class.json', () {
      expect(
        HeroData.fromJson(classJson()).mightTargets,
        {MightTarget.skill, MightTarget.alteration},
      );
    });

    test('une classe sans mightTargets ne se charge pas', () {
      expect(
        () => HeroData.fromJson(classJson()..remove('mightTargets')),
        throwsFormatException,
      );
    });

    test('construite en code, une classe oriente sa Puissance vers attack', () {
      const hero = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        baseDamage: 5,
      );
      expect(hero.mightTargets, {MightTarget.attack});
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/might_target_test.dart`
Expected: FAIL à la compilation — `Error when reading 'lib/models/might_target.dart'`.

- [ ] **Step 3: Écrire l'enum**

Create `lib/models/might_target.dart`:

```dart
/// Ce que la Puissance d'une classe renforce (spec P-41, §7.1).
///
/// La classe le déclare dans son `class.json` ; les stats du héros en portent
/// une copie, que lit `PowerRules`. L'ordre des valeurs est l'ordre
/// d'affichage.
enum MightTarget {
  /// Les dégâts d'un effet `damage` porté par une carte Attaque.
  attack,

  /// Les dégâts d'un effet `damage` porté par une carte Compétence.
  skill,

  /// L'intensité d'un statut posé sur un ennemi, par une carte ou par l'une de
  /// ses runes — jamais sa durée.
  alteration;

  /// Lit une liste JSON de cibles. Lève [FormatException] sur une valeur qui
  /// n'est pas une liste, sur une liste vide et sur une cible inconnue : une
  /// classe dont la Puissance ne renforcerait rien est une faute de donnée.
  static Set<MightTarget> parseAll(Object? json) {
    if (json is! List || json.isEmpty) {
      throw FormatException(
        'mightTargets doit être une liste non vide — reçu : $json',
      );
    }
    return {
      for (final name in json)
        MightTarget.values.firstWhere(
          (target) => target.name == name,
          orElse: () => throw FormatException(
            'mightTargets : cible inconnue "$name" — attendu : '
            '${MightTarget.values.map((target) => target.name).join(', ')}',
          ),
        ),
    };
  }
}
```

- [ ] **Step 4: `HeroData` lit l'orientation**

In `lib/models/data/hero_data.dart`, replace:
```dart
class HeroData {
```
with:
```dart
import '../might_target.dart';

class HeroData {
```
Replace:
```dart
  final int mastery;
```
with:
```dart
  final int mastery;

  /// Ce que la Puissance de la classe renforce (spec P-41, §7.1). Obligatoire
  /// dans `class.json` : la valeur par défaut ne sert qu'aux constructions
  /// écrites en code.
  final Set<MightTarget> mightTargets;
```
Replace:
```dart
    this.mastery = 0,
```
with:
```dart
    this.mastery = 0,
    this.mightTargets = const {MightTarget.attack},
```
Replace:
```dart
      mastery: json['mastery'] as int? ?? 0,
```
with:
```dart
      mastery: json['mastery'] as int? ?? 0,
      mightTargets: MightTarget.parseAll(json['mightTargets']),
```

- [ ] **Step 5: Lancer le test pour le voir passer**

Run: `flutter test test/unit/might_target_test.dart`
Expected: PASS, `+8: All tests passed!`

- [ ] **Step 6: Les trois classes et l'éditeur de contenu**

Les trois classes orientent leur Puissance vers `attack` : c'est le jeu actuel. L'éditeur déclare la clé en `enumListKeys`, ce qui ouvre des cases à cocher sans nouveau type de champ (précédent : `eligibleCardTypes`), l'exige, et la met au gabarit de classe.

In `assets/data/classes/berserker/class.json`, replace:
```json
  "luck": 0,
```
with:
```json
  "luck": 0,
  "mightTargets": ["attack"],
```
In `assets/data/classes/mage/class.json`, replace:
```json
  "luck": 0,
```
with:
```json
  "luck": 0,
  "mightTargets": ["attack"],
```
In `assets/data/classes/paladin/class.json`, replace:
```json
  "luck": 0,
```
with:
```json
  "luck": 0,
  "mightTargets": ["attack"],
```
In `lib/services/content_editor/entity_descriptor.dart`, replace:
```dart
import '../../models/enemy_intent.dart';
```
with:
```dart
import '../../models/enemy_intent.dart';
import '../../models/might_target.dart';
```
Replace:
```dart
    requiredKeys: const {'maxHp', 'maxMana', 'baseDamage'},
    hexColorKeys: const {'themeColor'},
```
with:
```dart
    requiredKeys: const {'maxHp', 'maxMana', 'baseDamage', 'mightTargets'},
    enumListKeys: {'mightTargets': _names(MightTarget.values)},
    hexColorKeys: const {'themeColor'},
```
Replace:
```dart
  "luck": 0,
  "mastery": 0,
```
with:
```dart
  "luck": 0,
  "mastery": 0,
  "mightTargets": ["attack"],
```

- [ ] **Step 7: Les fixtures de classe**

Sans ces ajouts, 18 tests échouent, tous parce qu'une classe construite par `HeroData.fromJson` n'a pas de `mightTargets` (mesuré le 2026-09-17) : le gabarit de classe (`entity_descriptor_test`), les familles « liste de références », « couleur hex » et « bijection skills » du validateur (`entity_validator_test`, via `fixtureHero`), `hero_data_identity_test`, et l'import d'icône de classe (`content_editor_screen_test`). Les autres classes écrites sur disque par `content_editor_screen_test.dart` ne sont jamais construites : elles restent telles quelles.

In `test/unit/content_editor/entity_descriptor_test.dart`, replace:
```dart
      'luck',
      'mastery',
      'displayOrder',
      'themeColor',
    ]) {
```
with:
```dart
      'luck',
      'mastery',
      'mightTargets',
      'displayOrder',
      'themeColor',
    ]) {
```
Replace:
```dart
        'luck',
        'mastery',
        'displayOrder',
        'themeColor',
      },
```
with:
```dart
        'luck',
        'mastery',
        'mightTargets',
        'displayOrder',
        'themeColor',
      },
```
In `test/unit/content_editor/fixtures.dart`, replace:
```dart
      'baseDamage': 5,
```
with:
```dart
      'baseDamage': 5,
      'mightTargets': ['attack'],
```
In `test/unit/content_editor/entity_validator_test.dart`, replace:
```dart
        'baseDamage': 4,
```
with:
```dart
        'baseDamage': 4,
        'mightTargets': ['attack'],
```
Replace:
```dart
              '"skills": $skillsJson}',
```
with:
```dart
              '"mightTargets": ["attack"], "skills": $skillsJson}',
```
Replace:
```dart
          mechanics: '{"maxHp": 100, "maxMana": 3, "baseDamage": 5}',
```
with:
```dart
          mechanics: '{"maxHp": 100, "maxMana": 3, "baseDamage": 5, '
              '"mightTargets": ["attack"]}',
```
In `test/unit/hero_data_identity_test.dart`, replace:
```dart
        'baseDamage': 5,
```
with:
```dart
        'baseDamage': 5,
        'mightTargets': ['attack'],
```
In `test/widget/content_editor_screen_test.dart`, replace:
```dart
          'baseDamage': 5,
          'displayOrder': 1,
```
with:
```dart
          'baseDamage': 5,
          'mightTargets': ['attack'],
          'displayOrder': 1,
```

- [ ] **Step 8: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+931: All tests passed!`

- [ ] **Step 9: Commit**

```bash
git add lib/models/might_target.dart lib/models/data/hero_data.dart assets/data/classes lib/services/content_editor/entity_descriptor.dart test/unit/might_target_test.dart test/unit/content_editor test/unit/hero_data_identity_test.dart test/widget/content_editor_screen_test.dart
git commit -F- <<'EOF'
feat(puissance): la classe declare ce que sa Puissance renforce

mightTargets, obligatoire dans class.json, est lu par HeroData ; les
trois classes l orientent vers attack, comme le jeu actuel. L editeur
de contenu le propose en cases a cocher. Aucun lecteur encore.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 2: `attackPower` devient `might`

Renommage mécanique, sans test nouveau : la suite existante le couvre. L'étape de migration v1 → v2 et son test gardent `attackPower` (spec §7.5) ; `save_service_test.dart` est traité à la main.

**Files:**
- Modify (script) : 22 fichiers de `lib/`, 19 de `test/` (liste à l'étape 1)
- Modify (à la main) : `lib/models/entity_stats.dart:99` ; `test/unit/save_service_test.dart:220-257`

**Interfaces:**
- Consumes: rien de Task 1.
- Produces: `EntityStats.might` (constructeur : `required this.might`), `EntityStats.effectiveMight`, `GainResource.might`, `applyHeroStatModifier({int mightAcc})`, `DraftChoice.mightBoost`, `EncounterSystem`/`CombatController` : `playerMight`, `CombatBottomHud` et `PlayerHealthBar` : `effectiveMight`. `EntityStats.fromJson` lit `might` à 0 quand il manque.

- [ ] **Step 1: Lancer le renommage**

Depuis la racine du dépôt :

```bash
PYTHONUTF8=1 python - <<'EOF'
"""P-41 lot B, partie 1, Task 2 : attackPower devient might.

Renommage mecanique, sans changement de comportement. Les paires sont
appliquees dans l'ordre : les plus longues d'abord, pour qu'aucune n'en
entame une autre. L'etape de migration v1 -> v2 et son test gardent
`attackPower` : c'est le format v2 fige (spec P-41, §7.5), et
`save_service_test.dart` est traite a la main."""
import io
import pathlib
import subprocess

PAIRS = [
    ("effectiveAttackPower", "effectiveMight"),
    ("attackPower: 0, // Force de base à 0", "might: 0, // Puissance de base à 0"),
    ("label: 'Attaque',", "label: 'Puissance',"),
    ("Attack: ${playerAttaque", "Might: ${playerMight"),
    ("(attaque * 10)", "(might * 10)"),
    ("attackPower", "might"),
    ("attackAcc", "mightAcc"),
    ("atkBoost", "mightBoost"),
    ("playerAttaque", "playerMight"),
]

EXCLUDED = {
    "lib/services/save_migrations.dart",
    "test/unit/save_migrations_test.dart",
    "test/unit/save_service_test.dart",
}

paths = subprocess.run(
    ["git", "grep", "-l", "-e", "attackPower", "-e", "effectiveAttackPower", "-e", "attackAcc",
     "-e", "atkBoost", "-e", "playerAttaque", "--", "lib", "test"],
    capture_output=True, text=True, check=True,
).stdout.split()

total = 0
for rel in sorted(p for p in paths if p not in EXCLUDED):
    path = pathlib.Path(rel)
    text = io.open(path, encoding="utf-8", newline="").read()
    count = 0
    for old, new in PAIRS:
        count += text.count(old)
        text = text.replace(old, new)
    io.open(path, "w", encoding="utf-8", newline="").write(text)
    total += count
    print(f"{count:3} {rel}")
print("TOTAL", total, "remplacements dans", len(paths) - len(EXCLUDED & set(paths)), "fichiers")
EOF
```

Expected: exactement cette sortie (mesurée le 2026-09-17) :
```
  4 lib/game/components/entities/enemy_card.dart
  8 lib/game/controllers/combat_controller.dart
  1 lib/game/controllers/event_controller.dart
  5 lib/game/controllers/run/player_stats_manager.dart
  5 lib/game/controllers/run_controller.dart
  4 lib/game/services/combat_debug_logger.dart
  3 lib/game/services/level_up_reward_service.dart
  5 lib/game/systems/encounter_system.dart
  1 lib/game/systems/power_rules.dart
  4 lib/game/systems/stat_gains.dart
  5 lib/models/enemy_instance.dart
 12 lib/models/entity_stats.dart
  4 lib/tutorial/tutorial_engine.dart
  3 lib/tutorial/widgets/tutorial_enemy_intents_widget.dart
  2 lib/ui/screens/draft_screen.dart
  4 lib/ui/screens/game_screen.dart
  3 lib/ui/widgets/debug/tabs/debug_hero_tab.dart
  1 lib/ui/widgets/draft/draft_choice_labels.dart
  4 lib/ui/widgets/hud/combat_bottom_hud.dart
  3 lib/ui/widgets/hud/player_health_bar.dart
  1 lib/ui/widgets/map/dialogs/stats_dialog.dart
  1 lib/ui/widgets/map/hero_mini_stats_panel.dart
 23 test/encounter_system_test.dart
 14 test/unit/combat_controller_test.dart
  2 test/unit/combat_debug_logger_test.dart
  1 test/unit/debug_actions_test.dart
 17 test/unit/effect_resolver_test.dart
  1 test/unit/event_controller_test.dart
  1 test/unit/level_up_reward_values_test.dart
  1 test/unit/notifier_hydrate_test.dart
  3 test/unit/power_split_test.dart
  2 test/unit/relic_exchange_test.dart
  1 test/unit/reward_controller_test.dart
  1 test/unit/run_state_persistence_test.dart
  4 test/unit/stat_gain_single_passage_test.dart
  5 test/unit/stat_gains_characterization_test.dart
  6 test/unit/stat_gains_test.dart
  1 test/widget/debug_drawer_test.dart
  2 test/widget/draft_screen_test.dart
  2 test/widget/enemy_intents_panel_overflow_test.dart
  1 test/widget/player_health_bar_test.dart
TOTAL 171 remplacements dans 41 fichiers
```
Si le total diffère, s'arrêter et comprendre avant d'aller plus loin.

- [ ] **Step 2: La lecture tolère une sauvegarde sans `might`**

Une partie sauvegardée avant ce lot n'a pas de clé `might` : elle se recharge à 0 au lieu d'échouer (spec §7.5).

In `lib/models/entity_stats.dart`, replace:
```dart
      might: json['might'] as int,
```
with:
```dart
      might: json['might'] as int? ?? 0,
```

- [ ] **Step 3: Le test de la sauvegarde v1**

Il simulait une v1 en renommant `attackPower` et vérifiait que l'attaque survivait. Depuis ce lot, la valeur d'`attaque` n'est plus relue : le test garde ce qu'il protège vraiment, la chaîne de migration qui ouvre la partie.

In `test/unit/save_service_test.dart`, replace:
```dart
    test('load migrates a legacy v1 save: attaque is kept as attackPower', () async {
      const hero = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        baseDamage: 5,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(hero);
      container.read(runProvider.notifier).applyHeroStatModifier(attackAcc: 4);
      await SaveService.save(container.read);

      // Réécrit la sauvegarde telle que l'écrivaient tous les builds jusqu'à
      // 0.5.1 : version 1, clé `attaque`, sans les deux nouvelles puissances,
      // sous l'ancienne clé de stockage.
      final prefs = await SharedPreferences.getInstance();
      final save =
          jsonDecode(prefs.getString('run_save')!) as Map<String, dynamic>;
      final run = save['run'] as Map<String, dynamic>;
      final heroStats = run['heroStats'] as Map<String, dynamic>;
      heroStats['attaque'] = heroStats.remove('attackPower');
      heroStats.remove('skillPower');
      heroStats.remove('alterationPower');
      save['schemaVersion'] = 1;
      await prefs.setString('run_save_v1', jsonEncode(save));
      await prefs.remove('run_save');

      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      final result = await SaveService.load(fresh.read);

      expect(result.success, isTrue);
      expect(fresh.read(runProvider).heroStats.attackPower, 4);
      expect(fresh.read(runProvider).heroStats.skillPower, 0);
      expect(fresh.read(runProvider).heroStats.alterationPower, 0);
    });
```
with:
```dart
    test('load migrates a legacy v1 save stored under run_save_v1', () async {
      const hero = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        baseDamage: 5,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(hero);
      await SaveService.save(container.read);

      // Réécrit la sauvegarde telle que l'écrivaient tous les builds jusqu'à
      // 0.5.1 : version 1, clé `attaque`, sous l'ancienne clé de stockage. La
      // valeur d'`attaque` n'est plus relue depuis le lot B de P-41 (spec,
      // §7.5) : seul compte ici que la chaîne de migration ouvre la partie.
      final prefs = await SharedPreferences.getInstance();
      final save =
          jsonDecode(prefs.getString('run_save')!) as Map<String, dynamic>;
      final run = save['run'] as Map<String, dynamic>;
      final heroStats = run['heroStats'] as Map<String, dynamic>;
      heroStats['attaque'] = heroStats.remove('might');
      heroStats.remove('skillPower');
      heroStats.remove('alterationPower');
      save['schemaVersion'] = 1;
      await prefs.setString('run_save_v1', jsonEncode(save));
      await prefs.remove('run_save');

      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      final result = await SaveService.load(fresh.read);

      expect(result.success, isTrue);
      expect(fresh.read(runProvider).heroClassId, 'paladin');
    });
```

- [ ] **Step 4: Vérifier qu'il ne reste que l'étape de migration**

Run: `git grep -nw -e attackPower -e effectiveAttackPower -e attackAcc -e atkBoost -e playerAttaque -- lib test`
Expected: exactement ces quatre lignes :
```
lib/services/save_migrations.dart:67:/// v1 → v2 (P-41, lot A) : `attaque` devient `attackPower`. `skillPower` et
lib/services/save_migrations.dart:77:  heroStats['attackPower'] = heroStats.remove('attaque');
test/unit/save_migrations_test.dart:74:    test('v1 vers v2 : attaque devient attackPower', () {
test/unit/save_migrations_test.dart:86:      expect(heroStats['attackPower'], 7);
```

- [ ] **Step 5: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+931: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add -u lib test
git commit -F- <<'EOF'
refactor(puissance): attackPower devient might

Renommage mecanique de la stat, de son getter effectif, de la ressource
de gain, du parametre de progression, de la recompense Aiguisage et de
l entree du budget de rencontre. Aucun comportement ne change. L etape
de migration v1 vers v2 garde attackPower, que la lecture ignore.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 3: Une seule Puissance, orientée par la classe

**Files:**
- Delete: `test/unit/power_split_test.dart` (ses 9 tests sont remplacés)
- Create: `test/unit/might_orientation_test.dart`
- Modify: `lib/models/entity_stats.dart` ; `lib/game/systems/power_rules.dart` (réécrit en entier) ; `lib/game/systems/stat_gains.dart:4`, `:51-59` ; `lib/game/controllers/run_controller.dart:246-247` ; `lib/tutorial/tutorial_engine.dart:62-63` ; `lib/services/save_migrations.dart:67-70`
- Test: `test/unit/stat_gains_test.dart:32-50` ; `test/unit/stat_gain_single_passage_test.dart:5`, `:18`, `:20` ; `test/unit/save_service_test.dart` ; `test/tutorial/tutorial_engine_test.dart:203-204`

**Interfaces:**
- Consumes: `MightTarget`, `MightTarget.parseAll`, `HeroData.mightTargets` (Task 1) ; `EntityStats.might`, `effectiveMight`, `GainResource.might` (Task 2).
- Produces:
  - `EntityStats.mightTargets` (`Set<MightTarget>`), paramètre nommé optionnel du constructeur, par défaut `const {MightTarget.attack}` ; `copyWith(mightTargets:)` ; en JSON, clé `mightTargets`, liste dans l'ordre de `MightTarget`, `{attack}` quand elle manque.
  - `enum GainResource { armor, mana, might }`.
  - `PowerRules.damageBonusFor(CardType)` et `statusBonusFor(CardTarget)`, mêmes signatures, lisent `mightTargets`.
  - `RunController.startNewRun` et `TutorialMockState.baseStatsForHero` copient `HeroData.mightTargets` dans les stats.

- [ ] **Step 1: Remplacer le test du lot A par le test qui échoue**

Run: `git rm -q test/unit/power_split_test.dart`

Create `test/unit/might_orientation_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/game/services/effects/effect_strategy.dart';
import 'package:roguelike_card_game/game/systems/power_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/might_target.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

const _temporaryMight = StatusEffect(
  id: 'strength',
  name: 'Attaque',
  type: StatusType.buff,
  value: 5,
  duration: 2,
);

/// La Puissance, que la classe oriente (spec P-41, §7.1).
void main() {
  group('PowerRules', () {
    EntityStats stats(Set<MightTarget> targets) => EntityStats(
          maxPv: 50,
          currentPv: 50,
          armure: 0,
          might: 2,
          mightTargets: targets,
          statuses: const [_temporaryMight],
        );

    test('vers attack : seules les cartes Attaque la recoivent, temporaire comprise', () {
      final s = stats({MightTarget.attack});
      expect(s.damageBonusFor(CardType.attack), 2 + 5);
      expect(s.damageBonusFor(CardType.skill), 0);
      expect(s.statusBonusFor(CardTarget.singleEnemy), 0);
    });

    test('vers skill : seules les cartes Competence la recoivent', () {
      final s = stats({MightTarget.skill});
      expect(s.damageBonusFor(CardType.attack), 0);
      expect(s.damageBonusFor(CardType.skill), 2 + 5);
      expect(s.statusBonusFor(CardTarget.singleEnemy), 0);
    });

    test('vers alteration : seuls les statuts poses sur un ennemi la recoivent', () {
      final s = stats({MightTarget.alteration});
      expect(s.damageBonusFor(CardType.attack), 0);
      expect(s.damageBonusFor(CardType.skill), 0);
      expect(s.statusBonusFor(CardTarget.singleEnemy), 2 + 5);
      expect(s.statusBonusFor(CardTarget.allEnemies), 2 + 5);
    });

    test('les cartes Pouvoir et Statut ne recoivent jamais rien', () {
      final s = stats(MightTarget.values.toSet());
      expect(s.damageBonusFor(CardType.power), 0);
      expect(s.damageBonusFor(CardType.status), 0);
    });

    test('un statut pose sur soi, ou sans cible, ne recoit jamais rien', () {
      final s = stats(MightTarget.values.toSet());
      expect(s.statusBonusFor(CardTarget.self), 0);
      expect(s.statusBonusFor(CardTarget.none), 0);
    });

    test('des stats construites sans orientation la tournent vers attack', () {
      final s = EntityStats(maxPv: 10, currentPv: 10, armure: 0, might: 1);
      expect(s.mightTargets, {MightTarget.attack});
    });
  });

  group('EntityStats en JSON', () {
    test('mightTargets fait l aller-retour', () {
      final s = EntityStats(
        maxPv: 10,
        currentPv: 10,
        armure: 0,
        might: 3,
        mightTargets: const {MightTarget.alteration, MightTarget.skill},
      );
      final json = s.toJson();
      expect(json['mightTargets'], ['skill', 'alteration']);
      expect(EntityStats.fromJson(json).mightTargets, s.mightTargets);
    });

    test('absent du JSON : attack', () {
      final json = EntityStats(maxPv: 10, currentPv: 10, armure: 0, might: 3)
          .toJson()
        ..remove('mightTargets');
      expect(EntityStats.fromJson(json).mightTargets, {MightTarget.attack});
    });
  });

  group('resolution d une carte', () {
    const mage = HeroData(
      id: 'mage',
      classCard: 'mage.png',
      maxHp: 60,
      maxMana: 3,
      baseDamage: 0,
      mightTargets: {MightTarget.skill, MightTarget.alteration},
    );
    final slime = EnemyData(
      id: 'slime',
      nameEn: 'Slime',
      nameFr: 'Slime',
      maxHp: 100,
      baseDamage: 1,
      spritePath: 'slime.png',
      tier: 1,
      intents: [EnemyIntent(type: IntentType.attack, value: 1)],
    );

    late ProviderContainer container;
    late RunController run;
    late CombatController combat;
    late String enemyId;

    setUp(() {
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
      combat = container.read(combatProvider.notifier);
      run.startNewRun(mage);
      run.updateState(
        run.currentState.copyWith(
          heroStats: run.currentState.heroStats.copyWith(might: 3),
        ),
      );
      final enemy = EnemyInstance(
        data: slime,
        stats: EntityStats(
          maxPv: 100,
          currentPv: 100,
          armure: 0,
          might: 1,
        ),
      );
      enemyId = enemy.id;
      combat.state = CombatState(
        enemies: [enemy],
        selectedEnemyId: enemyId,
        turnPhase: TurnPhase.player,
      );
    });

    tearDown(() => container.dispose());

    CardInstance card(
      CardType type,
      CardTarget target,
      List<CardEffect> effects, {
      List<String> runes = const [],
    }) {
      return CardInstance(
        data: CardData(
          id: 'test_card',
          cost: 0,
          type: type,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: target,
          effects: effects,
        ),
        forgeUpgrades: runes,
      );
    }

    void play(CardInstance card) {
      final played = EffectResolver.resolveCard(
        card,
        run,
        container.read(deckProvider.notifier),
        combat,
        enemyId,
        container.read(effectRegistryProvider),
      );
      expect(played, isTrue);
    }

    EnemyInstance enemy() => combat.currentState.enemies.single;

    test('startNewRun copie l orientation de la classe dans les stats', () {
      expect(
        run.currentState.heroStats.mightTargets,
        {MightTarget.skill, MightTarget.alteration},
      );
    });

    test('une Competence offensive recoit la Puissance, temporaire comprise', () {
      run.addStatus(_temporaryMight);

      play(card(CardType.skill, CardTarget.singleEnemy, const [
        CardEffect(type: 'damage', value: 5),
      ]));

      expect(enemy().stats.currentPv, 100 - (5 + 3 + 5));
    });

    test('une carte Attaque ne recoit rien quand la classe ne l oriente pas', () {
      play(card(CardType.attack, CardTarget.singleEnemy, const [
        CardEffect(type: 'damage', value: 5),
      ]));

      expect(enemy().stats.currentPv, 100 - 5);
    });

    test('un statut pose sur l ennemi gagne la Puissance en intensite, pas en duree', () {
      play(card(CardType.attack, CardTarget.singleEnemy, const [
        CardEffect(type: 'apply_status', value: 4, statusId: 'poison', duration: 3),
      ]));

      final poison = enemy().stats.statuses.singleWhere((s) => s.id == 'poison');
      expect(poison.value, 4 + 3);
      expect(poison.duration, 3);
    });

    test('un statut pose sur soi ignore la Puissance', () {
      play(card(CardType.skill, CardTarget.self, const [
        CardEffect(type: 'apply_status', value: 2, statusId: 'strength', duration: 1),
      ]));

      final applied = run.currentState.heroStats.statuses
          .singleWhere((s) => s.id == 'strength');
      expect(applied.value, 2);
    });

    test('une rune d alteration gagne la Puissance en intensite', () {
      play(card(
        CardType.attack,
        CardTarget.singleEnemy,
        const [CardEffect(type: 'damage', value: 1)],
        runes: const ['burning:1'],
      ));

      final burn = enemy().stats.statuses.singleWhere((s) => s.id == 'burn');
      expect(burn.value, 1 + 3);
      expect(burn.duration, 1);
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/might_orientation_test.dart`
Expected: FAIL à la compilation — `No named parameter with the name 'mightTargets'` et `The getter 'mightTargets' isn't defined for the type 'EntityStats'`.

- [ ] **Step 3: `EntityStats` porte l'orientation, et perd les deux autres puissances**

In `lib/models/entity_stats.dart`, replace:
```dart
import 'status_effect.dart';
```
with:
```dart
import 'might_target.dart';
import 'status_effect.dart';
```
Replace:
```dart
  final int might; // Dégâts des cartes Attaque — la Force s'y ajoute
  final int skillPower; // Dégâts des cartes Compétence
  final int alterationPower; // Intensité des statuts posés sur un ennemi
```
with:
```dart
  final int might; // Puissance permanente : ce qu'elle renforce, voir mightTargets
  final Set<MightTarget> mightTargets; // Copie de l'orientation de la classe (spec P-41, §7.1)
```
Replace:
```dart
    required this.might,
    this.skillPower = 0,
    this.alterationPower = 0,
```
with:
```dart
    required this.might,
    this.mightTargets = const {MightTarget.attack},
```
Replace:
```dart
    int? might,
    int? skillPower,
    int? alterationPower,
```
with:
```dart
    int? might,
    Set<MightTarget>? mightTargets,
```
Replace:
```dart
      might: might ?? this.might,
      skillPower: skillPower ?? this.skillPower,
      alterationPower: alterationPower ?? this.alterationPower,
```
with:
```dart
      might: might ?? this.might,
      mightTargets: mightTargets ?? this.mightTargets,
```
Replace:
```dart
      might: json['might'] as int? ?? 0,
      skillPower: json['skillPower'] as int? ?? 0,
      alterationPower: json['alterationPower'] as int? ?? 0,
```
with:
```dart
      might: json['might'] as int? ?? 0,
      mightTargets: json['mightTargets'] == null
          ? const {MightTarget.attack}
          : MightTarget.parseAll(json['mightTargets']),
```
Replace:
```dart
    'might': might,
    'skillPower': skillPower,
    'alterationPower': alterationPower,
```
with:
```dart
    'might': might,
    'mightTargets': [
      for (final target in MightTarget.values)
        if (mightTargets.contains(target)) target.name,
    ],
```
Replace:
```dart
  /// Calcule l'attaque effective en prenant en compte les buffs de force
```
with:
```dart
  /// La Puissance permanente plus la Puissance temporaire que portent les
  /// statuts.
```

- [ ] **Step 4: `PowerRules` lit l'orientation**

Replace the whole content of `lib/game/systems/power_rules.dart` with:

```dart
import '../../models/data/card_data.dart';
import '../../models/entity_stats.dart';
import '../../models/might_target.dart';

/// Les règles d'attribution de la Puissance (spec P-41, §7.1) : ce qu'elle
/// renforce, selon la carte qui porte l'effet et selon l'orientation que la
/// classe a déclarée.
///
/// Règle pure, sans provider : la résolution d'une carte, ses runes, le
/// tutoriel (ADR-081) et l'aperçu des dégâts lisent la même. Elle vit ici et
/// non sur `EntityStats`, partagé avec les ennemis : le modèle ne porte que
/// l'orientation.
extension PowerRules on EntityStats {
  /// Bonus ajouté aux dégâts d'un effet `damage`, selon le type de la carte
  /// qui le porte. Une carte Pouvoir ou Statut ne reçoit rien, par
  /// construction.
  int damageBonusFor(CardType type) => switch (type) {
        CardType.attack => _mightFor(MightTarget.attack),
        CardType.skill => _mightFor(MightTarget.skill),
        CardType.power || CardType.status => 0,
      };

  /// Bonus ajouté à l'intensité d'un statut posé par une carte ou par l'une
  /// de ses runes. Il ne renforce qu'un statut posé sur un ennemi — jamais sa
  /// durée, et jamais un buff posé sur soi : sans cette borne, la Puissance
  /// temporaire se nourrirait d'elle-même.
  int statusBonusFor(CardTarget target) => switch (target) {
        CardTarget.singleEnemy ||
        CardTarget.allEnemies =>
          _mightFor(MightTarget.alteration),
        CardTarget.self || CardTarget.none => 0,
      };

  /// La Puissance effective, temporaire comprise, si la classe l'oriente vers
  /// [target] ; 0 sinon.
  int _mightFor(MightTarget target) =>
      mightTargets.contains(target) ? effectiveMight : 0;
}
```

- [ ] **Step 5: `StatGains` ne connaît plus que la Puissance**

In `lib/game/systems/stat_gains.dart`, replace:
```dart
enum GainResource { armor, mana, might, skillPower, alterationPower }
```
with:
```dart
enum GainResource { armor, mana, might }
```
Replace:
```dart
      GainResource.might => stats.copyWith(
          might: stats.might + gain.amount,
        ),
      GainResource.skillPower => stats.copyWith(
          skillPower: stats.skillPower + gain.amount,
        ),
      GainResource.alterationPower => stats.copyWith(
          alterationPower: stats.alterationPower + gain.amount,
        ),
```
with:
```dart
      GainResource.might => stats.copyWith(
          might: stats.might + gain.amount,
        ),
```

- [ ] **Step 6: Copier l'orientation de la classe**

In `lib/game/controllers/run_controller.dart`, replace:
```dart
        might: 0, // Puissance de base à 0
        luck: chosenClass.luck,
```
with:
```dart
        might: 0, // Puissance de base à 0
        mightTargets: chosenClass.mightTargets,
        luck: chosenClass.luck,
```
In `lib/tutorial/tutorial_engine.dart`, replace:
```dart
      might: 0,
      luck: hero.luck,
```
with:
```dart
      might: 0,
      mightTargets: hero.mightTargets,
      luck: hero.luck,
```

- [ ] **Step 7: Lancer le test pour le voir passer**

Run: `flutter test test/unit/might_orientation_test.dart`
Expected: PASS, `+14: All tests passed!`

- [ ] **Step 8: Les tests et le commentaire qui nommaient les puissances retirées**

In `test/unit/stat_gains_test.dart`, replace:
```dart
    test('puissances : chacune dans sa stat, et un gain negatif retire', () {
      final s = stats();
      expect(
        StatGains.apply(s, const StatGain(GainResource.might, 4, GainSource.progression)).might,
        2 + 4,
      );
      expect(
        StatGains.apply(s, const StatGain(GainResource.might, -2, GainSource.progression)).might,
        0,
      );
      expect(
        StatGains.apply(s, const StatGain(GainResource.skillPower, 3, GainSource.progression)).skillPower,
        3,
      );
      expect(
        StatGains.apply(s, const StatGain(GainResource.alterationPower, 5, GainSource.progression)).alterationPower,
        5,
      );
    });
```
with:
```dart
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
```
In `test/unit/stat_gain_single_passage_test.dart`, replace:
```dart
/// Aucune ligne de `lib/` n'ajoute à l'armure, au mana ou à une puissance par
```
with:
```dart
/// Aucune ligne de `lib/` n'ajoute à l'armure, au mana ou à la Puissance par
```
Replace:
```dart
  RegExp(r'\b(armure|currentMana|might|skillPower|alterationPower)\s*:\s*\(?\s*[\w.\[\]!?]*\b\1\b\s*\+'),
```
with:
```dart
  RegExp(r'\b(armure|currentMana|might)\s*:\s*\(?\s*[\w.\[\]!?]*\b\1\b\s*\+'),
```
Replace:
```dart
  RegExp(r'\b(armure|currentMana|might|skillPower|alterationPower)\s*:[^,;{}]*?\+\s*[\w.\[\]!?]*\b\1\b'),
```
with:
```dart
  RegExp(r'\b(armure|currentMana|might)\s*:[^,;{}]*?\+\s*[\w.\[\]!?]*\b\1\b'),
```
In `test/unit/save_service_test.dart`, replace:
```dart
      heroStats['attaque'] = heroStats.remove('might');
      heroStats.remove('skillPower');
      heroStats.remove('alterationPower');
```
with:
```dart
      heroStats['attaque'] = heroStats.remove('might');
      heroStats.remove('mightTargets');
```
In `test/tutorial/tutorial_engine_test.dart`, replace:
```dart
      expect(engine.mockState.heroStats.maxPv, 60);
      expect(engine.mockState.heroStats.maxMana, 3);
```
with:
```dart
      expect(engine.mockState.heroStats.maxPv, 60);
      expect(engine.mockState.heroStats.maxMana, 3);
      expect(engine.mockState.heroStats.mightTargets, mage.mightTargets);
```
In `lib/services/save_migrations.dart`, replace:
```dart
/// v1 → v2 (P-41, lot A) : `attaque` devient `attackPower`. `skillPower` et
/// `alterationPower` n'ont pas à être écrites : `EntityStats.fromJson` les lit
/// à 0 quand elles manquent. Aucun ennemi n'est sérialisé : `SaveService`
/// n'est jamais appelé en combat.
```
with:
```dart
/// v1 → v2 (P-41, lot A) : `attaque` devient `attackPower`. Depuis le lot B,
/// `EntityStats.fromJson` lit `might` et ignore `attackPower` : avant la
/// 1.0.0, la Puissance d'une ancienne partie est perdue, sans étape de
/// migration (spec P-41, §7.5). Aucun ennemi n'est sérialisé : `SaveService`
/// n'est jamais appelé en combat.
```

- [ ] **Step 9: Vérifier la disparition**

Run: `git grep -nw -e skillPower -e alterationPower -- lib test`
Expected: aucune sortie.

- [ ] **Step 10: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+936: All tests passed!` (931 − 9 tests retirés + 14 nouveaux)

- [ ] **Step 11: Commit**

```bash
git add -A lib test
git commit -F- <<'EOF'
feat(puissance): une seule Puissance, orientee par la classe

skillPower et alterationPower disparaissent. Les stats du heros portent
une copie de l orientation de sa classe, lue par PowerRules. Les trois
classes orientant vers attack, le jeu ne change pas.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 4: Le statut et les effets `strength` deviennent `might`

Renommage mécanique, sans test nouveau. `applyAttackBuff` n'a aucun appelant : il est supprimé plutôt que renommé.

**Files:**
- Modify: `lib/game/controllers/run_controller.dart:430-434` ; `lib/game/controllers/run/player_stats_manager.dart:438-455`
- Modify (script) : 30 fichiers de `lib/`, `test/` et `assets/data/` (liste à l'étape 2)

**Interfaces:**
- Consumes: Task 3.
- Produces: statuts `might` (la Puissance temporaire, nommée « Puissance ») et `might_regen` (« Éveil de Puissance ») ; `effectType` `gain_might`, `charge_might_turn`, `charge_might_combat` ; `EntityStats.effectiveMight` additionne les statuts `might`.

- [ ] **Step 1: Supprimer le code mort**

In `lib/game/controllers/run_controller.dart`, delete these lines, with the blank line that follows them:
```dart
  /// Applique un buff d'attaque pour une durée donnée
  void applyAttackBuff(int duration) {
    _playerStatsManager.applyAttackBuff(duration);
  }
```
In `lib/game/controllers/run/player_stats_manager.dart`, delete these lines, with the blank line that follows them:
```dart
  /// Applique un buff d'attaque pour une durée donnée
  void applyAttackBuff(int duration) {
    int bonus = (controller.currentState.heroStats.maxPv * 0.15).round();
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: controller.currentState.heroStats.addStatus(
          StatusEffect(
            id: 'strength',
            name: 'Attaque',
            type: StatusType.buff,
            value: bonus,
            duration: duration,
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 2: Lancer le renommage**

Depuis la racine du dépôt :

```bash
PYTHONUTF8=1 python - <<'EOF'
"""P-41 lot B, partie 1, Task 4 : le statut et les effets strength deviennent might.

Renommage mecanique, sans changement de comportement : identifiants de statut
et d'effet dans le code, les tests et les donnees, et noms des statuts crees
en code. Les paires sont appliquees dans l'ordre ; `strength_regen` passe
avant `strength`, dont il ne contient pas la forme entre guillemets."""
import io
import pathlib
import subprocess

APOSTROPHE = chr(92) + "'"

PAIRS = [
    ("'strength_regen'", "'might_regen'"),
    ("'strength'", "'might'"),
    ('"strength"', '"might"'),
    ("strengthGain", "mightGain"),
    ("'gain_strength'", "'gain_might'"),
    ('"gain_strength"', '"gain_might"'),
    ("'charge_strength_turn'", "'charge_might_turn'"),
    ('"charge_strength_turn"', '"charge_might_turn"'),
    ("'charge_strength_combat'", "'charge_might_combat'"),
    ('"charge_strength_combat"', '"charge_might_combat"'),
    ("name: 'Attaque',", "name: 'Puissance',"),
    ("name: 'Force (Relique)',", "name: 'Puissance (Relique)',"),
    ("name: 'Force',", "name: 'Puissance',"),
    ("name: 'Éveil d" + APOSTROPHE + "Attaque',", "name: 'Éveil de Puissance',"),
]

paths = subprocess.run(
    ["git", "grep", "-l", "-e", "strength", "-e", "Force (Relique)", "-e", "name: 'Attaque'",
     "-e", "name: 'Force'", "--", "lib", "test", "assets"],
    capture_output=True, text=True, check=True,
).stdout.split()

total = 0
changed = 0
for rel in sorted(paths):
    path = pathlib.Path(rel)
    text = io.open(path, encoding="utf-8", newline="").read()
    count = 0
    for old, new in PAIRS:
        count += text.count(old)
        text = text.replace(old, new)
    if count:
        io.open(path, "w", encoding="utf-8", newline="").write(text)
        total += count
        changed += 1
        print(f"{count:3} {rel}")
print("TOTAL", total, "remplacements dans", changed, "fichiers")
EOF
```

Expected: exactement cette sortie (mesurée le 2026-09-17) :
```
  1 assets/data/cards/demon_form.json
  1 assets/data/classes/berserker/cards/rage_form.json
  1 assets/data/events/blessed_fountain.json
  1 assets/data/events/mysterious_altar.json
  1 assets/data/relics/cursed_blade.json
  1 assets/data/relics/pen_nib.json
  1 assets/data/relics/shuriken.json
  1 assets/data/relics/whetstone.json
  2 lib/game/components/card_component.dart
  2 lib/game/components/entities/status_indicator.dart
  6 lib/game/components/widgets/card_text_renderer.dart
 14 lib/game/controllers/combat/status_effect_processor.dart
  2 lib/game/controllers/combat/turn_phase_manager.dart
  1 lib/game/controllers/event_controller.dart
 10 lib/game/controllers/run/player_stats_manager.dart
  6 lib/game/services/effect_resolver.dart
  1 lib/models/data/relic_data.dart
  1 lib/models/entity_stats.dart
  2 lib/ui/screens/event_screen.dart
  2 lib/ui/widgets/hud/status_effects_panel.dart
  2 lib/ui/widgets/ui_card/card_compact_description.dart
  4 lib/ui/widgets/ui_card/ui_card_helpers.dart
  2 test/unit/combat_controller_test.dart
  8 test/unit/effect_resolver_test.dart
  2 test/unit/event_controller_test.dart
  4 test/unit/might_orientation_test.dart
  3 test/unit/relic_exchange_test.dart
  1 test/widget/card_dictionary_screen_test.dart
  1 test/widget/debug_drawer_test.dart
  2 test/widget/status_effects_panel_overflow_test.dart
TOTAL 86 remplacements dans 30 fichiers
```
Si le total diffère, s'arrêter et comprendre avant d'aller plus loin.

- [ ] **Step 3: Vérifier la disparition**

Run: `git grep -n -e "'strength" -e '"strength' -e strengthGain -e gain_strength -e charge_strength -e applyAttackBuff -e "Force (Relique)" -- lib test assets`
Expected: aucune sortie.

- [ ] **Step 4: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+936: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add -u lib test assets
git commit -F- <<'EOF'
refactor(puissance): le statut strength devient might

Identifiants de statut et d effet renommes dans le code, les tests et
les donnees ; les noms des statuts crees en code disent Puissance.
applyAttackBuff, sans appelant, est supprime.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 5: La Puissance dans les textes du jeu

Textes de la spec §7.4. Seule logique nouvelle : les libellés abrégés des cibles, pour la fiche des stats.

**Files:**
- Create: `test/unit/might_targets_label_test.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, et les trois fichiers générés `lib/l10n/app_localizations*.dart` ; `lib/models/data/model_extensions.dart` ; `lib/ui/widgets/hud/status_effects_panel.dart` ; `lib/game/components/card_component.dart` ; `lib/game/components/widgets/card_text_renderer.dart` ; `lib/ui/widgets/ui_card/ui_card_helpers.dart` ; `lib/ui/screens/event_screen.dart` ; `lib/game/components/entities/enemy_card.dart` ; `lib/ui/widgets/map/dialogs/stats_dialog.dart` ; `lib/ui/widgets/map/hero_mini_stats_panel.dart` ; `lib/tutorial/tutorial_data.dart` ; `lib/tutorial/widgets/tutorial_elements_widget.dart` ; `lib/ui/widgets/relic_carousel/draft_card_reel.dart` ; commentaires de `lib/game/components/entities/stat_badge.dart`, `lib/ui/widgets/hud/player_health_bar.dart`, `lib/ui/widgets/debug/tabs/debug_combat_tab.dart`, `lib/ui/widgets/draft/draft_choice_card.dart` ; descriptions de 8 fichiers de `assets/data/`

**Interfaces:**
- Consumes: `EntityStats.mightTargets` (Task 3).
- Produces:
  - clés ARB `statusMight`, `statusMightRegen`, `cardDescStatusMight`, `cardDescStatusMightRegen`, `eventGainMight` (renommées), `mightTargetAttackShort`, `mightTargetSkillShort`, `mightTargetAlterationShort` (nouvelles) ; `enemyStatsDesc` prend un paramètre `might` au lieu d'`attack`.
  - `extension MightTargetsLabels on Set<MightTarget>` dans `lib/models/data/model_extensions.dart`, avec `String shortLabel(AppLocalizations l10n)` : les cibles abrégées dans l'ordre de `MightTarget`, jointes par ` · `.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/might_targets_label_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/model_extensions.dart';
import 'package:roguelike_card_game/models/might_target.dart';

/// Ce que renforce la Puissance, en abrégé (spec P-41, §7.4).
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('une cible', () {
    expect({MightTarget.attack}.shortLabel(fr), 'Attaques');
    expect({MightTarget.attack}.shortLabel(en), 'Attacks');
  });

  test('plusieurs cibles, dans l ordre de MightTarget quel que soit le Set', () {
    expect(
      {MightTarget.alteration, MightTarget.skill}.shortLabel(fr),
      'Compétences · Altérations',
    );
    expect(
      MightTarget.values.toSet().shortLabel(en),
      'Attacks · Skills · Alterations',
    );
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/might_targets_label_test.dart`
Expected: FAIL à la compilation — `The method 'shortLabel' isn't defined for the type 'Set<MightTarget>'`.

- [ ] **Step 3: Les ARB**

Les clés `tooltipAttackTitle` et `tooltipAttackDesc` gardent leur nom : elles servent la branche `StatType.attack` de `StatBadge`, que rien ne construit (spec §7.4).

In `lib/l10n/app_en.arb`, replace:
```json
  "tooltipAttackTitle": "Attack Damage Boost",
  "tooltipAttackDesc": "Increases the damage of your attack cards.",
```
with:
```json
  "tooltipAttackTitle": "Might",
  "tooltipAttackDesc": "Strengthens what your class channels it into: Attacks, Skills or alterations.",
  "mightTargetAttackShort": "Attacks",
  "mightTargetSkillShort": "Skills",
  "mightTargetAlterationShort": "Alterations",
```
Replace:
```json
  "intentBuff": "Buff Attack: +{value}",
```
with:
```json
  "intentBuff": "Buff Might: +{value}",
```
Replace:
```json
  "enemyStatsDesc": "Health: {hp}/{maxHp} HP.\nAttack: {attack}.\nArmor: {armor}.",
```
with:
```json
  "enemyStatsDesc": "Health: {hp}/{maxHp} HP.\nMight: {might}.\nArmor: {armor}.",
```
Replace:
```json
      "attack": { "type": "int" },
```
with:
```json
      "might": { "type": "int" },
```
Replace:
```json
  "cardDescStatusStrength": "Gains {amount} ATK for {duration} turns.",
  "@cardDescStatusStrength": {
```
with:
```json
  "cardDescStatusMight": "Gains {amount} Might for {duration} turns.",
  "@cardDescStatusMight": {
```
Replace:
```json
  "cardDescStatusStrengthRegen": "Gains {amount} Attack Awakening for {duration} turns.",
  "@cardDescStatusStrengthRegen": {
```
with:
```json
  "cardDescStatusMightRegen": "Gains {amount} Might Awakening for {duration} turns.",
  "@cardDescStatusMightRegen": {
```
Replace:
```json
  "draftChoiceSharpeningDesc": "+{amount} Attack",
```
with:
```json
  "draftChoiceSharpeningDesc": "+{amount} Might",
```
Replace:
```json
  "statusStrength": "Attack: +{value}",
  "@statusStrength": {
```
with:
```json
  "statusMight": "Might: +{value}",
  "@statusMight": {
```
Replace:
```json
  "statusStrengthRegen": "Attack Awakening: +{value}",
  "@statusStrengthRegen": {
```
with:
```json
  "statusMightRegen": "Might Awakening: +{value}",
  "@statusMightRegen": {
```
Replace:
```json
  "eventGainAttack": "+{amount} Attack",
  "@eventGainAttack": {
```
with:
```json
  "eventGainMight": "+{amount} Might",
  "@eventGainMight": {
```
In `lib/l10n/app_fr.arb`, replace:
```json
  "tooltipAttackTitle": "Boost d'Attaque (Force)",
  "tooltipAttackDesc": "Augmente les dégâts de vos cartes d'attaque.",
```
with:
```json
  "tooltipAttackTitle": "Puissance",
  "tooltipAttackDesc": "Renforce ce qu'oriente votre classe : Attaques, Compétences ou altérations.",
  "mightTargetAttackShort": "Attaques",
  "mightTargetSkillShort": "Compétences",
  "mightTargetAlterationShort": "Altérations",
```
Replace:
```json
  "intentBuff": "Buff Attaque : +{value}",
```
with:
```json
  "intentBuff": "Buff Puissance : +{value}",
```
Replace:
```json
  "enemyStatsDesc": "Santé : {hp}/{maxHp} PV.\nAttaque : {attack}.\nArmure : {armor}.",
```
with:
```json
  "enemyStatsDesc": "Santé : {hp}/{maxHp} PV.\nPuissance : {might}.\nArmure : {armor}.",
```
Replace:
```json
  "cardDescStatusStrength": "Gagne {amount} ATK pendant {duration} tours.",
```
with:
```json
  "cardDescStatusMight": "Gagne {amount} Puissance pendant {duration} tours.",
```
Replace:
```json
  "cardDescStatusStrengthRegen": "Gagne {amount} Éveil d'Attaque pendant {duration} tours.",
```
with:
```json
  "cardDescStatusMightRegen": "Gagne {amount} Éveil de Puissance pendant {duration} tours.",
```
Replace:
```json
  "draftChoiceSharpeningDesc": "+{amount} Attaque",
```
with:
```json
  "draftChoiceSharpeningDesc": "+{amount} Puissance",
```
Replace:
```json
  "statusStrength": "Attaque : +{value}",
```
with:
```json
  "statusMight": "Puissance : +{value}",
```
Replace:
```json
  "statusStrengthRegen": "Éveil d'Attaque : +{value}",
```
with:
```json
  "statusMightRegen": "Éveil de Puissance : +{value}",
```
Replace:
```json
  "eventGainAttack": "+{amount} Attaque",
```
with:
```json
  "eventGainMight": "+{amount} Puissance",
```

Run: `flutter gen-l10n`
Expected: aucune erreur ; `lib/l10n/app_localizations.dart`, `app_localizations_en.dart` et `app_localizations_fr.dart` sont modifiés.

- [ ] **Step 4: Les libellés abrégés des cibles**

In `lib/models/data/model_extensions.dart`, replace:
```dart
import '../enemy_intent.dart';
```
with:
```dart
import '../enemy_intent.dart';
import '../might_target.dart';
```
Replace:
```dart
      case IntentType.buff:
        return l10n.intentBuff(value);
    }
  }
}
```
with:
```dart
      case IntentType.buff:
        return l10n.intentBuff(value);
    }
  }
}

extension MightTargetsLabels on Set<MightTarget> {
  /// Ce que renforce la Puissance, en abrégé et dans l'ordre de [MightTarget],
  /// quel que soit l'ordre du `Set` : « Compétences · Altérations » (spec P-41,
  /// §7.4).
  String shortLabel(AppLocalizations l10n) => [
        for (final target in MightTarget.values)
          if (contains(target))
            switch (target) {
              MightTarget.attack => l10n.mightTargetAttackShort,
              MightTarget.skill => l10n.mightTargetSkillShort,
              MightTarget.alteration => l10n.mightTargetAlterationShort,
            },
      ].join(' · ');
}
```

- [ ] **Step 5: Lancer le test pour le voir passer**

Run: `flutter test test/unit/might_targets_label_test.dart`
Expected: PASS, `+2: All tests passed!`

- [ ] **Step 6: Les appels et les textes de repli**

In `lib/ui/widgets/hud/status_effects_panel.dart`, replace:
```dart
label = l10n.statusStrength(status.value);
```
with:
```dart
label = l10n.statusMight(status.value);
```
Replace:
```dart
label = l10n.statusStrengthRegen(status.value);
```
with:
```dart
label = l10n.statusMightRegen(status.value);
```
In `lib/game/components/card_component.dart`, replace:
```dart
l.cardDescStatusStrength(scaledValue, duration), fallback: 'Gagne $scaledValue ATK pendant $duration tours.')
```
with:
```dart
l.cardDescStatusMight(scaledValue, duration), fallback: 'Gagne $scaledValue Puissance pendant $duration tours.')
```
Replace:
```dart
l.cardDescStatusStrengthRegen(scaledValue, duration), fallback: 'Gagne $scaledValue Éveil d\'Attaque pendant $duration tours.')
```
with:
```dart
l.cardDescStatusMightRegen(scaledValue, duration), fallback: 'Gagne $scaledValue Éveil de Puissance pendant $duration tours.')
```
In `lib/game/components/widgets/card_text_renderer.dart`, replace:
```dart
l.cardDescStatusStrength(scaledValue, duration), fallback: "Gagne $scaledValue ATK pendant $duration tours.")
```
with:
```dart
l.cardDescStatusMight(scaledValue, duration), fallback: "Gagne $scaledValue Puissance pendant $duration tours.")
```
Replace:
```dart
l.cardDescStatusStrengthRegen(scaledValue, duration), fallback: "Gagne $scaledValue Éveil d'Attaque pendant $duration tours.")
```
with:
```dart
l.cardDescStatusMightRegen(scaledValue, duration), fallback: "Gagne $scaledValue Éveil de Puissance pendant $duration tours.")
```
In `lib/ui/widgets/ui_card/ui_card_helpers.dart`, replace:
```dart
l10n.cardDescStatusStrength(scaledValue, duration)
```
with:
```dart
l10n.cardDescStatusMight(scaledValue, duration)
```
Replace:
```dart
l10n.cardDescStatusStrengthRegen(scaledValue, duration)
```
with:
```dart
l10n.cardDescStatusMightRegen(scaledValue, duration)
```
In `lib/ui/screens/event_screen.dart`, replace:
```dart
        bgColor = Colors.orange.withValues(alpha: 0.12);
        text = l10n.eventGainAttack(action.value);
```
with:
```dart
        bgColor = Colors.orange.withValues(alpha: 0.12);
        text = l10n.eventGainMight(action.value);
```
Replace:
```dart
        bgColor = Colors.orange.withValues(alpha: 0.08);
        text = l10n.eventGainAttack(action.value);
```
with:
```dart
        bgColor = Colors.orange.withValues(alpha: 0.08);
        text = l10n.eventGainMight(action.value);
```
In `lib/game/components/entities/enemy_card.dart`, replace:
```dart
\nAttaque : ${stats.effectiveMight}.
```
with:
```dart
\nPuissance : ${stats.effectiveMight}.
```

- [ ] **Step 7: La fiche et le mini-panneau des stats**

In `lib/ui/widgets/map/dialogs/stats_dialog.dart`, replace:
```dart
import '../../../../game/controllers/run_controller.dart';
```
with:
```dart
import '../../../../game/controllers/run_controller.dart';
import '../../../../models/data/model_extensions.dart';
```
Replace:
```dart
                    title: locale == 'fr' ? 'Attaque' : 'Attack',
                    value: '${stats.might}',
                    subtitle: locale == 'fr' ? 'Dégâts de base' : 'Base damage',
```
with:
```dart
                    title: locale == 'fr' ? 'Puissance' : 'Might',
                    value: '${stats.might}',
                    subtitle: stats.mightTargets.shortLabel(l10n),
```
In `lib/ui/widgets/map/hero_mini_stats_panel.dart`, replace:
```dart
          // Attaque
          _buildMiniStatRowWidget(
            icon: SwordIcon(size: 16, color: Colors.orangeAccent),
            value: '${stats.might} ${locale == 'fr' ? 'Attaque' : 'Attack'}',
```
with:
```dart
          // Puissance
          _buildMiniStatRowWidget(
            icon: SwordIcon(size: 16, color: Colors.orangeAccent),
            value: '${stats.might} ${locale == 'fr' ? 'Puissance' : 'Might'}',
```

- [ ] **Step 8: Le tutoriel**

In `lib/tutorial/tutorial_data.dart`, replace:
```dart
        'The damage printed on a card is not the final number: your Hero\'s '
        'Attack stat is added on top, and rarity multiplies the base value.',
```
with:
```dart
        'The damage printed on a card is not the final number: your Hero\'s '
        'Might is added on top, depending on what their class strengthens, and '
        'rarity multiplies the base value.',
```
Replace:
```dart
        'Les dégâts imprimés sur une carte ne sont pas le chiffre final : '
        'l\'Attaque de votre héros s\'y ajoute, et la rareté multiplie la valeur '
        'de base.',
```
with:
```dart
        'Les dégâts imprimés sur une carte ne sont pas le chiffre final : '
        'la Puissance de votre héros s\'y ajoute, selon ce que renforce sa '
        'classe, et la rareté multiplie la valeur de base.',
```
Replace:
```dart
        'There are three: Attack, Defend, and Buff Attack. Attacks change icon '
```
with:
```dart
        'There are three: Attack, Defend, and Buff Might. Attacks change icon '
```
Replace:
```dart
        'accumulated Attack, and halves while they are Frozen.',
```
with:
```dart
        'accumulated Might, and halves while they are Frozen.',
```
Replace:
```dart
        'Il en existe trois : Attaque, Défense et Buff Attaque. Les attaques '
```
with:
```dart
        'Il en existe trois : Attaque, Défense et Buff Puissance. Les attaques '
```
Replace:
```dart
        'l\'ennemi et son Attaque accumulée, et se divise par deux tant qu\'il '
```
with:
```dart
        'l\'ennemi et sa Puissance accumulée, et se divise par deux tant qu\'il '
```
In `lib/tutorial/widgets/tutorial_elements_widget.dart`, replace:
```dart
      nameEn: 'Attack',
      nameFr: 'Attaque',
      descEn: 'Adds to every attack\'s damage',
      descFr: 'S\'ajoute aux dégâts de chaque attaque',
```
with:
```dart
      nameEn: 'Might',
      nameFr: 'Puissance',
      descEn: 'Adds to what your class strengthens',
      descFr: 'S\'ajoute à ce que renforce votre classe',
```
Replace:
```dart
      nameEn: 'Attack Awakening',
      nameFr: 'Éveil d\'Attaque',
      descEn: 'Grants Attack at the start of the turn',
      descFr: 'Donne de l\'Attaque au début du tour',
```
with:
```dart
      nameEn: 'Might Awakening',
      nameFr: 'Éveil de Puissance',
      descEn: 'Grants Might at the start of the turn',
      descFr: 'Donne de la Puissance au début du tour',
```

- [ ] **Step 9: Le carrousel des récompenses et les commentaires**

Le carrousel nommait encore *Forge d'Acier*, oubliée par P-49 : elle devient *Affinité* au passage (spec §7.4).

In `lib/ui/widgets/relic_carousel/draft_card_reel.dart`, replace:
```dart
    {'title': 'Aiguisage', 'description': '+4 Attaque'},
    {'title': 'Forge d\'Acier', 'description': '+2 gains d\'Armure'},
```
with:
```dart
    {'title': 'Aiguisage', 'description': '+4 Puissance'},
    {'title': 'Affinité', 'description': '+2 Maîtrise'},
```
In `lib/game/components/entities/stat_badge.dart`, replace:
```dart
      // 1. Dessine l'Attaque : Épée + Valeur
```
with:
```dart
      // 1. Dessine la Puissance : Épée + Valeur
```
In `lib/ui/widgets/hud/player_health_bar.dart`, replace:
```dart
                // Dégâts d'Attaque (Rouge Gradient, sans fond)
```
with:
```dart
                // Puissance (Rouge Gradient, sans fond)
```
In `lib/ui/widgets/debug/tabs/debug_combat_tab.dart`, replace:
```dart
/// maxima, attaque, chance, niveau.
```
with:
```dart
/// maxima, Puissance, chance, niveau.
```
In `lib/ui/widgets/draft/draft_choice_card.dart`, replace:
```dart
      emoji = '⚔️'; // Attack Power
```
with:
```dart
      emoji = '⚔️'; // Might
```

- [ ] **Step 10: Les descriptions des cartes, reliques et événements**

In `assets/data/cards/demon_form.json`, replace:
```json
"Gain 2 Strength for 4 turns."
```
with:
```json
"Gain 2 Might for 4 turns."
```
Replace:
```json
"Gagne 2 Force pendant 4 tours."
```
with:
```json
"Gagne 2 Puissance pendant 4 tours."
```
In `assets/data/classes/berserker/cards/rage_form.json`, replace:
```json
"Apply 2 Strength this turn. Draw 1 card."
```
with:
```json
"Apply 2 Might this turn. Draw 1 card."
```
Replace:
```json
"Applique 2 Force ce tour-ci. Pioche 1 carte."
```
with:
```json
"Applique 2 Puissance ce tour-ci. Pioche 1 carte."
```
In `assets/data/relics/whetstone.json`, replace:
```json
"+1 Strength permanently for the entire run."
```
with:
```json
"+1 Might permanently for the entire run."
```
Replace:
```json
"+1 Force de manière permanente pour toute la run."
```
with:
```json
"+1 Puissance de manière permanente pour toute la run."
```
In `assets/data/relics/cursed_blade.json`, replace:
```json
"+2 Strength permanently for the entire run."
```
with:
```json
"+2 Might permanently for the entire run."
```
Replace:
```json
"+2 Force de manière permanente pour toute la run."
```
with:
```json
"+2 Puissance de manière permanente pour toute la run."
```
In `assets/data/relics/pen_nib.json`, replace:
```json
gain 3 Strength for the current turn."
```
with:
```json
gain 3 Might for the current turn."
```
Replace:
```json
gagne 3 Force pour le tour en cours."
```
with:
```json
gagne 3 Puissance pour le tour en cours."
```
In `assets/data/relics/shuriken.json`, replace:
```json
gain 1 Strength for combat."
```
with:
```json
gain 1 Might for combat."
```
Replace:
```json
gagne 1 Force pour le combat."
```
with:
```json
gagne 1 Puissance pour le combat."
```
In `assets/data/events/blessed_fountain.json`, replace:
```json
(-12 Max HP, +1 Attack)"
```
with:
```json
(-12 Max HP, +1 Might)"
```
Replace:
```json
(-12 PV Max, +1 Attaque)"
```
with:
```json
(-12 PV Max, +1 Puissance)"
```
In `assets/data/events/mysterious_altar.json`, replace:
```json
(-15 HP, +1 Attack)"
```
with:
```json
(-15 HP, +1 Might)"
```
Replace:
```json
(-15 PV, +1 Attaque)"
```
with:
```json
(-15 PV, +1 Puissance)"
```

- [ ] **Step 11: Vérifier les textes**

Run: `git grep -nw -e Force -e Strength -e ATK -- lib assets ":!lib/l10n/app_localizations*"`
Expected: exactement ces quatre lignes — la branche jamais construite de `StatBadge`, et trois commentaires où *Force* est un verbe :
```
lib/game/components/entities/stat_badge.dart:184:        iconText = 'ATK';
lib/main.dart:28:    // Force l'activation de l'écoute d'autosave dès le démarrage de l'app.
lib/services/map/map_node_generator.dart:45:        // Force structure rules
lib/ui/screens/map_screen.dart:335:    // Force le re-centrage si on change d'acte ou si on n'a jamais centré
```
Run: `git grep -n -e statusStrength -e cardDescStatusStrength -e eventGainAttack -- lib ":!lib/l10n/app_localizations*"`
Expected: aucune sortie.

- [ ] **Step 12: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+938: All tests passed!`

- [ ] **Step 13: Commit**

```bash
git add -A lib test assets
git commit -F- <<'EOF'
feat(puissance): la Puissance dans les textes du jeu

Force, Attaque et ATK deviennent Puissance (Might) dans les ARB, les
cartes, les reliques, les evenements et le tutoriel. La fiche des stats
dit ce que renforce la Puissance. Au passage, le carrousel des
recompenses nomme Affinite a la place de Forge d Acier.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 6: Vérification finale et livraison

**Files:**
- Modify: `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md:4`
- Géré par skills : `.obsidian_vault/`, `docs/ROADMAP.md`, `assets/data/patch_notes.json`

**Interfaces:**
- Consumes: toute la partie 1.
- Produces: une branche prête à la PR.

- [ ] **Step 1: Vérifications propres au lot**

Aucun fichier de `lib/`, `test/` ni `assets/` n'a changé depuis la vérification complète de Task 5 Step 12 : ne relancer ni `dart analyze` ni la suite, reprendre le total qu'elle a affiché : `+938`.
Run: `git grep -nw -e attackPower -e effectiveAttackPower -e skillPower -e alterationPower -e attackAcc -e atkBoost -e playerAttaque -e applyAttackBuff -- lib test assets`
Expected: exactement ces cinq lignes, l'étape de migration v1 → v2 et son test :
```
lib/services/save_migrations.dart:67:/// v1 → v2 (P-41, lot A) : `attaque` devient `attackPower`. Depuis le lot B,
lib/services/save_migrations.dart:68:/// `EntityStats.fromJson` lit `might` et ignore `attackPower` : avant la
lib/services/save_migrations.dart:78:  heroStats['attackPower'] = heroStats.remove('attaque');
test/unit/save_migrations_test.dart:74:    test('v1 vers v2 : attaque devient attackPower', () {
test/unit/save_migrations_test.dart:86:      expect(heroStats['attackPower'], 7);
```

- [ ] **Step 2: Mettre à jour le statut de la spec**

In `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md`, replace:
```markdown
Statut : **Lot A implémenté** (fusionné dans `main`, PR #38) — lots B à D non implémentés, **lot B reconçu le 2026-09-17** (§0.3) ; chantier frère P-49 implémenté (fusionné dans `main`, PR #39), voir sa [spec](2026-09-16-p49-passifs-partages-design.md)
```
with:
```markdown
Statut : **Lot A implémenté** (fusionné dans `main`, PR #38) — **lot B, partie 1 implémentée** (branche `feat/p41-lot-b-puissance`) ; partie 2 et lots C, D non implémentés ; lot B reconçu le 2026-09-17 (§0.3) ; chantier frère P-49 implémenté (fusionné dans `main`, PR #39), voir sa [spec](2026-09-16-p49-passifs-partages-design.md)
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md
git commit -F- <<'EOF'
docs(P-41): partie 1 du lot B implementee

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

- [ ] **Step 4: Synchroniser la mémoire du projet**

Invoke the `memory-bank-sync` skill. Ce qu'il doit consigner :
- un ADR pour la **Puissance orientée par la classe** (décisions D9 et D10 de la spec) : une seule stat, `might`, dont la classe déclare les cibles, lue par `PowerRules` sur une copie portée par les stats ; il **amende [ADR-095](../../../.obsidian_vault/_adr/ADR-095-passage-unique-des-gains-scission-des-puissances-et.md)** sur sa scission en trois puissances, dont le statut pointe vers lui ;
- dans `docs/ROADMAP.md`, tableau des lots de P-41 : la partie 1 de **P-41 B** livrée ;
- les métriques de `progress.md`, que le skill re-mesure lui-même.

- [ ] **Step 5: Note de version — avec l'accord du propriétaire**

**Ne pas invoquer `patch-notes-writer` sans l'accord explicite du propriétaire**, qui décide aussi du numéro : la note `0.5.2` a déjà été rouverte en place pour P-49, et son tag attend P-42 (`docs/ROADMAP.md` §4). Contenu à proposer, en *Améliorations* : la Force et l'Attaque du héros deviennent la **Puissance**, un seul mot sur les cartes, les reliques, les événements et le tutoriel ; la fiche des stats dit ce que la Puissance renforce.

- [ ] **Step 6: Terminer la branche**

Invoke the `superpowers:finishing-a-development-branch` skill.

---

## Suites relevées, hors de la partie 1

1. **`StatBadge` porte trois branches que rien ne construit.** Il n'est instancié qu'en `StatType.hp` (`lib/game/components/entities/enemy_card.dart:123`) : ses branches `attack`, `armor` et `mana` sont du code mort, avec l'`iconText = 'ATK'` et les clés `tooltipAttackTitle` et `tooltipAttackDesc`. → Un nettoyage à part, hors de P-41.
2. **Cinq classes écrites sur disque par `test/widget/content_editor_screen_test.dart` n'ont pas de `mightTargets`** (`:85`, `:432`, `:827`, `:1032`, et la classe `gambler` de `:1375`). Aucun de ces tests ne les construit ; elles ne décrivent plus une classe valide. → À compléter si un test vient à les charger.
3. **La partie 2 du lot B** (spec §7.6) : orientations du Mage et du Paladin, conversion d'armure du Berserker, neuf passifs, stats de départ, icônes de la Puissance — son plan s'écrit une fois cette partie fusionnée, pour citer le code renommé.

