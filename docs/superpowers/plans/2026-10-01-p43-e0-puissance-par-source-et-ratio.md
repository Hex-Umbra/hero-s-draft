# P-43 E0 — Une Puissance par source et le `ratio` de conversion — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Faire retenir à un statut l'identité de ce qui l'a posé, ne plus fusionner que même statut **et** même source — seule la Puissance reçoit une source —, et donner à la règle de classe un `ratio` de conversion, que le Berserker déclare à 0,5 arrondi à l'entier supérieur : *Forme Démoniaque* puis *Mur de Fer* donnent 7 Puissance ce tour-ci, puis 2 pendant trois tours, au lieu de 12 pendant quatre.

**Architecture:** `StatusEffect` gagne un `sourceId` nullable et un prédicat unique, `mergesWith`, que lisent `combine` et `EntityStats.addStatus` ; l'utilitaire `StatusSource`, à côté de lui, est le seul endroit qui écrive les six formes `<nature>:<id>`. Les neuf sites qui fabriquent une Puissance passent chacun leur source ; la fabrique `EffectResolver.createStatus` gagne un paramètre nommé facultatif que seule sa branche `might` retient — la portée « `might` seul » s'écrit là, une fois. `StatRule` gagne `ratio` (]0, 1], refusé par `fromJson`), l'accesseur `statName` et l'arithmétique `convertedAmount`, qu'appellent `StatGains._convert` et `StatRuleLabel.describe` ; `classes/berserker/class.json` déclare `"ratio": 0.5`.

**Tech Stack:** Flutter 3.41 / Dart 3.11, Flame, Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-10-01-p43-e0-puissance-par-source-et-ratio-design.md` — à lire **en entier**, ses arbitrages A1 à A8 compris. Le déroulé du programme fait foi dans `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` (fiche §8.1, partie E0).

## Global Constraints

Celles du fichier d'orchestration, §3.5, recopiées :

- `dart analyze` doit rendre `No issues found!` et `flutter test` être entièrement vert **à la fin de chaque tâche** ;
- **ne rien pousser, n'ouvrir aucune PR, n'invoquer aucun skill de livraison** — ni `finishing-a-development-branch`, ni `patch-notes-writer`, ni `memory-bank-sync` ;
- **jamais `dart format`** ; Write / Edit plutôt que heredoc ;
- les fichiers que `flutter` régénère sont **suivis** par git — `macos/Flutter/GeneratedPluginRegistrant.swift`, et sous `linux/flutter/` et `windows/flutter/` les `generated_plugin_registrant.*` et `generated_plugins.cmake` : ne jamais indexer leur modification (`git add` par chemin, jamais `git add -A`), les restaurer par `git restore` s'ils apparaissent modifiés ;
- après toute retouche d'un fichier ARB : `flutter gen-l10n`, et les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit ;
- après une suppression ou un déplacement sous `assets/` : supprimer `build/unit_test_assets` avant de croire un `real_bundle_load_test` rouge — `flutter test` ne purge jamais ce dossier, et la copie périmée d'un fichier disparu continue d'être chargée ;
- tout texte joueur d'un JSON porte `_fr` **et** `_en` ; un id est le nom de son fichier, en `snake_case` ; un dossier neuf sous `assets/` demande `dart run tool/sync_assets.dart` ;
- les trois couches de `CLAUDE.md` ne se mélangent pas ; pas de code sans lecteur, pas de code mort ;
- commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` ;
- ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/` : ils appartiennent à `patch-notes-writer`.

Propres au lot :

- **La branche.** Le plan s'exécute sur `feat/v0.5.3-p43-e0-e1`, la branche courante. Il **ne crée aucune branche**, ne bascule sur aucune autre, ne commite rien sur `main`. Pas de worktree.
- **La base de tests : 1187**, le total de `flutter test` sur la branche le 2026-10-01 (`f38a0f1`). Chaque tâche donne le total attendu, recompté sur les blocs de test qu'elle écrit — **et mesuré** en rejouant le plan tâche par tâche sur une copie neuve du dépôt à `f38a0f1`, les blocs « replace / with » appliqués tels qu'écrits ici, le 2026-10-02 : 1204, 1212, 1226, 1228, 1228, `dart analyze` propre à chaque tâche, et les sorties attendues de Task 6 constatées.
- **Les `fichier:ligne`** des sections « Files » sont mesurés le 2026-10-01 sur `f38a0f1`, avant toute tâche. Une tâche qui retouche un fichier qu'une tâche précédente a déjà modifié désigne l'endroit par le texte à remplacer : **c'est ce texte qui fait foi**, pas le numéro.
- **Le point propre au lot.** Aucune tâche ne touche `lib/models/data/forge_upgrade_data.dart`, ni le `switch` des runes d'`effect_resolver.dart` (`:142-164`), ni le bloc élémentaire (`:176-220`) — ses trois appels à `createStatus` (`:184`, `:188`, `:192`) ne changent pas, le paramètre neuf étant facultatif. La fabrique `createStatus` (`:16-93`), elle, est dans le lot. `lib/services/content_editor/entity_descriptor.dart` n'est pas touché non plus : `ratio` n'y entre pas (spec A5, §6.1).
- **La simulation.** Aucune tâche ne touche `tool/simulations/d26_economy_sim.dart` ni `tool/simulations/d26_reference_output.md` : le script ignore la clé `ratio`, son taux est en dur (fiche §8.1, spec §9). Aucun réalignement.
- **Changements de jeu voulus, et eux seuls** (spec §4.6 et §10) : deux Puissances de sources différentes ne fusionnent plus ; la Puissance de *Rage* ne s'accumule plus dans une *Forme Démoniaque* ; le Berserker convertit la moitié de son Armure, arrondie au supérieur ; la règle de sa carte de classe et du tutoriel dit son taux ; la Puissance d'Éveil d'un ennemi ne rejoint plus celle de son intention Buff (branche que rien ne pose aujourd'hui). Aucune carte ne change (D37).
- **Sauvegarde : aucune étape de migration**, `SaveMigrator.currentVersion` ne bouge pas (spec §7). Avant la `1.0.0`, une sauvegarde n'a pas à survivre à un changement de version.
- **Le passage unique d'ADR-095 tient** : la conversion reste dans `StatGains.apply`, `test/unit/stat_gain_single_passage_test.dart` n'est pas touché et reste vert.
- **Le tutoriel ne référence aucun provider** (ADR-081), vérifié par `test/tutorial/tutorial_isolation_test.dart`.

## Review Focus

Les cinq cas que la spec implique sans qu'un test de son §8 les pose, les plus susceptibles de mordre un joueur ; chacun a son test dans la tâche qui possède le code :

1. **La même source rejouée après un tic** — deux *Forme Démoniaque* jouées à un tour d'écart doivent faire **une** entrée de 4, la source traversant le `copyWith` de `tickStatuses`. Test : Task 1, `status_source_test.dart`, groupe « la meme carte rejouee ».
2. **Un même passif déclenché d'un tour à l'autre** — *Ferveur*, encore active, rejoint son entrée et prend la plus longue durée, au lieu d'en ouvrir une seconde. Test : Task 2, `passives_paladin_test.dart`.
3. **Une relique dont le seuil est atteint deux fois** — *Shuriken* fait une entrée `relic:shuriken` de 2 pour le combat, et ses charges, posées sans source, restent une seule entrée que le compteur lit par `first`. Test : Task 2, `stat_gains_characterization_test.dart`.
4. **Une sauvegarde d'avant E0 et une run rechargée** — un statut sans clé `sourceId` se relit sans source ; une règle reconstruite depuis le registre doit être égale à la règle de la classe, ratio compris (`class_identity_test.dart`, groupe de `fromJsonWithReport`, reste vert parce que `==` compte le ratio). Tests : Task 1 (JSON) et Task 3 (`==` et `hashCode`).
5. **Un produit flottant à la frontière** — `0.1 × 30` doit donner 3 et non 4, et l'exemple que lit le joueur doit sortir de la même fonction que le moteur. Tests : Task 3 (`convertedAmount`), Task 4 (`describe`).

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/models/status_effect.dart` | `StatusSource` (formes carte et règle, puis passif, relique, statut, ennemi), `StatusEffect.sourceId`, JSON, `mergesWith`, `combine` | 1, 2 |
| `lib/models/entity_stats.dart` | `addStatus` : même statut et même source | 1 |
| `lib/models/data/stat_rule.dart` | `statName` (1) ; `ratio`, sa borne, `convertedAmount`, `==`, `hashCode`, `toString` (3) | 1, 3 |
| `lib/game/systems/stat_gains.dart` | `_convert` : source `rule:<ressource>` (1), montant par le ratio (3) | 1, 3 |
| `lib/game/services/effect_resolver.dart` | `createStatus` : paramètre nommé facultatif `sourceId`, retenu par la seule branche `might` | 1 |
| `lib/game/services/effects/strategies.dart` | La carte passe `card:<id>` | 1 |
| `lib/game/systems/passives/passive_strategies.dart` | `_temporaryMight` reçoit le passif, pose `passive:<id>` | 2 |
| `lib/game/controllers/run/player_stats_manager.dart` | Trois Puissances de relique, `relic:<id>` | 2 |
| `lib/game/controllers/combat/status_effect_processor.dart` | Éveil de Puissance, héros et ennemi, `status:might_regen` | 2 |
| `lib/game/controllers/combat/turn_phase_manager.dart` | Intention Buff, `enemy:<id>` | 2 |
| `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_localizations*.dart` | `statRuleRatioArmor`, `statRuleRatioMana` | 4 |
| `lib/models/data/model_extensions.dart` | `StatRuleLabel.describe` : la seconde phrase | 4 |
| `assets/data/classes/berserker/class.json` | `"ratio": 0.5` | 5 |
| `lib/tutorial/widgets/tutorial_armor_widget.dart` | Hauteur du cadre d'une classe à règle, 480 → 510 | 5 |
| `lib/tutorial/tutorial_engine.dart` | Commentaire « +2 puis +4 Puissance » | 5 |
| `test/unit/status_source_test.dart` *(nouveau)* | Fusion par source, JSON, formes, le cas de D36 | 1, 2, 3 |
| `test/unit/effect_resolver_test.dart`, `test/unit/might_orientation_test.dart`, `test/widget/status_effects_panel_overflow_test.dart` | La fabrique, la carte, le panneau | 1 |
| `test/unit/stat_rule_conversion_test.dart`, `test/unit/stat_rule_vocabulary_test.dart` | La règle au gain ; `statName`, `toString` | 1, 3 |
| `test/unit/passives_berserker_test.dart`, `test/unit/passives_paladin_test.dart`, `test/unit/stat_gains_characterization_test.dart`, `test/unit/combat_controller_test.dart` | Passifs, reliques, Éveil, ennemi | 2 |
| `test/unit/stat_rule_test.dart`, `test/unit/content_editor/entity_validator_test.dart`, `test/widget/debug_drawer_test.dart` | `ratio`, sa borne, son arithmétique ; l'éditeur ; le debug | 3 |
| `test/unit/stat_rule_label_test.dart` | Les deux phrases | 4 |
| `test/unit/class_identity_test.dart`, `test/tutorial/tutorial_engine_test.dart`, `test/widget/tutorial_armor_step_test.dart`, `test/widget/tutorial_play_card_step_test.dart`, `test/widget/class_selection_screen_test.dart` | Le vrai Berserker à 0,5 | 5 |

---

### Task 1: Une Puissance par source — le modèle, la carte et la conversion

Le cœur de D36 : un statut retient ce qui l'a posé, et deux Puissances de sources différentes ne se confondent plus. Cette tâche donne leur source aux deux poseurs du cas de D36 — la carte (*Forme Démoniaque*) et la règle de classe (la conversion de *Mur de Fer*) ; Task 2 fait les sept autres. Tout statut posé sans source fusionne comme avant (A1).

