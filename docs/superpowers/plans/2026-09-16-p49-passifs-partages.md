# P-49 — Passifs partagés — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Faire déclarer au passif les classes qui peuvent le prendre, lire les passifs disponibles par un point d'accès unique, faire de `TraitSystem` un répartiteur de stratégies, et remplacer la Maîtrise d'Armure par une *Maîtrise* dont chaque passif déclare l'effet — sa récompense devenant *Affinité*.

**Architecture:** `PassiveData` gagne `classes` (liste ou `null` pour « toutes ») et un bloc `mastery` (`PassiveMastery` : paramètre visé, gain par point, texte bilingue à `{amount}`), avec une fonction pure `withMastery`. La fonction pure `availablePassivesFor` est le seul lecteur de `classes`. `TraitSystem.dispatch` vérifie le déclencheur, applique la Maîtrise au passif, puis appelle la stratégie de son `effectType`, tirée d'une table constante ; `StatGains` perd sa règle spéciale. L'éditeur de contenu apprend le type de champ `referenceList`.

**Tech Stack:** Flutter / Dart 3.11, Flame, Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-09-16-p49-passifs-partages-design.md` — à lire en entier ; la frontière avec P-41 est au §5 de `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md`.

## Global Constraints

- **Comportement de jeu inchangé, à une exception voulue près** (spec §6.4) : avec de la Maîtrise, *Armure du Berserker* donne `tranches × (1 + Maîtrise)` au lieu de `tranches × 1 + Maîtrise`. Changent aussi, voulus : les noms montrés au joueur (*Maîtrise*, *Affinité*) et l'affichage de l'effet de la Maîtrise.
- **Sauvegarde : aucune étape de migration, aucun test de compatibilité entre versions** (spec §9, décision N6). `SaveMigrator.currentVersion` reste à 2. Avant la `1.0.0`, une sauvegarde n'a pas à survivre à un changement de version.
- `dart analyze` doit afficher `No issues found!` à la fin de **chaque** tâche.
- `flutter test` doit être **entièrement** vert à la fin de chaque tâche. Point de départ mesuré le 2026-09-16 sur `main`, remesuré le 2026-09-17 sur `18cc738` : **876 tests**. Chaque tâche donne le total attendu, mesuré en rejouant le plan sur une copie du dépôt le 2026-09-17.
- **Ne jamais lancer `dart format`** : le dépôt ne l'utilise pas.
- Créer et modifier les fichiers avec les outils Write / Edit. **Jamais par heredoc bash** : les heredocs de cet environnement mangent les antislashs, et le code Dart du plan en contient (`'d\'Armure'`). Les scripts Python du plan n'en contiennent aucun et peuvent passer par heredoc.
- Tout texte joueur d'un JSON porte ses variantes `_fr` **et** `_en` (`CLAUDE.md`).
- Le tutoriel ne référence aucun provider d'état (ADR-081), vérifié par `test/tutorial/tutorial_isolation_test.dart`. Il peut importer une fonction pure de `lib/game/systems/`.
- Ne pas toucher `assets/data/patch_notes.json` ni le champ `version:` de `pubspec.yaml` : ils appartiennent au skill `patch-notes-writer`.
- Les fichiers `lib/l10n/app_localizations.dart`, `app_localizations_en.dart` et `app_localizations_fr.dart` sont générés **et commités** : après toute modification d'un ARB, lancer `flutter gen-l10n` et commiter les trois.
- Le code va sur la branche `feat/p49-passifs-partages`, jamais sur `main`. Seule la documentation de Task 0 est commitée sur `main`.
- Messages de commit en français, forme `type(portee): message`, **sans accents ni apostrophes**, terminés par la ligne `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- Les commandes `flutter` peuvent réécrire des fichiers générés sans en changer le contenu, fins de ligne seulement : `macos/Flutter/GeneratedPluginRegistrant.swift` et, dans un checkout neuf, ceux de `linux/flutter/` et de `windows/flutter/`. S'ils apparaissent dans `git status`, les restaurer (`git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`) ; ne jamais les commiter.
- Les greps qui vérifient la disparition d'un identifiant cherchent des **mots entiers** (`git grep -w`).

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/models/data/passive_data.dart` | `PassiveMastery`, `PassiveData.classes`, `.mastery`, `.withMastery` | 1 |
| `lib/game/systems/passive_availability.dart` *(nouveau)* | `availablePassivesFor`, le point d'accès unique | 2 |
| `assets/data/passives/*.json` | `classes` (2), puis `mastery` et descriptions (7) | 2, 7 |
| `lib/ui/screens/class_selection_screen.dart` | Lit le passif par le point d'accès ; ligne « Par point de Maîtrise » | 2, 8 |
| `lib/tutorial/tutorial_fixtures.dart` | Lit le passif par le point d'accès | 2 |
| `assets/data/classes/*/class.json`, `lib/models/data/hero_data.dart`, `lib/game/controllers/run_controller.dart` | Retrait de `passiveTrait` | 3 |
| `lib/services/content_editor/field_kind.dart`, `entity_descriptor.dart`, `entity_validator.dart`, `lib/ui/widgets/content_editor/document_form.dart`, `lib/ui/screens/content_editor_screen.dart` | `referenceList`, descripteurs de passif et de classe | 3, 4 |
| `lib/game/systems/passives/passive_strategy.dart` *(nouveau)* | `PassiveEvent`, `PassiveStrategy` | 5 |
| `lib/game/systems/passives/passive_strategies.dart` *(nouveau)* | Les trois stratégies, `PassiveStrategies.byEffectType` | 5 |
| `lib/game/systems/trait_system.dart` | `TraitSystem.dispatch` | 5, 7 |
| `lib/game/controllers/run_controller.dart`, `lib/game/controllers/combat_controller.dart`, `lib/ui/screens/game_screen.dart` | Appels de `dispatch`, `RunController.endTurn()` | 5 |
| `lib/models/entity_stats.dart`, `lib/game/controllers/run/player_stats_manager.dart`, `assets/data/relics/kunai.json` et 29 autres fichiers | Renommage `armorMastery` → `mastery` | 6 |
| `lib/game/systems/stat_gains.dart` | Retrait de la règle de Maîtrise | 7 |
| `lib/game/services/level_up_reward_service.dart`, `lib/ui/widgets/draft/draft_choice_labels.dart`, `draft_choice_card.dart`, `lib/ui/screens/draft_screen.dart`, `lib/tutorial/widgets/tutorial_draft_widget.dart` | *Affinité* | 8 |
| `lib/ui/widgets/map/dialogs/stats_dialog.dart`, `lib/l10n/*.arb`, `lib/tutorial/tutorial_data.dart` | Affichage de la Maîtrise, textes | 8 |

---

### Task 0: Documentation sur `main`, puis branche

**À faire dans le checkout principal, avant toute tâche de code** : la branche part du commit de documentation. **Pas de worktree** (décision du propriétaire) : la branche est créée dans le checkout principal, même si le skill d'exécution en propose un.

**Files:**
- Modify: `docs/INDEX.md:8`, `:50` ; `docs/ROADMAP.md:259`, `:403`

**Interfaces:**
- Consumes: ce plan et la spec, retouchée pendant sa rédaction, non commités.
- Produces: un commit de documentation sur `main`, puis la branche `feat/p49-passifs-partages` créée depuis lui.

- [ ] **Step 1: Vérifier l'état de départ**

Run: `git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift` (fins de ligne seulement), puis `git status --short`
Expected: exactement ces deux lignes, et rien d'autre :
```
 M docs/superpowers/specs/2026-09-16-p49-passifs-partages-design.md
?? docs/superpowers/plans/2026-09-16-p49-passifs-partages.md
```

- [ ] **Step 2: Relier le plan depuis l'index et la feuille de route**

Comme pour le plan du lot A de P-41, le plan est lié dans le même commit que lui.

In `docs/INDEX.md`, replace:
```markdown
| 📐 | [P-49 — Passifs partagés](superpowers/specs/2026-09-16-p49-passifs-partages-design.md) *(éligibilité déclarée par le passif, point d'accès unique, Maîtrise hybride)* | 16/09/2026 |
```
with:
```markdown
| 📐🔨 | [P-49 — Passifs partagés](superpowers/specs/2026-09-16-p49-passifs-partages-design.md) · [plan](superpowers/plans/2026-09-16-p49-passifs-partages.md) *(éligibilité déclarée par le passif, point d'accès unique, Maîtrise hybride)* | 16/09/2026 |
```
and replace `**Dernière mise à jour** : 2026-09-16` with the date of the day.

In `docs/ROADMAP.md`, replace:
```markdown
[spec](superpowers/specs/2026-09-16-p49-passifs-partages-design.md), écrite le 2026-09-16 | *à chiffrer au plan* |
```
with:
```markdown
[spec](superpowers/specs/2026-09-16-p49-passifs-partages-design.md), écrite le 2026-09-16 · [plan](superpowers/plans/2026-09-16-p49-passifs-partages.md), en neuf tâches | *non chiffré* |
```
and replace:
```markdown
[spec](superpowers/specs/2026-09-16-p49-passifs-partages-design.md), *plan à écrire* |
```
with:
```markdown
[spec](superpowers/specs/2026-09-16-p49-passifs-partages-design.md) · [plan](superpowers/plans/2026-09-16-p49-passifs-partages.md) |
```

- [ ] **Step 3: Commiter la documentation sur `main`**

```bash
git add docs/superpowers/specs/2026-09-16-p49-passifs-partages-design.md docs/superpowers/plans/2026-09-16-p49-passifs-partages.md docs/INDEX.md docs/ROADMAP.md
git commit -F- <<'EOF'
docs(P-49): plan d implementation, spec completee

La redaction du plan releve deux textes que la spec manquait : la
phrase du tutoriel sur la Maitrise a l etape Armure, et l icone de la
carte de draft choisie sur le titre Forge. Plan rejoue tache par tache
sur une copie du depot avant ce commit.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

- [ ] **Step 4: Créer la branche**

Run: `git switch -c feat/p49-passifs-partages` — depuis le commit du Step 3, dans le checkout principal.

- [ ] **Step 5: Mesurer la base**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+876: All tests passed!`

---

### Task 1: `PassiveData` — `classes`, `mastery`, `withMastery`

Modèle pur, sans lecteur encore : rien du jeu ne change.

**Files:**
- Modify: `lib/models/data/passive_data.dart` (réécrit en entier)
- Test: `test/unit/passive_data_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: rien.
- Produces:
  - `class PassiveMastery` — `static const List<String> fields = ['value']` ; champs `String field`, `int perPoint`, `String descriptionEn`, `String descriptionFr` ; `const PassiveMastery({required String field, required int perPoint, String descriptionEn = '', String descriptionFr = ''})` ; `String describe(String locale, int points)` ; `factory PassiveMastery.fromJson(Map<String, dynamic>)`, qui lève `FormatException`.
  - `PassiveData.classes` (`List<String>?`), `PassiveData.mastery` (`PassiveMastery?`), paramètres nommés optionnels `classes` et `mastery` du constructeur `const`.
  - `PassiveData withMastery(int points)`.
  - `PassiveData.fromJson` lève `FormatException` sur `"classes": []` et sur tout bloc `mastery` invalide.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/passive_data_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

/// Le modèle d'un passif partagé (spec P-49, §3).
void main() {
  Map<String, dynamic> passiveJson() => {
        'id': 'regen_armor',
        'name_en': 'Armor Regeneration',
        'name_fr': "Régénération d'Armure",
        'description_en': 'x',
        'description_fr': 'x',
        'trigger': 'endOfTurn',
        'effectType': 'gain_armor',
        'value': 2,
      };

  Map<String, dynamic> masteryJson() => {
        'field': 'value',
        'perPoint': 1,
        'description_en': '+{amount} Block at end of turn',
        'description_fr': '+{amount} Armure en fin de tour',
      };

  PassiveData regen() =>
      PassiveData.fromJson({...passiveJson(), 'mastery': masteryJson()});

  group('classes', () {
    test('absente : le passif est ouvert a toutes les classes', () {
      expect(PassiveData.fromJson(passiveJson()).classes, isNull);
    });

    test('une liste : les classes declarees', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'classes': ['paladin', 'mage'],
      });
      expect(passive.classes, ['paladin', 'mage']);
    });

    test('une liste vide est refusee', () {
      expect(
        () => PassiveData.fromJson({...passiveJson(), 'classes': <String>[]}),
        throwsFormatException,
      );
    });
  });

  group('mastery', () {
    test('absent : null', () {
      expect(PassiveData.fromJson(passiveJson()).mastery, isNull);
    });

    test('lu', () {
      final mastery = regen().mastery!;
      expect(mastery.field, 'value');
      expect(mastery.perPoint, 1);
      expect(mastery.descriptionEn, '+{amount} Block at end of turn');
      expect(mastery.descriptionFr, '+{amount} Armure en fin de tour');
    });

    test('un field inconnu est refuse', () {
      expect(
        () => PassiveData.fromJson({
          ...passiveJson(),
          'mastery': {...masteryJson(), 'field': 'duration'},
        }),
        throwsFormatException,
      );
    });

    test('un perPoint nul est refuse', () {
      expect(
        () => PassiveData.fromJson({
          ...passiveJson(),
          'mastery': {...masteryJson(), 'perPoint': 0},
        }),
        throwsFormatException,
      );
    });

    test('une description sans {amount} est refusee', () {
      for (final key in ['description_en', 'description_fr']) {
        expect(
          () => PassiveData.fromJson({
            ...passiveJson(),
            'mastery': {...masteryJson(), key: '+1 Armure'},
          }),
          throwsFormatException,
          reason: key,
        );
      }
    });

    test('une description absente est refusee', () {
      final mastery = masteryJson()..remove('description_en');
      expect(
        () => PassiveData.fromJson({...passiveJson(), 'mastery': mastery}),
        throwsFormatException,
      );
    });
  });

  group('withMastery', () {
    test('augmente le parametre designe', () {
      expect(regen().withMastery(3).value, 2 + 3);
    });

    test('un perPoint negatif fait baisser le parametre', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'mastery': {...masteryJson(), 'perPoint': -1},
      });
      expect(passive.withMastery(1).value, 2 - 1);
    });

    test('a 0 point : le passif tel quel', () {
      final passive = regen();
      expect(identical(passive.withMastery(0), passive), isTrue);
    });

    test('sans mastery : le passif tel quel', () {
      final passive = PassiveData.fromJson(passiveJson());
      expect(identical(passive.withMastery(5), passive), isTrue);
    });

    test('le reste du passif est conserve', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'classes': ['paladin'],
        'mastery': masteryJson(),
      }).withMastery(2);
      expect(passive.id, 'regen_armor');
      expect(passive.nameFr, "Régénération d'Armure");
      expect(passive.trigger, RelicTrigger.endOfTurn);
      expect(passive.effectType, 'gain_armor');
      expect(passive.classes, ['paladin']);
      expect(passive.mastery!.perPoint, 1);
    });
  });

  group('PassiveMastery.describe', () {
    test('{amount} vaut perPoint fois les points', () {
      expect(regen().mastery!.describe('fr', 3), '+3 Armure en fin de tour');
      expect(regen().mastery!.describe('en', 1), '+1 Block at end of turn');
    });

    test('le signe est porte par le texte, pas par {amount}', () {
      final mastery = PassiveMastery.fromJson({
        ...masteryJson(),
        'perPoint': -2,
        'description_fr': 'Seuil -{amount}',
      });
      expect(mastery.describe('fr', 2), 'Seuil -4');
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/passive_data_test.dart`
Expected: FAIL à la compilation — `PassiveMastery` n'existe pas, `classes`, `mastery` et `withMastery` non plus.

- [ ] **Step 3: Écrire l'implémentation**

Replace the whole content of `lib/models/data/passive_data.dart` with:

```dart
import 'relic_data.dart';
import 'package:flutter/foundation.dart';
import 'game_data_registry.dart';

/// Ce qu'un point de Maîtrise apporte à un passif (spec P-49, §3.3).
///
/// La Maîtrise est une stat unique ; c'est le passif qui déclare le paramètre
/// qu'elle augmente, et de combien par point.
@immutable
class PassiveMastery {
  /// Les paramètres qu'un point de Maîtrise peut augmenter. Le lot B de P-41
  /// en ajoute un par paramètre qu'il crée sur [PassiveData] ; l'éditeur de
  /// contenu lit cette liste.
  static const List<String> fields = ['value'];

  /// Le paramètre augmenté, parmi [fields].
  final String field;

  /// Ce qu'un point ajoute au paramètre. Jamais nul ; négatif pour un
  /// paramètre qui baisse avec la Maîtrise, comme un seuil.
  final int perPoint;

  /// L'effet, avec `{amount}` à la place de la valeur.
  final String descriptionEn;
  final String descriptionFr;

  const PassiveMastery({
    required this.field,
    required this.perPoint,
    this.descriptionEn = '',
    this.descriptionFr = '',
  });

  /// L'effet de [points] de Maîtrise : `{amount}` y devient
  /// `|perPoint × points|`, le texte portant le sens (spec P-49, §6.5).
  String describe(String locale, int points) =>
      (locale == 'fr' ? descriptionFr : descriptionEn)
          .replaceAll('{amount}', (perPoint * points).abs().toString());

  factory PassiveMastery.fromJson(Map<String, dynamic> json) {
    final field = json['field'] as String;
    if (!fields.contains(field)) {
      throw FormatException(
        'mastery.field "$field" inconnu — attendu : ${fields.join(', ')}',
      );
    }
    final perPoint = json['perPoint'] as int;
    if (perPoint == 0) {
      throw const FormatException('mastery.perPoint ne peut pas valoir 0');
    }
    final descriptionEn = json['description_en'] as String? ?? '';
    final descriptionFr = json['description_fr'] as String? ?? '';
    for (final (key, text) in [
      ('description_en', descriptionEn),
      ('description_fr', descriptionFr),
    ]) {
      if (!text.contains('{amount}')) {
        throw FormatException('mastery.$key doit contenir {amount}');
      }
    }
    return PassiveMastery(
      field: field,
      perPoint: perPoint,
      descriptionEn: descriptionEn,
      descriptionFr: descriptionFr,
    );
  }
}

class PassiveData {
  final String id;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final RelicTrigger trigger;
  final String effectType; // ex: 'gain_armor', 'berserker_armor', 'spell_armor'
  final int value;

  /// Les classes qui peuvent prendre ce passif ; `null` : toutes
  /// (spec P-49, §3.2). Seul le point d'accès unique la lit (spec P-49, §4).
  final List<String>? classes;

  /// Ce qu'un point de Maîtrise apporte à ce passif ; `null` : rien.
  final PassiveMastery? mastery;

  const PassiveData({
    required this.id,
    this.nameEn = '',
    this.nameFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    required this.trigger,
    required this.effectType,
    required this.value,
    this.classes,
    this.mastery,
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;
  String getDescription(String locale) =>
      locale == 'fr' ? descriptionFr : descriptionEn;

  /// Ce passif avec [points] de Maîtrise appliqués au paramètre que désigne
  /// [mastery] (spec P-49, §6.2). Rendu tel quel sans [mastery] ou à 0 point.
  /// Borner le résultat est l'affaire de la stratégie qui le lit.
  PassiveData withMastery(int points) {
    final m = mastery;
    if (m == null || points == 0) return this;
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

  factory PassiveData.fromJson(Map<String, dynamic> json) {
    final nEn = json['name_en'] as String? ?? json['name'] as String? ?? '';
    final nFr = json['name_fr'] as String? ?? json['name'] as String? ?? '';
    final dEn =
        json['description_en'] as String? ??
        json['description'] as String? ??
        '';
    final dFr =
        json['description_fr'] as String? ??
        json['description'] as String? ??
        '';

    final classesJson = json['classes'] as List<dynamic>?;
    if (classesJson != null && classesJson.isEmpty) {
      throw const FormatException(
        'classes ne peut pas être vide : omettre la clé ouvre le passif à '
        'toutes les classes',
      );
    }
    final masteryJson = json['mastery'] as Map<String, dynamic>?;

    return PassiveData(
      id: json['id'] as String,
      nameEn: nEn,
      nameFr: nFr,
      descriptionEn: dEn,
      descriptionFr: dFr,
      trigger: RelicTrigger.values.firstWhere((e) => e.name == json['trigger']),
      effectType: json['effectType'] as String,
      value: json['value'] as int,
      classes: classesJson?.map((e) => e as String).toList(),
      mastery:
          masteryJson == null ? null : PassiveMastery.fromJson(masteryJson),
    );
  }

  static PassiveData? getById(String id) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return null;
    try {
      return registry.passives.firstWhere((p) => p.id == id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PassiveData.getById: no passive found for id "$id" ($e)');
      }
      return null;
    }
  }
}
```

- [ ] **Step 4: Lancer le test pour le voir passer**

Run: `flutter test test/unit/passive_data_test.dart`
Expected: PASS, `+16: All tests passed!`

- [ ] **Step 5: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+892: All tests passed!` (876 + 16).

- [ ] **Step 6: Commit**

```bash
git add lib/models/data/passive_data.dart test/unit/passive_data_test.dart
git commit -F- <<'EOF'
feat(passifs): classes et maitrise declarees par le passif

PassiveData lit les classes qui peuvent le prendre et ce qu un point
de Maitrise lui apporte ; withMastery applique la Maitrise au
parametre declare. Aucun lecteur encore.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 2: Le point d'accès unique et ses deux lecteurs

**Files:**
- Create: `lib/game/systems/passive_availability.dart`
- Modify: `assets/data/passives/regen_armor.json`, `berserker_armor.json`, `spell_armor.json`
- Modify: `lib/ui/screens/class_selection_screen.dart:1-13`, `:154-156`
- Modify: `lib/tutorial/tutorial_fixtures.dart:1-6`, `:53-54`
- Test: `test/unit/passive_availability_test.dart` *(nouveau)*
- Test: `test/unit/referential_integrity_test.dart`, `test/tutorial/tutorial_fixtures_test.dart:28-32`, `test/widget/class_selection_screen_test.dart`

**Interfaces:**
- Consumes: `PassiveData.classes` (Task 1).
- Produces: `List<PassiveData> availablePassivesFor(HeroData hero, GameDataRegistry registry)` dans `lib/game/systems/passive_availability.dart` — passifs dont `classes` est `null` ou contient `hero.id`, triés par `id`.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/passive_availability_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

/// Le point d'accès unique aux passifs d'une classe (spec P-49, §4).
void main() {
  const paladin = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
  );
  const mage = HeroData(
    id: 'mage',
    classCard: 'mage.png',
    maxHp: 60,
    maxMana: 3,
    baseDamage: 10,
  );

  PassiveData passive(String id, {List<String>? classes}) => PassiveData(
        id: id,
        trigger: RelicTrigger.startOfTurn,
        effectType: 'gain_armor',
        value: 1,
        classes: classes,
      );

  GameDataRegistry registryOf(List<PassiveData> passives) => GameDataRegistry(
        enemies: const [],
        heroes: const [paladin, mage],
        cards: const [],
        events: const [],
        passives: passives,
        relics: const [],
        forgeUpgrades: const [],
      );

  List<String> idsFor(HeroData hero, GameDataRegistry registry) =>
      availablePassivesFor(hero, registry).map((p) => p.id).toList();

  test('un passif qui declare une classe n est disponible que pour elle', () {
    final registry = registryOf([passive('ward', classes: ['paladin'])]);
    expect(idsFor(paladin, registry), ['ward']);
    expect(idsFor(mage, registry), isEmpty);
  });

  test('un passif sans classes est disponible pour toutes', () {
    final registry = registryOf([passive('aegis')]);
    expect(idsFor(paladin, registry), ['aegis']);
    expect(idsFor(mage, registry), ['aegis']);
  });

  test('un passif partage entre deux classes l est pour les deux', () {
    final registry = registryOf([
      passive('bond', classes: ['paladin', 'mage']),
    ]);
    expect(idsFor(paladin, registry), ['bond']);
    expect(idsFor(mage, registry), ['bond']);
  });

  test('tries par id, pas par ordre de lecture', () {
    final registry = registryOf([
      passive('zeal'),
      passive('aegis'),
      passive('mind', classes: ['paladin']),
    ]);
    expect(idsFor(paladin, registry), ['aegis', 'mind', 'zeal']);
  });

  test('le catalogue du registre n est pas reordonne', () {
    final registry = registryOf([passive('zeal'), passive('aegis')]);
    availablePassivesFor(paladin, registry);
    expect(registry.passives.map((p) => p.id), ['zeal', 'aegis']);
  });
}
```

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/passive_availability_test.dart`
Expected: FAIL à la compilation — `passive_availability.dart` n'existe pas.

- [ ] **Step 3: Écrire le point d'accès**

Create `lib/game/systems/passive_availability.dart`:

```dart
import '../../models/data/game_data_registry.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/passive_data.dart';

/// Le point d'accès unique aux passifs qu'une classe peut prendre
/// (spec P-49, §4).
///
/// Tout lecteur qui choisit un passif passe par ici : l'écran de sélection,
/// le tutoriel, et demain l'éligibilité des récompenses. Aucun ne lit
/// `PassiveData.classes` lui-même : le jour où la méta-progression (P-13)
/// filtrera les passifs débloqués, elle le fera dans cette fonction, sans
/// toucher à ses lecteurs. D'ici là, « débloqué » vaut « tous ».
///
/// Triés par `id`, pour ne pas dépendre de l'ordre de lecture des fichiers.
/// Fonction pure, sans provider : le tutoriel l'appelle comme le jeu (ADR-081).
List<PassiveData> availablePassivesFor(
  HeroData hero,
  GameDataRegistry registry,
) {
  return registry.passives
      .where((passive) => passive.classes?.contains(hero.id) ?? true)
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));
}
```

- [ ] **Step 4: Lancer le test pour le voir passer**

Run: `flutter test test/unit/passive_availability_test.dart`
Expected: PASS, `+5: All tests passed!`

- [ ] **Step 5: Déclarer les classes dans les trois passifs**

In `assets/data/passives/regen_armor.json`, replace:
```json
  "trigger": "endOfTurn",
```
with:
```json
  "classes": ["paladin"],
  "trigger": "endOfTurn",
```

In `assets/data/passives/berserker_armor.json`, replace:
```json
  "trigger": "startOfTurn",
```
with:
```json
  "classes": ["berserker"],
  "trigger": "startOfTurn",
```

In `assets/data/passives/spell_armor.json`, replace:
```json
  "trigger": "onCardPlayed",
```
with:
```json
  "classes": ["mage"],
  "trigger": "onCardPlayed",
```

- [ ] **Step 6: Les garde-fous d'intégrité**

In `test/unit/referential_integrity_test.dart`, add the import after `import 'package:flutter_test/flutter_test.dart';`:
```dart
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
```

Then insert these two tests immediately before `  test('tout passiveTrait designe un passif existant', () {`:

```dart
  test('toute classe declaree par un passif existe', () {
    final known = registry.heroes.map((h) => h.id).toSet();
    final offenders = <String>[];

    for (final passive in registry.passives) {
      for (final heroId in passive.classes ?? const <String>[]) {
        if (!known.contains(heroId)) {
          offenders.add('${passive.id} → classe "$heroId" introuvable');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // Une classe sans passif disponible démarrerait sa run sans passif : le jeu
  // le permet (`passive_absent_test`), mais aucune classe livrée n'est dans ce
  // cas (spec P-49, §4.2).
  test('chaque classe a au moins un passif disponible', () {
    final offenders = [
      for (final hero in registry.heroes)
        if (availablePassivesFor(hero, registry).isEmpty) hero.id,
    ];

    expect(
      offenders,
      isEmpty,
      reason: 'classes sans passif : ${offenders.join(', ')}',
    );
  });

```

Run: `flutter test test/unit/referential_integrity_test.dart`
Expected: PASS, `+7: All tests passed!` (5 + 2 nouveaux).

- [ ] **Step 7: Brancher l'écran de sélection**

In `lib/ui/screens/class_selection_screen.dart`, add the import after `import 'package:roguelike_card_game/l10n/app_localizations.dart';`:
```dart
import '../../game/systems/passive_availability.dart';
```

Replace:
```dart
    final matchingPassives =
        gameData.passives.where((p) => p.id == playerClass.passiveTrait);
    final passive = matchingPassives.isEmpty ? null : matchingPassives.first;
```
with:
```dart
    // Le premier passif que le point d'accès unique ouvre à la classe : le
    // choix entre plusieurs passifs revient au lot C de P-41.
    final passives = availablePassivesFor(playerClass, gameData);
    final passive = passives.isEmpty ? null : passives.first;
```

- [ ] **Step 8: Tester l'écran de sélection**

In `test/widget/class_selection_screen_test.dart`, add the imports after `import 'package:roguelike_card_game/models/data/game_data_registry.dart';`:
```dart
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
```

Replace:
```dart
GameDataRegistry _registryOf(List<HeroData> heroes) => GameDataRegistry(
  enemies: const [],
  heroes: heroes,
  cards: const [],
  events: const [],
  passives: const [],
  relics: const [],
  forgeUpgrades: const [],
);
```
with:
```dart
GameDataRegistry _registryOf(
  List<HeroData> heroes, {
  List<PassiveData> passives = const [],
}) => GameDataRegistry(
  enemies: const [],
  heroes: heroes,
  cards: const [],
  events: const [],
  passives: passives,
  relics: const [],
  forgeUpgrades: const [],
);
```

Replace:
```dart
  List<HeroData> heroes = _heroes,
}) async {
```
with:
```dart
  List<HeroData> heroes = _heroes,
  List<PassiveData> passives = const [],
}) async {
```

Replace:
```dart
      gameDataLoaderProvider.overrideWith((ref) => _registryOf(heroes)),
```
with:
```dart
      gameDataLoaderProvider.overrideWith(
        (ref) => _registryOf(heroes, passives: passives),
      ),
```

Then add this group at the end of `main()`, just before its closing `}`:

```dart
  group('le passif montre est lu par le point d acces unique', () {
    const ward = PassiveData(
      id: 'ward',
      nameEn: 'Ward',
      nameFr: 'Garde',
      classes: ['paladin'],
      trigger: RelicTrigger.endOfTurn,
      effectType: 'gain_armor',
      value: 2,
    );
    const aegis = PassiveData(
      id: 'aegis',
      nameEn: 'Aegis',
      nameFr: 'Egide',
      trigger: RelicTrigger.endOfTurn,
      effectType: 'gain_armor',
      value: 1,
    );

    testWidgets('seule la classe que le passif declare le montre', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(tester, passives: const [ward]);
      expect(find.text('WARD'), findsOneWidget);
    });

    testWidgets(
      'un passif ouvert a toutes les classes, premier par id, est montre partout',
      (WidgetTester tester) async {
        await _buildAndReady(tester, passives: const [ward, aegis]);
        expect(find.text('AEGIS'), findsNWidgets(3));
        expect(find.text('WARD'), findsNothing);
      },
    );
  });
```

Run: `flutter test test/widget/class_selection_screen_test.dart`
Expected: PASS, `+8: All tests passed!` (6 + 2 nouveaux).

- [ ] **Step 9: Brancher le tutoriel**

In `lib/tutorial/tutorial_fixtures.dart`, add the import before `import '../models/data/card_data.dart';`:
```dart
import '../game/systems/passive_availability.dart';
```

Replace:
```dart
  PassiveData passiveFor(HeroData hero) =>
      registry.passives.firstWhere((p) => p.id == hero.passiveTrait);
```
with:
```dart
  /// Le passif de la classe au tutoriel : le premier que lui ouvre le point
  /// d'accès unique, comme à l'écran de sélection (spec P-49, §4.2).
  PassiveData passiveFor(HeroData hero) =>
      availablePassivesFor(hero, registry).first;
```

In `test/tutorial/tutorial_fixtures_test.dart`, replace:
```dart
    test('chaque classe a un passif résoluble', () {
      for (final hero in fixtures.heroes) {
        expect(fixtures.passiveFor(hero).id, hero.passiveTrait);
      }
    });
```
with:
```dart
    test('chaque classe a pour passif le premier que lui ouvre le point d acces', () {
      const attendus = {
        'paladin': 'regen_armor',
        'berserker': 'berserker_armor',
        'mage': 'spell_armor',
      };
      for (final hero in fixtures.heroes) {
        expect(fixtures.passiveFor(hero).id, attendus[hero.id]);
      }
    });
```

- [ ] **Step 10: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+901: All tests passed!` (892 + 5 + 2 + 2), `tutorial_isolation_test.dart` compris.
Run: `git grep -n "passiveTrait" -- lib/ui/screens/class_selection_screen.dart lib/tutorial` — Expected: aucune sortie.

- [ ] **Step 11: Commit**

```bash
git add lib/game/systems/passive_availability.dart assets/data/passives lib/ui/screens/class_selection_screen.dart lib/tutorial/tutorial_fixtures.dart test/unit/passive_availability_test.dart test/unit/referential_integrity_test.dart test/tutorial/tutorial_fixtures_test.dart test/widget/class_selection_screen_test.dart
git commit -F- <<'EOF'
feat(passifs): point d acces unique aux passifs d une classe

Chaque passif declare sa classe. La selection et le tutoriel lisent
le premier passif disponible par availablePassivesFor, que la
meta-progression filtrera sans toucher a ses lecteurs.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 3: Retirer `passiveTrait`

Le lien part désormais du passif (Task 2) : `passiveTrait` n'a plus aucun lecteur de jeu. Les tests de l'éditeur qui s'en servaient comme exemple de référence unique passent à un descripteur de test — le mécanisme reste, aucun descripteur livré ne l'emploie plus.

**Files:**
- Modify: `assets/data/classes/berserker/class.json`, `mage/class.json`, `paladin/class.json` (ligne 13)
- Modify: `lib/models/data/hero_data.dart:25`, `:46`, `:81`
- Modify: `lib/game/controllers/run_controller.dart:28`, `:65`, `:83`, `:103`, `:125`, `:181`, `:212`, `:244`
- Modify: `lib/services/content_editor/entity_descriptor.dart:98-99`, `:329`
- Modify: `lib/services/content_editor/entity_validator.dart:313-316` (commentaire)
- Modify: `lib/ui/screens/content_editor_screen.dart:489` (commentaire)
- Modify: 24 fichiers de `test/` (script), plus `test/unit/run_state_persistence_test.dart`, `test/unit/passive_absent_test.dart`, `test/unit/referential_integrity_test.dart`, `test/unit/run_controller_test.dart`, `test/unit/content_editor/field_kind_test.dart`, `entity_descriptor_test.dart`, `entity_validator_test.dart`, `test/widget/content_editor/document_form_test.dart`, `reference_panel_test.dart`, `test/widget/content_editor_screen_test.dart`

**Interfaces:**
- Consumes: `availablePassivesFor` (Task 2), seul lecteur restant du lien classe → passif.
- Produces: `HeroData` et `RunState` sans `passiveTrait` ; le blob de run ne porte plus la clé `passiveTrait`.

- [ ] **Step 1: Retirer le champ des données et des modèles**

In each of `assets/data/classes/berserker/class.json`, `assets/data/classes/mage/class.json` and `assets/data/classes/paladin/class.json`, delete the line `  "passiveTrait": "<id>",` (ligne 13). Vérifier : `git grep -n passiveTrait -- assets` — aucune sortie.

In `lib/models/data/hero_data.dart`, delete these three lines:
```dart
  final String? passiveTrait;
```
```dart
    this.passiveTrait,
```
```dart
      passiveTrait: json['passiveTrait'] as String?,
```

In `lib/game/controllers/run_controller.dart`, delete these lines:
```dart
  final String? passiveTrait; // Trait passif du héros (ex: regen_armor)
```
```dart
    this.passiveTrait,
```
```dart
    String? passiveTrait,
```
```dart
      passiveTrait: passiveTrait ?? this.passiveTrait,
```
```dart
        'passiveTrait': passiveTrait,
```
```dart
      passiveTrait: json['passiveTrait'] as String?,
```
```dart
      passiveTrait: 'regen_armor',
```
```dart
      passiveTrait: chosenClass.passiveTrait,
```

- [ ] **Step 2: L'éditeur de contenu**

In `lib/services/content_editor/entity_descriptor.dart`, replace:
```dart
  /// Cle -> categorie que sa valeur doit designer. `passiveTrait` pointe un
  /// passif, et `referential_integrity_test` le verifie deja.
  final Map<String, EntityCategory> referenceKeys;
```
with:
```dart
  /// Cle -> categorie que sa valeur doit designer. Aucun descripteur livre
  /// n'en declare depuis que la classe ne nomme plus son passif (spec P-49,
  /// §3.4) : le mecanisme reste, verifie sur un descripteur de test.
  final Map<String, EntityCategory> referenceKeys;
```

In the same file, delete the line:
```dart
    referenceKeys: const {'passiveTrait': EntityCategory.passive},
```

In `lib/services/content_editor/entity_validator.dart`, replace:
```dart
  /// Famille 6 — les references vers une autre categorie.
  ///
  /// `passiveTrait` doit designer un passif existant : `referential_integrity_test`
  /// le verifie deja, et une reference pendante ferait rougir la suite bien
  /// apres l'ecriture.
```
with:
```dart
  /// Famille 6 — les references vers une autre categorie.
  ///
  /// Une reference doit designer une entite existante : une reference
  /// pendante ferait rougir `referential_integrity_test` bien apres
  /// l'ecriture.
```

In `lib/ui/screens/content_editor_screen.dart`, replace:
```dart
  /// cible** : toute cle que le gabarit ne porte pas — le `skills` d'une
  /// classe, son `passiveTrait`, les `effects` d'une carte, les `intents` d'un
```
with:
```dart
  /// cible** : toute cle que le gabarit ne porte pas — le `skills` d'une
  /// classe, les `classes` d'un passif, les `effects` d'une carte, les `intents` d'un
```

- [ ] **Step 3: Retirer `passiveTrait:` des constructeurs de test**

Run this script from the repository root:

```bash
python - <<'EOF'
import subprocess

files = subprocess.run(
    ["git", "grep", "-l", "passiveTrait: '", "--", "test"],
    capture_output=True, text=True, check=True,
).stdout.split()
for path in files:
    with open(path, encoding="utf-8", newline="") as f:
        lines = f.readlines()
    kept = [
        line for line in lines
        if not (line.strip().startswith("passiveTrait: '") and line.strip().endswith("',"))
    ]
    if len(kept) != len(lines):
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.writelines(kept)
        print(path, len(lines) - len(kept))
EOF
```

Expected: 24 fichiers listés, 36 lignes retirées en tout.

- [ ] **Step 4: Les usages de test restants**

In `test/unit/run_state_persistence_test.dart`, delete the two lines:
```dart
      expect(restored.passiveTrait, 'regen_armor');
```
```dart
      json['passiveTrait'] = 'removed_passive';
```

In `test/unit/passive_absent_test.dart`, replace:
```dart
    // Un héros dont le passiveTrait ne désigne aucun passif chargé.
```
with:
```dart
    // Un héros démarré sans passif actif.
```

In `test/unit/referential_integrity_test.dart`, delete the whole test, and the blank line that follows it:
```dart
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
```
In the same file, replace `  // Garde de tete de fichier : sans elle, les quatre tests suivants` with `  // Garde de tete de fichier : sans elle, les tests suivants`.

In `test/unit/content_editor/field_kind_test.dart`, replace:
```dart
  final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
```
with:
```dart
  final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
  // Aucun descripteur livre ne declare de reference unique depuis que la
  // classe ne nomme plus son passif (spec P-49, §3.4) : le mecanisme se
  // verifie sur un descripteur de test.
  final mentor = EntityDescriptor(
    category: EntityCategory.heroClass,
    label: 'Classe de test',
    directory: 'classes',
    folderFile: 'class.json',
    requiredKeys: const {},
    bilingualBases: const [],
    construct: (_) {},
    template: '{}',
    referenceKeys: const {'mentor': EntityCategory.passive},
  );
```
and replace:
```dart
    expect(kindOf(hero, const ['passiveTrait'], null), FieldKind.reference);
```
with:
```dart
    expect(kindOf(mentor, const ['mentor'], null), FieldKind.reference);
```

In `test/unit/content_editor/entity_descriptor_test.dart`, delete these three comment lines:
```dart
  // - `passiveTrait`, qui est une `referenceKeys` : le formulaire le rend en
  //   catalogue de passifs, pas en champ texte. L'assertion qui suit la table
  //   le verifie.
```
and delete this block, with the blank line that follows it:
```dart
  // `passiveTrait` est la seule cle de modele deliberement absente d'un
  // gabarit tout en restant atteignable : le formulaire la rend en catalogue
  // de passifs (§5.5), et la substitution du §5.1 la laisse absente plutot que
  // d'inventer une reference.
  test('passiveTrait est atteignable par le catalogue, pas par le gabarit', () {
    final descriptor = kEntityDescriptors[EntityCategory.heroClass]!;
    expect(descriptor.decodeTemplate().containsKey('passiveTrait'), isFalse);
    expect(descriptor.referenceKeys.keys, contains('passiveTrait'));
  });
```

In `test/unit/content_editor/entity_validator_test.dart`, replace the whole group `group('famille 6 — references', () { ... });` — its two tests `un passiveTrait pendant est refuse` and `un passiveTrait resolu passe` — with:

```dart
  group('famille 6 — references', () {
    // Aucun descripteur livre ne declare de reference unique depuis que la
    // classe ne nomme plus son passif (spec P-49, §3.4) : le mecanisme se
    // verifie sur un descripteur de test.
    final mentor = EntityDescriptor(
      category: EntityCategory.heroClass,
      label: 'Classe de test',
      directory: 'classes',
      folderFile: 'class.json',
      requiredKeys: const {},
      bilingualBases: const [],
      construct: (_) {},
      template: '{}',
      referenceKeys: const {'mentor': EntityCategory.passive},
    );

    EntityDraft draftWith(String mechanics) => EntityDraft(
          descriptor: mentor,
          id: 'barde',
          bilingual: const {},
          mechanics: mechanics,
        );

    test('une reference pendante est refusee', () {
      final faults = validatorWith(
        registry: fixtureRegistry(passives: [fixturePassive('regen_armor')]),
      ).validate(draftWith('{"mentor": "chant_inexistant"}'));
      expect(faults, hasLength(1));
      expect(faults.first.field, 'mentor');
    });

    test('une reference resolue passe', () {
      final faults = validatorWith(
        registry: fixtureRegistry(passives: [fixturePassive('regen_armor')]),
      ).validate(draftWith('{"mentor": "regen_armor"}'));
      expect(faults, isEmpty);
    });
  });
```

In `test/widget/content_editor/document_form_test.dart`, replace:
```dart
  testWidgets('une reference absente se choisit dans son catalogue',
      (tester) async {
    final document = templateOf(hero);
    await pump(tester, document, hero, references: const {
      'passiveTrait': ['regen_armor'],
    });

    await tester.tap(find.text('regen_armor'));
    expect(document.root['passiveTrait'], 'regen_armor');
  });
```
with:
```dart
  testWidgets('une reference absente se choisit dans son catalogue',
      (tester) async {
    // Aucun descripteur livre ne declare de reference unique depuis P-49 :
    // le mecanisme se verifie sur un descripteur de test.
    final mentor = EntityDescriptor(
      category: EntityCategory.heroClass,
      label: 'Classe de test',
      directory: 'classes',
      folderFile: 'class.json',
      requiredKeys: const {},
      bilingualBases: const [],
      construct: (_) {},
      template: '{}',
      referenceKeys: const {'mentor': EntityCategory.passive},
    );
    final document = templateOf(mentor);
    await pump(tester, document, mentor, references: const {
      'mentor': ['regen_armor'],
    });

    await tester.tap(find.text('regen_armor'));
    expect(document.root['mentor'], 'regen_armor');
  });
```

In `test/widget/content_editor/reference_panel_test.dart`, replace:
```dart
          'passiveTrait': ['regen_armor', 'spell_armor'],
```
with:
```dart
          'effectType': ['regen_armor', 'spell_armor'],
```
and replace:
```dart
    expect(find.text('passiveTrait'), findsOneWidget);
```
with:
```dart
    expect(find.text('effectType'), findsOneWidget);
```

In `test/unit/run_controller_test.dart`, replace:
```dart
        // activePassive n'est plus déduit du passiveTrait par un repli codé
        // en dur : on le fournit explicitement, comme le ferait le vrai
        // chargement depuis assets/data/passives/ via PassiveData.getById.
```
with:
```dart
        // activePassive n'est déduit d'aucun repli codé en dur : on le
        // fournit explicitement, comme le ferait le vrai chargement depuis
        // assets/data/passives/ via PassiveData.getById.
```

`test/widget/content_editor_screen_test.dart` choisit un passif dans le catalogue de la référence `passiveTrait` d'une classe, à deux endroits. Sans référence livrée, ces deux vérifications n'ont plus d'objet ; Task 4 les réécrit sur les `classes` d'un passif. In that file, replace:
```dart
    Directory('$root/assets/data/passives').createSync(recursive: true);
    File('$root/assets/data/passives/regen_armor.json').writeAsStringSync('{}');
  }
```
with:
```dart
  }
```
replace:
```dart
      expectReadable(const ['Neutre', 'mage', 'paladin']);

      await tester.tap(find.text('Classe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('regen_armor'));
      await tester.tap(find.text('regen_armor'));
      await tester.pumpAndSettle();
      expectReadable(const ['regen_armor']);
    });
```
with:
```dart
      expectReadable(const ['Neutre', 'mage', 'paladin']);
    });
```
and delete this test, with the blank line that follows it:
```dart
  testWidgets('le passif se choisit dans le catalogue, pas dans l usage',
      (tester) async {
    // Un passif present sur le disque qu'aucune classe n'emploie : le cas que
    // `knownValues`, qui liste les valeurs *employees*, manquerait.
    Directory('$root/assets/data/passives').createSync(recursive: true);
    File('$root/assets/data/passives/chance_du_joueur.json')
        .writeAsStringSync('{}');

    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Classe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(find.text('chance_du_joueur'), findsWidgets);
  });

```

- [ ] **Step 5: Vérification complète**

Run: `git grep -nw passiveTrait -- lib test assets` — Expected: aucune sortie.
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+898: All tests passed!` — 901 moins trois tests retirés : le garde `passiveTrait` de `referential_integrity_test`, le test de gabarit `passiveTrait` de `entity_descriptor_test`, et le catalogue de passifs de `content_editor_screen_test`.

- [ ] **Step 6: Commit**

```bash
git add -A assets/data/classes lib test
git status --short
git commit -F- <<'EOF'
refactor(passifs): retirer passiveTrait, le lien part du passif

Plus aucun lecteur de jeu depuis le point d acces unique. Les tests
de l editeur qui prenaient passiveTrait pour exemple de reference
passent a un descripteur de test.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

Avant le commit, `git status --short` ne doit montrer que des fichiers de `assets/data/classes/`, `lib/` et `test/` — aucun fichier généré de plateforme (voir Global Constraints).

---

### Task 4: L'éditeur apprend la liste de références

Les « cases à cocher » de la spec (§8.1) prennent la forme visuelle des autres choix multiples de l'éditeur : les boutons à bascule de `enumMulti`, par `_choices`.

**Files:**
- Modify: `lib/services/content_editor/field_kind.dart:5-20`, `:34`
- Modify: `lib/services/content_editor/entity_descriptor.dart` (champ `referenceListKeys`, descripteur de passif `:240-255`)
- Modify: `lib/services/content_editor/entity_validator.dart` (`_references`)
- Modify: `lib/ui/widgets/content_editor/document_form.dart:80-86`, `_field`
- Modify: `lib/ui/screens/content_editor_screen.dart:859-871`
- Test: `test/unit/content_editor/fixtures.dart`, `field_kind_test.dart`, `entity_validator_test.dart`, `entity_descriptor_test.dart`, `test/widget/content_editor/document_form_test.dart`, `test/widget/content_editor_screen_test.dart`

**Interfaces:**
- Consumes: `PassiveMastery.fields` (Task 1).
- Produces:
  - `FieldKind.referenceList` ;
  - `EntityDescriptor.referenceListKeys` (`Map<String, EntityCategory>`, défaut `const {}`) ;
  - descripteur de passif : `referenceListKeys: {'classes': EntityCategory.heroClass}`, `enumKeys['mastery.field'] == PassiveMastery.fields`, gabarit avec `mastery` ;
  - `fixtureHero(String id)` et le paramètre `heroes` de `fixtureRegistry` dans `test/unit/content_editor/fixtures.dart`.

- [ ] **Step 1: Les fixtures et les tests qui échouent**

In `test/unit/content_editor/fixtures.dart`, add the import after `import 'package:roguelike_card_game/models/data/game_data_registry.dart';`:
```dart
import 'package:roguelike_card_game/models/data/hero_data.dart';
```

Replace:
```dart
GameDataRegistry fixtureRegistry({
  List<CardData> cards = const [],
  List<PassiveData> passives = const [],
}) =>
    GameDataRegistry(
      enemies: const [],
      heroes: const [],
```
with:
```dart
HeroData fixtureHero(String id) => HeroData.fromJson({
      'id': id,
      'name_en': 'x',
      'name_fr': 'x',
      'classCard': 'assets/data/classes/$id/$id.png',
      'maxHp': 80,
      'maxMana': 3,
      'baseDamage': 5,
    });

GameDataRegistry fixtureRegistry({
  List<CardData> cards = const [],
  List<HeroData> heroes = const [],
  List<PassiveData> passives = const [],
}) =>
    GameDataRegistry(
      enemies: const [],
      heroes: heroes,
```

In `test/unit/content_editor/field_kind_test.dart`, replace:
```dart
  final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
```
with:
```dart
  final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
  final passive = kEntityDescriptors[EntityCategory.passive]!;
```
and replace:
```dart
    expect(kindOf(mentor, const ['mentor'], null), FieldKind.reference);
```
with:
```dart
    expect(kindOf(mentor, const ['mentor'], null), FieldKind.reference);
    // Une liste de chaines serait une `stringList` sans la declaration.
    expect(kindOf(passive, const ['classes'], ['paladin']),
        FieldKind.referenceList);
    expect(kindOf(passive, const ['classes'], null), FieldKind.referenceList);
    expect(kindOf(passive, const ['mastery', 'field'], 'value'),
        FieldKind.enumChoice);
```

In `test/unit/content_editor/entity_validator_test.dart`, insert this group immediately after the group `famille 6 — references`:

```dart
  group('famille 6 — listes de references', () {
    final passive = kEntityDescriptors[EntityCategory.passive]!;

    EntityDraft passiveDraft(Object? classes) {
      final mechanics = passive.decodeTemplate();
      if (classes != null) mechanics['classes'] = classes;
      return EntityDraft(
        descriptor: passive,
        id: 'garde',
        bilingual: const {
          'name_fr': 'Garde',
          'name_en': 'Guard',
          'description_fr': 'Gagne 1 Armure.',
          'description_en': 'Gain 1 Block.',
        },
        mechanics: jsonEncode(mechanics),
      );
    }

    EntityValidator withClasses() => validatorWith(
          registry: fixtureRegistry(
            heroes: [fixtureHero('paladin'), fixtureHero('mage')],
          ),
        );

    test('sans classes, le passif est ouvert a toutes et passe', () {
      expect(withClasses().validate(passiveDraft(null)), isEmpty);
    });

    test('des classes existantes passent', () {
      expect(
        withClasses().validate(passiveDraft(['paladin', 'mage'])),
        isEmpty,
      );
    });

    test('une classe inconnue est refusee', () {
      final faults =
          withClasses().validate(passiveDraft(['paladin', 'paladn']));
      expect(faults, hasLength(1));
      expect(faults.first.field, 'classes');
      expect(faults.first.message, contains('paladn'));
    });

    test('une liste vide est refusee', () {
      final faults = withClasses().validate(passiveDraft(<String>[]));
      expect(faults, hasLength(1));
      expect(faults.first.field, 'classes');
    });

    test('une valeur qui n est pas une liste est refusee', () {
      final faults = withClasses().validate(passiveDraft('paladin'));
      expect(faults, isNotEmpty);
      expect(faults.first.field, 'classes');
    });
  });
```

In `test/unit/content_editor/entity_descriptor_test.dart`, add the import after the existing `entity_descriptor.dart` import:
```dart
import 'package:roguelike_card_game/models/data/passive_data.dart';
```
In the comment list that precedes `test('chaque gabarit porte exactement les cles attendues'`, replace:
```dart
  // - `heroClass` et `category`, imposes par le repertoire ;
```
with:
```dart
  // - `heroClass` et `category`, imposes par le repertoire ;
  // - `classes` d'un passif, qui est une `referenceListKeys` : absente, elle
  //   ouvre le passif a toutes les classes (spec P-49, §3.2). L'assertion
  //   qui suit la table le verifie.
```
In the same test's table, replace:
```dart
      EntityCategory.passive: {'trigger', 'effectType', 'value'},
```
with:
```dart
      EntityCategory.passive: {'trigger', 'effectType', 'value', 'mastery'},
```
Then insert, immediately after that test's closing `});`:

```dart

  test('classes est atteignable par le catalogue, pas par le gabarit', () {
    final descriptor = kEntityDescriptors[EntityCategory.passive]!;
    expect(descriptor.decodeTemplate().containsKey('classes'), isFalse);
    expect(descriptor.referenceListKeys, {'classes': EntityCategory.heroClass});
  });

  test('mastery.field propose les parametres que le modele accepte', () {
    final descriptor = kEntityDescriptors[EntityCategory.passive]!;
    expect(descriptor.enumKeys['mastery.field'], PassiveMastery.fields);
  });
```

In `test/widget/content_editor/document_form_test.dart`, insert after the test `une reference absente se choisit dans son catalogue`:

```dart
  group('une liste de references', () {
    final passive = kEntityDescriptors[EntityCategory.passive]!;
    const catalogue = {
      'classes': ['mage', 'paladin'],
    };

    testWidgets('absente, elle se coche', (tester) async {
      final document = templateOf(passive);
      await pump(tester, document, passive, references: catalogue);

      await tester.tap(find.text('paladin'));
      expect(document.root['classes'], ['paladin']);
    });

    testWidgets('cocher ajoute dans l ordre du catalogue', (tester) async {
      final document = EditorDocument({
        ...passive.decodeTemplate(),
        'classes': ['paladin'],
      });
      await pump(tester, document, passive, references: catalogue);

      await tester.tap(find.text('mage'));
      expect(document.root['classes'], ['mage', 'paladin']);
    });

    testWidgets('decocher la derniere retire la cle', (tester) async {
      // `[]` est refuse au chargement : l'absence vaut « toutes ».
      final document = EditorDocument({
        ...passive.decodeTemplate(),
        'classes': ['paladin'],
      });
      await pump(tester, document, passive, references: catalogue);

      await tester.tap(find.text('paladin'));
      expect(document.root.containsKey('classes'), isFalse);
    });
  });
```

In `test/widget/content_editor_screen_test.dart`, les deux vérifications retirées par Task 3 reviennent sur les `classes` d'un passif. Replace:
```dart
      expectReadable(const ['Neutre', 'mage', 'paladin']);
    });
```
with:
```dart
      expectReadable(const ['Neutre', 'mage', 'paladin']);

      await tester.tap(find.text('Passif'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('paladin'));
      await tester.tap(find.text('paladin'));
      await tester.pumpAndSettle();
      expectReadable(const ['paladin']);
    });
```
and insert this test immediately before `  testWidgets('une saisie non entiere est une faute, et rien n est ecrit',`:
```dart
  testWidgets('les classes d un passif se choisissent dans le catalogue',
      (tester) async {
    // Une classe presente sur le disque qu'aucun passif ne declare : le cas
    // que `knownValues`, qui liste les valeurs *employees*, manquerait.
    Directory('$root/assets/data/classes/barde').createSync(recursive: true);
    File('$root/assets/data/classes/barde/class.json').writeAsStringSync('{}');

    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Passif'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(buttonOf('barde'), findsOneWidget);
  });

```

Run: `flutter test test/unit/content_editor test/widget/content_editor test/widget/content_editor_screen_test.dart`
Expected: FAIL. À la compilation pour `field_kind_test.dart` et `entity_descriptor_test.dart` — `FieldKind.referenceList` et `referenceListKeys` n'existent pas. À l'exécution pour les autres : trois tests de `famille 6 — listes de references` (classe inconnue, liste vide, valeur qui n'est pas une liste), les trois de `une liste de references`, et les deux de `content_editor_screen_test` — aucune case de classe n'est rendue.

- [ ] **Step 2: `FieldKind` et le descripteur**

In `lib/services/content_editor/field_kind.dart`, replace:
```dart
  reference,
```
with:
```dart
  reference,
  referenceList,
```
and replace:
```dart
  if (descriptor.referenceKeys.containsKey(pattern)) return FieldKind.reference;
```
with:
```dart
  if (descriptor.referenceKeys.containsKey(pattern)) return FieldKind.reference;
  if (descriptor.referenceListKeys.containsKey(pattern)) {
    return FieldKind.referenceList;
  }
```

In `lib/services/content_editor/entity_descriptor.dart`, replace:
```dart
    this.referenceKeys = const {},
```
with:
```dart
    this.referenceKeys = const {},
    this.referenceListKeys = const {},
```
and, after the declaration `  final Map<String, EntityCategory> referenceKeys;`, add:
```dart

  /// Comme [referenceKeys], pour une cle portant une **liste** de references.
  /// Absente, la cle vaut « toute la categorie » ; une liste vide est refusee.
  /// `classes` d'un passif (spec P-49, §8).
  final Map<String, EntityCategory> referenceListKeys;
```

In the same file, replace the passive descriptor:
```dart
  EntityCategory.passive: EntityDescriptor(
    category: EntityCategory.passive,
    label: 'Passif',
    directory: 'passives',
    requiredKeys: const {'trigger', 'effectType', 'value'},
    enumKeys: {'trigger': _names(RelicTrigger.values)},
    bilingualBases: const ['name', 'description'],
    construct: PassiveData.fromJson,
    vocabularyKeys: const {'effectType'},
    template: '''
{
  "trigger": "startOfTurn",
  "effectType": "gain_armor",
  "value": 2
}''',
  ),
```
with:
```dart
  EntityCategory.passive: EntityDescriptor(
    category: EntityCategory.passive,
    label: 'Passif',
    directory: 'passives',
    requiredKeys: const {'trigger', 'effectType', 'value'},
    enumKeys: {
      'trigger': _names(RelicTrigger.values),
      'mastery.field': PassiveMastery.fields,
    },
    // Absente du gabarit : sans `classes`, le passif est ouvert a toutes les
    // classes (spec P-49, §3.2).
    referenceListKeys: const {'classes': EntityCategory.heroClass},
    bilingualBases: const ['name', 'description'],
    construct: PassiveData.fromJson,
    vocabularyKeys: const {'effectType'},
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
  ),
```

- [ ] **Step 3: Le validateur**

In `lib/services/content_editor/entity_validator.dart`, inside `_references`, replace:
```dart
            '"$value"',
            field: key,
          ),
        );
      }
    });
    return faults;
  }
```
with:
```dart
            '"$value"',
            field: key,
          ),
        );
      }
    });
    draft.descriptor.referenceListKeys.forEach((key, category) {
      final value = mechanics[key];
      if (value == null) return; // absente : toute la categorie
      if (value is! List) {
        faults.add(ValidationFault('doit être une liste', field: key));
        return;
      }
      if (value.isEmpty) {
        faults.add(
          ValidationFault(
            'une liste vide ne désigne personne — retirer la clé pour viser '
            'toute la catégorie',
            field: key,
          ),
        );
        return;
      }
      final ids = _idsOf(category);
      if (ids == null) return; // registre indisponible : on ne devine pas
      for (final element in value) {
        if (element is! String || !ids.contains(element)) {
          faults.add(
            ValidationFault(
              'aucune entité de la catégorie '
              '"${kEntityDescriptors[category]!.label}" ne porte l\'identifiant '
              '"$element"',
              field: key,
            ),
          );
        }
      }
    });
    return faults;
  }
```

- [ ] **Step 4: Le formulaire et son catalogue**

In `lib/ui/widgets/content_editor/document_form.dart`, replace:
```dart
      for (final key in descriptor.referenceKeys.keys)
        if (!root.containsKey(key)) key: null,
    };
```
with:
```dart
      for (final key in descriptor.referenceKeys.keys)
        if (!root.containsKey(key)) key: null,
      for (final key in descriptor.referenceListKeys.keys)
        if (!root.containsKey(key)) key: null,
    };
```

In the same file, in `_field`, insert this case immediately before `      case FieldKind.color:`:
```dart
      case FieldKind.referenceList:
        final options = widget.referenceOptions[pattern] ?? const <String>[];
        // Une valeur qui n'est pas une liste ne selectionne rien : la
        // validation dira pourquoi elle est refusee.
        final selected = {
          ...(value is List ? value.whereType<String>() : const <String>[]),
        };
        built = row(
          _choices(
            path,
            options,
            isSelected: selected.contains,
            onTap: (option) {
              final next = [
                for (final o in options)
                  if (selected.contains(o) != (o == option)) o,
              ];
              // Decocher la derniere retire la cle : `[]` est refuse au
              // chargement, et l'absence vaut « toute la categorie ».
              if (next.isEmpty) {
                _document.removeAt(path);
                widget.onChanged();
              } else {
                _set(path, next);
              }
            },
          ),
          alignTop: true,
        );
```

In `lib/ui/screens/content_editor_screen.dart`, replace:
```dart
    // Le catalogue de chaque `referenceKeys` du descripteur — tire de
    // `entityIdsByOwner`, jamais de `knownValues` : ce dernier ne liste que
    // les valeurs deja employees, et un passif jamais utilise y serait
    // invisible.
    _references = {
      for (final entry in _descriptor.referenceKeys.entries)
```
with:
```dart
    // Le catalogue de chaque `referenceKeys` et `referenceListKeys` du
    // descripteur — tire de `entityIdsByOwner`, jamais de `knownValues` : ce
    // dernier ne liste que les valeurs deja employees, et une entite jamais
    // referencee y serait invisible.
    _references = {
      for (final entry in {
        ..._descriptor.referenceKeys,
        ..._descriptor.referenceListKeys,
      }.entries)
```

- [ ] **Step 5: Lancer les tests de l'éditeur**

Run: `flutter test test/unit/content_editor test/widget/content_editor test/widget/content_editor_screen_test.dart`
Expected: PASS, `+306: All tests passed!`

- [ ] **Step 6: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+909: All tests passed!` (898 + 5 de validation + 2 de descripteur + 3 de formulaire + 1 de l'écran).

- [ ] **Step 7: Commit**

```bash
git add lib/services/content_editor lib/ui/widgets/content_editor/document_form.dart lib/ui/screens/content_editor_screen.dart test/unit/content_editor test/widget/content_editor test/widget/content_editor_screen_test.dart
git commit -F- <<'EOF'
feat(editeur): liste de references, classes et maitrise d un passif

Nouveau type de champ referenceList : une case par entite du
catalogue, une classe inconnue ou une liste vide refusees a la saisie.
Le gabarit de passif porte le bloc mastery.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 5: `TraitSystem` en répartiteur de stratégies, `RunController.endTurn()`

Comportement identique : la Maîtrise reste appliquée par `StatGains` jusqu'à Task 7.

**Files:**
- Create: `lib/game/systems/passives/passive_strategy.dart`
- Create: `lib/game/systems/passives/passive_strategies.dart`
- Modify: `lib/game/systems/trait_system.dart` (réécrit en entier)
- Modify: `lib/game/controllers/run_controller.dart:12`, `:392-395`, `:413-416`
- Modify: `lib/game/controllers/combat_controller.dart:14`, `:226-227`
- Modify: `lib/ui/screens/game_screen.dart:16`, `:522-525`
- Test: `test/unit/trait_system_test.dart` *(nouveau)*, `test/unit/stat_gains_characterization_test.dart`, `test/unit/passive_absent_test.dart`, `test/unit/run_controller_test.dart`, `test/unit/referential_integrity_test.dart`

**Interfaces:**
- Consumes: `RunController.grant`, `StatGain`, `GainResource`, `GainSource` (lot A de P-41).
- Produces:
  - `class PassiveEvent { final RelicTrigger trigger; final CardInstance? card; const PassiveEvent(this.trigger, {this.card}); }`
  - `abstract class PassiveStrategy { const PassiveStrategy(); void resolve(PassiveData passive, PassiveEvent event, RunController run); }`
  - `GainArmorPassive`, `BerserkerArmorPassive`, `SpellArmorPassive` ; `PassiveStrategies.byEffectType` (`Map<String, PassiveStrategy>`, constante).
  - `TraitSystem.dispatch(RunController run, PassiveEvent event)` ; `TraitSystem.onTurnStart`, `onTurnEnd`, `onCardPlayed` disparaissent.
  - `RunController.endTurn()`.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/unit/trait_system_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/passives/passive_strategy.dart';
import 'package:roguelike_card_game/game/systems/trait_system.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

/// Le répartiteur des passifs (spec P-49, §5.3).
void main() {
  const hero = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
  );

  late ProviderContainer container;
  late RunController run;

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
  });

  tearDown(() => container.dispose());

  int armor() => run.currentState.heroStats.armure;

  PassiveData passive(RelicTrigger trigger, String effectType) => PassiveData(
        id: 'test_passive',
        trigger: trigger,
        effectType: effectType,
        value: 2,
      );

  test('sans passif actif : rien', () {
    run.startNewRun(hero);
    TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
    expect(armor(), 0);
  });

  test('un evenement que le passif n attend pas : rien', () {
    run.startNewRun(hero, passive(RelicTrigger.endOfTurn, 'gain_armor'));
    TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.startOfTurn));
    expect(armor(), 0);
  });

  test('l evenement attendu : la strategie de l effectType agit', () {
    run.startNewRun(hero, passive(RelicTrigger.endOfTurn, 'gain_armor'));
    TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
    expect(armor(), 2);
  });

  test('le declencheur suit la donnee : gain_armor sur une carte jouee', () {
    // Avant P-49, gain_armor n etait honore qu en debut et en fin de tour.
    run.startNewRun(hero, passive(RelicTrigger.onCardPlayed, 'gain_armor'));
    TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.onCardPlayed));
    expect(armor(), 2);
  });

  test('un effectType sans strategie : rien, sans exception', () {
    run.startNewRun(hero, passive(RelicTrigger.endOfTurn, 'inconnu'));
    expect(
      () => TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn)),
      returnsNormally,
    );
    expect(armor(), 0);
  });
}
```

Run: `flutter test test/unit/trait_system_test.dart`
Expected: FAIL à la compilation — `passive_strategy.dart` et `TraitSystem.dispatch` n'existent pas.

- [ ] **Step 2: La stratégie et l'événement**

Create `lib/game/systems/passives/passive_strategy.dart`:

```dart
import '../../../models/card_instance.dart';
import '../../../models/data/passive_data.dart';
import '../../../models/data/relic_data.dart';
import '../../controllers/run_controller.dart';

/// Ce qui déclenche un passif : le moment, et la carte jouée s'il y en a une.
class PassiveEvent {
  final RelicTrigger trigger;

  /// Renseignée pour `onCardPlayed`, `null` sinon.
  final CardInstance? card;

  const PassiveEvent(this.trigger, {this.card});
}

/// L'effet d'un `effectType` de passif (spec P-49, §5.1), sur le modèle des
/// effets de cartes (ADR-061).
///
/// `TraitSystem.dispatch` n'appelle une stratégie qu'une fois le déclencheur
/// vérifié : elle n'a pas à le tester.
abstract class PassiveStrategy {
  const PassiveStrategy();

  void resolve(PassiveData passive, PassiveEvent event, RunController run);
}
```

- [ ] **Step 3: Les trois stratégies et leur table**

Create `lib/game/systems/passives/passive_strategies.dart`:

```dart
import '../../../models/data/card_data.dart';
import '../../../models/data/passive_data.dart';
import '../../controllers/run_controller.dart';
import '../stat_gains.dart';
import 'passive_strategy.dart';

/// `gain_armor` : accorde `value` d'armure.
class GainArmorPassive extends PassiveStrategy {
  const GainArmorPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    run.grant(StatGain(GainResource.armor, passive.value, GainSource.passive));
  }
}

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

/// La table `effectType` → stratégie. Une table de code, constante, pas un
/// état : un passif du lot B de P-41 y ajoute une ligne et une classe.
abstract final class PassiveStrategies {
  static const Map<String, PassiveStrategy> byEffectType = {
    'gain_armor': GainArmorPassive(),
    'berserker_armor': BerserkerArmorPassive(),
    'spell_armor': SpellArmorPassive(),
  };
}
```

- [ ] **Step 4: Le répartiteur**

Replace the whole content of `lib/game/systems/trait_system.dart` with:

```dart
import '../controllers/run_controller.dart';
import 'passives/passive_strategies.dart';
import 'passives/passive_strategy.dart';

/// Le répartiteur des passifs (spec P-49, §5.3).
///
/// Il ne connaît aucun passif : il vérifie que l'événement est celui qu'attend
/// le passif actif, puis confie l'effet à la stratégie de son `effectType`.
/// Un `effectType` sans stratégie ne fait rien — jamais d'exception en plein
/// combat ; `referential_integrity_test` refuse qu'un passif livré soit dans
/// ce cas.
abstract final class TraitSystem {
  static void dispatch(RunController run, PassiveEvent event) {
    final passive = run.currentState.activePassive;
    if (passive == null || passive.trigger != event.trigger) return;
    PassiveStrategies.byEffectType[passive.effectType]
        ?.resolve(passive, event, run);
  }
}
```

- [ ] **Step 5: Les appels**

In `lib/game/controllers/run_controller.dart`, replace:
```dart
import '../systems/trait_system.dart';
```
with:
```dart
import '../systems/passives/passive_strategy.dart';
import '../systems/trait_system.dart';
```

Replace:
```dart
    // 3. Déclenchement des passifs de début de combat/tour pour le tour 1 (ex: Berserker)
    TraitSystem.onTurnStart(this);
```
with:
```dart
    // 3. Déclenchement des passifs de début de combat/tour pour le tour 1 (ex: Berserker)
    TraitSystem.dispatch(this, const PassiveEvent(RelicTrigger.startOfTurn));
```

Replace:
```dart
    // 4. Déclencher les traits passifs
    TraitSystem.onTurnStart(this);
  }
```
with:
```dart
    // 4. Déclencher les traits passifs
    TraitSystem.dispatch(this, const PassiveEvent(RelicTrigger.startOfTurn));
  }

  /// Fin du tour du joueur : le passif, puis les reliques de fin de tour, dans
  /// l'ordre que suivait `game_screen.dart` (spec P-49, §5.4). La défausse et
  /// le tour ennemi restent à l'écran : ils ne relèvent pas de ce controller.
  void endTurn() {
    TraitSystem.dispatch(this, const PassiveEvent(RelicTrigger.endOfTurn));
    applyRelics(RelicTrigger.endOfTurn);
  }
```

In `lib/game/controllers/combat_controller.dart`, replace:
```dart
import '../systems/trait_system.dart';
```
with:
```dart
import '../systems/passives/passive_strategy.dart';
import '../systems/trait_system.dart';
```
and replace:
```dart
      TraitSystem.onCardPlayed(runController, card);
```
with:
```dart
      TraitSystem.dispatch(
        runController,
        PassiveEvent(RelicTrigger.onCardPlayed, card: card),
      );
```

In `lib/ui/screens/game_screen.dart`, delete the line:
```dart
import '../../game/systems/trait_system.dart';
```
and replace:
```dart
                        TraitSystem.onTurnEnd(ref.read(runProvider.notifier));
                        ref
                            .read(runProvider.notifier)
                            .applyRelics(RelicTrigger.endOfTurn);
```
with:
```dart
                        ref.read(runProvider.notifier).endTurn();
```

Run: `flutter test test/unit/trait_system_test.dart`
Expected: PASS, `+5: All tests passed!`

- [ ] **Step 6: Les tests existants passent au répartiteur**

In `test/unit/stat_gains_characterization_test.dart`, add the import after `import 'package:roguelike_card_game/game/services/effects/effect_strategy.dart';`:
```dart
import 'package:roguelike_card_game/game/systems/passives/passive_strategy.dart';
```
Replace every occurrence (`replace_all`) of:
```dart
      TraitSystem.onTurnStart(run);
```
with:
```dart
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.startOfTurn));
```
Replace:
```dart
      TraitSystem.onTurnEnd(run);
```
with:
```dart
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
```
Replace:
```dart
      TraitSystem.onCardPlayed(run, card(CardType.attack, const []));
```
with:
```dart
      TraitSystem.dispatch(
        run,
        PassiveEvent(
          RelicTrigger.onCardPlayed,
          card: card(CardType.attack, const []),
        ),
      );
```
Replace:
```dart
      TraitSystem.onCardPlayed(run, card(CardType.skill, const []));
```
with:
```dart
      TraitSystem.dispatch(
        run,
        PassiveEvent(
          RelicTrigger.onCardPlayed,
          card: card(CardType.skill, const []),
        ),
      );
```
Les valeurs attendues ne changent pas.

In `test/unit/passive_absent_test.dart`, add the imports after `import 'package:roguelike_card_game/game/controllers/run_controller.dart';`:
```dart
import 'package:roguelike_card_game/game/systems/passives/passive_strategy.dart';
```
and after `import 'package:roguelike_card_game/models/data/hero_data.dart';`:
```dart
import 'package:roguelike_card_game/models/data/relic_data.dart';
```
Replace:
```dart
    TraitSystem.onTurnStart(controller);
    TraitSystem.onTurnEnd(controller);
```
with:
```dart
    TraitSystem.dispatch(
      controller,
      const PassiveEvent(RelicTrigger.startOfTurn),
    );
    TraitSystem.dispatch(controller, const PassiveEvent(RelicTrigger.endOfTurn));
```

In `test/unit/run_controller_test.dart`, add this group at the end of `main()`, just before its closing `}`:

```dart
  group('RunController.endTurn', () {
    const hero = HeroData(
      id: 'berserker',
      classCard: 'berserker.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
    );

    test('le passif, puis les reliques de fin de tour', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runController = container.read(runProvider.notifier);

      const berserkerArmor = PassiveData(
        id: 'berserker_armor',
        trigger: RelicTrigger.endOfTurn,
        effectType: 'berserker_armor',
        value: 1,
      );
      runController.startNewRun(hero, berserkerArmor);
      runController.takeDamage(30);
      container.read(inventoryProvider.notifier).addRelic(
            const RelicData(
              id: 'test_heal',
              trigger: RelicTrigger.endOfTurn,
              effectType: 'heal',
              value: 20,
              rarity: RelicRarity.common,
              emoji: '💧',
            ),
          );

      runController.endTurn();

      // Passif d'abord : 30 PV manquants, 3 d'armure. Les reliques d'abord
      // auraient soigné avant, et laissé 10 PV manquants, 1 d'armure.
      expect(runController.state.heroStats.armure, 3);
      expect(runController.state.heroStats.currentPv, 90);
    });
  });
```

In `test/unit/referential_integrity_test.dart`, add the import after `import 'package:roguelike_card_game/game/systems/passive_availability.dart';`:
```dart
import 'package:roguelike_card_game/game/systems/passives/passive_strategies.dart';
```
and insert, immediately before `  test('toute classe declaree par un passif existe', () {`:

```dart
  test('chaque effectType de passif a sa strategie', () {
    final offenders = [
      for (final passive in registry.passives)
        if (!PassiveStrategies.byEffectType.containsKey(passive.effectType))
          '${passive.id} → effectType "${passive.effectType}" sans stratégie',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

```

- [ ] **Step 7: Vérification complète**

Run: `git grep -nE "TraitSystem\.on(TurnStart|TurnEnd|CardPlayed)" -- lib test` — Expected: aucune sortie.
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+916: All tests passed!` (909 + 5 du répartiteur + 1 de fin de tour + 1 d'intégrité).

- [ ] **Step 8: Commit**

```bash
git add lib/game/systems lib/game/controllers/run_controller.dart lib/game/controllers/combat_controller.dart lib/ui/screens/game_screen.dart test/unit/trait_system_test.dart test/unit/stat_gains_characterization_test.dart test/unit/passive_absent_test.dart test/unit/run_controller_test.dart test/unit/referential_integrity_test.dart
git commit -F- <<'EOF'
refactor(passifs): TraitSystem repartit vers une strategie par effet

Une strategie par effectType, dans une table constante. Le
declencheur suit la donnee. La fin de tour quitte l ecran de combat
pour RunController.endTurn, dans le meme ordre. Comportement
identique.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 6: Renommer la Maîtrise d'Armure en Maîtrise

Renommage mécanique : aucun comportement ne change, `StatGains` applique toujours la Maîtrise aux gains de passif.

**Files:**
- Modify (script): tous les fichiers de `lib/`, `test/` et `assets/` qui contiennent `armorMastery`, `ArmorMastery`, `armor_mastery` ou `armorAcc` — dont `lib/models/entity_stats.dart`, `lib/models/data/hero_data.dart`, `lib/game/controllers/run_controller.dart`, `lib/game/controllers/run/player_stats_manager.dart`, `lib/game/systems/stat_gains.dart`, `lib/tutorial/tutorial_engine.dart`, `lib/ui/screens/draft_screen.dart`, `lib/ui/widgets/map/dialogs/stats_dialog.dart`, `lib/ui/widgets/map/hero_mini_stats_panel.dart`, `lib/services/content_editor/entity_descriptor.dart`, `assets/data/relics/kunai.json`
- Modify: `lib/game/controllers/run/player_stats_manager.dart:266`, `test/unit/content_editor/entity_descriptor_test.dart:144-146`

**Interfaces:**
- Consumes: rien de nouveau.
- Produces: `EntityStats.mastery` (clé JSON `mastery`), `EntityStats.effectiveMastery`, statut de combat `mastery`, `HeroData.mastery` (clé `mastery`), `applyHeroStatModifier(masteryAcc:)` sur `RunController` et `PlayerStatsManager`, effet de relique `charge_mastery_combat`.

- [ ] **Step 1: Le renommage**

Run this script from the repository root:

```bash
python - <<'EOF'
import subprocess

RENAMES = [
    ("effectiveArmorMastery", "effectiveMastery"),
    ("charge_armor_mastery_combat", "charge_mastery_combat"),
    ("'armor_mastery'", "'mastery'"),
    ("statut armor_mastery", "statut mastery"),
    ("armorMastery", "mastery"),
    ("armorAcc", "masteryAcc"),
]
files = subprocess.run(
    ["git", "grep", "-lE", "ArmorMastery|armorMastery|armor_mastery|armorAcc", "--", "lib", "test", "assets"],
    capture_output=True, text=True, check=True,
).stdout.split()
for path in files:
    with open(path, encoding="utf-8", newline="") as f:
        text = f.read()
    new = text
    for old, repl in RENAMES:
        new = new.replace(old, repl)
    if new != text:
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(new)
        print(path)
EOF
```

Expected: 32 fichiers listés (10 de `lib/`, 21 de `test/`, `assets/data/relics/kunai.json`).
Run: `git grep -nE "ArmorMastery|armorMastery|armor_mastery|armorAcc" -- lib test assets`
Expected: aucune sortie.

- [ ] **Step 2: Le nom du statut et un commentaire**

In `lib/game/controllers/run/player_stats_manager.dart`, replace:
```dart
              name: 'Maîtrise d\'Armure (Relique)',
```
with:
```dart
              name: 'Maîtrise (Relique)',
```

In `test/unit/content_editor/entity_descriptor_test.dart`, replace:
```dart
  // `mastery` est lu par run_controller.dart:253 et applique a chaque
  // gain d armure. Absent du gabarit, il etait invisible dans l editeur et
```
with:
```dart
  // `mastery` est lu par `startNewRun` : c'est la Maitrise de depart de la
  // classe. Absent du gabarit, il etait invisible dans l editeur et
```

- [ ] **Step 3: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+916: All tests passed!`, sans qu'aucune valeur attendue ait changé.

- [ ] **Step 4: Commit**

```bash
git add -A lib test assets
git status --short
git commit -F- <<'EOF'
refactor(maitrise): armorMastery devient mastery

Renommage mecanique de la stat, de son statut de combat, du champ de
classe, du parametre de progression et de l effet de relique du Croc
Kunai. Aucun comportement ne change.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

Avant le commit, `git status --short` ne doit montrer que des fichiers de `lib/`, `test/` et `assets/`.

---

### Task 7: La Maîtrise s'applique au passif

Le changement de comportement du lot : `TraitSystem` applique la Maîtrise au passif, `StatGains` n'y touche plus. *Armure du Berserker* change d'échelle (spec §6.4).

**Files:**
- Modify: `assets/data/passives/regen_armor.json`, `berserker_armor.json`, `spell_armor.json` (réécrits en entier)
- Modify: `lib/game/systems/trait_system.dart` (réécrit en entier)
- Modify: `lib/game/systems/stat_gains.dart:6-8`, `:44-46`, `:60-67`
- Modify: `lib/models/entity_stats.dart:11`
- Test: `test/unit/stat_gains_test.dart` (réécrit en entier), `test/unit/stat_gains_characterization_test.dart`, `test/unit/trait_system_test.dart`, `test/unit/run_controller_test.dart`, `test/unit/stat_gain_single_passage_test.dart:5-9`

**Interfaces:**
- Consumes: `PassiveData.withMastery`, `PassiveMastery` (Task 1) ; `TraitSystem.dispatch` (Task 5) ; `EntityStats.effectiveMastery` (Task 6).
- Produces: `TraitSystem.dispatch` passe `passive.withMastery(heroStats.effectiveMastery)` à la stratégie ; `StatGains.apply` n'ajoute plus la Maîtrise.

- [ ] **Step 1: Les tests qui décrivent le nouveau comportement**

Replace the whole content of `test/unit/stat_gains_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/stat_gains.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';

void main() {
  EntityStats stats() => EntityStats(
        maxPv: 50,
        currentPv: 40,
        maxMana: 3,
        currentMana: 3,
        armure: 1,
        mastery: 3,
        attackPower: 2,
        lastActionWasCrit: true,
      );

  group('StatGains.apply', () {
    // La Maîtrise agit sur le passif avant son gain (spec P-49, §6.3) :
    // aucune source, `passive` comprise, ne la reçoit ici.
    for (final source in GainSource.values) {
      test('armure de source ${source.name} : la valeur seule', () {
        final gain = StatGain(GainResource.armor, 2, source);
        expect(StatGains.apply(stats(), gain).armure, 1 + 2);
      });
    }

    test('mana : aucun plafond', () {
      const gain = StatGain(GainResource.mana, 2, GainSource.card);
      expect(StatGains.apply(stats(), gain).currentMana, 3 + 2);
    });

    test('puissances : chacune dans sa stat, et un gain negatif retire', () {
      final s = stats();
      expect(
        StatGains.apply(s, const StatGain(GainResource.attackPower, 4, GainSource.progression)).attackPower,
        2 + 4,
      );
      expect(
        StatGains.apply(s, const StatGain(GainResource.attackPower, -2, GainSource.progression)).attackPower,
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

    test('un gain ne touche a rien d autre', () {
      const gain = StatGain(GainResource.armor, 2, GainSource.card);
      final after = StatGains.apply(stats(), gain);

      expect(after.currentPv, 40);
      expect(after.currentMana, 3);
      expect(after.attackPower, 2);
      expect(after.mastery, 3);
      expect(after.lastActionWasCrit, isTrue);
    });
  });
}
```

In `test/unit/trait_system_test.dart`, add the import after `import 'package:roguelike_card_game/models/data/relic_data.dart';`:
```dart
import 'package:roguelike_card_game/models/status_effect.dart';
```
and add this group at the end of `main()`, just before its closing `}`:

```dart
  group('la Maitrise, appliquee avant la strategie', () {
    const master = HeroData(
      id: 'paladin',
      classCard: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      mastery: 3,
    );
    const regen = PassiveData(
      id: 'regen_armor',
      trigger: RelicTrigger.endOfTurn,
      effectType: 'gain_armor',
      value: 2,
      mastery: PassiveMastery(field: 'value', perPoint: 1),
    );

    test('un passif qui declare mastery en tire son parametre augmente', () {
      run.startNewRun(master, regen);
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
      expect(armor(), 2 + 3);
    });

    test('un passif sans mastery l ignore', () {
      run.startNewRun(master, passive(RelicTrigger.endOfTurn, 'gain_armor'));
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
      expect(armor(), 2);
    });

    test('le statut de combat mastery compte', () {
      run.startNewRun(master, regen);
      run.addStatus(
        const StatusEffect(
          id: 'mastery',
          name: 'Maîtrise (Relique)',
          type: StatusType.buff,
          value: 1,
          duration: 99,
        ),
      );
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
      expect(armor(), 2 + 3 + 1);
    });

    test('la Maitrise ne s accumule pas sur le passif actif', () {
      run.startNewRun(master, regen);
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
      expect(armor(), 2 * (2 + 3));
      expect(run.currentState.activePassive!.value, 2);
    });
  });
```

In `test/unit/stat_gains_characterization_test.dart`, replace the helper:
```dart
  PassiveData passive(RelicTrigger trigger, String effectType, int value) =>
      PassiveData(
        id: 'test_passive',
        trigger: trigger,
        effectType: effectType,
        value: value,
      );
```
with:
```dart
  PassiveData passive(RelicTrigger trigger, String effectType, int value) =>
      PassiveData(
        id: 'test_passive',
        trigger: trigger,
        effectType: effectType,
        value: value,
        mastery: const PassiveMastery(field: 'value', perPoint: 1),
      );
```
Replace:
```dart
  // Une Maîtrise d'Armure non nulle : elle ne doit s'ajouter qu'aux passifs.
```
with:
```dart
  // Une Maîtrise non nulle : seuls les passifs qui la déclarent en tirent parti.
```
Replace:
```dart
  group('armure des passifs : la valeur plus la Maitrise', () {
```
with:
```dart
  // P-49 (spec, §6.4) : la Maîtrise augmente le paramètre que le passif
  // déclare, avant son calcul. Régénération et Armure Magique n'en voient pas
  // la différence ; Armure du Berserker, si — changement voulu.
  group('armure des passifs : la Maitrise augmente le parametre declare', () {
```
Replace:
```dart
    test('berserker_armor : par tranche de 10 PV manquants', () {
```
with:
```dart
    test('berserker_armor : la Maitrise compte a chaque tranche (P-49)', () {
```
and, in that same test, replace:
```dart
      expect(heroStats().armure, 2 * 1 + 3);
```
with:
```dart
      // Avant P-49 : 2 tranches × 1 + 3 = 5.
      expect(heroStats().armure, 2 * (1 + 3));
```
In the file's header doc comment, replace:
```dart
/// passent sur le code d'origine et restent inchangés après la conversion :
/// c'est la preuve que le lot A ne change rien au jeu.
```
with:
```dart
/// passent sur le code d'origine et restent inchangés après la conversion :
/// c'est la preuve que le lot A ne change rien au jeu. Une seule valeur a
/// changé depuis, voulue : Armure du Berserker avec de la Maîtrise (P-49).
```

In `test/unit/run_controller_test.dart`, replace:
```dart
          effectType: 'berserker_armor',
          value: 1,
        );

        runController.startNewRun(berserkerHero, berserkerArmor);
```
with:
```dart
          effectType: 'berserker_armor',
          value: 1,
          mastery: PassiveMastery(field: 'value', perPoint: 1),
        );

        runController.startNewRun(berserkerHero, berserkerArmor);
```
and replace:
```dart
        // Missing HP = 20. Gain = 20 ~/ 10 = 2 armor.
        // Total gain = 2 + mastery (1) = 3 armor.
        runController.startCombat();

        expect(runController.state.heroStats.armure, 3);
```
with:
```dart
        // Missing HP = 20, i.e. 2 tranches. Mastery raises the passive's
        // value first (spec P-49, §6.4): 2 × (1 + 1) = 4 armor.
        runController.startCombat();

        expect(runController.state.heroStats.armure, 4);
```

Run: `flutter test test/unit/stat_gains_test.dart test/unit/trait_system_test.dart test/unit/stat_gains_characterization_test.dart test/unit/run_controller_test.dart`
Expected: FAIL, `+40 -4` — la Maîtrise est encore ajoutée par `StatGains`, à tout passif, et pas encore par `TraitSystem`. Échouent exactement : `armure de source passive : la valeur seule` (6 au lieu de 3), `un passif sans mastery l ignore` (5 au lieu de 2), `berserker_armor : la Maitrise compte a chaque tranche (P-49)` (5 au lieu de 8) et, dans `run_controller_test`, `Berserker armor passive triggers at start of combat…` (3 au lieu de 4). Les trois autres tests de la Maîtrise du répartiteur passent déjà : sur un passif qui déclare `mastery` à 1 par point, l'ancien calcul et le nouveau coïncident.

- [ ] **Step 2: Déplacer la Maîtrise**

Replace the whole content of `lib/game/systems/trait_system.dart` with:

```dart
import '../controllers/run_controller.dart';
import 'passives/passive_strategies.dart';
import 'passives/passive_strategy.dart';

/// Le répartiteur des passifs (spec P-49, §5.3).
///
/// Il ne connaît aucun passif : il vérifie que l'événement est celui qu'attend
/// le passif actif, lui applique la Maîtrise du héros, puis confie l'effet à
/// la stratégie de son `effectType` — qui ne lit donc jamais la stat
/// (spec P-49, §6.2). Un `effectType` sans stratégie ne fait rien — jamais
/// d'exception en plein combat ; `referential_integrity_test` refuse qu'un
/// passif livré soit dans ce cas.
abstract final class TraitSystem {
  static void dispatch(RunController run, PassiveEvent event) {
    final passive = run.currentState.activePassive;
    if (passive == null || passive.trigger != event.trigger) return;
    PassiveStrategies.byEffectType[passive.effectType]?.resolve(
      passive.withMastery(run.currentState.heroStats.effectiveMastery),
      event,
      run,
    );
  }
}
```

In `lib/game/systems/stat_gains.dart`, replace:
```dart
/// D'où vient un gain. C'est ce qui permet à une règle de ne viser qu'une
/// provenance : la Maîtrise d'Armure ne s'ajoute qu'aux gains `passive`.
```
with:
```dart
/// D'où vient un gain : l'étiquette qu'une règle peut viser — les règles de
/// classe du lot B de P-41. La Maîtrise n'en est plus une : elle agit sur le
/// passif avant qu'il ne calcule son gain (spec P-49, §6.3).
```
Replace:
```dart
          armure: stats.armure + gain.amount + _masteryFor(stats, gain),
```
with:
```dart
          armure: stats.armure + gain.amount,
```
And delete the method with its doc comment, and the blank line before it, so that the class ends right after `apply`:
```dart

  /// La Maîtrise d'Armure ne s'ajoute qu'aux gains des passifs : c'est sur ce
  /// périmètre qu'est calibrée la récompense *Forge d'Acier*
  /// (`level_up_reward_service.dart`). Sa refonte en bonus de passif est une
  /// décision de P-49 (spec P-41, §5.4).
  static int _masteryFor(EntityStats stats, StatGain gain) =>
      gain.source == GainSource.passive ? stats.effectiveMastery : 0;
```

In `lib/models/entity_stats.dart`, replace:
```dart
  final int mastery; // Bonus permanent ajouté aux gains d'armure des passifs (voir StatGains)
```
with:
```dart
  final int mastery; // Maîtrise : chaque passif déclare ce qu'un point lui apporte (spec P-49, §6)
```

In `test/unit/stat_gain_single_passage_test.dart`, replace:
```dart
/// (spec P-41, §4.1). Un gain écrit ailleurs échapperait aux règles de classe,
/// comme les gains de cartes, de runes et de reliques échappaient à la
/// Maîtrise d'Armure, appliquée aux seuls passifs.
```
with:
```dart
/// (spec P-41, §4.1). Un gain écrit ailleurs échapperait aux règles de classe
/// que le lot B de P-41 y fera entrer.
```

- [ ] **Step 3: Les trois passifs déclarent leur Maîtrise**

Replace the whole content of `assets/data/passives/regen_armor.json` with:

```json
{
  "id": "regen_armor",
  "name_en": "Armor Regeneration",
  "name_fr": "Régénération d'Armure",
  "description_en": "Gain 2 Block automatically at the end of each turn.",
  "description_fr": "Gagne 2 points d'Armure automatiquement à la fin de chaque tour.",
  "classes": ["paladin"],
  "trigger": "endOfTurn",
  "effectType": "gain_armor",
  "value": 2,
  "mastery": {
    "field": "value",
    "perPoint": 1,
    "description_en": "+{amount} Block at end of turn",
    "description_fr": "+{amount} Armure en fin de tour"
  }
}
```

Replace the whole content of `assets/data/passives/berserker_armor.json` with:

```json
{
  "id": "berserker_armor",
  "name_en": "Berserker Armor",
  "name_fr": "Armure du Berserker",
  "description_en": "Gain 1 Block at the start of your turn for every 10 missing HP.",
  "description_fr": "Gagne 1 point d'Armure au début du tour pour chaque tranche de 10 PV manquants.",
  "classes": ["berserker"],
  "trigger": "startOfTurn",
  "effectType": "berserker_armor",
  "value": 1,
  "mastery": {
    "field": "value",
    "perPoint": 1,
    "description_en": "+{amount} Block per 10 missing HP",
    "description_fr": "+{amount} Armure par tranche de 10 PV manquants"
  }
}
```

Replace the whole content of `assets/data/passives/spell_armor.json` with:

```json
{
  "id": "spell_armor",
  "name_en": "Spell Armor",
  "name_fr": "Armure Magique",
  "description_en": "Gain 1 Block instantly each time you play a Skill card.",
  "description_fr": "Gagne 1 point d'Armure instantanément chaque fois que vous jouez une carte Compétence.",
  "classes": ["mage"],
  "trigger": "onCardPlayed",
  "effectType": "spell_armor",
  "value": 1,
  "mastery": {
    "field": "value",
    "perPoint": 1,
    "description_en": "+{amount} Block per Skill played",
    "description_fr": "+{amount} Armure par Compétence jouée"
  }
}
```

- [ ] **Step 4: Lancer les tests ciblés**

Run: `flutter test test/unit/stat_gains_test.dart test/unit/trait_system_test.dart test/unit/stat_gains_characterization_test.dart test/unit/run_controller_test.dart test/unit/stat_gain_single_passage_test.dart test/unit/real_bundle_load_test.dart`
Expected: PASS, `+58: All tests passed!`

- [ ] **Step 5: Vérification complète**

Run: `git grep -nw "_masteryFor" -- lib test` — Expected: aucune sortie.
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+917: All tests passed!` (916 − 3 tests de `stat_gains_test` fondus dans la boucle des sources + 4 tests de la Maîtrise du répartiteur).

- [ ] **Step 6: Commit**

```bash
git add assets/data/passives lib/game/systems/trait_system.dart lib/game/systems/stat_gains.dart lib/models/entity_stats.dart test/unit/stat_gains_test.dart test/unit/trait_system_test.dart test/unit/stat_gains_characterization_test.dart test/unit/run_controller_test.dart test/unit/stat_gain_single_passage_test.dart
git commit -F- <<'EOF'
feat(maitrise): chaque passif declare ce qu un point lui apporte

TraitSystem applique la Maitrise au parametre que le passif declare,
StatGains n y touche plus. Armure du Berserker compte desormais la
Maitrise a chaque tranche de PV manquants, voulu.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 8: *Affinité* et l'effet de la Maîtrise à l'écran

**Files:**
- Modify: `lib/game/services/level_up_reward_service.dart` (script, commentaires `:122-126`, `:166-169`)
- Modify: `lib/ui/widgets/draft/draft_choice_labels.dart` (réécrit en entier)
- Modify: `lib/ui/widgets/draft/draft_choice_card.dart:49-50`
- Modify: `lib/ui/screens/draft_screen.dart:131`, les trois appels de `getChoiceDescription`, `:644` (script)
- Modify: `lib/tutorial/widgets/tutorial_draft_widget.dart:85`
- Modify: `lib/ui/widgets/map/dialogs/stats_dialog.dart:50-54`, `:185-186`, `:258-265`
- Modify: `lib/ui/screens/class_selection_screen.dart:161-162`, `:401-413`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` ; régénérés : `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_fr.dart`
- Modify: `lib/tutorial/tutorial_data.dart:179-181`, `:189-191`, `:312`, `:317-318`, `:322`, `:327-329`
- Modify: `assets/data/relics/kunai.json:5-6`
- Test: `test/unit/draft_choice_labels_test.dart` *(nouveau)*, `test/unit/level_up_reward_values_test.dart`, `test/widget/class_selection_screen_test.dart`

La spec (§10) place le texte d'*Affinité* dans `test/widget/draft_screen_test.dart`. Ce plan le vérifie dans un test unitaire des libellés : `DraftScreen` tire ses récompenses au hasard, et un test d'écran ne peut pas y forcer *Affinité*. Le branchement du passif actif sur l'écran est vérifié par le compte des trois appels (Step 5).

**Interfaces:**
- Consumes: `PassiveMastery.describe`, `PassiveData.mastery` (Task 1) ; `EntityStats.effectiveMastery` (Task 6).
- Produces:
  - `LevelUpRewardType.affinity` (ex-`steelForge`), `DraftChoice.masteryBoost` (ex-`armorBoost`) ;
  - `DraftChoiceLabels.getChoiceDescription(AppLocalizations l10n, DraftChoice choice, {PassiveData? passive})` ;
  - clés ARB `draftChoiceAffinity`, `draftChoiceAffinityDesc(String passive, String effect)`, `draftChoiceAffinityNoEffect(int amount)`, `passiveMasteryCurrent(String effect)`, `passiveMasteryPerPoint(String effect)` ; `draftChoiceSteelForge` et `draftChoiceSteelForgeDesc` disparaissent.

- [ ] **Step 1: Renommer la récompense**

Run this script from the repository root:

```bash
python - <<'EOF'
import subprocess

RENAMES = [("steelForge", "affinity"), ("armorBoost", "masteryBoost")]
files = subprocess.run(
    ["git", "grep", "-lE", "steelForge|armorBoost", "--", "lib", "test"],
    capture_output=True, text=True, check=True,
).stdout.split()
for path in files:
    with open(path, encoding="utf-8", newline="") as f:
        text = f.read()
    new = text
    for old, repl in RENAMES:
        new = new.replace(old, repl)
    if new != text:
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(new)
        print(path)
EOF
```

Expected: `level_up_reward_service.dart`, `draft_choice_labels.dart`, `draft_screen.dart` et `level_up_reward_values_test.dart` listés.

In `lib/game/services/level_up_reward_service.dart`, replace:
```dart
      // `if` qui avait laisse passer l'absence du palier legendaire sur la
      // Maitrise d'Armure ci-dessous, ou un legendaire retombait sur la
      // valeur d'un commun.
```
with:
```dart
      // `if` qui avait laisse passer l'absence du palier legendaire sur
      // l'Affinite ci-dessous, alors Forge d'Acier, ou un legendaire
      // retombait sur la valeur d'un commun.
```
and replace:
```dart
        // La Maitrise d'Armure a sa propre courbe : elle s'ajoute a *chaque*
        // gain d'armure du passif, donc a chaque tour pour le Paladin mais a
        // chaque Competence jouee pour le Mage. Elle compose plus fort que
        // les autres recompenses, d'ou une progression distincte.
```
with:
```dart
        // L'Affinite a sa propre courbe : la Maitrise augmente le parametre
        // du passif a *chacun* de ses declenchements — chaque tour pour le
        // Paladin, chaque Competence jouee pour le Mage (spec P-49, §6). Elle
        // compose plus fort que les autres recompenses, d'ou une progression
        // distincte.
```

In `test/unit/level_up_reward_values_test.dart`, replace:
```dart
/// laissé la Forge d'Acier légendaire retomber sur la valeur d'un commun
```
with:
```dart
/// laissé la Forge d'Acier — aujourd'hui l'Affinité — légendaire retomber sur la valeur d'un commun
```
replace:
```dart
/// et des tables propres pour Forge d'Acier, Précision et Férocité. Les
```
with:
```dart
/// et des tables propres pour Affinité, Précision et Férocité. Les
```
and replace:
```dart
    test('la Forge d\'Acier légendaire vaut plus que l\'épique', () {
      // Non-régression directe du défaut trouvé : la cascade de `if` sans
      // palier légendaire renvoyait 1, soit la valeur d'un commun.
      final forge = _attendu[LevelUpRewardType.affinity]!;
      expect(forge[RewardRarity.legendary], greaterThan(forge[RewardRarity.epic]!));
      expect(forge[RewardRarity.legendary], isNot(forge[RewardRarity.common]));
    });
```
with:
```dart
    test('l\'Affinité légendaire vaut plus que l\'épique', () {
      // Non-régression directe du défaut trouvé : la cascade de `if` sans
      // palier légendaire renvoyait 1, soit la valeur d'un commun.
      final affinity = _attendu[LevelUpRewardType.affinity]!;
      expect(affinity[RewardRarity.legendary], greaterThan(affinity[RewardRarity.epic]!));
      expect(affinity[RewardRarity.legendary], isNot(affinity[RewardRarity.common]));
    });
```

- [ ] **Step 2: Les textes ARB**

In `lib/l10n/app_en.arb`, replace:
```json
  "draftChoiceSteelForge": "Steel Forge",
  "draftChoiceSteelForgeDesc": "+{amount} to your passive's Block gain",
  "@draftChoiceSteelForgeDesc": {
    "placeholders": {
      "amount": { "type": "int" }
    }
  },
```
with:
```json
  "draftChoiceAffinity": "Affinity",
  "draftChoiceAffinityDesc": "{passive}: {effect}",
  "@draftChoiceAffinityDesc": {
    "placeholders": {
      "passive": { "type": "String" },
      "effect": { "type": "String" }
    }
  },
  "draftChoiceAffinityNoEffect": "+{amount} Mastery, no effect on your passive",
  "@draftChoiceAffinityNoEffect": {
    "placeholders": {
      "amount": { "type": "int" }
    }
  },
```
and replace:
```json
  "classPassive": "Class Passive",
```
with:
```json
  "classPassive": "Class Passive",
  "passiveMasteryCurrent": "Mastery: {effect}",
  "@passiveMasteryCurrent": {
    "placeholders": {
      "effect": { "type": "String" }
    }
  },
  "passiveMasteryPerPoint": "Per Mastery point: {effect}",
  "@passiveMasteryPerPoint": {
    "placeholders": {
      "effect": { "type": "String" }
    }
  },
```

In `lib/l10n/app_fr.arb`, replace:
```json
  "draftChoiceSteelForge": "Forge d'Acier",
  "draftChoiceSteelForgeDesc": "+{amount} aux gains d'Armure de votre passif",
```
with:
```json
  "draftChoiceAffinity": "Affinité",
  "draftChoiceAffinityDesc": "{passive} : {effect}",
  "draftChoiceAffinityNoEffect": "+{amount} Maîtrise, sans effet sur votre passif",
```
and replace:
```json
  "classPassive": "Effet Passif",
```
with:
```json
  "classPassive": "Effet Passif",
  "passiveMasteryCurrent": "Maîtrise : {effect}",
  "passiveMasteryPerPoint": "Par point de Maîtrise : {effect}",
```

Run: `flutter gen-l10n`
Expected: aucune erreur ; les trois fichiers `lib/l10n/app_localizations*.dart` gagnent les cinq nouvelles clés et perdent `draftChoiceSteelForge` et `draftChoiceSteelForgeDesc`.

- [ ] **Step 3: Écrire le test des libellés, qui échoue**

Create `test/unit/draft_choice_labels_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/level_up_reward_service.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/ui/widgets/draft/draft_choice_labels.dart';

/// Affinité se décrit par le passif actif (spec P-49, §6.5).
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  const affinity = DraftChoice(
    type: LevelUpRewardType.affinity,
    masteryBoost: 2,
  );

  PassiveData regen({int perPoint = 1}) => PassiveData(
        id: 'regen_armor',
        nameEn: 'Armor Regeneration',
        nameFr: "Régénération d'Armure",
        trigger: RelicTrigger.endOfTurn,
        effectType: 'gain_armor',
        value: 2,
        mastery: PassiveMastery(
          field: 'value',
          perPoint: perPoint,
          descriptionEn: '+{amount} Block at end of turn',
          descriptionFr: '+{amount} Armure en fin de tour',
        ),
      );

  test('le titre', () {
    expect(DraftChoiceLabels.getChoiceTitle(fr, affinity), 'Affinité');
    expect(DraftChoiceLabels.getChoiceTitle(en, affinity), 'Affinity');
  });

  test('la description : le passif actif et l effet de la Maitrise tiree', () {
    expect(
      DraftChoiceLabels.getChoiceDescription(fr, affinity, passive: regen()),
      "Régénération d'Armure : +2 Armure en fin de tour",
    );
    expect(
      DraftChoiceLabels.getChoiceDescription(en, affinity, passive: regen()),
      'Armor Regeneration: +2 Block at end of turn',
    );
  });

  test('perPoint multiplie la valeur tiree', () {
    expect(
      DraftChoiceLabels.getChoiceDescription(
        fr,
        affinity,
        passive: regen(perPoint: 2),
      ),
      "Régénération d'Armure : +4 Armure en fin de tour",
    );
  });

  test('sans passif, ou avec un passif sans mastery : sans effet', () {
    expect(
      DraftChoiceLabels.getChoiceDescription(fr, affinity),
      '+2 Maîtrise, sans effet sur votre passif',
    );
    const bare = PassiveData(
      id: 'bare',
      trigger: RelicTrigger.endOfTurn,
      effectType: 'gain_armor',
      value: 1,
    );
    expect(
      DraftChoiceLabels.getChoiceDescription(en, affinity, passive: bare),
      '+2 Mastery, no effect on your passive',
    );
  });

  test('les autres recompenses ignorent le passif', () {
    const vitality = DraftChoice(type: LevelUpRewardType.vitality, pvBoost: 5);
    expect(
      DraftChoiceLabels.getChoiceDescription(fr, vitality, passive: regen()),
      DraftChoiceLabels.getChoiceDescription(fr, vitality),
    );
  });
}
```

Run: `flutter test test/unit/draft_choice_labels_test.dart`
Expected: FAIL à la compilation — `getChoiceDescription` n'a pas de paramètre `passive`, et `draftChoiceSteelForge` n'existe plus.

- [ ] **Step 4: Les libellés**

Replace the whole content of `lib/ui/widgets/draft/draft_choice_labels.dart` with:

```dart
import '../../../game/services/level_up_reward_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/data/passive_data.dart';

/// Dérive les libellés localisés d'un [DraftChoice] (titre, description et
/// rareté) tel que généré par [LevelUpRewardService.generateChoices].
///
/// Extrait de `DraftScreen` (`_getChoiceTitle` / `_getChoiceDescription` /
/// `_rarityToString`) pour être partagé, à l'identique, avec
/// `TutorialDraftWidget` : les deux doivent afficher exactement les mêmes
/// libellés pour un même [DraftChoice], sans dupliquer la correspondance
/// type -> texte localisé. Ne dépend que d'[AppLocalizations] et des
/// modèles — jamais de `BuildContext` ni de Riverpod, pour rester
/// consommable depuis `lib/tutorial/`.
class DraftChoiceLabels {
  const DraftChoiceLabels._();

  /// Libellé de rareté affiché sur la carte de draft.
  static String rarityToString(AppLocalizations l10n, RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.mythic:
        return l10n.localeName == 'fr' ? 'MYTHIQUE' : 'MYTHIC';
      case RewardRarity.legendary:
        return l10n.rarityLegendary;
      case RewardRarity.epic:
        return l10n.rarityEpic;
      case RewardRarity.rare:
        return l10n.rarityRare;
      case RewardRarity.uncommon:
        return l10n.rarityUncommon;
      case RewardRarity.common:
        return l10n.rarityCommon;
    }
  }

  /// Titre affiché pour ce choix de draft.
  static String getChoiceTitle(AppLocalizations l10n, DraftChoice choice) {
    switch (choice.type) {
      case LevelUpRewardType.vitality:
        return l10n.draftChoiceVitality;
      case LevelUpRewardType.sharpening:
        return l10n.draftChoiceSharpening;
      case LevelUpRewardType.affinity:
        return l10n.draftChoiceAffinity;
      case LevelUpRewardType.wisdom:
        return l10n.draftChoiceWisdom;
      case LevelUpRewardType.luckyClover:
        return l10n.draftChoiceClover;
      case LevelUpRewardType.mirror:
        return l10n.draftChoiceMirror;
      case LevelUpRewardType.precision:
        return l10n.draftChoicePrecision;
      case LevelUpRewardType.ferocity:
        return l10n.draftChoiceFerocity;
    }
  }

  /// Description (avec la valeur du gain) affichée pour ce choix de draft.
  ///
  /// [passive] est le passif actif : *Affinité* se décrit par ce que la
  /// Maîtrise tirée lui apporte (spec P-49, §6.5). Les autres récompenses
  /// l'ignorent.
  static String getChoiceDescription(
    AppLocalizations l10n,
    DraftChoice choice, {
    PassiveData? passive,
  }) {
    switch (choice.type) {
      case LevelUpRewardType.vitality:
        return l10n.draftChoiceVitalityDesc(choice.pvBoost);
      case LevelUpRewardType.sharpening:
        return l10n.draftChoiceSharpeningDesc(choice.atkBoost);
      case LevelUpRewardType.affinity:
        final mastery = passive?.mastery;
        if (passive == null || mastery == null) {
          return l10n.draftChoiceAffinityNoEffect(choice.masteryBoost);
        }
        return l10n.draftChoiceAffinityDesc(
          passive.getName(l10n.localeName),
          mastery.describe(l10n.localeName, choice.masteryBoost),
        );
      case LevelUpRewardType.wisdom:
        return l10n.draftChoiceWisdomDesc(choice.manaBoost);
      case LevelUpRewardType.luckyClover:
        return l10n.draftChoiceCloverDesc(choice.luckBoost);
      case LevelUpRewardType.mirror:
        return l10n.draftChoiceMirrorDesc;
      case LevelUpRewardType.precision:
        return l10n.draftChoicePrecisionDesc(choice.critChanceBoost);
      case LevelUpRewardType.ferocity:
        return l10n.draftChoiceFerocityDesc(
          (choice.critDamageBoost * 100).round(),
        );
    }
  }
}
```

Run: `flutter test test/unit/draft_choice_labels_test.dart`
Expected: PASS, `+5: All tests passed!`

- [ ] **Step 5: Passer le passif actif aux libellés, et l'icône**

In `lib/ui/screens/draft_screen.dart`, replace:
```dart
    final l10n = AppLocalizations.of(context)!;
    final visibleChoices = _mythicCompleted ? _choices : _choices.sublist(0, 3);
```
with:
```dart
    final l10n = AppLocalizations.of(context)!;
    // Affinité se décrit par le passif actif (spec P-49, §6.5).
    final activePassive = ref.watch(runProvider).activePassive;
    final visibleChoices = _mythicCompleted ? _choices : _choices.sublist(0, 3);
```
Then, in each of the **three** calls `DraftChoiceLabels.getChoiceDescription(` of that file (vers les lignes 228, 319 et 443), add the named argument `passive: activePassive,` on its own line right after the `choice,` argument, at the same indentation.
Vérifier : `grep -c "passive: activePassive" lib/ui/screens/draft_screen.dart` — Expected: `3`.

In `lib/tutorial/widgets/tutorial_draft_widget.dart`, replace:
```dart
                        final desc = DraftChoiceLabels.getChoiceDescription(l10n, choice);
```
with:
```dart
                        final desc = DraftChoiceLabels.getChoiceDescription(
                          l10n,
                          choice,
                          passive: widget.engine.mockState.activePassive,
                        );
```

In `lib/ui/widgets/draft/draft_choice_card.dart`, replace:
```dart
    } else if (titleUpper.contains('FORGE')) {
      emoji = '🛡️'; // Armor Mastery
```
with:
```dart
    } else if (titleUpper.contains('AFFINIT')) {
      emoji = '💠'; // Affinity / Mastery
```

- [ ] **Step 6: La fiche des stats et l'écran de sélection**

In `lib/ui/widgets/map/dialogs/stats_dialog.dart`, replace:
```dart
    final stats = runState.heroStats;
```
with:
```dart
    final stats = runState.heroStats;
    // L'effet de la Maîtrise acquise sur le passif actif, s'il en tire un
    // (spec P-49, §6.5).
    final mastery = passive?.mastery;
    final masteryEffect = mastery != null && stats.effectiveMastery > 0
        ? mastery.describe(locale, stats.effectiveMastery)
        : null;
```
Replace:
```dart
                    subtitle:
                        locale == 'fr' ? "Sur l'Armure Passive" : "On passive armor",
```
with:
```dart
                    subtitle: locale == 'fr' ? 'Sur votre passif' : 'On your passive',
```
Replace:
```dart
                  const SizedBox(height: 6),
                  Text(
                    traitDesc,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.cyanAccent.withValues(alpha: 0.8),
                      height: 1.3,
                    ),
                  ),
```
with:
```dart
                  const SizedBox(height: 6),
                  Text(
                    traitDesc,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.cyanAccent.withValues(alpha: 0.8),
                      height: 1.3,
                    ),
                  ),
                  if (masteryEffect != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.passiveMasteryCurrent(masteryEffect),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent.withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                    ),
                  ],
```

In `lib/ui/screens/class_selection_screen.dart`, replace:
```dart
    final String traitName = passive?.getName(locale) ?? '—';
    final String traitDesc = passive?.getDescription(locale) ?? '';
```
with:
```dart
    final String traitName = passive?.getName(locale) ?? '—';
    final String traitDesc = passive?.getDescription(locale) ?? '';
    // Ce qu'un point de Maîtrise apporte au passif (spec P-49, §6.5).
    final String? masteryPerPoint = passive?.mastery?.describe(locale, 1);
    final l10n = AppLocalizations.of(context)!;
```
and replace:
```dart
                                      Text(
                                        traitDesc,
                                        style: TextStyle(
                                          fontSize: widget.isMobile
                                              ? 9.5
                                              : 10.5,
                                          color: Colors.cyanAccent.withValues(
                                            alpha: 0.85,
                                          ),
                                          height: 1.25,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
```
with:
```dart
                                      Text(
                                        traitDesc,
                                        style: TextStyle(
                                          fontSize: widget.isMobile
                                              ? 9.5
                                              : 10.5,
                                          color: Colors.cyanAccent.withValues(
                                            alpha: 0.85,
                                          ),
                                          height: 1.25,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (masteryPerPoint != null) ...[
                                        SizedBox(
                                          height: widget.isMobile ? 1 : 3,
                                        ),
                                        Text(
                                          l10n.passiveMasteryPerPoint(
                                            masteryPerPoint,
                                          ),
                                          style: TextStyle(
                                            fontSize: widget.isMobile
                                                ? 9
                                                : 10,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.cyanAccent.withValues(
                                              alpha: 0.7,
                                            ),
                                            height: 1.2,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
```

In `test/widget/class_selection_screen_test.dart`, add this test inside the group `le passif montre est lu par le point d acces unique`, after its last test:

```dart
    testWidgets('le passif dit ce qu un point de Maitrise lui apporte', (
      WidgetTester tester,
    ) async {
      const regen = PassiveData(
        id: 'regen_armor',
        nameEn: 'Armor Regeneration',
        nameFr: "Régénération d'Armure",
        classes: ['paladin'],
        trigger: RelicTrigger.endOfTurn,
        effectType: 'gain_armor',
        value: 2,
        mastery: PassiveMastery(
          field: 'value',
          perPoint: 1,
          descriptionEn: '+{amount} Block at end of turn',
          descriptionFr: '+{amount} Armure en fin de tour',
        ),
      );
      await _buildAndReady(tester, passives: const [regen]);
      expect(
        find.text('Per Mastery point: +1 Block at end of turn'),
        findsOneWidget,
      );
    });
```

Run: `flutter test test/widget/class_selection_screen_test.dart test/widget/draft_screen_test.dart`
Expected: PASS, `+14: All tests passed!`, sans exception de débordement.

- [ ] **Step 7: Les textes du jeu**

In `assets/data/relics/kunai.json`, replace:
```json
  "description_en": "Every 3 Attacks played in a turn, gain 1 Armor Mastery for combat.",
  "description_fr": "Toutes les 3 attaques jouées dans un tour, gagne 1 Maîtrise d'Armure pour le combat.",
```
with:
```json
  "description_en": "Every 3 Attacks played in a turn, gain 1 Mastery for combat.",
  "description_fr": "Toutes les 3 attaques jouées dans un tour, gagne 1 Maîtrise pour le combat.",
```

In `lib/tutorial/tutorial_data.dart`, replace:
```dart
        'What your class changes is *how you earn it*: that is your passive. '
        'Armor Mastery, a permanent stat, is added to every Armor gain your '
        'passive produces.',
```
with:
```dart
        'What your class changes is *how you earn it*: that is your passive. '
        'Mastery, a permanent stat, strengthens what your passive produces — '
        'each passive states what one point adds.',
```
Replace:
```dart
        'votre passif. La Maîtrise d\'Armure, statistique permanente, s\'ajoute '
        'à chaque gain d\'Armure produit par votre passif.',
```
with:
```dart
        'votre passif. La Maîtrise, statistique permanente, renforce ce que '
        'produit votre passif — chaque passif indique ce qu\'un point lui '
        'apporte.',
```
Replace:
```dart
        'Vitality, Sharpening, Steel Forge, Wisdom, Precision, Ferocity — and '
```
with:
```dart
        'Vitality, Sharpening, Affinity, Wisdom, Precision, Ferocity — and '
```
Replace:
```dart
        'Careful with Steel Forge: it grants **Armor Mastery**, added to the '
        'Armor your passive produces — not a flat block of Armor.',
```
with:
```dart
        'Careful with Affinity: it grants **Mastery**, which strengthens what '
        'your passive produces — each passive states what one point adds.',
```
Replace:
```dart
        'six types — Vitalité, Aiguisage, Forge d\'Acier, Sagesse, Précision, '
```
with:
```dart
        'six types — Vitalité, Aiguisage, Affinité, Sagesse, Précision, '
```
Replace:
```dart
        'Attention à la Forge d\'Acier : elle donne de la **Maîtrise d\'Armure**, '
        'ajoutée à l\'Armure que produit votre passif — pas un bloc d\'Armure '
        'directe.',
```
with:
```dart
        'Attention à l\'Affinité : elle donne de la **Maîtrise**, qui renforce '
        'ce que produit votre passif — chaque passif indique ce qu\'un point '
        'lui apporte.',
```

- [ ] **Step 8: Vérification complète**

Run: `git grep -nwE "steelForge|armorBoost|draftChoiceSteelForge|draftChoiceSteelForgeDesc" -- lib test` — Expected: aucune sortie.
Run: `git grep -nE "Armor Mastery|Steel Forge|Maîtrise d.Armure" -- lib test assets ":!assets/data/patch_notes.json"` — Expected: aucune sortie.
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+923: All tests passed!` (917 + 5 de libellés + 1 de l'écran de sélection), `test/tutorial/` compris.

- [ ] **Step 9: Commit**

```bash
git add lib/game/services/level_up_reward_service.dart lib/ui/widgets/draft lib/ui/screens/draft_screen.dart lib/tutorial lib/ui/widgets/map/dialogs/stats_dialog.dart lib/ui/screens/class_selection_screen.dart lib/l10n assets/data/relics/kunai.json test/unit/draft_choice_labels_test.dart test/unit/level_up_reward_values_test.dart test/widget/class_selection_screen_test.dart
git status --short
git commit -F- <<'EOF'
feat(maitrise): Affinite, et l effet de la Maitrise affiche

La Forge d Acier devient Affinite, a valeurs identiques ; sa carte
dit ce que la Maitrise tiree apporte au passif actif. La fiche des
stats et l ecran de selection montrent l effet de la Maitrise. Textes
du tutoriel et du Croc Kunai alignes.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 9: Vérification finale et livraison

**Files:**
- Modify: `docs/superpowers/specs/2026-09-16-p49-passifs-partages-design.md:4`, `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md:4`
- Géré par skills : `.obsidian_vault/`, `docs/ROADMAP.md`, `assets/data/patch_notes.json`

**Interfaces:**
- Consumes: tout le lot.
- Produces: une branche prête à la PR.

- [ ] **Step 1: Vérifications propres au lot**

Aucun fichier de `lib/`, `test/` ni `assets/` n'a changé depuis la vérification complète de Task 8 Step 8 : ne relancer ni `dart analyze` ni la suite, reprendre le total qu'elle a affiché : `+923`.
Run: `git grep -nwE "passiveTrait|armorMastery|effectiveArmorMastery|armorAcc|steelForge|armorBoost|_masteryFor" -- lib test assets` — Expected: aucune sortie.
Run: `git grep -nE "TraitSystem\.on(TurnStart|TurnEnd|CardPlayed)|armor_mastery" -- lib test assets` — Expected: aucune sortie.

- [ ] **Step 2: Mettre à jour le statut des deux specs**

In `docs/superpowers/specs/2026-09-16-p49-passifs-partages-design.md`, replace:
```markdown
Statut : **Conçue, non implémentée**
```
with:
```markdown
Statut : **Implémentée** (branche `feat/p49-passifs-partages`)
```

In `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md`, replace:
```markdown
Statut : **Lot A implémenté** (fusionné dans `main`, PR #38) — lots B à D et chantier frère P-49 non implémentés ; P-49 conçu dans sa [spec de P-49](2026-09-16-p49-passifs-partages-design.md)
```
with:
```markdown
Statut : **Lot A implémenté** (fusionné dans `main`, PR #38) — lots B à D non implémentés ; chantier frère P-49 implémenté (branche `feat/p49-passifs-partages`), voir sa [spec](2026-09-16-p49-passifs-partages-design.md)
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/2026-09-16-p49-passifs-partages-design.md docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md
git commit -F- <<'EOF'
docs(P-49): passifs partages implementes

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

- [ ] **Step 4: Synchroniser la mémoire du projet**

Invoke the `memory-bank-sync` skill. Ce qu'il doit consigner :
- un ADR qui **remplace la décision D4 d'ADR-086** (passifs à plat, éligibilité déclarée par le passif, point d'accès unique) et consigne la **Maîtrise hybride** (une stat, l'effet déclaré par le passif, appliqué avant la stratégie) et le **registre de stratégies de passifs** ; ADR-086 voit son statut pointer vers lui ;
- dans `docs/ROADMAP.md`, section P-13 : cocher « Éligibilité des passifs par classe, déclarée par le passif » et « Point d'accès unique » ; dans le tableau des lots de P-41 : marquer **P-49** livré ;
- les métriques de `progress.md`, que le skill re-mesure lui-même.

- [ ] **Step 5: Note de version — avec l'accord du propriétaire**

**Ne pas invoquer `patch-notes-writer` sans l'accord explicite du propriétaire.** Décision du propriétaire du 2026-09-16 : **pas de nouveau numéro, la note `0.5.2` est rouverte en place** (`docs/ROADMAP.md` §4), ce qui déroge à la règle du skill « ne jamais modifier une entrée existante » — le dire dans l'invocation. `pubspec.yaml` et `site/_site/versions.json` restent à `0.5.2`. Contenu à proposer :
- *Équilibrage* : Armure du Berserker compte la Maîtrise à chaque tranche de 10 PV manquants ;
- *Améliorations* : la Maîtrise d'Armure devient la Maîtrise, qui renforce ce que produit le passif ; la Forge d'Acier devient Affinité, et sa carte dit ce qu'elle apporte au passif ; la fiche des stats et l'écran de sélection montrent l'effet de la Maîtrise.

- [ ] **Step 6: Terminer la branche**

Invoke the `superpowers:finishing-a-development-branch` skill.

---

## Suites relevées, hors de P-49

1. **La référence unique de l'éditeur n'a plus de descripteur livré.** `FieldKind.reference` et la première moitié de la famille 6 ne servent plus qu'à un descripteur de test depuis Task 3. → **P-18 ou P-42**, si une restriction à référence unique y est retenue ; sinon, les retirer.
2. ***Affinité* est tirée même quand le passif actif ne déclare pas `mastery`.** Aucun passif livré n'est dans ce cas, et la carte le dit (« sans effet sur votre passif »). → **lot C de P-41**, avec les récompenses data-driven.
3. **La description d'un passif écrit sa valeur de base en dur** (« Gagne 2 points d'Armure »). Avec de la Maîtrise, la valeur réelle diffère : seule la ligne « Maîtrise : … » de la fiche des stats le dit. → **lot C de P-41** (écran de sélection), ou une génération des descriptions depuis la donnée.
4. **Le tutoriel ne déclenche aucun passif** : aucun appel à `TraitSystem` sous `lib/tutorial/`, antérieur à P-49. → **lot D de P-41**.