**Files:**
- Modify: `lib/models/status_effect.dart` (réécrit en entier, 79 lignes aujourd'hui)
- Modify: `lib/models/entity_stats.dart:133-135`
- Modify: `lib/models/data/stat_rule.dart:68-69` (ajout après)
- Modify: `lib/game/systems/stat_gains.dart:95-106`
- Modify: `lib/game/services/effect_resolver.dart:15-16`, `:26-33`
- Modify: `lib/game/services/effects/strategies.dart:3`, `:164-169`
- Test: `test/unit/status_source_test.dart` *(nouveau)*
- Test: `test/unit/effect_resolver_test.dart:1`, `:233-237` ; `test/unit/might_orientation_test.dart:229-232` ; `test/unit/stat_rule_conversion_test.dart:87-92` ; `test/unit/stat_rule_vocabulary_test.dart:60-70` ; `test/widget/status_effects_panel_overflow_test.dart:4`, `:114-126`

**Interfaces:**
- Consumes: rien.
- Produces:
  - `abstract final class StatusSource` dans `lib/models/status_effect.dart` — `static String card(String cardId)` → `'card:<cardId>'` ; `static String rule(String resource)` → `'rule:<resource>'`. Task 2 y ajoute quatre formes.
  - `StatusEffect.sourceId` (`String?`) — paramètre nommé facultatif du constructeur `const` et de `copyWith` ; clé JSON `sourceId`, écrite seulement si non nulle, `null` si absente à la lecture.
  - `bool StatusEffect.mergesWith(StatusEffect other)` — même `id` et même `sourceId`, `null` compris ; lu par `combine` et `EntityStats.addStatus`.
  - `String get StatRule.statName` — la ressource dans le vocabulaire du fichier (`'armor'`, `'mana'`).
  - `static StatusEffect? EffectResolver.createStatus(String statusId, int value, int duration, {String? sourceId})`.

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/unit/status_source_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

/// Un statut retient ce qui l'a posé, et ne rejoint qu'une entrée de même
/// statut et de même source (spec P-43 E0, D36, §4.1 à §4.3).
void main() {
  StatusEffect might(int value, int duration, {String? sourceId}) =>
      StatusEffect(
        id: 'might',
        name: 'Puissance',
        type: StatusType.buff,
        value: value,
        duration: duration,
        sourceId: sourceId,
      );

  EntityStats hero([List<StatusEffect> statuses = const []]) => EntityStats(
        maxPv: 80,
        currentPv: 80,
        armure: 0,
        might: 0,
        statuses: statuses,
      );

  List<StatusEffect> mightOf(EntityStats stats) =>
      stats.statuses.where((s) => s.id == 'might').toList();

  final demonForm = StatusSource.card('demon_form');
  final armorRule = StatusSource.rule('armor');

  group('StatusSource', () {
    test('les formes de la carte et de la regle', () {
      expect(StatusSource.card('demon_form'), 'card:demon_form');
      expect(StatusSource.rule('armor'), 'rule:armor');
    });
  });

  group('addStatus', () {
    test('meme statut et meme source : une entree, valeurs additionnees, duree la plus longue', () {
      final stats = hero()
          .addStatus(might(2, 4, sourceId: demonForm))
          .addStatus(might(3, 1, sourceId: demonForm));

      expect(mightOf(stats), hasLength(1));
      expect(mightOf(stats).single.value, 2 + 3);
      expect(mightOf(stats).single.duration, 4);
    });

    test('sources differentes : deux entrees, chacune sa duree', () {
      final stats = hero()
          .addStatus(might(2, 4, sourceId: demonForm))
          .addStatus(might(5, 1, sourceId: armorRule));

      expect(
        mightOf(stats).map((s) => (s.sourceId, s.value, s.duration)),
        [(demonForm, 2, 4), (armorRule, 5, 1)],
      );
    });

    // A1 : hors de la Puissance, rien ne bouge — les statuts sont posés sans
    // source et fusionnent entre eux comme avant.
    test('deux statuts sans source fusionnent comme avant', () {
      const poison = StatusEffect(
        id: 'poison',
        name: 'Poison',
        type: StatusType.debuff,
        value: 3,
        duration: 2,
      );
      final stats = hero().addStatus(poison).addStatus(poison);

      expect(stats.statuses, hasLength(1));
      expect(stats.statuses.single.value, 3 + 3);
      expect(stats.statuses.single.sourceId, isNull);
    });

    test('un statut sans source ne rejoint pas une entree qui en a une', () {
      final stats = hero()
          .addStatus(might(2, 4, sourceId: demonForm))
          .addStatus(might(1, 1));

      expect(mightOf(stats), hasLength(2));
    });
  });

  group('combine', () {
    test('rend l effet inchange si les sources different', () {
      final combined = might(2, 4, sourceId: demonForm)
          .combine(might(5, 1, sourceId: armorRule));

      expect(combined.value, 2);
      expect(combined.duration, 4);
      expect(combined.sourceId, demonForm);
    });
  });

  group('lecture et vieillissement', () {
    test('effectiveMight somme les entrees de toutes les sources', () {
      final stats = hero([
        might(2, 4, sourceId: demonForm),
        might(5, 1, sourceId: armorRule),
      ]);

      expect(stats.effectiveMight, 2 + 5);
    });

    test('tickStatuses vieillit chaque entree separement, sa source avec elle', () {
      final stats = hero([
        might(2, 4, sourceId: demonForm),
        might(5, 1, sourceId: armorRule),
      ]).tickStatuses();

      expect(mightOf(stats), hasLength(1));
      expect(mightOf(stats).single.sourceId, demonForm);
      expect(mightOf(stats).single.duration, 3);
    });
  });

  group('JSON', () {
    test('aller-retour avec une source', () {
      final restored =
          StatusEffect.fromJson(might(2, 4, sourceId: demonForm).toJson());

      expect(restored.sourceId, demonForm);
      expect(restored.value, 2);
      expect(restored.duration, 4);
    });

    test('une sauvegarde sans la cle se relit sans source', () {
      final restored = StatusEffect.fromJson(const {
        'id': 'might',
        'name': 'Puissance',
        'type': 'buff',
        'value': 2,
        'duration': 4,
        'isStackable': true,
      });

      expect(restored.sourceId, isNull);
    });

    test('aucune cle ecrite sans source', () {
      expect(might(2, 4).toJson().containsKey('sourceId'), isFalse);
    });
  });

  group('la meme carte rejouee', () {
    // D36 : « la même carte rejouée s'additionne comme aujourd'hui ». La
    // source traverse le tic, que `tickStatuses` reconstruit par `copyWith`.
    test('deux Forme Demoniaque a un tic d ecart : une entree de 4', () {
      final stats = hero()
          .addStatus(might(2, 4, sourceId: demonForm))
          .tickStatuses()
          .addStatus(might(2, 4, sourceId: demonForm));

      expect(mightOf(stats), hasLength(1));
      expect(mightOf(stats).single.value, 2 + 2);
      expect(mightOf(stats).single.duration, 4);
    });
  });
}
```

In `test/unit/effect_resolver_test.dart`, replace:
```dart
import 'package:flutter_test/flutter_test.dart';
```
with:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
```
and replace the end of the file:
```dart
        expect(eliteEnemy.effectiveIntent?.value, 29);
      },
    );
  });
}
```
with:
```dart
        expect(eliteEnemy.effectiveIntent?.value, 29);
      },
    );
  });

  // La portée de la règle s'écrit dans la fabrique, une fois (spec P-43 E0,
  // A1 et §4.4) : seule la Puissance retient sa source.
  group('EffectResolver.createStatus', () {
    test('la Puissance retient sa source', () {
      final status = EffectResolver.createStatus(
        'might',
        2,
        4,
        sourceId: StatusSource.card('demon_form'),
      )!;

      expect(status.sourceId, 'card:demon_form');
    });

    test('un autre statut est pose sans source', () {
      final status = EffectResolver.createStatus(
        'poison',
        3,
        2,
        sourceId: StatusSource.card('poison_dart'),
      )!;

      expect(status.sourceId, isNull);
    });
  });
}
```
Le test des deux `poison` (`:26-71`) reste tel quel : c'est la preuve que, hors de la Puissance, rien ne bouge.

In `test/unit/might_orientation_test.dart`, replace:
```dart
      final applied = run.currentState.heroStats.statuses
          .singleWhere((s) => s.id == 'might');
      expect(applied.value, 2);
    });
```
with:
```dart
      final applied = run.currentState.heroStats.statuses
          .singleWhere((s) => s.id == 'might');
      expect(applied.value, 2);
      // Posée au nom de la carte, par l'id de sa donnée (spec P-43 E0, A2).
      expect(applied.sourceId, 'card:test_card');
    });
```

In `test/unit/stat_rule_conversion_test.dart`, replace:
```dart
      final twice = StatGains.apply(once, gain, const [armorToMight]);
      expect(mightOf(twice)!.value, 8);
    });
```
with:
```dart
      final twice = StatGains.apply(once, gain, const [armorToMight]);
      expect(mightOf(twice)!.value, 8);
    });

    // D36 : la conversion pose sa Puissance au nom de la règle, et non de la
    // carte qui a donné l'armure (spec P-43 E0, A2).
    test('la Puissance convertie porte le nom de la regle', () {
      const gain = StatGain(GainResource.armor, 4, GainSource.card);
      final after = StatGains.apply(stats(), gain, const [armorToMight]);
      expect(mightOf(after)!.sourceId, 'rule:armor');
    });
```
Le test « deux gains convertis s empilent en un seul statut » (`:87-92`) reste vert sans retouche : deux conversions ont la même source.

In `test/unit/stat_rule_vocabulary_test.dart`, replace the end of the file:
```dart
      'mana convert status:might, 3 tour(s)',
    );
  });
}
```
with:
```dart
      'mana convert status:might, 3 tour(s)',
    );
  });

  // `rule:<ressource>` lit la ressource par cet accesseur : le nom du
  // fichier, jamais le nom d'enum Dart (spec P-43 E0, §4.2).
  test('statName rend la ressource dans le vocabulaire du fichier', () {
    expect(
      const StatRule(
        stat: RuleStat.armor,
        mode: RuleMode.convert,
        to: RuleTarget.statusMight,
      ).statName,
      'armor',
    );
    expect(
      const StatRule(
        stat: RuleStat.mana,
        mode: RuleMode.convert,
        to: RuleTarget.statusMight,
      ).statName,
      'mana',
    );
  });
}
```

In `test/widget/status_effects_panel_overflow_test.dart`, replace:
```dart
import 'package:roguelike_card_game/l10n/app_localizations.dart';
```
with:
```dart
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
```
and replace the end of the file:
```dart
      await tester.pumpWidget(
        _harness(
          [_status(id: 'poison', name: 'Poison')],
          locale: const Locale('en', ''),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
```
with:
```dart
      await tester.pumpWidget(
        _harness(
          [_status(id: 'poison', name: 'Poison')],
          locale: const Locale('en', ''),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // D36, A8 (spec P-43 E0) : une ligne par entrée, chacune avec sa durée. Une
  // ligne sommée n'aurait qu'une durée pour dire deux vieillissements.
  testWidgets('deux Puissances de sources differentes : deux lignes', (
    tester,
  ) async {
    final statuses = EntityStats(
      maxPv: 80,
      currentPv: 80,
      armure: 0,
      might: 0,
    )
        .addStatus(
          StatusEffect(
            id: 'might',
            name: 'Puissance',
            type: StatusType.buff,
            value: 2,
            duration: 4,
            sourceId: StatusSource.card('demon_form'),
          ),
        )
        .addStatus(
          StatusEffect(
            id: 'might',
            name: 'Puissance',
            type: StatusType.buff,
            value: 5,
            duration: 1,
            sourceId: StatusSource.rule('armor'),
          ),
        )
        .statuses;

    await tester.pumpWidget(_harness(statuses));
    await tester.pumpAndSettle();

    expect(find.text('Puissance : +2'), findsOneWidget);
    expect(find.text('4 trs'), findsOneWidget);
    expect(find.text('Puissance : +5'), findsOneWidget);
    expect(find.text('1 trs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```
Aucun code du panneau ne change (A8) : `status_effects_panel.dart:74-84` rend déjà une ligne par entrée.

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/status_source_test.dart test/unit/effect_resolver_test.dart test/unit/might_orientation_test.dart test/unit/stat_rule_conversion_test.dart test/unit/stat_rule_vocabulary_test.dart test/widget/status_effects_panel_overflow_test.dart`
Expected: FAIL à la compilation — `No named parameter with the name 'sourceId'`, `Undefined name 'StatusSource'`, `The getter 'sourceId' isn't defined`, `The getter 'statName' isn't defined`.

- [ ] **Step 3: Le modèle — `StatusEffect` et `StatusSource`**

Replace the whole content of `lib/models/status_effect.dart` with:

```dart
enum StatusType { buff, debuff }

/// L'identité de ce qui pose un statut, `<nature>:<id>` (spec P-43 E0, §4.2).
///
/// Le seul endroit qui écrive ces formes. La source est l'identifiant du
/// **contenu** qui pose, jamais celui d'un exemplaire : deux exemplaires d'une
/// même carte sont une même source, et la même source rejouée s'additionne
/// comme avant (D36). Le préfixe de nature empêche une carte et un passif de
/// même identifiant de se confondre.
abstract final class StatusSource {
  /// Une carte, par l'id de sa donnée : `card:demon_form`.
  static String card(String cardId) => 'card:$cardId';

  /// Une règle de classe, par la ressource qu'elle convertit, dans le
  /// vocabulaire du fichier (`StatRule.statName`) : `rule:armor`.
  static String rule(String resource) => 'rule:$resource';
}

class StatusEffect {
  final String id;
  final String name;
  final StatusType type;
  final int value;
  final int duration;
  final bool isStackable;

  /// Ce qui a posé le statut ([StatusSource]), ou `null` : « sans source ».
  /// Seule la Puissance en reçoit une (spec P-43 E0, A1) ; tout autre statut
  /// est posé sans source et fusionne comme avant.
  final String? sourceId;

  const StatusEffect({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.duration,
    this.isStackable = true,
    this.sourceId,
  });

  StatusEffect copyWith({
    String? id,
    String? name,
    StatusType? type,
    int? value,
    int? duration,
    bool? isStackable,
    String? sourceId,
  }) {
    return StatusEffect(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      duration: duration ?? this.duration,
      isStackable: isStackable ?? this.isStackable,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  factory StatusEffect.fromJson(Map<String, dynamic> json) {
    return StatusEffect(
      id: json['id'] as String,
      name: json['name'] as String,
      type: StatusType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => StatusType.buff,
      ),
      value: json['value'] as int,
      duration: json['duration'] as int,
      isStackable: json['isStackable'] as bool? ?? true,
      // Absente d'une sauvegarde écrite avant P-43 E0 : sans source.
      sourceId: json['sourceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.toString().split('.').last,
    'value': value,
    'duration': duration,
    'isStackable': isStackable,
    if (sourceId != null) 'sourceId': sourceId,
  };

  /// Vrai si [other] rejoint cet effet plutôt que d'ouvrir une autre entrée :
  /// même statut **et** même source, `null` compris (spec P-43 E0, §4.1). La
  /// seule règle de fusion, que lisent [combine] et `EntityStats.addStatus`.
  bool mergesWith(StatusEffect other) =>
      id == other.id && sourceId == other.sourceId;

  /// Retourne un nouvel effet combiné si stackable, sinon rafraîchit la durée.
  /// Rendu tel quel si [other] ne le rejoint pas ([mergesWith]).
  StatusEffect combine(StatusEffect other) {
    if (!mergesWith(other)) return this;
    if (isStackable) {
      return copyWith(
        value: value + other.value,
        duration: duration > other.duration
            ? duration
            : other.duration, // Ne pas additionner les durées
      );
    } else {
      // Rafraîchit la durée si elle est plus grande
      return copyWith(
        duration: other.duration > duration ? other.duration : duration,
        value: other.value > value ? other.value : value,
      );
    }
  }
}
```

In `lib/models/entity_stats.dart`, replace:
```dart
  /// Ajoute ou combine un effet de statut
  EntityStats addStatus(StatusEffect effect) {
    final index = statuses.indexWhere((s) => s.id == effect.id);
```
with:
```dart
  /// Ajoute un statut, ou le combine à l'entrée de même statut et même source
  EntityStats addStatus(StatusEffect effect) {
    final index = statuses.indexWhere((s) => s.mergesWith(effect));
```
Le commentaire reste sur une ligne, à dessein : `lib/tutorial/tutorial_engine.dart:361` et `test/tutorial/tutorial_engine_test.dart:284` citent `entity_stats.dart:134`, la ligne de `addStatus`, qui ne doit pas bouger. `effectiveMight` (`:180-188`) et `tickStatuses` (`:148-166`) ne changent pas.

- [ ] **Step 4: `StatRule.statName`**

In `lib/models/data/stat_rule.dart`, replace:
```dart
  static String _nameOf<T>(T value, Map<String, T> by) =>
      by.entries.firstWhere((entry) => entry.value == value).key;
```
with:
```dart
  static String _nameOf<T>(T value, Map<String, T> by) =>
      by.entries.firstWhere((entry) => entry.value == value).key;

  /// La ressource de cette règle dans le vocabulaire du fichier — `armor`,
  /// jamais le nom d'énumération Dart. C'est par lui que la Puissance
  /// convertie est posée au nom de la règle, `rule:armor` (spec P-43 E0, §4.2).
  String get statName => _nameOf(stat, _stats);
```
`_nameOf` reste à la ligne 68, que cite `test/unit/stat_rule_vocabulary_test.dart:29`.

- [ ] **Step 5: La conversion pose au nom de la règle**

In `lib/game/systems/stat_gains.dart`, replace:
```dart
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
```
with:
```dart
        // R5 (spec §7.2) : la cible est la Puissance **temporaire**. Convertir
        // en Puissance permanente ferait gagner de la puissance définitive à
        // chaque `iron_wall` jouée, et casserait le jeu au troisième combat.
        //
        // Posée au nom de la règle, jamais de la carte qui a donné l'armure :
        // toutes les conversions d'un tour ont la durée de la règle et
        // fusionnent entre elles, sans rejoindre une Puissance durable
        // (spec P-43 E0, A2).
        RuleTarget.statusMight => stats.addStatus(
            StatusEffect(
              id: 'might',
              name: 'Puissance',
              type: StatusType.buff,
              value: gain.amount,
              duration: rule.duration,
              sourceId: StatusSource.rule(rule.statName),
            ),
          ),
```
`StatGain` et `GainSource` ne changent pas (spec §4.7).

- [ ] **Step 6: La fabrique et la carte**

In `lib/game/services/effect_resolver.dart`, replace:
```dart
  /// Helper pour créer un StatusEffect à partir des données de la carte
  static StatusEffect? createStatus(String statusId, int value, int duration) {
    switch (statusId) {
```
with:
```dart
  /// Helper pour créer un StatusEffect à partir des données de la carte.
  ///
  /// [sourceId] est ce qui pose le statut (`StatusSource`). Seule la
  /// Puissance le retient : tout autre statut est posé sans source et fusionne
  /// comme avant — la portée de la règle s'écrit ici, une fois, pour le chemin
  /// des cartes (spec P-43 E0, A1 et §4.4).
  static StatusEffect? createStatus(
    String statusId,
    int value,
    int duration, {
    String? sourceId,
  }) {
    switch (statusId) {
```
and replace:
```dart
      case 'might':
        return StatusEffect(
          id: 'might',
          name: 'Puissance',
          type: StatusType.buff,
          value: value,
          duration: duration,
        );
```
with:
```dart
      case 'might':
        return StatusEffect(
          id: 'might',
          name: 'Puissance',
          type: StatusType.buff,
          value: value,
          duration: duration,
          sourceId: sourceId,
        );
```
Rien d'autre dans ce fichier : ni le `switch` des runes (`:142-164`), ni le bloc élémentaire (`:176-220`), dont les trois appels gardent leur forme. *Marque du Mage* (`passive_strategies.dart:84-88`) appelle la fabrique sans source : inchangée.

In `lib/game/services/effects/strategies.dart`, replace:
```dart
import '../../../models/data/card_data.dart';
```
with:
```dart
import '../../../models/data/card_data.dart';
import '../../../models/status_effect.dart';
```
and replace:
```dart
        effect.duration ?? 1,
      );
```
with:
```dart
        effect.duration ?? 1,
        // L'id de la carte, jamais celui de l'exemplaire : deux exemplaires
        // d'une même carte s'additionnent (spec P-43 E0, A2).
        sourceId: StatusSource.card(card.data.id),
      );
```

- [ ] **Step 7: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/status_source_test.dart` — Expected: `+12: All tests passed!`
Run: `flutter test test/unit/effect_resolver_test.dart` — Expected: `+7: All tests passed!`
Run: `flutter test test/unit/might_orientation_test.dart` — Expected: `+14: All tests passed!`
Run: `flutter test test/unit/stat_rule_conversion_test.dart` — Expected: `+11: All tests passed!`
Run: `flutter test test/unit/stat_rule_vocabulary_test.dart` — Expected: `+4: All tests passed!`
Run: `flutter test test/widget/status_effects_panel_overflow_test.dart` — Expected: `+6: All tests passed!`

- [ ] **Step 8: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1204: All tests passed!` (1187 + 12 + 2 + 1 + 1 + 1).

- [ ] **Step 9: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/models/status_effect.dart lib/models/entity_stats.dart lib/models/data/stat_rule.dart lib/game/systems/stat_gains.dart lib/game/services/effect_resolver.dart lib/game/services/effects/strategies.dart test/unit/status_source_test.dart test/unit/effect_resolver_test.dart test/unit/might_orientation_test.dart test/unit/stat_rule_conversion_test.dart test/unit/stat_rule_vocabulary_test.dart test/widget/status_effects_panel_overflow_test.dart
git commit -F- <<'EOF'
feat(statuts): une Puissance par source, la carte et la conversion

StatusEffect retient ce qui l a pose ; addStatus et combine ne
fusionnent plus que meme statut et meme source. La carte pose sa
Puissance a son nom, la regle de classe au sien : Forme Demoniaque puis
Mur de Fer ne se confondent plus. Tout statut pose sans source fusionne
comme avant.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 2: Les sept autres poseurs — passifs, reliques, Éveil, ennemi

Chacun pose désormais sa Puissance à son nom. Deux effets visibles, voulus : la Puissance de *Rage* ne grossit plus l'entrée d'une *Forme Démoniaque* en cours (R3 c) ; la Puissance d'Éveil d'un ennemi ne rejoint plus celle de son intention Buff — branche que rien ne pose aujourd'hui (aucun `might_regen` sous `assets/data/`). Ce sont, avec les deux de Task 1, les neuf constructions de `id: 'might'` de `lib/`.

**Files:**
- Modify: `lib/models/status_effect.dart` (la classe `StatusSource` de Task 1)
- Modify: `lib/game/systems/passives/passive_strategies.dart:12-21`, `:130`, `:174-176`, `:215`
- Modify: `lib/game/controllers/run/player_stats_manager.dart:255-263`, `:350-357`, `:384-391`
- Modify: `lib/game/controllers/combat/status_effect_processor.dart:35-43`, `:96-104`
- Modify: `lib/game/controllers/combat/turn_phase_manager.dart:143-151`
- Test: `test/unit/status_source_test.dart` (le test des formes de Task 1)
- Test: `test/unit/passives_berserker_test.dart:17`, `:132-142`, `:210-211` ; `test/unit/passives_paladin_test.dart:98-104` ; `test/unit/stat_gains_characterization_test.dart:89-96`, `:206-214` ; `test/unit/combat_controller_test.dart:186-191`

**Interfaces:**
- Consumes: `StatusSource`, `StatusEffect.sourceId`, `mergesWith` (Task 1).
- Produces: `StatusSource.passive(String passiveId)` → `'passive:<id>'` ; `StatusSource.relic(String relicId)` → `'relic:<id>'` ; `StatusSource.status(String statusId)` → `'status:<id>'` ; `StatusSource.enemy(String enemyId)` → `'enemy:<id>'`. La fabrique locale `_temporaryMight(PassiveData passive, int value)` de `passive_strategies.dart`, privée.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/status_source_test.dart`, replace:
```dart
    test('les formes de la carte et de la regle', () {
      expect(StatusSource.card('demon_form'), 'card:demon_form');
      expect(StatusSource.rule('armor'), 'rule:armor');
    });
```
with:
```dart
    test('les six formes', () {
      expect(StatusSource.card('demon_form'), 'card:demon_form');
      expect(StatusSource.rule('armor'), 'rule:armor');
      expect(StatusSource.passive('rage'), 'passive:rage');
      expect(StatusSource.relic('shuriken'), 'relic:shuriken');
      expect(StatusSource.status('might_regen'), 'status:might_regen');
      expect(StatusSource.enemy('orc'), 'enemy:orc');
    });
```

In `test/unit/passives_berserker_test.dart`, replace:
```dart
import 'package:roguelike_card_game/models/entity_stats.dart';
```
with:
```dart
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
```
then replace:
```dart
      expect(stats().might, 0);
      expect(
        stats().statuses.singleWhere((s) => s.id == 'might').duration,
        1,
      );
    });
  });
```
with:
```dart
      expect(stats().might, 0);
      final gained = stats().statuses.singleWhere((s) => s.id == 'might');
      expect(gained.duration, 1);
      expect(gained.sourceId, 'passive:rage');
    });

    // R3 c de la revue du brainstorm v3 (spec P-43 E0, §4.6) : la Puissance
    // de Rage ne grossit plus l'entree d'une Forme Demoniaque en cours.
    test('Rage ne rejoint pas une Forme Demoniaque, et expire au tic suivant', () {
      run.startNewRun(berserker, rage());
      run.addStatus(
        StatusEffect(
          id: 'might',
          name: 'Puissance',
          type: StatusType.buff,
          value: 2,
          duration: 4,
          sourceId: StatusSource.card('demon_form'),
        ),
      );

      run.startTurn();
      run.startTurn();

      final might = stats().statuses.where((s) => s.id == 'might').toList();
      expect(might, hasLength(2));
      final fromDemon =
          might.singleWhere((s) => s.sourceId == 'card:demon_form');
      expect((fromDemon.value, fromDemon.duration), (2, 2));
      final fromRage = might.singleWhere((s) => s.sourceId == 'passive:rage');
      expect((fromRage.value, fromRage.duration), (1, 1));
      // Avant P-43 E0 : une seule entree, 2 + 1 + 1 = 4.
      expect(temporaryMight(), 2 + 1);
    });
  });
```
and replace:
```dart
      expect(combat.currentState.enemies, isEmpty);
      expect(temporaryMight(), 2);
```
with:
```dart
      expect(combat.currentState.enemies, isEmpty);
      expect(temporaryMight(), 2);
      expect(
        stats().statuses.singleWhere((s) => s.id == 'might').sourceId,
        'passive:frenzy',
      );
```
Les variables locales s'appellent `gained`, `fromDemon`, `fromRage` et non `rage` : une locale `rage` déclarée dans un bloc qui appelle déjà `rage()` ne compile pas.

In `test/unit/passives_paladin_test.dart`, replace:
```dart
      expect(temporaryMight(), 1);
      expect(stats().might, 0, reason: 'jamais de Puissance permanente');
      expect(
        stats().statuses.singleWhere((s) => s.id == 'might').duration,
        2,
      );
    });
```
with:
```dart
      expect(temporaryMight(), 1);
      expect(stats().might, 0, reason: 'jamais de Puissance permanente');
      final gained = stats().statuses.singleWhere((s) => s.id == 'might');
      expect(gained.duration, 2);
      expect(gained.sourceId, 'passive:fervor');
    });

    // La meme source rejouee s'additionne (D36) : d'un tour ennemi a
    // l'autre, Ferveur rejoint son entree encore active et prend sa duree.
    test('d un tour a l autre, Ferveur rejoint son entree', () {
      run.startNewRun(paladin, fervor());
      setHero(armure: 10);
      run.takeDamage(2);

      run.startTurn(); // le tic : l'entree passe a 1 tour
      setHero(armure: 10);
      run.takeDamage(2);

      final gained = stats().statuses.where((s) => s.id == 'might').toList();
      expect(gained, hasLength(1));
      expect(gained.single.value, 1 + 1);
      expect(gained.single.duration, 2);
    });
```

In `test/unit/stat_gains_characterization_test.dart`, replace:
```dart
  RelicData relic(String effectType, int value) => RelicData(
        id: 'test_relic',
```
with:
```dart
  RelicData relic(String effectType, int value, {String id = 'test_relic'}) =>
      RelicData(
        id: id,
```
then replace the end of the file:
```dart
      run.applyHeroStatModifier(mightAcc: -4);
      expect(heroStats().might, 0);
    });
  });
}
```
with:
```dart
      run.applyHeroStatModifier(mightAcc: -4);
      expect(heroStats().might, 0);
    });
  });

  // P-43 E0 (spec, §4.3) : chaque poseur de Puissance la pose a son nom. Les
  // valeurs et les durees ne changent pas.
  group('la Puissance des reliques et d Eveil porte sa source', () {
    setUp(() => run.startNewRun(paladin));

    test('relique gain_might hors debut de run', () {
      run.applyRelicEffect(relic('gain_might', 2));

      final gained = heroStats().statuses.singleWhere((s) => s.id == 'might');
      expect(gained.sourceId, 'relic:test_relic');
      expect((gained.value, gained.duration), (2, 99));
    });

    test('Shuriken : une entree pour le combat, ses charges une entree', () {
      final shuriken = relic('charge_might_combat', 1, id: 'shuriken');
      run.applyRelicEffect(shuriken);
      run.applyRelicEffect(shuriken);

      final charges =
          heroStats().statuses.where((s) => s.id == 'shuriken_charge');
      expect(charges, hasLength(1));
      expect(charges.single.value, 2);

      // Le seuil de trois atteint deux fois : la meme source s'additionne.
      for (var i = 0; i < 4; i++) {
        run.applyRelicEffect(shuriken);
      }

      final gained = heroStats().statuses.where((s) => s.id == 'might').toList();
      expect(gained, hasLength(1));
      expect(gained.single.sourceId, 'relic:shuriken');
      expect((gained.single.value, gained.single.duration), (1 + 1, 99));
    });

    test('Plume de scribe : une entree pour le tour, ses charges une entree', () {
      final penNib = relic('charge_might_turn', 3, id: 'pen_nib');
      for (var i = 0; i < 4; i++) {
        run.applyRelicEffect(penNib);
      }

      final charges =
          heroStats().statuses.where((s) => s.id == 'pen_nib_charge');
      expect(charges, hasLength(1));
      expect(charges.single.value, 4);

      run.applyRelicEffect(penNib); // la cinquieme carte

      final gained = heroStats().statuses.singleWhere((s) => s.id == 'might');
      expect(gained.sourceId, 'relic:pen_nib');
      expect((gained.value, gained.duration), (3, 1));
    });

    test('Eveil de Puissance du heros : 1, 2, 3, 3, sous sa source', () {
      const eveil = StatusEffect(
        id: 'might_regen',
        name: 'Eveil de Puissance',
        type: StatusType.buff,
        value: 1,
        duration: 3,
      );
      var stats = EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0)
          .addStatus(eveil);

      final releves = <int>[];
      for (var tour = 0; tour < 4; tour++) {
        stats = StatusEffectProcessor.processPlayerStatuses(stats, const []);
        releves.add(stats.effectiveMight);
      }

      // Seule, elle s'accumule comme avant : la meme source a chaque tour.
      expect(releves, [1, 2, 3, 3]);
      expect(
        stats.statuses.singleWhere((s) => s.id == 'might').sourceId,
        'status:might_regen',
      );
    });

    // La branche ennemie, que rien ne pose aujourd'hui (aucun might_regen sous
    // assets/data/) : la Puissance d'Eveil devient une entree a part, que le
    // tic final du meme appel retire.
    test('Eveil de Puissance d un ennemi : ne rejoint plus l intention Buff', () {
      final orc = EntityStats(
        maxPv: 50,
        currentPv: 50,
        armure: 0,
        might: 0,
        statuses: [
          StatusEffect(
            id: 'might',
            name: 'Puissance',
            type: StatusType.buff,
            value: 2,
            duration: 99,
            sourceId: StatusSource.enemy('orc'),
          ),
          const StatusEffect(
            id: 'might_regen',
            name: 'Eveil de Puissance',
            type: StatusType.buff,
            value: 1,
            duration: 3,
          ),
        ],
      );

      final after = StatusEffectProcessor.processEnemyStatuses(orc);

      // 2, et non 3 comme avant P-43 E0.
      expect(after.effectiveMight, 2);
      expect(after.statuses.where((s) => s.id == 'might'), hasLength(1));
    });
  });
}
```

In `test/unit/combat_controller_test.dart`, replace:
```dart
      // Apply defense intent
      combatController.resolveEnemyIntent(updatedEnemy.id);
      final defendedEnemy = combatController.currentState.enemies.first;
      // Enemy armor should increase by 6
      expect(defendedEnemy.stats.armure, 6);
    });
```
with:
```dart
      // Apply defense intent
      combatController.resolveEnemyIntent(updatedEnemy.id);
      final defendedEnemy = combatController.currentState.enemies.first;
      // Enemy armor should increase by 6
      expect(defendedEnemy.stats.armure, 6);
    });

    // P-43 E0 (spec, A2) : l'intention Buff pose sa Puissance au nom de
    // l'ennemi, par l'id de sa donnee ; deux Buff font une entree.
    test('l intention Buff pose une Puissance au nom de l ennemi', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final combatController = container.read(combatProvider.notifier);
      container.read(runProvider.notifier).startNewRun(paladinHero);

      final orc = EnemyInstance(
        data: orcData,
        stats: EntityStats(maxPv: 30, currentPv: 30, armure: 0, might: 8),
        currentIntent: EnemyIntent(type: IntentType.buff, value: 2),
      );
      combatController.state = CombatState(
        enemies: [orc],
        selectedEnemyId: orc.id,
        turnPhase: TurnPhase.enemy,
      );

      combatController.resolveEnemyIntent(orc.id);
      combatController.resolveEnemyIntent(orc.id);

      final might = combatController.currentState.enemies.single.stats.statuses
          .where((s) => s.id == 'might')
          .toList();
      expect(might, hasLength(1));
      expect(might.single.sourceId, 'enemy:orc');
      expect(might.single.value, 2 + 2);
    });
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/status_source_test.dart test/unit/passives_berserker_test.dart test/unit/passives_paladin_test.dart test/unit/stat_gains_characterization_test.dart test/unit/combat_controller_test.dart`
Expected: FAIL — à la compilation pour `status_source_test.dart` et `stat_gains_characterization_test.dart` (`Member not found: 'StatusSource.enemy'`) ; ailleurs, les assertions `sourceId` reçoivent `null`, et `singleWhere((s) => s.sourceId == 'passive:rage')` ne trouve rien. Un seul test neuf passe déjà depuis Task 1, *Ferveur* d'un tour à l'autre (deux Puissances sans source fusionnent) : il ne prouve ici que l'absence de régression.

- [ ] **Step 3: Les quatre formes restantes de `StatusSource`**

In `lib/models/status_effect.dart`, replace:
```dart
  /// Une règle de classe, par la ressource qu'elle convertit, dans le
  /// vocabulaire du fichier (`StatRule.statName`) : `rule:armor`.
  static String rule(String resource) => 'rule:$resource';
}
```
with:
```dart
  /// Une règle de classe, par la ressource qu'elle convertit, dans le
  /// vocabulaire du fichier (`StatRule.statName`) : `rule:armor`.
  static String rule(String resource) => 'rule:$resource';

  /// Un passif, par son id : `passive:rage`.
  static String passive(String passiveId) => 'passive:$passiveId';

  /// Une relique, par son id : `relic:pen_nib`.
  static String relic(String relicId) => 'relic:$relicId';

  /// Un statut qui en pose un autre, par l'id du statut qui pose :
  /// `status:might_regen`.
  static String status(String statusId) => 'status:$statusId';

  /// Un ennemi, par l'id de sa donnée, jamais celui de l'instance :
  /// `enemy:orc`.
  static String enemy(String enemyId) => 'enemy:$enemyId';
}
```

- [ ] **Step 4: Les passifs**

In `lib/game/systems/passives/passive_strategies.dart`, replace:
```dart
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
with:
```dart
/// La Puissance temporaire qu'un passif accorde, pour sa durée et à son nom :
/// elle ne rejoint jamais celle d'une carte ou d'une règle (spec P-43 E0,
/// A2). Le nom est celui que voient le panneau des statuts et la carte du
/// héros ; l'identifiant `might` est ce que lit `effectiveMight`.
StatusEffect _temporaryMight(PassiveData passive, int value) => StatusEffect(
      id: 'might',
      name: 'Puissance',
      type: StatusType.buff,
      value: value,
      duration: passive.duration,
      sourceId: StatusSource.passive(passive.id),
    );
```
Then the three callers. *Ferveur* — replace:
```dart
    run.addStatus(_temporaryMight(passive.value, passive.duration));
  }
}

/// `blessing`
```
with:
```dart
    run.addStatus(_temporaryMight(passive, passive.value));
  }
}

/// `blessing`
```
*Rage* — replace:
```dart
    run.addStatus(
      _temporaryMight(passive.value * (1 + tranches), passive.duration),
    );
```
with:
```dart
    run.addStatus(_temporaryMight(passive, passive.value * (1 + tranches)));
```
*Frénésie* — replace:
```dart
    run.addStatus(_temporaryMight(passive.value, passive.duration));
    if (passive.draw > 0) {
```
with:
```dart
    run.addStatus(_temporaryMight(passive, passive.value));
    if (passive.draw > 0) {
```
`TraitSystem.dispatch` applique la Maîtrise par `withMastery`, qui garde l'id du passif : la source ne change pas avec la Maîtrise.

- [ ] **Step 5: Les reliques**

In `lib/game/controllers/run/player_stats_manager.dart`, `gain_might` hors début de run — replace:
```dart
              name: 'Puissance (Relique)',
              type: StatusType.buff,
              value: relic.value,
              duration: 99, // 99 tours (durée du combat)
            ),
```
with:
```dart
              name: 'Puissance (Relique)',
              type: StatusType.buff,
              value: relic.value,
              duration: 99, // 99 tours (durée du combat)
              sourceId: StatusSource.relic(relic.id),
            ),
```
*Shuriken* (`charge_might_combat`) — replace:
```dart
              name: 'Puissance (Relique)',
              type: StatusType.buff,
              value: relic.value,
              duration: 99,
            ),
```
with:
```dart
              name: 'Puissance (Relique)',
              type: StatusType.buff,
              value: relic.value,
              duration: 99,
              sourceId: StatusSource.relic(relic.id),
            ),
```
*Plume de scribe* (`charge_might_turn`) — replace:
```dart
              name: 'Puissance (Relique)',
              type: StatusType.buff,
              value: relic.value,
              duration: 1,
            ),
```
with:
```dart
              name: 'Puissance (Relique)',
              type: StatusType.buff,
              value: relic.value,
              duration: 1,
              sourceId: StatusSource.relic(relic.id),
            ),
```
Les charges (`kunai_charge`, `shuriken_charge`, `pen_nib_charge`, `incense_charge`) et `gain_crit` restent sans source : leurs lecteurs (`:305-306`, `:339-340`, `:373-374`, `:407-408`) supposent une entrée par identifiant, et l'ont toujours (A1).

- [ ] **Step 6: Éveil de Puissance et l'intention Buff**

In `lib/game/controllers/combat/status_effect_processor.dart`, the hero branch — replace:
```dart
          duration: 3, // 3 tours maximum pour le joueur
        ),
```
with:
```dart
          duration: 3, // 3 tours maximum pour le joueur
          // Le même statut pose à chaque tour : sa Puissance s'additionne
          // comme avant, sans rejoindre celle d'une carte (spec P-43 E0, A2).
          sourceId: StatusSource.status('might_regen'),
        ),
```
the enemy branch — replace:
```dart
          duration: 1, // 1 tour maximum pour l'ennemi
        ),
```
with:
```dart
          duration: 1, // 1 tour maximum pour l'ennemi
          // Une entrée à part, que le tic final ci-dessous retire dans
          // l'appel même qui la crée : elle ne rejoint plus la Puissance de
          // l'intention Buff (spec P-43 E0, §4.3 ; ADR-097).
          sourceId: StatusSource.status('might_regen'),
        ),
```
Le vieillissement délibéré de la Puissance d'Éveil du héros, 3 → 2 (`:45-55`), ne change pas.

In `lib/game/controllers/combat/turn_phase_manager.dart`, replace:
```dart
              value: intent.value,
              duration: 99,
            ),
```
with:
```dart
              value: intent.value,
              duration: 99,
              // L'id de la donnée, jamais l'uuid de l'instance (spec P-43
              // E0, A2).
              sourceId: StatusSource.enemy(enemy.data.id),
            ),
```

- [ ] **Step 7: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/status_source_test.dart` — Expected: `+12: All tests passed!`
Run: `flutter test test/unit/passives_berserker_test.dart` — Expected: `+11: All tests passed!`
Run: `flutter test test/unit/passives_paladin_test.dart` — Expected: `+9: All tests passed!`
Run: `flutter test test/unit/stat_gains_characterization_test.dart` — Expected: `+17: All tests passed!`
Run: `flutter test test/unit/combat_controller_test.dart` — Expected: `+11: All tests passed!`

- [ ] **Step 8: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1212: All tests passed!` (1204 + 1 + 1 + 5 + 1 ; le test des formes est remplacé, pas ajouté).
Run: `git grep -c "id: 'might'" -- lib` — Expected: neuf constructions en six fichiers — `status_effect_processor.dart:2`, `turn_phase_manager.dart:1`, `player_stats_manager.dart:3`, `effect_resolver.dart:1`, `passive_strategies.dart:1`, `stat_gains.dart:1`.
Run: `git grep -n "StatusSource\.[a-z]*(" -- lib` — Expected: exactement neuf lignes, une par poseur — `status_effect_processor.dart` (deux `status`), `turn_phase_manager.dart` (`enemy`), `player_stats_manager.dart` (trois `relic`), `strategies.dart` (`card`), `passive_strategies.dart` (`passive`), `stat_gains.dart` (`rule`). La neuvième construction, la branche `might` de `createStatus`, reçoit sa source de `strategies.dart`.

- [ ] **Step 9: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/models/status_effect.dart lib/game/systems/passives/passive_strategies.dart lib/game/controllers/run/player_stats_manager.dart lib/game/controllers/combat/status_effect_processor.dart lib/game/controllers/combat/turn_phase_manager.dart test/unit/status_source_test.dart test/unit/passives_berserker_test.dart test/unit/passives_paladin_test.dart test/unit/stat_gains_characterization_test.dart test/unit/combat_controller_test.dart
git commit -F- <<'EOF'
feat(statuts): passifs, reliques, Eveil et ennemis posent a leur nom

Les sept autres poseurs de Puissance donnent leur source. La Puissance
de Rage ne grossit plus une Forme Demoniaque en cours ; celle d Eveil
d un ennemi ne rejoint plus son intention Buff. La meme source rejouee
s additionne comme avant.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 3: `StatRule.ratio` — la borne, l'arithmétique, la conversion

D37 en moteur : la règle de classe convertit une part de chaque gain, arrondie à l'entier supérieur. Aucune donnée ne déclare encore de ratio : le jeu ne change pas avant Task 5. L'éditeur de contenu apprend la borne par le modèle (famille 7), le menu de debug la lit par `toString`.

**Files:**
- Modify: `lib/models/data/stat_rule.dart:33-41`, `:83-88`, `:94-104`, `:106-114`, et après `statName` (Task 1)
- Modify: `lib/game/systems/stat_gains.dart:73-76`, `:103`
- Test: `test/unit/stat_rule_test.dart:62` ; `test/unit/stat_rule_vocabulary_test.dart:29` et l'ajout de Task 1 ; `test/unit/stat_rule_conversion_test.dart:14-21` et l'ajout de Task 1 ; `test/unit/status_source_test.dart` (fin) ; `test/unit/content_editor/entity_validator_test.dart:790-802` ; `test/widget/debug_drawer_test.dart:48-55`, `:326-328`

**Interfaces:**
- Consumes: `StatRule.statName`, `StatusSource.rule` (Task 1).
- Produces:
  - `final double StatRule.ratio` — paramètre nommé `ratio` du constructeur `const`, 1 par défaut ; lu par `fromJson` sous la clé `ratio`, absente : 1 ; hors de ]0, 1] ou non numérique : `FormatException` dont le message contient `statRules.ratio` et la valeur reçue.
  - `int StatRule.convertedAmount(int amount)` — le montant converti d'un gain strictement positif : `ceil(amount × ratio − 10⁻⁹)`, au moins 1.
  - `StatRule.==` et `hashCode` comptent le ratio ; `toString()` ajoute `, ratio <valeur>` quand il diffère de 1.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/stat_rule_test.dart`, replace:
```dart
  group('StatRule.parseAll', () {
```
with:
```dart
  // D37 : la part convertie, bornee par le modele (spec P-43 E0, A5).
  group('StatRule.ratio', () {
    test('lu a 0,5', () {
      expect(StatRule.fromJson({...ruleJson(), 'ratio': 0.5}).ratio, 0.5);
    });

    test('1 en son absence', () {
      expect(StatRule.fromJson(ruleJson()).ratio, 1);
    });

    test('un entier est admis', () {
      expect(StatRule.fromJson({...ruleJson(), 'ratio': 1}).ratio, 1);
    });

    test('refuse hors de ]0, 1], ou non numerique', () {
      for (final bad in const <Object>[0, -0.5, 1.5, '0.5']) {
        expect(
          () => StatRule.fromJson({...ruleJson(), 'ratio': bad}),
          throwsFormatException,
          reason: 'ratio refuse : $bad',
        );
      }
    });

    // `RunState.fromJsonWithReport` reconstruit les regles depuis le
    // registre : une egalite qui ignorerait le ratio laisserait passer une
    // reconstruction fausse.
    test('compte par == et hashCode', () {
      final half = StatRule.fromJson({...ruleJson(), 'ratio': 0.5});
      final halfAgain = StatRule.fromJson({...ruleJson(), 'ratio': 0.5});
      final whole = StatRule.fromJson(ruleJson());

      expect(half, halfAgain);
      expect(half.hashCode, halfAgain.hashCode);
      expect(half, isNot(whole));
      expect(half.hashCode, isNot(whole.hashCode));
    });
  });

  // A6 : chaque gain converti seul, arrondi a l'entier superieur a 10^-9
  // pres, jamais moins de 1.
  group('StatRule.convertedAmount', () {
    StatRule withRatio(double ratio) =>
        StatRule.fromJson({...ruleJson(), 'ratio': ratio});

    const amounts = [1, 5, 6, 10, 30];

    test('a 0,5 : 1 donne 1, 5 donne 3, 6 donne 3', () {
      expect(amounts.map(withRatio(0.5).convertedAmount), [1, 3, 3, 5, 15]);
    });

    test('a 1 : le montant lui-meme', () {
      expect(amounts.map(withRatio(1).convertedAmount), amounts);
    });

    // 0,1 x 30 vaut 3,0000000000000004 en flottant : sans la tolerance, le
    // texte dirait « arrondi a l'entier superieur » et le moteur donnerait 4.
    test('a 0,1 : 30 donne 3, et non 4', () {
      expect(amounts.map(withRatio(0.1).convertedAmount), [1, 1, 1, 1, 3]);
    });
  });

  group('StatRule.parseAll', () {
```

In `test/unit/stat_rule_vocabulary_test.dart`, replace:
```dart
  // `_nameOf`, sans `orElse` (`stat_rule.dart:68`), leve alors `StateError`
```
with:
```dart
  // `_nameOf`, sans `orElse` (`stat_rule.dart:75`), leve alors `StateError`
```
(le champ `ratio` et sa doc, ajoutés plus haut dans `stat_rule.dart`, font descendre `_nameOf` de sept lignes), then replace:
```dart
  // `rule:<ressource>` lit la ressource par cet accesseur
```
with:
```dart
  // Le menu de debug lit le ratio sur cette ligne (spec P-43 E0, §6.2).
  test('toString porte le ratio quand il differe de 1', () {
    expect(
      const StatRule(
        stat: RuleStat.armor,
        mode: RuleMode.convert,
        to: RuleTarget.statusMight,
        duration: 1,
        ratio: 0.5,
      ).toString(),
      'armor convert status:might, 1 tour(s), ratio 0.5',
    );
  });

  // `rule:<ressource>` lit la ressource par cet accesseur
```
Le test existant `toString rend le vocabulaire du fichier` (`:50-69`) reste tel quel : à ratio 1, rien ne s'ajoute.

In `test/unit/stat_rule_conversion_test.dart`, replace:
```dart
    duration: 1,
  );

  EntityStats stats() => EntityStats(
```
with:
```dart
    duration: 1,
  );

  // Le taux du Berserker (spec P-43 E0, D37).
  const armorToMightHalf = StatRule(
    stat: RuleStat.armor,
    mode: RuleMode.convert,
    to: RuleTarget.statusMight,
    duration: 1,
    ratio: 0.5,
  );

  EntityStats stats() => EntityStats(
```
then replace:
```dart
      expect(mightOf(after)!.sourceId, 'rule:armor');
    });
```
with:
```dart
      expect(mightOf(after)!.sourceId, 'rule:armor');
    });

    // D37 : la moitie de l'armure, arrondie a l'entier superieur.
    test('a 0,5 : 6 Armure donnent 3 Puissance, et aucune Armure', () {
      const gain = StatGain(GainResource.armor, 6, GainSource.card);
      final after = StatGains.apply(stats(), gain, const [armorToMightHalf]);

      expect(after.armure, 2, reason: 'aucune armure ecrite');
      expect(mightOf(after)!.value, 3);
    });

    // A6 : chaque gain est arrondi seul — deux gains de 5 font 3 + 3, et non
    // l'arrondi de 10 / 2.
    test('a 0,5 : deux gains de 5 donnent 6, arrondis un par un', () {
      const gain = StatGain(GainResource.armor, 5, GainSource.card);
      final once = StatGains.apply(stats(), gain, const [armorToMightHalf]);
      final twice = StatGains.apply(once, gain, const [armorToMightHalf]);

      expect(mightOf(twice)!.value, 3 + 3);
    });
```

In `test/unit/status_source_test.dart`, replace:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
```
with:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/stat_gains.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
```
then replace the end of the file:
```dart
      expect(mightOf(stats), hasLength(1));
      expect(mightOf(stats).single.value, 2 + 2);
      expect(mightOf(stats).single.duration, 4);
    });
  });
}
```
with:
```dart
      expect(mightOf(stats), hasLength(1));
      expect(mightOf(stats).single.value, 2 + 2);
      expect(mightOf(stats).single.duration, 4);
    });
  });

  // Le cas de D36 : Forme Demoniaque (2 Puissance, 4 tours) puis Mur de Fer
  // (10 Armure) au meme tour, chez une classe qui convertit a 0,5. Avant
  // P-43 E0 : une entree de 12 pendant 4 tours.
  group('le cas de D36', () {
    const berserkerRule = StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
      ratio: 0.5,
    );

    test('7 ce tour, puis 2 pendant trois tours, puis 0', () {
      var stats = StatGains.apply(
        hero().addStatus(might(2, 4, sourceId: demonForm)),
        const StatGain(GainResource.armor, 10, GainSource.card),
        const [berserkerRule],
      );

      expect(
        mightOf(stats).map((s) => (s.sourceId, s.value, s.duration)),
        [(demonForm, 2, 4), (armorRule, 5, 1)],
      );
      expect(stats.effectiveMight, 7);

      final releves = <int>[];
      for (var tic = 0; tic < 4; tic++) {
        stats = stats.tickStatuses();
        releves.add(stats.effectiveMight);
      }
      expect(releves, [2, 2, 2, 0]);
    });
  });
}
```

In `test/unit/content_editor/entity_validator_test.dart`, inside the group `les regles de stat d une classe`, replace:
```dart
    test('une cible inconnue est refusee', () {
      // `statusMight` est le **nom Dart** de la valeur ; le fichier ecrit
      // `status:might`. Confondre les deux est l'erreur la plus probable.
      final faults = validatorWith().validate(classeAvecRegles(
        '[{"stat": "armor", "mode": "convert", "to": "statusMight"}]',
      ));
      expect(
        faults.where((f) => f.field == 'statRules[0].to'),
        hasLength(1),
        reason: faults.join(' ; '),
      );
    });
```
with:
```dart
    test('une cible inconnue est refusee', () {
      // `statusMight` est le **nom Dart** de la valeur ; le fichier ecrit
      // `status:might`. Confondre les deux est l'erreur la plus probable.
      final faults = validatorWith().validate(classeAvecRegles(
        '[{"stat": "armor", "mode": "convert", "to": "statusMight"}]',
      ));
      expect(
        faults.where((f) => f.field == 'statRules[0].to'),
        hasLength(1),
        reason: faults.join(' ; '),
      );
    });

    // La borne de `ratio` vit dans `StatRule.fromJson`, que la famille 7
    // traverse : aucune copie dans le descripteur (spec P-43 E0, A5, §6.1).
    test('un ratio hors de ]0, 1], ou non numerique, est refuse', () {
      for (final ratio in const ['0', '1.5', '"0.5"']) {
        final faults = validatorWith().validate(classeAvecRegles(
          '[{"stat": "armor", "mode": "convert", "to": "status:might", '
          '"ratio": $ratio}]',
        ));
        expect(faults, hasLength(1), reason: 'ratio $ratio : $faults');
        expect(faults.single.message, contains('ratio'), reason: ratio);
      }
    });

    test('un ratio de 0,5 passe', () {
      final faults = validatorWith().validate(classeAvecRegles(
        '[{"stat": "armor", "mode": "convert", "to": "status:might", '
        '"duration": 1, "ratio": 0.5}]',
      ));
      expect(faults, isEmpty, reason: faults.join(' ; '));
    });
```

In `test/widget/debug_drawer_test.dart`, replace:
```dart
  statRules: [
    StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
    ),
  ],
);
```
with:
```dart
  statRules: [
    StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
      ratio: 0.5,
    ),
  ],
);
```
then replace:
```dart
    // La regle, dans le vocabulaire du fichier : c'est la donnee que le
    // developpeur edite, pas la phrase du joueur.
    final regle = _berserker.statRules.first.toString();
```
with:
```dart
    // La regle, dans le vocabulaire du fichier : c'est la donnee que le
    // developpeur edite, pas la phrase du joueur — ratio compris.
    final regle = _berserker.statRules.first.toString();
    expect(regle, 'armor convert status:might, 1 tour(s), ratio 0.5');
```
Aucun code de l'onglet Héros ne change (`debug_hero_tab.dart:121-127` affiche déjà `'$rule'`).

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/stat_rule_test.dart test/unit/stat_rule_vocabulary_test.dart test/unit/stat_rule_conversion_test.dart test/unit/status_source_test.dart test/unit/content_editor/entity_validator_test.dart test/widget/debug_drawer_test.dart`
Expected: FAIL — à la compilation (`The getter 'ratio' isn't defined`, `The getter 'convertedAmount' isn't defined`, `No named parameter with the name 'ratio'`), et, pour `entity_validator_test.dart`, le test des ratios refusés : sans borne, `StatRule.fromJson` accepte tout.

- [ ] **Step 3: Le champ, sa borne, son arithmétique**

In `lib/models/data/stat_rule.dart`, replace:
```dart
  /// La durée du statut produit, en tours.
  final int duration;

  const StatRule({
    required this.stat,
    required this.mode,
    required this.to,
    this.duration = 1,
  });
```
with:
```dart
  /// La durée du statut produit, en tours.
  final int duration;

  /// La part de chaque gain que la règle convertit, dans ]0, 1] ; 1 par
  /// défaut, la conversion entière d'avant (spec P-43 E0, D37). Un garde-fou
  /// de classe, pas un nerf de carte : le Berserker la déclare à 0,5. Le
  /// montant converti est [convertedAmount].
  final double ratio;

  const StatRule({
    required this.stat,
    required this.mode,
    required this.to,
    this.duration = 1,
    this.ratio = 1,
  });
```
then replace:
```dart
  String get statName => _nameOf(stat, _stats);
```
with:
```dart
  String get statName => _nameOf(stat, _stats);

  /// Ce que devient un gain strictement positif de [amount] : son produit par
  /// [ratio], arrondi à l'entier supérieur, jamais moins de 1. L'arrondi se
  /// fait à 10⁻⁹ près : `0.1 × 30` vaut 3,0000000000000004 en flottant, et
  /// monterait sinon à 4. À ratio 1, [amount] lui-même.
  ///
  /// Chaque gain est converti seul (spec P-43 E0, A6). La seule arithmétique
  /// du ratio : `StatGains` la lit au gain, `StatRuleLabel.describe` pour
  /// l'exemple qu'il écrit au joueur.
  int convertedAmount(int amount) {
    final converted = (amount * ratio - _roundingTolerance).ceil();
    return converted < 1 ? 1 : converted;
  }

  static const double _roundingTolerance = 1e-9;

  /// Lit `ratio`, absent : 1. Le moteur refuse déjà de créer une Puissance
  /// nulle ou négative (`StatGains._convert`) ; le modèle refuse au
  /// chargement le ratio qui en fabriquerait une. La borne haute laisse
  /// élargir plus tard sans casser aucun fichier (spec P-43 E0, A5).
  static double _readRatio(Object? value) {
    if (value == null) return 1;
    if (value is! num || value <= 0 || value > 1) {
      throw FormatException(
        'statRules.ratio : valeur "$value" refusée — attendu : un nombre '
        'dans ]0, 1]',
      );
    }
    return value.toDouble();
  }
```
then replace:
```dart
        duration: json['duration'] as int? ?? 1,
      );
```
with:
```dart
        duration: json['duration'] as int? ?? 1,
        ratio: _readRatio(json['ratio']),
      );
```
then replace:
```dart
          other.to == to &&
          other.duration == duration);

  @override
  int get hashCode => Object.hash(stat, mode, to, duration);

  /// La règle dans le vocabulaire du **fichier de classe** :
  /// `armor convert status:might, 1 tour(s)`.
  ///
```
with:
```dart
          other.to == to &&
          other.duration == duration &&
          other.ratio == ratio);

  @override
  int get hashCode => Object.hash(stat, mode, to, duration, ratio);

  /// La règle dans le vocabulaire du **fichier de classe** :
  /// `armor convert status:might, 1 tour(s)`, suivi de `, ratio 0.5` quand le
  /// ratio diffère de 1.
  ///
```
and replace:
```dart
  String toString() => '${_nameOf(stat, _stats)} ${_nameOf(mode, _modes)} '
      '${_nameOf(to, _targets)}, $duration tour(s)';
```
with:
```dart
  String toString() => '$statName ${_nameOf(mode, _modes)} '
      '${_nameOf(to, _targets)}, $duration tour(s)'
      '${ratio == 1 ? '' : ', ratio $ratio'}';
```
`HeroData.fromJson` ne change pas : il lit déjà `statRules` par `StatRule.parseAll`.

- [ ] **Step 4: La conversion au ratio**

In `lib/game/systems/stat_gains.dart`, replace:
```dart
  /// Un gain nul ou négatif n'est jamais converti : il n'y a rien à
  /// transformer, et un statut de valeur négative n'a pas de sens.
  static EntityStats? _convert(
```
with:
```dart
  /// Un gain nul ou négatif n'est jamais converti : il n'y a rien à
  /// transformer, et un statut de valeur négative n'a pas de sens. Un gain
  /// positif est converti seul, au `ratio` de la règle
  /// (`StatRule.convertedAmount`, spec P-43 E0, A6).
  static EntityStats? _convert(
```
and replace:
```dart
              value: gain.amount,
              duration: rule.duration,
              sourceId: StatusSource.rule(rule.statName),
```
with:
```dart
              value: rule.convertedAmount(gain.amount),
              duration: rule.duration,
              sourceId: StatusSource.rule(rule.statName),
```
Le garde d'un gain nul ou négatif (`if (gain.amount <= 0) return null;`) reste devant.

- [ ] **Step 5: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/stat_rule_test.dart` — Expected: `+19: All tests passed!`
Run: `flutter test test/unit/stat_rule_vocabulary_test.dart` — Expected: `+5: All tests passed!`
Run: `flutter test test/unit/stat_rule_conversion_test.dart` — Expected: `+13: All tests passed!`
Run: `flutter test test/unit/status_source_test.dart` — Expected: `+13: All tests passed!`
Run: `flutter test test/unit/content_editor/entity_validator_test.dart` — Expected: `+59: All tests passed!`
Run: `flutter test test/widget/debug_drawer_test.dart` — Expected: `+7: All tests passed!`

- [ ] **Step 6: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1226: All tests passed!` (1212 + 8 + 1 + 2 + 1 + 2).

- [ ] **Step 7: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/models/data/stat_rule.dart lib/game/systems/stat_gains.dart test/unit/stat_rule_test.dart test/unit/stat_rule_vocabulary_test.dart test/unit/stat_rule_conversion_test.dart test/unit/status_source_test.dart test/unit/content_editor/entity_validator_test.dart test/widget/debug_drawer_test.dart
git commit -F- <<'EOF'
feat(regles): ratio de conversion, sa borne et son arrondi

La regle de classe convertit une part de chaque gain, dans ]0, 1],
arrondie a l entier superieur a 1e-9 pres, jamais moins de 1. Le modele
refuse un ratio hors borne au chargement, que l editeur montre par sa
famille 7 ; le menu de debug le lit. Aucune classe ne le declare encore.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 4: La règle dit son taux — deux chaînes ARB, une seconde phrase

À ratio 1, la phrase ne change pas ; sinon une seconde phrase dit le taux et l'exemple de D37, calculé par `convertedAmount` (A7). Le titre court « ARMURE → PUISSANCE » ne change pas, le titre de l'étape du tutoriel non plus (`tutorial_data.dart:177-178`). Aucun appelant ne change : la carte de classe (`class_selection_screen.dart:646-649`) et l'encadré du tutoriel (`tutorial_armor_widget.dart:464-466`) appellent déjà `describe`.

**Files:**
- Modify: `lib/l10n/app_fr.arb:109` (ajout après), `lib/l10n/app_en.arb:178-183` (ajout après)
- Generated: `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_fr.dart`
- Modify: `lib/models/data/model_extensions.dart:154-166`
- Test: `test/unit/stat_rule_label_test.dart:40-53` (ajout après)

**Interfaces:**
- Consumes: `StatRule.ratio`, `StatRule.convertedAmount` (Task 3).
- Produces: `String AppLocalizations.statRuleRatioArmor(int percent, int amount, int converted)` et `statRuleRatioMana(int percent, int amount, int converted)` ; `StatRuleLabel.describe(AppLocalizations l10n)` rend une phrase à ratio 1, deux sinon, séparées par une espace.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/stat_rule_label_test.dart`, replace the end of the file:
```dart
    expect(regle.describe(fr), 'Son Mana devient de la Puissance pour un tour.');
    expect(regle.describe(en), 'Their Mana becomes Might for one turn.');
  });
}
```
with:
```dart
    expect(regle.describe(fr), 'Son Mana devient de la Puissance pour un tour.');
    expect(regle.describe(en), 'Their Mana becomes Might for one turn.');
  });

  // D37, A7 (spec P-43 E0, §5.1) : a un ratio autre que 1, une seconde phrase
  // dit le taux, et l'exemple de D37 tel que le moteur le calcule.
  test('a 0,5, la conversion d armure dit son taux et son exemple', () {
    const regle = StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
      ratio: 0.5,
    );

    expect(
      regle.describe(fr),
      'Son Armure devient de la Puissance pour un tour. '
      "Taux : 50%, arrondi à l'entier supérieur — 6 Armure → 3 Puissance.",
    );
    expect(
      regle.describe(en),
      'Their Armor becomes Might for one turn. '
      'Rate: 50%, rounded up — 6 Armor → 3 Might.',
    );
  });

  test('a 0,5, la conversion de mana dit son taux et son exemple', () {
    const regle = StatRule(
      stat: RuleStat.mana,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
      ratio: 0.5,
    );

    expect(
      regle.describe(fr),
      'Son Mana devient de la Puissance pour un tour. '
      "Taux : 50%, arrondi à l'entier supérieur — 6 Mana → 3 Puissance.",
    );
    expect(
      regle.describe(en),
      'Their Mana becomes Might for one turn. '
      'Rate: 50%, rounded up — 6 Mana → 3 Might.',
    );
  });
}
```
Les trois tests existants, à ratio 1, restent tels quels.

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/stat_rule_label_test.dart`
Expected: FAIL, `+3 -2: Some tests failed.` — à 0,5, `describe` ne rend encore que la première phrase.

- [ ] **Step 3: Les chaînes**

In `lib/l10n/app_fr.arb`, replace:
```json
  "statRuleConvertManaToMight": "{duration, plural, =1{Son Mana devient de la Puissance pour un tour.} other{Son Mana devient de la Puissance pour {duration} tours.}}",
```
with:
```json
  "statRuleConvertManaToMight": "{duration, plural, =1{Son Mana devient de la Puissance pour un tour.} other{Son Mana devient de la Puissance pour {duration} tours.}}",
  "statRuleRatioArmor": "Taux : {percent}%, arrondi à l'entier supérieur — {amount} Armure → {converted} Puissance.",
  "statRuleRatioMana": "Taux : {percent}%, arrondi à l'entier supérieur — {amount} Mana → {converted} Puissance.",
```
`50%` sans espace, comme les pourcentages du français existant (`app_fr.arb:64`, `:184`).

In `lib/l10n/app_en.arb` (le gabarit, `l10n.yaml`), replace:
```json
  "statRuleConvertManaToMight": "{duration, plural, =1{Their Mana becomes Might for one turn.} other{Their Mana becomes Might for {duration} turns.}}",
  "@statRuleConvertManaToMight": {
    "placeholders": {
      "duration": { "type": "int" }
    }
  },
```
with:
```json
  "statRuleConvertManaToMight": "{duration, plural, =1{Their Mana becomes Might for one turn.} other{Their Mana becomes Might for {duration} turns.}}",
  "@statRuleConvertManaToMight": {
    "placeholders": {
      "duration": { "type": "int" }
    }
  },
  "statRuleRatioArmor": "Rate: {percent}%, rounded up — {amount} Armor → {converted} Might.",
  "@statRuleRatioArmor": {
    "description": "Second sentence of a class rule whose conversion ratio is not 1: the rate as a percentage, and an example amount converted as the engine converts it.",
    "placeholders": {
      "percent": { "type": "int" },
      "amount": { "type": "int" },
      "converted": { "type": "int" }
    }
  },
  "statRuleRatioMana": "Rate: {percent}%, rounded up — {amount} Mana → {converted} Might.",
  "@statRuleRatioMana": {
    "description": "Second sentence of a class rule whose conversion ratio is not 1, for a class that converts its Mana.",
    "placeholders": {
      "percent": { "type": "int" },
      "amount": { "type": "int" },
      "converted": { "type": "int" }
    }
  },
```

Run: `flutter gen-l10n`
Expected: les trois `lib/l10n/app_localizations*.dart` gagnent `statRuleRatioArmor(int percent, int amount, int converted)` et `statRuleRatioMana(...)`, et rien d'autre (`git diff --stat lib/l10n` : des ajouts seulement). La ligne « To use the command line arguments, delete the l10n.yaml file » est informative.

- [ ] **Step 4: La seconde phrase**

In `lib/models/data/model_extensions.dart`, replace:
```dart
extension StatRuleLabel on StatRule {
  /// La règle en clair : « Son Armure devient de la Puissance pour un tour. »
  ///
  /// Générée à partir de la règle, jamais écrite classe par classe
  /// (spec P-41, §8.3). Le `switch` est **exhaustif** sur le triplet
  /// (ressource, mode, cible) : ajouter une valeur à l'une des trois
  /// énumérations sans son libellé ne compile plus.
  String describe(AppLocalizations l10n) => switch ((stat, mode, to)) {
        (RuleStat.armor, RuleMode.convert, RuleTarget.statusMight) =>
          l10n.statRuleConvertArmorToMight(duration),
        (RuleStat.mana, RuleMode.convert, RuleTarget.statusMight) =>
          l10n.statRuleConvertManaToMight(duration),
      };
```
with:
```dart
extension StatRuleLabel on StatRule {
  /// Le montant de l'exemple que la seconde phrase convertit : les
  /// « 6 Armure → 3 Puissance » de D37.
  static const int _ratioExampleAmount = 6;

  /// La règle en clair : « Son Armure devient de la Puissance pour un tour. »
  ///
  /// Quand son `ratio` diffère de 1, une seconde phrase dit le taux et un
  /// exemple : « Taux : 50%, arrondi à l'entier supérieur — 6 Armure →
  /// 3 Puissance. » L'exemple sort de [StatRule.convertedAmount], l'arithmétique
  /// même du moteur : il ne peut pas mentir sur elle (spec P-43 E0, A7, §5.1).
  ///
  /// Générée à partir de la règle, jamais écrite classe par classe
  /// (spec P-41, §8.3). Le `switch` est **exhaustif** sur le triplet
  /// (ressource, mode, cible) : ajouter une valeur à l'une des trois
  /// énumérations sans ses deux libellés ne compile plus.
  String describe(AppLocalizations l10n) {
    final percent = (ratio * 100).round();
    final converted = convertedAmount(_ratioExampleAmount);
    final (sentence, rate) = switch ((stat, mode, to)) {
      (RuleStat.armor, RuleMode.convert, RuleTarget.statusMight) => (
          l10n.statRuleConvertArmorToMight(duration),
          l10n.statRuleRatioArmor(percent, _ratioExampleAmount, converted),
        ),
      (RuleStat.mana, RuleMode.convert, RuleTarget.statusMight) => (
          l10n.statRuleConvertManaToMight(duration),
          l10n.statRuleRatioMana(percent, _ratioExampleAmount, converted),
        ),
    };
    return ratio == 1 ? sentence : '$sentence $rate';
  }
```
`shortTitle` (`:168-186`) ne change pas (A7).

- [ ] **Step 5: Lancer le test pour le voir passer**

Run: `flutter test test/unit/stat_rule_label_test.dart` — Expected: `+5: All tests passed!`

- [ ] **Step 6: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1228: All tests passed!` (1226 + 2).

- [ ] **Step 7: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart lib/models/data/model_extensions.dart test/unit/stat_rule_label_test.dart
git commit -F- <<'EOF'
feat(regles): la regle de classe dit son taux de conversion

A un ratio autre que 1, la regle en clair gagne une seconde phrase :
le taux, et la conversion de 6 telle que le moteur la calcule. A ratio
1, rien ne change. Deux chaines par langue.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 5: Le Berserker convertit à 0,5

La seule donnée qui change : *Mur de Fer* lui donne 5 Puissance au lieu de 10, *Défense* 3, *Éveil* et *Cri de Guerre* 2. Les tests qui vérifiaient la conversion 1:1 sur le vrai Berserker passent sur la conversion réelle. La seconde phrase de la règle fait déborder l'encadré de l'étape « Armure & Dégâts » à sa hauteur d'aujourd'hui (22 pixels, mesuré) : la hauteur passe de 480 à 510 (502 au plus juste). La carte de classe, elle, tient ses deux phrases sans retouche, sur mobile, sur bureau et sous `TextScaler.linear(1.3)` (mesuré). Aucun dossier neuf : `tool/sync_assets.dart` n'est pas à relancer.

**Files:**
- Modify: `assets/data/classes/berserker/class.json:15`
- Modify: `lib/tutorial/widgets/tutorial_armor_widget.dart:183-189`
- Modify: `lib/tutorial/tutorial_engine.dart:361-362` (commentaire)
- Test: `test/unit/class_identity_test.dart:49-55` ; `test/tutorial/tutorial_engine_test.dart:168-174`, `:278-280`, `:284-286` ; `test/widget/tutorial_armor_step_test.dart:95-103`, `:138`, `:152-155`, `:164-170` ; `test/widget/tutorial_play_card_step_test.dart:121-123` ; `test/widget/class_selection_screen_test.dart:94-101`

**Interfaces:**
- Consumes: `StatRule.ratio`, `convertedAmount` (Task 3) ; la seconde phrase de `describe` (Task 4).
- Produces: la règle du Berserker, `ratio` 0,5, lue par le jeu, le tutoriel (`tutorial_engine.dart:318-323`, `:399-407`, par `StatGains.apply` — ADR-081) et une run rechargée (relue du registre, `run_controller.dart:202-204`).

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/class_identity_test.dart`, replace:
```dart
      expect(rule.to, RuleTarget.statusMight);
      expect(rule.duration, 1);
    });
```
with:
```dart
      expect(rule.to, RuleTarget.statusMight);
      expect(rule.duration, 1);
      // D37 : la moitie de son armure, arrondie au superieur.
      expect(rule.ratio, 0.5);
    });
```

In `test/tutorial/tutorial_engine_test.dart`, replace:
```dart
      // Aucune Armure conservee, et la Puissance temporaire a sa place :
      // c'est `StatGains.apply` qui le decide, pas le tutoriel.
      expect(engine.mockState.heroStats.armure, 0);
      final buff = engine.mockState.heroStats.statuses
          .firstWhere((s) => s.id == 'might');
      expect(buff.value, valeur);
      expect(buff.duration, berserker.statRules.first.duration);
```
with:
```dart
      // Aucune Armure conservee, et la Puissance temporaire a sa place, au
      // taux de la classe : 5 Armure a 50 %, arrondi au superieur, font 3.
      // C'est `StatGains.apply` qui le decide, pas le tutoriel.
      expect(engine.mockState.heroStats.armure, 0);
      final buff = engine.mockState.heroStats.statuses
          .firstWhere((s) => s.id == 'might');
      expect(valeur, 5);
      expect(buff.value, 3);
      expect(buff.duration, berserker.statRules.first.duration);
```
then replace:
```dart
      // Le meme verdict que `playCard` : c'est le meme appel a StatGains.
      expect(engine.mockState.heroStats.armure, 0);
      expect(engine.mockState.heroStats.effectiveMight, 4);
```
with:
```dart
      // Le meme verdict que `playCard` : c'est le meme appel a StatGains —
      // 4 Armure au taux de la classe, 50 % : 2 Puissance.
      expect(engine.mockState.heroStats.armure, 0);
      expect(engine.mockState.heroStats.effectiveMight, 2);
```
and replace:
```dart
      // nettoyage, presser deux fois « Voir la difference » afficherait +4
      // puis +8 Puissance a un Berserker.
```
with:
```dart
      // nettoyage, presser deux fois « Voir la difference » afficherait +2
      // puis +4 Puissance a un Berserker.
```

In `test/widget/tutorial_armor_step_test.dart`, replace:
```dart
    // verifie la forme des deux panneaux, pas la conversion : ce qui la
    // prouve ici, ce sont '70/80' (le Berserker afficherait 74/80 s'il
    // gardait son Armure), le badge '4' de Puissance et Icons.bolt_rounded.
    expect(find.text('0'), findsNWidgets(2));
    // La Puissance temporaire produite est montree, avec sa valeur.
    expect(find.text('4'), findsOneWidget);
```
with:
```dart
    // verifie la forme des deux panneaux, pas la conversion : ce qui la
    // prouve ici, ce sont '70/80' (le Berserker afficherait 74/80 s'il
    // gardait son Armure), le badge '2' de Puissance et Icons.bolt_rounded.
    expect(find.text('0'), findsNWidgets(2));
    // La Puissance temporaire produite est montree, avec sa valeur : 4 Armure
    // au taux de la classe, 50 %.
    expect(find.text('2'), findsOneWidget);
```
then replace:
```dart
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('4'), findsOneWidget); // le badge de Puissance
```
with:
```dart
      expect(find.text('0'), findsNWidgets(2));
      expect(find.text('2'), findsOneWidget); // le badge de Puissance, a 50 %
```
(le commentaire voisin, « le badge droit afficherait 4 », parle du badge d'**Armure** sans conversion : il reste tel quel), then replace:
```dart
    expect(
      find.text('Son Armure devient de la Puissance pour un tour.'),
      findsOneWidget,
    );
```
with:
```dart
    // Deux phrases : la regle, puis son taux (spec P-43 E0, §5.1). L'encadre
    // les tient sans deborder — un debordement ferait echouer le test.
    expect(
      find.text(
        'Son Armure devient de la Puissance pour un tour. '
        "Taux : 50%, arrondi à l'entier supérieur — 6 Armure → 3 Puissance.",
      ),
      findsOneWidget,
    );
```
and replace:
```dart
    // +4, jamais +8 : `resetHeroStatsForDemo` efface les statuts entre deux
    // passages, sans quoi `addStatus` les empilerait. C'est le garde reel :
    // `_rightMightGain` (widget) est un delta borne a un seul appel de
    // `gainArmorForDemo`, donc toujours 0 ou 4 par construction, jamais 8,
    // que la classe empile ou non — le badge affiche ne peut donc jamais
    // trahir un empilement. Seul l'etat du moteur le peut.
    expect(engine.mockState.heroStats.effectiveMight, 4);
```
with:
```dart
    // +2, jamais +4 : `resetHeroStatsForDemo` efface les statuts entre deux
    // passages, sans quoi `addStatus` les empilerait. C'est le garde reel :
    // `_rightMightGain` (widget) est un delta borne a un seul appel de
    // `gainArmorForDemo`, donc toujours 0 ou 2 par construction, jamais 4,
    // que la classe empile ou non — le badge affiche ne peut donc jamais
    // trahir un empilement. Seul l'etat du moteur le peut.
    expect(engine.mockState.heroStats.effectiveMight, 2);
```

In `test/widget/tutorial_play_card_step_test.dart`, replace:
```dart
    expect(engine.mockState.heroStats.armure, 0);
    expect(find.text('+$valeur 🛡️'), findsNothing);
    expect(find.text('+$valeur ⚡'), findsOneWidget);
```
with:
```dart
    expect(engine.mockState.heroStats.armure, 0);
    expect(find.text('+$valeur 🛡️'), findsNothing);
    // 5 Armure au taux de la classe, 50 % arrondi au superieur : 3 Puissance.
    expect(valeur, 5);
    expect(find.text('+3 ⚡'), findsOneWidget);
```

In `test/widget/class_selection_screen_test.dart`, `_berserkerReel` — la copie du vrai Berserker, que les groupes « sans débordement » emploient (`:866`, `:1004`, sous `TextScaler.linear(1.3)` en `:950` et `:1073`) — replace:
```dart
  critChance: 10,
  mightTargets: {MightTarget.attack},
  statRules: [
    StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
    ),
  ],
  displayOrder: 2,
);
```
with:
```dart
  critChance: 10,
  mightTargets: {MightTarget.attack},
  statRules: [
    StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
      ratio: 0.5,
    ),
  ],
  displayOrder: 2,
);
```
Le `berserker` local du groupe de l'identité générée (`:667-684`, lu en `:734`) **reste à ratio 1** : son test garde la phrase seule.

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/class_identity_test.dart test/tutorial/tutorial_engine_test.dart test/widget/tutorial_armor_step_test.dart test/widget/tutorial_play_card_step_test.dart test/widget/class_selection_screen_test.dart`
Expected: FAIL — huit tests : `class_identity_test` (`-1`, le ratio vaut 1), `tutorial_engine_test` (`-2`), `tutorial_armor_step_test` (`-4`), `tutorial_play_card_step_test` (`-1`) ; `class_selection_screen_test` passe déjà (`+62`) : sa copie à 0,5 tient ses deux phrases sans déborder.

- [ ] **Step 3: La donnée**

In `assets/data/classes/berserker/class.json`, replace:
```json
    { "stat": "armor", "mode": "convert", "to": "status:might", "duration": 1 }
```
with:
```json
    { "stat": "armor", "mode": "convert", "to": "status:might", "duration": 1, "ratio": 0.5 }
```

In `lib/tutorial/tutorial_engine.dart`, replace:
```dart
  /// (`entity_stats.dart:134`). Sans ce nettoyage, rejouer la démonstration
  /// afficherait +4 puis +8 Puissance.
```
with:
```dart
  /// (`entity_stats.dart:134`). Sans ce nettoyage, rejouer la démonstration
  /// afficherait +2 puis +4 Puissance au Berserker.
```

Run: `flutter test test/widget/tutorial_armor_step_test.dart`
Expected: FAIL, `+2 -4` — `A RenderFlex overflowed by 22 pixels on the bottom` (et 6 pixels sur l'autre panneau) : la seconde phrase pousse les panneaux hors du cadre de 480.

- [ ] **Step 4: Le cadre de l'étape « Armure & Dégâts »**

In `lib/tutorial/widgets/tutorial_armor_widget.dart`, replace:
```dart
          // il pousserait les panneaux hors du cadre (`RenderFlex overflow`)
          // pour toute classe qui en déclare une.
          height: rules.isEmpty ? 380 : 480,
```
with:
```dart
          // il pousserait les panneaux hors du cadre (`RenderFlex overflow`)
          // pour toute classe qui en déclare une — davantage encore quand la
          // règle écrit son taux en seconde phrase, son ratio différant de 1
          // (spec P-43 E0, §5.3).
          height: rules.isEmpty ? 380 : 510,
```
Le cadre est sous un `FittedBox(fit: BoxFit.scaleDown)` : plus haut, il se réduit à l'écran au lieu de déborder. Le Paladin et le Mage, sans règle, gardent 380.

- [ ] **Step 5: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/class_identity_test.dart` — Expected: `+12: All tests passed!`
Run: `flutter test test/tutorial/tutorial_engine_test.dart` — Expected: `+47: All tests passed!`
Run: `flutter test test/widget/tutorial_armor_step_test.dart` — Expected: `+6: All tests passed!`
Run: `flutter test test/widget/tutorial_play_card_step_test.dart` — Expected: `+2: All tests passed!`
Run: `flutter test test/widget/class_selection_screen_test.dart` — Expected: `+62: All tests passed!`

- [ ] **Step 6: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1228: All tests passed!` (aucun test ajouté ni retiré), `tutorial_isolation_test.dart`, `real_bundle_load_test.dart` et `class_identity_test.dart` (reconstruction de `fromJsonWithReport`, `==` ratio compris) compris.

- [ ] **Step 7: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add assets/data/classes/berserker/class.json lib/tutorial/widgets/tutorial_armor_widget.dart lib/tutorial/tutorial_engine.dart test/unit/class_identity_test.dart test/tutorial/tutorial_engine_test.dart test/widget/tutorial_armor_step_test.dart test/widget/tutorial_play_card_step_test.dart test/widget/class_selection_screen_test.dart
git commit -F- <<'EOF'
feat(berserker): la moitie de l armure devient Puissance

Le Berserker convertit son Armure a 50 %, arrondie a l entier
superieur : Mur de Fer lui donne 5 Puissance, Defense 3. Sa carte de
classe et le tutoriel ecrivent le taux ; le cadre de l etape Armure
grandit pour la seconde phrase. Aucune carte ne change.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 6: Vérification finale

Rien à écrire ni à commiter : la tâche constate. Si une vérification échoue, la tâche qui possède le code la corrige par un commit neuf, et cette tâche se rejoue en entier.

**Files:** aucun.

**Interfaces:**
- Consumes: tout le lot.
- Produces: la branche `feat/v0.5.3-p43-e0-e1`, E0 implémenté, prête pour E1 — rien de poussé, aucune PR.

- [ ] **Step 1: Analyse et suite**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1228: All tests passed!` — 1187 + 41, dont `stat_gain_single_passage_test.dart` (ADR-095) et `tutorial_isolation_test.dart` (ADR-081), inchangés.

- [ ] **Step 2: Les neuf poseurs de Puissance et l'utilitaire unique (spec §4.2, §4.3)**

Run: `git grep -c "id: 'might'" -- lib`
Expected: neuf constructions — `lib/game/controllers/combat/status_effect_processor.dart:2`, `lib/game/controllers/combat/turn_phase_manager.dart:1`, `lib/game/controllers/run/player_stats_manager.dart:3`, `lib/game/services/effect_resolver.dart:1`, `lib/game/systems/passives/passive_strategies.dart:1`, `lib/game/systems/stat_gains.dart:1`.

Run: `git grep -n "StatusSource\.[a-z]*(" -- lib`
Expected: exactement neuf lignes — `status_effect_processor.dart` (deux `StatusSource.status('might_regen')`), `turn_phase_manager.dart` (`StatusSource.enemy(enemy.data.id)`), `player_stats_manager.dart` (trois `StatusSource.relic(relic.id)`), `effects/strategies.dart` (`StatusSource.card(card.data.id)`), `passive_strategies.dart` (`StatusSource.passive(passive.id)`), `stat_gains.dart` (`StatusSource.rule(rule.statName)`).

Run: `git grep -nE "'(card|rule|passive|relic|status|enemy):[$]" -- lib`
Expected: six lignes, toutes dans `lib/models/status_effect.dart` — le seul endroit qui écrive les formes.

Run: `git grep -n "== 'might'" -- lib/models/entity_stats.dart lib/models/status_effect.dart`
Expected: une ligne, `lib/models/entity_stats.dart:183`, dans `effectiveMight` — ni `addStatus` ni `mergesWith` ne testent l'identifiant `might` (A1 : la portée s'écrit dans la fabrique, pas dans la règle de fusion).

- [ ] **Step 3: La donnée**

Run: `git grep -n '"ratio"' -- assets`
Expected: une ligne, `assets/data/classes/berserker/class.json:15`.

- [ ] **Step 4: Ce que le lot ne touche pas**

Run: `git diff --stat main...HEAD -- lib/models/data/forge_upgrade_data.dart lib/services/content_editor/entity_descriptor.dart tool site assets/data/patch_notes.json pubspec.yaml macos linux windows`
Expected: aucune sortie — ni la donnée de rune, ni le descripteur de l'éditeur (A5), ni la simulation, ni `site/`, ni la note de version, ni la version, ni un fichier généré de plateforme.

Run: `git diff -U0 main...HEAD -- lib/game/services/effect_resolver.dart | grep "^@@"`
Expected: deux blocs, et seulement eux, tous deux dans `createStatus` (lignes 15 à 93 d'avant le lot) — sortie mesurée sur la copie du dépôt :
```
@@ -15,2 +15,12 @@ class EffectResolver {
@@ -32,0 +43 @@ class EffectResolver {
```
Le `switch` des runes et le bloc élémentaire sont intacts : c'est E1 qui les réécrit (spec A4, §4.8).

- [ ] **Step 5: L'arbre**

Run: `git status --short`
Expected: aucune sortie. Si des fichiers générés de plateforme apparaissent : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`, puis relancer.

Run: `git log --oneline main..HEAD`
Expected: les cinq commits du lot (Tasks 1 à 5), au-dessus des commits de documentation de la vague. Rien n'est poussé.

---

## Ce que le plan laisse à E1 et aux suivants

Repris de la spec, §2 « Hors d'E0 », pour mémoire — aucune tâche ne les fait :

1. **Le bloc élémentaire d'`effect_resolver.dart`** (`:176-220`) concatène encore `burn`, `freeze` et `shock` à la liste de l'ennemi. E1 le réécrit et les pose par `addStatus`, **sans source** (A4) ; il trouve `createStatus` avec sa signature finale, et le changement de jeu qu'A4 chiffre est livré et annoncé par E1.
2. **Le texte d'une carte d'armure qui lirait la règle de la classe** (« +3 Puissance » au lieu de « 6 Armure » chez le Berserker) : non planifié, signalé pour la file (A7).
3. **`mightRatio` par effet `damage` et le budget de Puissance** (D38) : P-44 lot 1 ; **`shock` par coup**, `weakness`, `vulnerable`, `freeze` lus comme des booléens : P-44 lot 1.
