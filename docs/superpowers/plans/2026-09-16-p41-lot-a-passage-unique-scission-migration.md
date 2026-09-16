# P-41 lot A — Passage unique des gains, scission des puissances, migration de sauvegarde — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Faire passer tout gain d'armure, de mana et de puissance par une fonction pure unique, scinder `attaque` en trois puissances, et poser la première chaîne de migration de sauvegarde, sous une nouvelle clé — **sans changer le comportement du jeu**.

**Architecture:** Une fonction pure `StatGains.apply(EntityStats, StatGain)` devient le seul endroit du code qui accorde un gain d'armure, de mana ou de puissance ; chaque gain y arrive étiqueté par sa source, ce qui préserve le périmètre actuel de la Maîtrise d'Armure (passifs seulement). `EntityStats.attaque` devient `attackPower`, rejoint par `skillPower` et `alterationPower` à 0 ; l'extension pure `PowerRules` décide quelle puissance renforce quel effet, selon la carte qui le porte. `SaveService` gagne un `SaveMigrator` qui amène un blob ancien à la version courante au lieu de l'effacer ; il écrit sous la clé `run_save`, que les builds déjà publiés ignorent, et ne détruit jamais une sauvegarde écrite par un build plus récent.

**Tech Stack:** Flutter / Dart 3.11, Flame, Riverpod 2 (`Notifier`), `shared_preferences`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md` — §4 (lot A), à lire avec §1 et §2.

## Global Constraints

- **Aucun changement de comportement pour le joueur**, à une conséquence près, voulue (spec §4.3) : une partie sauvegardée par un build du lot A n'est plus proposée par les builds antérieurs, au lieu d'y être effacée.
- `dart analyze` doit afficher `No issues found!` à la fin de **chaque** tâche.
- `flutter test` doit être **entièrement** vert à la fin de chaque tâche — pas seulement les tests nouveaux —, sauf pour une tâche qui n'ajoute que des fichiers que rien n'importe encore (Tasks 6 et 7) : ses tests ciblés et `dart analyze` suffisent, la tâche suivante relance la suite. Point de départ mesuré le 2026-09-16 : **811 tests**.
- **Ne jamais lancer `dart format`** : le dépôt ne l'utilise pas (120 fichiers sur 185 changeraient).
- Créer et modifier les fichiers avec les outils Write / Edit. **Jamais par heredoc bash** : les heredocs de cet environnement mangent les antislashs, et les expressions régulières du plan en contiennent. Les scripts Python du plan n'en contiennent aucun et peuvent passer par heredoc.
- Le tutoriel ne référence aucun provider d'état (ADR-081) — vérifié par `test/tutorial/tutorial_isolation_test.dart`. Il peut importer une fonction pure de `lib/game/systems/`.
- Ne pas toucher `assets/data/patch_notes.json` ni le champ `version:` de `pubspec.yaml` : ils appartiennent au skill `patch-notes-writer`.
- Le code va sur la branche `feat/p41-lot-a`, jamais sur `main`. Seule la documentation de Task 0 est commitée sur `main`.
- Messages de commit en français, forme `type(portee): message`, **sans accents ni apostrophes** (convention des commits récents), terminés par la ligne `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- Les commandes `flutter` peuvent réécrire les fichiers d'enregistrement des plugins sans en changer le contenu, fins de ligne seulement : `macos/Flutter/GeneratedPluginRegistrant.swift` et, dans un checkout neuf, les fichiers générés de `linux/flutter/` et de `windows/flutter/`. S'ils apparaissent dans `git status`, les restaurer (`git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`) ; ne jamais les commiter.
- **Règle des tests de caractérisation (Task 6)** : ils décrivent le code d'origine. Si l'un d'eux échoue avant la conversion de Task 8, c'est **le test** qui se trompe — l'aligner sur le comportement observé, jamais modifier le code pour le faire passer.
- Les greps qui vérifient la disparition d'un identifiant cherchent des **mots entiers** (`git grep -w`) : `setHeroStats`, par exemple, est aussi une sous-chaîne de `resetHeroStatsForDemo`, une API du tutoriel sans rapport.

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/game/controllers/run_controller.dart`, `lib/game/systems/state_sync_system.dart`, `lib/game/components/entities/hero_card.dart` | Suppression de la chaîne morte `bonusAttack` | 1 |
| `lib/services/save_migrations.dart` *(nouveau)* | `SaveMigrator`, `SaveFromNewerBuildException` et la chaîne de production `saveMigrator` | 2, 4 |
| `lib/services/save_service.dart` | Branche le migrateur ; écrit sous `run_save`, relit `run_save_v1` ; refuse sans l'effacer une sauvegarde plus récente | 2 |
| `lib/ui/screens/home_screen.dart`, `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb` et les trois fichiers `lib/l10n/app_localizations*.dart` régénérés | Message « partie d'une version plus récente » | 2 |
| `lib/models/entity_stats.dart` | Les trois puissances, leurs clés JSON, le commentaire de la Maîtrise | 3, 4, 8 |
| `lib/game/systems/power_rules.dart` *(nouveau)* | Extension `PowerRules` : bonus de dégâts par type de carte, bonus d'altération par cible | 5 |
| `lib/game/systems/stat_gains.dart` *(nouveau)* | `GainResource`, `GainSource`, `StatGain`, `StatGains.apply` | 7 |
| `lib/game/controllers/run/player_stats_manager.dart` | `grant`, conversion de 4 sites, suppression de `setHeroStats` | 8 |
| `lib/game/controllers/run_controller.dart` | Façade `grant`, suppression de `setHeroStats` | 8 |
| `lib/game/systems/trait_system.dart` | 4 gains de passif convertis | 8 |
| `lib/game/services/effects/strategies.dart` | Bonus de dégâts par type, altération, 2 gains convertis | 5, 8 |
| `lib/game/services/effect_resolver.dart` | Altération des runes, 2 gains convertis | 5, 8 |
| `lib/game/controllers/combat/status_effect_processor.dart` | 2 gains `armor_regen` convertis | 8 |
| `lib/game/controllers/combat/turn_phase_manager.dart` | Gain de l'intention « défense » converti | 8 |
| `lib/tutorial/tutorial_engine.dart` | Bonus de dégâts par type, gain d'armure converti | 5, 8 |
| `lib/game/components/card_component.dart`, `lib/game/components/widgets/card_text_renderer.dart` | Affichage des dégâts prévus par type de carte | 5 |
| 30 fichiers de `lib/` et `test/` | Renommage mécanique `attaque` → `attackPower` | 3 |

---

### Task 0: Documentation sur `main`, puis espace de travail

**À faire dans le checkout principal, avant d'invoquer le skill d'exécution.** Les skills d'exécution préparent un espace isolé à partir d'un commit : la documentation doit donc être commitée d'abord, sans quoi cet espace ne contiendrait ni la spec révisée ni ce plan. Elle va sur `main`, comme les commits `docs(memoire)` récents, pour que toute session voie le plan en cours.

**Files:** aucun fichier de code.

**Interfaces:**
- Consumes: la spec révisée, ce plan et la documentation associée, non commités sur `main` au 2026-09-16.
- Produces: un commit de documentation sur `main`, puis la branche `feat/p41-lot-a` créée depuis ce commit.

- [ ] **Step 1: Vérifier l'état de départ**

Run: `git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift` (fins de ligne seulement, voir Global Constraints), puis `git status --short`
Expected: exactement ces fichiers modifiés ou nouveaux, et rien d'autre :
```
 M .obsidian_vault/_memory_bank/activeContext.md
 M docs/INDEX.md
 M docs/ROADMAP.md
 M docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md
?? docs/superpowers/plans/2026-09-16-p41-lot-a-passage-unique-scission-migration.md
```

- [ ] **Step 2: Commiter la documentation sur `main`**

```bash
git add .obsidian_vault/_memory_bank/activeContext.md docs/INDEX.md docs/ROADMAP.md docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md docs/superpowers/plans/2026-09-16-p41-lot-a-passage-unique-scission-migration.md
git commit -F- <<'EOF'
docs(P-41): spec re-verifiee et decoupee en lots, plan du lot A

Six passes de verification contre le code, decisions D1 a D8 du
proprietaire, decoupage en lots A a D et chantier frere P-49. La revue
du plan ajoute une nouvelle cle de sauvegarde, que les builds publies
ignorent.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

- [ ] **Step 3: Créer l'espace de travail**

Avec `superpowers:subagent-driven-development` ou `superpowers:executing-plans` : laisser `superpowers:using-git-worktrees` créer l'espace isolé sur une branche `feat/p41-lot-a`, depuis le commit du Step 2.
Sans espace isolé : `git switch -c feat/p41-lot-a`.

- [ ] **Step 4: Mesurer la base**

Si le skill d'espace de travail vient de lancer la suite, reprendre son résultat au lieu de la relancer. Sinon :
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+811: All tests passed!`

---

### Task 1: Supprimer la chaîne morte `bonusAttack`

**Pourquoi cette tâche existe.** `RunState.effectiveAttaque` (`run_controller.dart:43`) n'a qu'un consommateur, `StateSyncSystem` (`state_sync_system.dart:39`), qui en tire `bonusAtt` pour le passer à `HeroCard.bonusAttack`. Ce champ est stocké et transmis (`hero_card.dart:13-183`), **jamais lu**. Task 3 renommerait cette chaîne ; `CLAUDE.md` interdit le code mort : elle disparaît d'abord, et le renommage n'a plus à y toucher.

**Files:**
- Modify: `lib/game/controllers/run_controller.dart:41-43`
- Modify: `lib/game/systems/state_sync_system.dart:39-57`
- Modify: `lib/game/components/entities/hero_card.dart:13`, `:25`, `:146-184`

**Interfaces:**
- Consumes: rien.
- Produces: `HeroCard(EntityStats stats, {required String imagePath})` et `void HeroCard.updateStats(EntityStats newStats)`, sans `bonusAttack`. `RunState.effectiveAttaque` n'existe plus ; `EntityStats.effectiveAttaque` reste.

- [ ] **Step 1: Vérifier que la chaîne est morte**

Run: `git grep -nw "bonusAttack\|_pendingBonusAttack\|bonusAtt" -- lib test`
Expected: seulement `lib/game/components/entities/hero_card.dart` (lignes 13, 25, 146, 149, 158, 163, 172, 177, 183) et `lib/game/systems/state_sync_system.dart` (lignes 39, 51, 57) — des déclarations, des affectations et des passages de paramètre, aucune lecture.

Run: `git grep -nw "effectiveAttaque" -- lib/game/controllers/run_controller.dart lib/game/systems/state_sync_system.dart`
Expected: `run_controller.dart:43`, le getter de `RunState`, et `state_sync_system.dart:39`, son seul appel.

- [ ] **Step 2: Supprimer le getter de `RunState`**

In `lib/game/controllers/run_controller.dart`, replace:

```dart
  bool get isDead => heroStats.currentPv <= 0;

  int get effectiveAttaque => heroStats.effectiveAttaque;
```

with:

```dart
  bool get isDead => heroStats.currentPv <= 0;
```

- [ ] **Step 3: Ne plus calculer ni transmettre `bonusAtt`**

In `lib/game/systems/state_sync_system.dart`, replace:

```dart
    int bonusAtt = state.effectiveAttaque - state.heroStats.attaque;

    if (game.heroCard == null) {
```

with:

```dart
    if (game.heroCard == null) {
```

Replace:

```dart
        state.heroStats,
        bonusAttack: bonusAtt,
        imagePath: heroData.classCard,
```

with:

```dart
        state.heroStats,
        imagePath: heroData.classCard,
```

Replace:

```dart
      game.heroCard!.updateStats(state.heroStats, bonusAttack: bonusAtt);
```

with:

```dart
      game.heroCard!.updateStats(state.heroStats);
```

- [ ] **Step 4: Retirer `bonusAttack` de `HeroCard`**

In `lib/game/components/entities/hero_card.dart`, replace:

```dart
  EntityStats stats;
  int bonusAttack;
  final String imagePath;
```

with:

```dart
  EntityStats stats;
  final String imagePath;
```

Replace:

```dart
  HeroCard(this.stats, {this.bonusAttack = 0, required this.imagePath})
```

with:

```dart
  HeroCard(this.stats, {required this.imagePath})
```

Replace:

```dart
  int _pendingBonusAttack = 0;
  bool _pendingSuppressArmorChange = false;

  void updateStats(EntityStats newStats, {int bonusAttack = 0}) {
```

with:

```dart
  bool _pendingSuppressArmorChange = false;

  void updateStats(EntityStats newStats) {
```

Replace:

```dart
      _pendingStats = newStats;
      _pendingBonusAttack = bonusAttack;
      _pendingSuppressArmorChange = suppress;
      return;
    }

    _applyStats(newStats, bonusAttack, suppress);
```

with:

```dart
      _pendingStats = newStats;
      _pendingSuppressArmorChange = suppress;
      return;
    }

    _applyStats(newStats, suppress);
```

Replace:

```dart
    _applyStats(pending, _pendingBonusAttack, _pendingSuppressArmorChange);
```

with:

```dart
    _applyStats(pending, _pendingSuppressArmorChange);
```

Replace:

```dart
  void _applyStats(
    EntityStats newStats,
    int bonusAttack,
    bool suppressArmorChange,
  ) {
    triggerHitReactions(stats, newStats, suppressArmorChange: suppressArmorChange);

    stats = newStats;
    this.bonusAttack = bonusAttack;
  }
```

with:

```dart
  void _applyStats(EntityStats newStats, bool suppressArmorChange) {
    triggerHitReactions(stats, newStats, suppressArmorChange: suppressArmorChange);

    stats = newStats;
  }
```

- [ ] **Step 5: Vérifier**

Run: `git grep -nw "bonusAttack\|_pendingBonusAttack\|bonusAtt" -- lib test` — Expected: aucune sortie.
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+811: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/game/controllers/run_controller.dart lib/game/systems/state_sync_system.dart lib/game/components/entities/hero_card.dart
git commit -F- <<'EOF'
refactor(hud): supprimer la chaine morte bonusAttack

RunState.effectiveAttaque ne servait qu a calculer HeroCard.bonusAttack,
un champ transmis mais jamais lu.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 2: La chaîne de migration, sous une nouvelle clé, sans étape

**Pourquoi d'abord et à vide.** `SaveService.load` efface toute sauvegarde dont `schemaVersion` diffère de 1 (`save_service.dart:79-89`). Cette tâche pose l'infrastructure **sans rien migrer** : la version courante reste 1 et le contenu écrit ne change pas. La première étape arrive avec le changement de format, en Task 4.

**Pourquoi une nouvelle clé (spec §4.3, décision D8).** Toutes les versions web sont servies depuis la même origine et restent en ligne : elles partagent le même stockage, donc la clé `run_save_v1`. Les builds publiés jusqu'à `0.5.1` effacent toute sauvegarde de version autre que 1, et ne peuvent plus être corrigés. Le jeu écrit donc désormais sous `run_save`, que ces builds ignorent, et relit `run_save_v1` à défaut. Et parce que ce build sera un jour l'ancien, il **ne détruit jamais** une sauvegarde écrite par un build plus récent : il la refuse, la conserve, et l'écran d'accueil dit pourquoi.

**Files:**
- Create: `lib/services/save_migrations.dart`
- Modify: `lib/services/save_service.dart` (import, `SaveLoadResult`, clés, `save`, `hasSave`, `clear`, `load`)
- Modify: `lib/ui/screens/home_screen.dart:33-39`
- Modify: `lib/l10n/app_fr.arb:142`, `lib/l10n/app_en.arb:338` ; régénérés : `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_fr.dart`
- Test: `test/unit/save_migrations_test.dart` *(nouveau)*, `test/unit/save_service_test.dart`, `test/widget/home_screen_save_test.dart`

**Interfaces:**
- Consumes: rien.
- Produces:
  - `typedef SaveMigrationStep = Map<String, dynamic> Function(Map<String, dynamic> save);`
  - `class SaveFromNewerBuildException implements Exception { const SaveFromNewerBuildException(int version); final int version; }`
  - `class SaveMigrator { const SaveMigrator({required int currentVersion, required Map<int, SaveMigrationStep> steps}); final int currentVersion; final Map<int, SaveMigrationStep> steps; Map<String, dynamic> migrate(Map<String, dynamic> save); }` — `steps[n]` fait passer la version n à n + 1. `migrate` lève `FormatException` sur une version absente, non entière ou inférieure à 1, `SaveFromNewerBuildException` sur une version supérieure à `currentVersion`, `StateError` si une étape manque.
  - `const saveMigrator` — la chaîne de production : `currentVersion: 1`, aucune étape.
  - `SaveLoadResult.savedByNewerBuild` : `bool`, défaut `false`.
  - Clés de stockage : `run_save`, écrite ; `run_save_v1`, relue à défaut et retirée à la sauvegarde suivante.
  - Clés ARB `newerSaveTitle` et `newerSaveMessage`.

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/unit/save_migrations_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/save_migrations.dart';

Map<String, dynamic> _addA(Map<String, dynamic> save) => {...save, 'a': true};

Map<String, dynamic> _addB(Map<String, dynamic> save) =>
    {...save, 'b': save['a'] == true};

void main() {
  group('SaveMigrator', () {
    const migrator = SaveMigrator(
      currentVersion: 3,
      steps: {1: _addA, 2: _addB},
    );

    test('une sauvegarde a la version courante ressort intacte', () {
      final save = <String, dynamic>{'schemaVersion': 3, 'x': 1};
      expect(migrator.migrate(save), {'schemaVersion': 3, 'x': 1});
    });

    test('une sauvegarde ancienne traverse chaque etape dans l ordre', () {
      final migrated = migrator.migrate(<String, dynamic>{'schemaVersion': 1});

      expect(migrated['a'], isTrue);
      expect(migrated['b'], isTrue, reason: '_addB doit voir le travail de _addA');
      expect(migrated['schemaVersion'], 3);
    });

    test('une sauvegarde intermediaire ne rejoue pas les etapes passees', () {
      final migrated = migrator.migrate(<String, dynamic>{'schemaVersion': 2});

      expect(migrated.containsKey('a'), isFalse);
      expect(migrated['b'], isFalse);
      expect(migrated['schemaVersion'], 3);
    });

    for (final version in <Object?>[null, 0, '1']) {
      test('la version $version est une sauvegarde corrompue', () {
        expect(
          () => migrator.migrate(<String, dynamic>{'schemaVersion': version}),
          throwsFormatException,
        );
      });
    }

    test('une version plus recente est refusee, pas corrompue', () {
      expect(
        () => migrator.migrate(<String, dynamic>{'schemaVersion': 4}),
        throwsA(
          isA<SaveFromNewerBuildException>()
              .having((e) => e.version, 'version', 4),
        ),
      );
    });

    test('une etape manquante est une erreur de programmation', () {
      const holed = SaveMigrator(currentVersion: 3, steps: {1: _addA});

      expect(
        () => holed.migrate(<String, dynamic>{'schemaVersion': 1}),
        throwsStateError,
      );
    });
  });

  group('saveMigrator (production)', () {
    test('une etape existe pour chaque version anterieure, et aucune autre', () {
      expect(
        saveMigrator.steps.keys.toSet(),
        {for (var v = 1; v < saveMigrator.currentVersion; v++) v},
      );
    });
  });
}
```

In `test/unit/save_service_test.dart`, in the test `'a save still carrying a "skills" key loads without error'`, replace:

```dart
      final payload =
          jsonDecode(prefs.getString('run_save_v1')!) as Map<String, dynamic>;
      payload['skills'] = {'skill1Cooldown': 2, 'skill2Cooldown': 0};
      await prefs.setString('run_save_v1', jsonEncode(payload));
```

with:

```dart
      final payload =
          jsonDecode(prefs.getString('run_save')!) as Map<String, dynamic>;
      payload['skills'] = {'skill1Cooldown': 2, 'skill2Cooldown': 0};
      await prefs.setString('run_save', jsonEncode(payload));
```

Replace:

```dart
      await prefs.setString('run_save_v1', 'not valid json {{{');
```

with:

```dart
      await prefs.setString('run_save', 'not valid json {{{');
```

Replace the whole test `'load returns a failed result on an unknown schemaVersion'`:

```dart
    test('load returns a failed result on an unknown schemaVersion', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'run_save_v1',
        '{"schemaVersion": 999, "run": {}, "deck": {}, "inventory": {}, "skills": {}}',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = await SaveService.load(container.read);

      expect(result.success, isFalse);
      expect(await SaveService.hasSave(), isFalse);
    });
```

with:

```dart
    test('load refuses a save written by a newer build and keeps it', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'run_save',
        '{"schemaVersion": 999, "run": {}, "deck": {}, "inventory": {}}',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = await SaveService.load(container.read);

      expect(result.success, isFalse);
      expect(result.savedByNewerBuild, isTrue);
      expect(await SaveService.hasSave(), isTrue);
    });

    test('load returns a failed result and clears storage when schemaVersion is missing', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('run_save', '{"run": {}, "deck": {}, "inventory": {}}');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = await SaveService.load(container.read);

      expect(result.success, isFalse);
      expect(result.savedByNewerBuild, isFalse);
      expect(await SaveService.hasSave(), isFalse);
    });

    test('save writes under run_save and retires the legacy run_save_v1', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('run_save_v1', '{"schemaVersion": 1}');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await SaveService.save(container.read);

      expect(prefs.containsKey('run_save'), isTrue);
      expect(prefs.containsKey('run_save_v1'), isFalse);
    });

    test('load falls back to a legacy run_save_v1 save', () async {
      const hero = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        baseDamage: 5,
        passiveTrait: 'regen_armor',
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(hero);
      await SaveService.save(container.read);

      // Remet la sauvegarde sous l'ancienne clé, là où la laisse un build
      // publié jusqu'à 0.5.1.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('run_save_v1', prefs.getString('run_save')!);
      await prefs.remove('run_save');

      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      final result = await SaveService.load(fresh.read);

      expect(result.success, isTrue);
      expect(fresh.read(runProvider).heroClassId, 'paladin');
    });

    test('clear also removes a legacy run_save_v1 save', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('run_save_v1', '{"schemaVersion": 1}');
      expect(await SaveService.hasSave(), isTrue);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await SaveService.clear(container.read);

      expect(await SaveService.hasSave(), isFalse);
    });
```

In `test/widget/home_screen_save_test.dart`, replace both occurrences (edit with replace-all) of:

```dart
        'run_save_v1': '{"schemaVersion":1,"run":{},"deck":{},"inventory":{},"skills":{}}',
```

with:

```dart
        'run_save': '{"schemaVersion":1,"run":{},"deck":{},"inventory":{},"skills":{}}',
```

Replace:

```dart
          'run_save_v1',
          '{"schemaVersion":1,"run":{},"deck":{},"inventory":{},"skills":{}}',
```

with:

```dart
          'run_save',
          '{"schemaVersion":1,"run":{},"deck":{},"inventory":{},"skills":{}}',
```

Then add this test just after the test `'Nouvelle Partie shows a confirmation dialog when a save exists'` (it ends at line 124), inside the same `group`:

```dart
    testWidgets('Continuer explains a save written by a newer build and keeps it', (tester) async {
      SharedPreferences.setMockInitialValues({
        'run_save': '{"schemaVersion":999,"run":{},"deck":{},"inventory":{}}',
      });

      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(find.text("Partie d'une version plus récente"), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Continuer'), findsOneWidget);
      expect(await SaveService.hasSave(), isTrue);
    });
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `flutter test test/unit/save_migrations_test.dart test/unit/save_service_test.dart test/widget/home_screen_save_test.dart`
Expected: FAIL.
- `save_migrations_test.dart` ne compile pas : `Error when reading 'lib/services/save_migrations.dart'`.
- `save_service_test.dart` ne compile pas : `The getter 'savedByNewerBuild' isn't defined for the type 'SaveLoadResult'`.
- Dans `home_screen_save_test.dart`, quatre tests sur cinq échouent, faute pour le code actuel de regarder la clé `run_save` : le test ajouté, sur `tap`, et les trois tests existants dont la sauvegarde vient de passer sous cette clé (`Found 0 widgets with text "Continuer"`, ou `pumpAndSettle timed out` pour la confirmation de nouvelle partie). Seul `CONTINUER is hidden when no save exists` passe.
- Flutter affiche aussi `The Dart compiler exited unexpectedly` au chargement d'un fichier voisin : c'est l'écho de l'erreur de compilation, pas un défaut de plus. Résumé mesuré le 2026-09-16 : `+1 -6`.

- [ ] **Step 3: Écrire le migrateur**

Create `lib/services/save_migrations.dart`:

```dart
/// Une étape de migration : reçoit le blob décodé d'une version N et rend
/// celui de la version N + 1. Fonction pure, sans provider ; elle peut
/// modifier la map reçue et la rendre.
typedef SaveMigrationStep = Map<String, dynamic> Function(
  Map<String, dynamic> save,
);

/// Levée par [SaveMigrator.migrate] pour une sauvegarde écrite par un build
/// plus récent que celui-ci. Ce n'est pas une sauvegarde corrompue : elle est
/// refusée sans être effacée, pour que le build qui sait la lire la retrouve
/// (spec P-41, §4.3).
class SaveFromNewerBuildException implements Exception {
  final int version;

  const SaveFromNewerBuildException(this.version);

  @override
  String toString() => 'SaveFromNewerBuildException: schemaVersion $version';
}

/// Amène un blob de sauvegarde, lu à n'importe quelle version connue, à la
/// version courante (spec P-41, §4.3).
///
/// [steps] associe à chaque version l'étape qui la quitte : `steps[1]` fait
/// passer la version 1 à 2. La version courante est **déclarée**, jamais
/// déduite du nombre d'étapes : une étape supprimée, ou deux branches qui
/// ajoutent chacune la leur, font échouer `test/unit/save_migrations_test.dart`
/// ou la fusion, au lieu de renuméroter la chaîne en silence.
class SaveMigrator {
  final int currentVersion;
  final Map<int, SaveMigrationStep> steps;

  const SaveMigrator({required this.currentVersion, required this.steps});

  /// Une version absente, non entière ou inférieure à 1 lève une
  /// [FormatException] : `SaveService` traite la sauvegarde comme corrompue.
  /// Une version supérieure à [currentVersion] lève une
  /// [SaveFromNewerBuildException] : `SaveService` la conserve.
  Map<String, dynamic> migrate(Map<String, dynamic> save) {
    final version = save['schemaVersion'];
    if (version is! int || version < 1) {
      throw FormatException('Unsupported or missing schemaVersion: $version');
    }
    if (version > currentVersion) {
      throw SaveFromNewerBuildException(version);
    }
    var migrated = save;
    for (var from = version; from < currentVersion; from++) {
      final step = steps[from];
      if (step == null) {
        throw StateError('No save migration step from version $from');
      }
      migrated = step(migrated);
      migrated['schemaVersion'] = from + 1;
    }
    return migrated;
  }
}

/// La chaîne de production. Monter `currentVersion` et ajouter l'étape qui
/// quitte l'ancienne version vont toujours ensemble.
const saveMigrator = SaveMigrator(currentVersion: 1, steps: {});
```

- [ ] **Step 4: Brancher le migrateur et la nouvelle clé dans `SaveService`**

In `lib/services/save_service.dart`:

Add the import after `import '../models/missing_save_item.dart';`:

```dart
import 'save_migrations.dart';
```

Replace:

```dart
class SaveLoadResult {
  final bool success;
  final List<MissingSaveItem> missingItems;

  const SaveLoadResult({required this.success, this.missingItems = const []});
}
```

with:

```dart
class SaveLoadResult {
  final bool success;
  final List<MissingSaveItem> missingItems;

  /// La sauvegarde a été écrite par un build plus récent : elle n'est pas
  /// chargée, mais elle est conservée pour ce build-là.
  final bool savedByNewerBuild;

  const SaveLoadResult({
    required this.success,
    this.missingItems = const [],
    this.savedByNewerBuild = false,
  });
}
```

Replace:

```dart
  static const String _saveKey = 'run_save_v1';
  static const int _schemaVersion = 1;
```

with:

```dart
  // La version vit dans le blob, et `saveMigrator` amène un blob ancien à la
  // version courante. La clé n'a changé qu'une fois : les builds publiés
  // jusqu'à 0.5.1 lisent `run_save_v1` et effacent toute version autre que 1.
  // Toutes les versions web partagent le même stockage, et ces builds-là ne
  // se corrigent plus (spec P-41, §4.3).
  static const String _saveKey = 'run_save';
  static const String _legacySaveKey = 'run_save_v1';
```

Replace:

```dart
      'schemaVersion': _schemaVersion,
```

with:

```dart
      'schemaVersion': saveMigrator.currentVersion,
```

Replace:

```dart
    await prefs.setString(_saveKey, jsonEncode(payload));
  }
```

with:

```dart
    await prefs.setString(_saveKey, jsonEncode(payload));
    // La partie vit désormais sous la nouvelle clé : l'ancienne copie ne doit
    // plus être proposée, ni ici, ni par un build antérieur.
    await prefs.remove(_legacySaveKey);
  }
```

Replace:

```dart
    return prefs.containsKey(_saveKey);
```

with:

```dart
    return prefs.containsKey(_saveKey) || prefs.containsKey(_legacySaveKey);
```

Replace:

```dart
    await prefs.remove(_saveKey);
  }
```

with:

```dart
    await prefs.remove(_saveKey);
    await prefs.remove(_legacySaveKey);
  }
```

Replace:

```dart
    final raw = prefs.getString(_saveKey);
```

with:

```dart
    final raw = prefs.getString(_saveKey) ?? prefs.getString(_legacySaveKey);
```

Replace:

```dart
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> ||
          decoded['schemaVersion'] != _schemaVersion) {
        throw const FormatException('Unsupported or missing schemaVersion');
      }
      json = decoded;
    } catch (e) {
```

with:

```dart
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Save data is not a JSON object');
      }
      json = saveMigrator.migrate(decoded);
    } on SaveFromNewerBuildException catch (e) {
      // Ni lisible ici, ni corrompue : la laisser intacte pour le build qui
      // l'a écrite. L'écran d'accueil l'explique au joueur.
      if (kDebugMode) {
        debugPrint('SaveService.load: save written by a newer build ($e)');
      }
      return const SaveLoadResult(success: false, savedByNewerBuild: true);
    } catch (e) {
```

- [ ] **Step 5: Expliquer le refus à l'écran d'accueil**

In `lib/l10n/app_fr.arb`, replace:

```json
  "missingItemsMessage": "Certains éléments ne sont plus disponibles suite à une mise à jour et ont été retirés : {items}. Votre progression a été conservée.",
```

with:

```json
  "missingItemsMessage": "Certains éléments ne sont plus disponibles suite à une mise à jour et ont été retirés : {items}. Votre progression a été conservée.",
  "newerSaveTitle": "Partie d'une version plus récente",
  "newerSaveMessage": "Cette partie a été sauvegardée par une version plus récente du jeu. Elle est conservée : ouvrez cette version pour la reprendre.",
```

In `lib/l10n/app_en.arb`, replace:

```json
  "missingItemsMessage": "Some items are no longer available due to an update and have been removed: {items}. Your progress has been kept.",
```

with:

```json
  "missingItemsMessage": "Some items are no longer available due to an update and have been removed: {items}. Your progress has been kept.",
  "newerSaveTitle": "Game from a newer version",
  "newerSaveMessage": "This game was saved by a newer version of the game. It has been kept: open that version to resume it.",
```

Run: `flutter gen-l10n` — Expected: aucune erreur ; `lib/l10n/app_localizations.dart`, `app_localizations_en.dart` et `app_localizations_fr.dart` gagnent `newerSaveTitle` et `newerSaveMessage`.

In `lib/ui/screens/home_screen.dart`, replace:

```dart
    if (!result.success) {
      // The save was corrupted or unreadable; SaveService.load already
      // cleared it internally, so simply refresh this screen — the
      // "Continuer" button will disappear on rebuild.
      setState(() {});
      return;
    }
```

with:

```dart
    if (!result.success) {
      if (result.savedByNewerBuild) {
        // Écrite par un build plus récent : SaveService.load l'a conservée et
        // le bouton « Continuer » reste. Dire pourquoi elle ne s'ouvre pas.
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => GameDialog(
            title: Text(AppLocalizations.of(context)!.newerSaveTitle),
            content: Text(AppLocalizations.of(context)!.newerSaveMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
        return;
      }
      // The save was corrupted or unreadable; SaveService.load already
      // cleared it internally, so simply refresh this screen — the
      // "Continuer" button will disappear on rebuild.
      setState(() {});
      return;
    }
```

- [ ] **Step 6: Vérifier**

Run: `flutter test test/unit/save_migrations_test.dart test/unit/save_service_test.dart test/widget/home_screen_save_test.dart` — Expected: PASS
Run: `git grep -n "run_save_v1" -- lib` — Expected: deux lignes, toutes deux dans `lib/services/save_service.dart` : le commentaire qui explique le changement de clé et la constante `_legacySaveKey`.
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+825: All tests passed!` (mesuré le 2026-09-16 sur la base de 811).

- [ ] **Step 7: Commit**

```bash
git add lib/services/save_migrations.dart lib/services/save_service.dart lib/ui/screens/home_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart test/unit/save_migrations_test.dart test/unit/save_service_test.dart test/widget/home_screen_save_test.dart
git commit -F- <<'EOF'
feat(sauvegarde): chaine de migration sous une nouvelle cle

Aucune etape encore : la version courante reste 1. Le jeu ecrit sous
run_save, que les builds publies ignorent, et relit run_save_v1 a
defaut. Une sauvegarde ecrite par un build plus recent est conservee au
lieu d etre effacee, et l ecran d accueil explique pourquoi elle ne
s ouvre pas.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 3: Renommer `attaque` en `attackPower`

**Nature.** Renommage mécanique des identifiants Dart, **clé JSON inchangée** : `toJson` écrit toujours `'attaque'` et `fromJson` le lit toujours. Les sauvegardes existantes se chargent donc sans migration à cette étape. Le paramètre `playerAttaque` (`combat_controller.dart`, `encounter_system.dart`, `combat_debug_logger.dart`, `game_screen.dart`) est un autre identifiant et **n'est pas renommé** — la casse du `A` empêche le script de le toucher.

**Files:** 17 fichiers de `lib/`, 13 de `test/` — la liste exacte est l'affichage attendu du Step 1.

**Interfaces:**
- Consumes: la suppression de `RunState.effectiveAttaque` et de `bonusAtt` (Task 1).
- Produces: `EntityStats.attackPower` (champ, constructeur, `copyWith`), `EntityStats.effectiveAttackPower` (getter), paramètres de widget `effectiveAttackPower` sur `CombatBottomHud` et `PlayerHealthBar`.

- [ ] **Step 1: Appliquer le renommage**

Run (le script ne contient aucun antislash, le heredoc est sûr) :

```bash
python - <<'PY'
import io, pathlib
pairs = [
 ("effectiveAttaque", "effectiveAttackPower"),
 ("return attaque + bonus;", "return attackPower + bonus;"),
 ("final int attaque;", "final int attackPower;"),
 ("required this.attaque,", "required this.attackPower,"),
 ("int? attaque,", "int? attackPower,"),
 ("attaque: attaque ?? this.attaque,", "attackPower: attackPower ?? this.attackPower,"),
 ("attaque: json['attaque'] as int,", "attackPower: json['attaque'] as int,"),
 ("'attaque': attaque,", "'attaque': attackPower,"),
 (".attaque", ".attackPower"),
 ("attaque:", "attackPower:"),
]
total = 0
for root in ("lib", "test"):
    for p in sorted(pathlib.Path(root).rglob("*.dart")):
        s = io.open(p, encoding="utf-8").read()
        n = 0
        for a, b in pairs:
            n += s.count(a)
            s = s.replace(a, b)
        if n:
            io.open(p, "w", encoding="utf-8", newline="").write(s)
            total += n
            print(f"{n:3d}  {p.as_posix()}")
print("TOTAL", total)
PY
```

Expected: `TOTAL 101`, répartis ainsi (mesuré le 2026-09-16, sur le code tel que Task 1 le laisse) :

```
  1  lib/game/components/card_component.dart
  4  lib/game/components/entities/enemy_card.dart
  2  lib/game/components/widgets/card_text_renderer.dart
  1  lib/game/controllers/combat_controller.dart
  2  lib/game/controllers/run/player_stats_manager.dart
  2  lib/game/controllers/run_controller.dart
  2  lib/game/services/effects/strategies.dart
  5  lib/models/enemy_instance.dart
  8  lib/models/entity_stats.dart
  5  lib/tutorial/tutorial_engine.dart
  3  lib/tutorial/widgets/tutorial_enemy_intents_widget.dart
  3  lib/ui/screens/game_screen.dart
  2  lib/ui/widgets/debug/tabs/debug_hero_tab.dart
  4  lib/ui/widgets/hud/combat_bottom_hud.dart
  3  lib/ui/widgets/hud/player_health_bar.dart
  1  lib/ui/widgets/map/dialogs/stats_dialog.dart
  1  lib/ui/widgets/map/hero_mini_stats_panel.dart
  8  test/encounter_system_test.dart
 14  test/unit/combat_controller_test.dart
  1  test/unit/debug_actions_test.dart
 17  test/unit/effect_resolver_test.dart
  1  test/unit/event_controller_test.dart
  1  test/unit/notifier_hydrate_test.dart
  2  test/unit/relic_exchange_test.dart
  1  test/unit/reward_controller_test.dart
  1  test/unit/run_state_persistence_test.dart
  1  test/widget/debug_drawer_test.dart
  2  test/widget/draft_screen_test.dart
  2  test/widget/enemy_intents_panel_overflow_test.dart
  1  test/widget/player_health_bar_test.dart
```

Si le total diffère, **arrêter** : un fichier a changé depuis la rédaction du plan. Inspecter le diff avant d'aller plus loin (`git diff --stat`).

- [ ] **Step 2: Vérifier qu'aucun identifiant `attaque` ne subsiste**

Run: `git grep -nE "effectiveAttaque|\.attaque\b|\battaque:" -- lib test`
Expected: aucune sortie.

Run: `git grep -nw attaque -- lib/models/entity_stats.dart`
Expected: exactement ces trois lignes — la lecture et l'écriture de la clé JSON, et un commentaire :

```
lib/models/entity_stats.dart:91:      attackPower: json['attaque'] as int,
lib/models/entity_stats.dart:110:    'attaque': attackPower,
lib/models/entity_stats.dart:166:  /// Calcule l'attaque effective en prenant en compte les buffs de force
```

Toute autre ligne est un identifiant que le script a manqué : le corriger à la main avant le Step 3.

- [ ] **Step 3: Vérifier**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: tout vert, même nombre de tests qu'à la fin de Task 2 (`+825`).

- [ ] **Step 4: Commit**

Le script a réécrit les 30 fichiers en fins de ligne LF : `git add` affiche autant d'avertissements `LF will be replaced by CRLF`, sans effet sur le contenu du commit.

```bash
git add -u lib test
git commit -F- <<'EOF'
refactor(stats): attaque devient attackPower

Renommage mecanique des identifiants. La cle JSON reste attaque :
elle change avec sa migration.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 4: Les trois puissances, leurs clés JSON et l'étape de migration v1 → v2

**Files:**
- Modify: `lib/models/entity_stats.dart` (champs, constructeur, `copyWith`, `fromJson`, `toJson`)
- Modify: `lib/services/save_migrations.dart` (première étape)
- Test: `test/unit/save_migrations_test.dart`, `test/unit/save_service_test.dart`

**Interfaces:**
- Consumes: `SaveMigrator`, `saveMigrator` (Task 2) ; `EntityStats.attackPower` (Task 3).
- Produces:
  - `EntityStats.skillPower` et `EntityStats.alterationPower` : `int`, défaut `0`, dans le constructeur et `copyWith`.
  - Clés JSON `attackPower`, lue strictement comme `attaque` avant elle, et `skillPower`, `alterationPower`, lues à 0 quand elles manquent, comme `luck` ou `critChance` ; la clé `attaque` disparaît.
  - `saveMigrator` : `currentVersion: 2`, étape `1: _migrateV1ToV2`.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/save_migrations_test.dart`, add these tests at the end of the group `'saveMigrator (production)'`, after the test `'une etape existe pour chaque version anterieure, et aucune autre'`:

```dart
    test('v1 vers v2 : attaque devient attackPower', () {
      final migrated = saveMigrator.migrate(<String, dynamic>{
        'schemaVersion': 1,
        'run': <String, dynamic>{
          'heroStats': <String, dynamic>{'maxPv': 80, 'attaque': 7},
        },
      });

      final run = migrated['run'] as Map<String, dynamic>;
      final heroStats = run['heroStats'] as Map<String, dynamic>;
      expect(migrated['schemaVersion'], 2);
      expect(heroStats.containsKey('attaque'), isFalse);
      expect(heroStats['attackPower'], 7);
      expect(heroStats['maxPv'], 80);
    });

    test('une v1 sans stats de heros est refusee', () {
      expect(
        () => saveMigrator.migrate(<String, dynamic>{
          'schemaVersion': 1,
          'run': <String, dynamic>{},
        }),
        throwsFormatException,
      );
    });
```

In `test/unit/save_service_test.dart`, add this test inside the `group`, after the test `'clear also removes a legacy run_save_v1 save'` (Task 2):

```dart
    test('load migrates a legacy v1 save: attaque is kept as attackPower', () async {
      const hero = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        baseDamage: 5,
        passiveTrait: 'regen_armor',
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

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `flutter test test/unit/save_migrations_test.dart test/unit/save_service_test.dart`
Expected: FAIL.
- `save_migrations_test.dart` compile et échoue à l'exécution : la chaîne n'a pas encore d'étape, donc la v1 ressort telle quelle (`Expected: <2>`, `Actual: <1>`) et la v1 sans stats de héros n'est pas refusée.
- `save_service_test.dart` ne compile pas : `The getter 'skillPower' isn't defined for the type 'EntityStats'`.
- Flutter affiche aussi `The Dart compiler exited unexpectedly` au chargement de `save_migrations_test.dart`, compté comme un échec : le résumé est `+9 -4` (une erreur de compilation, ce message, deux échecs à l'exécution), et les tests de ce fichier s'exécutent bien.

- [ ] **Step 3: Ajouter les deux puissances à `EntityStats`**

In `lib/models/entity_stats.dart`:

Replace:

```dart
  final int attackPower;
```

with:

```dart
  final int attackPower; // Dégâts des cartes Attaque — la Force s'y ajoute
  final int skillPower; // Dégâts des cartes Compétence
  final int alterationPower; // Intensité des statuts posés sur un ennemi
```

Replace:

```dart
    required this.attackPower,
```

with:

```dart
    required this.attackPower,
    this.skillPower = 0,
    this.alterationPower = 0,
```

Replace (in the `copyWith` parameter list):

```dart
    int? attackPower,
```

with:

```dart
    int? attackPower,
    int? skillPower,
    int? alterationPower,
```

Replace (in the `copyWith` body):

```dart
      attackPower: attackPower ?? this.attackPower,
```

with:

```dart
      attackPower: attackPower ?? this.attackPower,
      skillPower: skillPower ?? this.skillPower,
      alterationPower: alterationPower ?? this.alterationPower,
```

Replace (in `fromJson`):

```dart
      attackPower: json['attaque'] as int,
```

with:

```dart
      attackPower: json['attackPower'] as int,
      skillPower: json['skillPower'] as int? ?? 0,
      alterationPower: json['alterationPower'] as int? ?? 0,
```

Replace (in `toJson`):

```dart
    'attaque': attackPower,
```

with:

```dart
    'attackPower': attackPower,
    'skillPower': skillPower,
    'alterationPower': alterationPower,
```

- [ ] **Step 4: Ajouter l'étape v1 → v2**

In `lib/services/save_migrations.dart`, replace:

```dart
/// La chaîne de production. Monter `currentVersion` et ajouter l'étape qui
/// quitte l'ancienne version vont toujours ensemble.
const saveMigrator = SaveMigrator(currentVersion: 1, steps: {});
```

with:

```dart
/// La chaîne de production. Monter `currentVersion` et ajouter l'étape qui
/// quitte l'ancienne version vont toujours ensemble.
const saveMigrator = SaveMigrator(
  currentVersion: 2,
  steps: {1: _migrateV1ToV2},
);

/// v1 → v2 (P-41, lot A) : `attaque` devient `attackPower`. `skillPower` et
/// `alterationPower` n'ont pas à être écrites : `EntityStats.fromJson` les lit
/// à 0 quand elles manquent. Aucun ennemi n'est sérialisé : `SaveService`
/// n'est jamais appelé en combat.
Map<String, dynamic> _migrateV1ToV2(Map<String, dynamic> save) {
  final run = save['run'];
  final heroStats = run is Map<String, dynamic> ? run['heroStats'] : null;
  if (heroStats is! Map<String, dynamic>) {
    throw const FormatException('v1 save without run.heroStats');
  }
  heroStats['attackPower'] = heroStats.remove('attaque');
  return save;
}
```

- [ ] **Step 5: Vérifier**

Run: `flutter test test/unit/save_migrations_test.dart test/unit/save_service_test.dart` — Expected: PASS
Run: `git grep -n "remove('attaque')" -- lib` — Expected: une seule ligne, dans `lib/services/save_migrations.dart`.
Run: `git grep -n "\['attaque'\]\|'attaque':" -- lib` — Expected: aucune sortie : ni lecture ni écriture de la clé ne subsiste. (Les tests la citent volontairement : ne pas chercher dans `test/`.)
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+828: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/models/entity_stats.dart lib/services/save_migrations.dart test/unit/save_migrations_test.dart test/unit/save_service_test.dart
git commit -F- <<'EOF'
feat(stats): trois puissances et premiere etape de migration de sauvegarde

skillPower et alterationPower rejoignent attackPower, a 0. Une sauvegarde
v1 est migree en v2 au chargement au lieu d etre effacee.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 5: Chaque puissance s'applique à son type de carte

**Règle (spec §4.2).** `attackPower` et la Force s'ajoutent aux dégâts des cartes Attaque ; `skillPower` aux dégâts des cartes Compétence ; rien aux cartes Pouvoir et Statut. `alterationPower` s'ajoute à l'intensité d'un statut posé sur un ennemi — par une carte ou par une rune d'altération —, jamais à sa durée. **Aucun changement visible aujourd'hui** : les 12 effets `damage` du catalogue sont tous sur des cartes Attaque, et `skillPower` comme `alterationPower` valent 0 pour tout le monde.

**Où vit la règle.** Dans une extension pure, `PowerRules`, rangée à côté de `StatGains` dans `lib/game/systems/` — pas sur `EntityStats`. Le modèle est partagé avec les ennemis, qui n'ont que faire d'une règle de héros, et il n'importe aujourd'hui que `meta` et `status_effect.dart` : y lire `CardType` le ferait dépendre de `card_data.dart`, donc du registre de données. Une seule règle sert ainsi la résolution d'une carte, ses runes, le tutoriel et l'aperçu des dégâts ; le lot B y branchera les `statRules`.

**Files:**
- Create: `lib/game/systems/power_rules.dart`
- Modify: `lib/game/services/effects/strategies.dart` (import, `DamageEffectStrategy`, `ApplyStatusEffectStrategy`)
- Modify: `lib/game/services/effect_resolver.dart` (import, runes d'altération `:175-187`)
- Modify: `lib/tutorial/tutorial_engine.dart` (import, `:345`)
- Modify: `lib/game/components/card_component.dart` (import, `:343`, `:365`)
- Modify: `lib/game/components/widgets/card_text_renderer.dart` (import, `:94`, `:123`, `:356`, `:379`)
- Test: `test/unit/power_split_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `EntityStats.attackPower`, `skillPower`, `alterationPower`, `effectiveAttackPower` (Tasks 3-4) ; `EffectResolver.resolveCard(CardInstance, RunController, DeckNotifier, CombatController, String?, EffectRegistry)` et `effectRegistryProvider` — existants.
- Produces: `extension PowerRules on EntityStats { int damageBonusFor(CardType type); int statusBonusFor(CardTarget target); }` dans `lib/game/systems/power_rules.dart`.

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/unit/power_split_test.dart`:

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
import 'package:roguelike_card_game/models/status_effect.dart';

const _strength = StatusEffect(
  id: 'strength',
  name: 'Force',
  type: StatusType.buff,
  value: 5,
  duration: 2,
);

void main() {
  group('PowerRules.damageBonusFor', () {
    final stats = EntityStats(
      maxPv: 50,
      currentPv: 50,
      armure: 0,
      attackPower: 2,
      skillPower: 3,
      alterationPower: 4,
      statuses: const [_strength],
    );

    test('une carte Attaque recoit la puissance d attaque et la Force', () {
      expect(stats.damageBonusFor(CardType.attack), 7);
    });

    test('une carte Competence recoit sa puissance, sans la Force', () {
      expect(stats.damageBonusFor(CardType.skill), 3);
    });

    test('les cartes Pouvoir et Statut ne recoivent aucun bonus', () {
      expect(stats.damageBonusFor(CardType.power), 0);
      expect(stats.damageBonusFor(CardType.status), 0);
    });
  });

  group('PowerRules.statusBonusFor', () {
    final stats = EntityStats(
      maxPv: 50,
      currentPv: 50,
      armure: 0,
      attackPower: 2,
      alterationPower: 4,
    );

    test('un statut pose sur un ou plusieurs ennemis recoit alterationPower', () {
      expect(stats.statusBonusFor(CardTarget.singleEnemy), 4);
      expect(stats.statusBonusFor(CardTarget.allEnemies), 4);
    });

    test('un statut pose sur soi, ou sans cible, ne recoit rien', () {
      expect(stats.statusBonusFor(CardTarget.self), 0);
      expect(stats.statusBonusFor(CardTarget.none), 0);
    });
  });

  group('resolution d une carte', () {
    const hero = HeroData(
      id: 'mage',
      classCard: 'mage.png',
      maxHp: 60,
      maxMana: 3,
      baseDamage: 0,
      passiveTrait: 'spell_armor',
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
      run.startNewRun(hero);
      run.updateState(
        run.currentState.copyWith(
          heroStats: run.currentState.heroStats.copyWith(
            skillPower: 3,
            alterationPower: 2,
          ),
        ),
      );
      final enemy = EnemyInstance(
        data: slime,
        stats: EntityStats(
          maxPv: 100,
          currentPv: 100,
          armure: 0,
          attackPower: 1,
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

    test('une Competence offensive ajoute skillPower, pas la Force', () {
      run.addStatus(_strength);

      play(card(CardType.skill, CardTarget.singleEnemy, const [
        CardEffect(type: 'damage', value: 5),
      ]));

      expect(enemy().stats.currentPv, 100 - (5 + 3));
    });

    test('un statut pose sur l ennemi gagne alterationPower en intensite', () {
      play(card(CardType.attack, CardTarget.singleEnemy, const [
        CardEffect(type: 'apply_status', value: 4, statusId: 'poison', duration: 3),
      ]));

      final poison = enemy().stats.statuses.singleWhere((s) => s.id == 'poison');
      expect(poison.value, 4 + 2);
      expect(poison.duration, 3);
    });

    test('un statut pose sur soi ignore alterationPower', () {
      play(card(CardType.skill, CardTarget.self, const [
        CardEffect(type: 'apply_status', value: 2, statusId: 'strength', duration: 1),
      ]));

      final strength = run.currentState.heroStats.statuses
          .singleWhere((s) => s.id == 'strength');
      expect(strength.value, 2);
    });

    test('une rune d altération gagne alterationPower en intensite', () {
      play(card(
        CardType.attack,
        CardTarget.singleEnemy,
        const [CardEffect(type: 'damage', value: 1)],
        runes: const ['burning:1'],
      ));

      final burn = enemy().stats.statuses.singleWhere((s) => s.id == 'burn');
      expect(burn.value, 1 + 2);
      expect(burn.duration, 1);
    });
  });
}
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `flutter test test/unit/power_split_test.dart`
Expected: FAIL à la compilation — `Error when reading 'lib/game/systems/power_rules.dart'`.

- [ ] **Step 3: Écrire `PowerRules`**

Create `lib/game/systems/power_rules.dart`:

```dart
import '../../models/data/card_data.dart';
import '../../models/entity_stats.dart';

/// Les règles d'attribution des trois puissances (spec P-41, §4.2) : quelle
/// puissance renforce quel effet, selon la carte qui le porte.
///
/// Règle pure, sans provider : la résolution d'une carte, ses runes, le
/// tutoriel (ADR-081) et l'aperçu des dégâts lisent la même. Elle vit ici et
/// non sur `EntityStats`, partagé avec les ennemis, qui n'en ont pas l'usage.
extension PowerRules on EntityStats {
  /// Bonus ajouté aux dégâts d'un effet `damage`, selon le type de la carte
  /// qui le porte. La Force ne renforce que les cartes Attaque ; une carte
  /// Pouvoir ou Statut ne reçoit rien, par construction.
  int damageBonusFor(CardType type) => switch (type) {
        CardType.attack => effectiveAttackPower,
        CardType.skill => skillPower,
        CardType.power || CardType.status => 0,
      };

  /// Bonus ajouté à l'intensité d'un statut posé par une carte ou par l'une
  /// de ses runes. La puissance d'altération ne renforce qu'un statut posé sur
  /// un ennemi — jamais sa durée, et jamais un buff posé sur soi : sans cette
  /// borne, la Force scalerait avec elle et l'altération se bouclerait.
  int statusBonusFor(CardTarget target) => switch (target) {
        CardTarget.singleEnemy || CardTarget.allEnemies => alterationPower,
        CardTarget.self || CardTarget.none => 0,
      };
}
```

- [ ] **Step 4: Appliquer le bonus aux dégâts**

In `lib/game/services/effects/strategies.dart`:

Add the import after `import '../../controllers/combat_controller.dart';`:

```dart
import '../../systems/power_rules.dart';
```

Replace both occurrences (edit with replace-all) of:

```dart
          initialDamage: scaledValue + runController.currentState.heroStats.effectiveAttackPower,
```

with:

```dart
          initialDamage: scaledValue + runController.currentState.heroStats.damageBonusFor(card.data.type),
```

In `lib/tutorial/tutorial_engine.dart`, replace:

```dart
import '../game/services/damage_pipeline.dart';
```

with:

```dart
import '../game/services/damage_pipeline.dart';
import '../game/systems/power_rules.dart';
```

and replace:

```dart
          initialDamage: scaled + mockState.heroStats.effectiveAttackPower,
```

with:

```dart
          initialDamage: scaled + mockState.heroStats.damageBonusFor(card.data.type),
```

In `lib/game/components/card_component.dart`:

Add the import after `import '../game_constants.dart';`:

```dart
import '../systems/power_rules.dart';
```

Replace:

```dart
    final heroAttack = game.heroCard?.stats.effectiveAttackPower ?? 0;
```

with:

```dart
    final damageBonus = game.heroCard?.stats.damageBonusFor(card.data.type) ?? 0;
```

and replace:

```dart
        final totalDmg = scaledValue + heroAttack;
```

with:

```dart
        final totalDmg = scaledValue + damageBonus;
```

In `lib/game/components/widgets/card_text_renderer.dart`:

Add the import after `import '../card_component.dart';`:

```dart
import '../../systems/power_rules.dart';
```

Replace both occurrences (edit with replace-all) of:

```dart
heroAttack = card.game.heroCard?.stats.effectiveAttackPower ?? 0;
```

with:

```dart
damageBonus = card.game.heroCard?.stats.damageBonusFor(card.card.data.type) ?? 0;
```

then replace:

```dart
          valueToDisplay = scaledValue + heroAttack;
```

with:

```dart
          valueToDisplay = scaledValue + damageBonus;
```

and replace:

```dart
        final totalDmg = scaledValue + heroAttack;
```

with:

```dart
        final totalDmg = scaledValue + damageBonus;
```

- [ ] **Step 5: Appliquer `alterationPower` aux statuts posés sur un ennemi**

In `lib/game/services/effects/strategies.dart`, in `ApplyStatusEffectStrategy.resolve`, replace:

```dart
    if (effect.statusId != null) {
      final status = EffectResolver.createStatus(
        effect.statusId!,
        scaledValue,
        effect.duration ?? 1,
      );
```

with:

```dart
    if (effect.statusId != null) {
      // Le ciblage se lit sur la carte, pas sur l'effet : `CardEffect` n'en a pas.
      final status = EffectResolver.createStatus(
        effect.statusId!,
        scaledValue +
            runController.currentState.heroStats.statusBonusFor(card.data.target),
        effect.duration ?? 1,
      );
```

In `lib/game/services/effect_resolver.dart`:

Add the import after `import '../controllers/combat_controller.dart';`:

```dart
import '../systems/power_rules.dart';
```

Replace:

```dart
      final List<StatusEffect> extraStatuses = [];
      if (elementBurn > 0) {
        final st = createStatus('burn', elementBurn, elementBurn);
        if (st != null) extraStatuses.add(st);
      }
      if (elementFreeze > 0) {
        final st = createStatus('freeze', elementFreeze, elementFreeze);
        if (st != null) extraStatuses.add(st);
      }
      if (elementShock > 0) {
        final st = createStatus('shock', elementShock, elementShock);
        if (st != null) extraStatuses.add(st);
      }
```

with:

```dart
      final List<StatusEffect> extraStatuses = [];
      // Même règle qu'un statut posé par la carte (`PowerRules`) : ces runes
      // sont résolues ici, hors du registre de stratégies.
      final bonus =
          runController.currentState.heroStats.statusBonusFor(card.data.target);
      if (elementBurn > 0) {
        final st = createStatus('burn', elementBurn + bonus, elementBurn);
        if (st != null) extraStatuses.add(st);
      }
      if (elementFreeze > 0) {
        final st = createStatus('freeze', elementFreeze + bonus, elementFreeze);
        if (st != null) extraStatuses.add(st);
      }
      if (elementShock > 0) {
        final st = createStatus('shock', elementShock + bonus, elementShock);
        if (st != null) extraStatuses.add(st);
      }
```

- [ ] **Step 6: Vérifier**

Run: `flutter test test/unit/power_split_test.dart` — Expected: PASS
Run: `git grep -nw "heroAttack\|effectiveAttackPower" -- lib/game/components/card_component.dart lib/game/components/widgets/card_text_renderer.dart lib/game/services/effects/strategies.dart lib/tutorial/tutorial_engine.dart`
Expected: aucune sortie. (Ailleurs, `effectiveAttackPower` reste légitime : `PowerRules`, les ennemis et le HUD lisent toujours l'attaque effective.)
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+837: All tests passed!`

- [ ] **Step 7: Commit**

```bash
git add lib/game/systems/power_rules.dart lib/game/services/effects/strategies.dart lib/game/services/effect_resolver.dart lib/tutorial/tutorial_engine.dart lib/game/components/card_component.dart lib/game/components/widgets/card_text_renderer.dart test/unit/power_split_test.dart
git commit -F- <<'EOF'
feat(stats): chaque puissance s applique a son type de carte

attackPower et la Force aux cartes Attaque, skillPower aux cartes
Competence, alterationPower aux statuts poses sur un ennemi, par une
carte ou par une rune. Une seule regle, PowerRules, pour la resolution,
le tutoriel et l apercu. Sans effet visible : tous les degats du
catalogue sont portes par des cartes Attaque et les deux nouvelles
puissances valent 0.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 6: Figer le comportement actuel des gains

**Nature.** Tests de caractérisation : ils décrivent le code **d'origine** et doivent passer **avant** toute conversion. Task 8 convertit les gains ; ces tests, inchangés, prouvent alors que le jeu n'a pas bougé. Deux gains sont déjà couverts ailleurs et ne sont pas redupliqués : l'intention « défense » d'un ennemi (`test/unit/combat_controller_test.dart:191-192`) et l'armure d'une carte du tutoriel (`test/tutorial/tutorial_engine_test.dart:75-88`). `berserker_armor` avec Maîtrise est aussi couvert, par le vrai chemin `startCombat` et à 20 PV manquants (`test/unit/run_controller_test.dart:66-118`) : le test ci-dessous n'y ajoute que l'arrondi par tranche de 10 PV, à 25 PV manquants.

Rappel de la règle globale : **si un test échoue ici, c'est lui qui se trompe.**

**Files:**
- Test: `test/unit/stat_gains_characterization_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `RunController.startNewRun(HeroData, [PassiveData?])`, `takeDamage`, `applyRelicEffect(RelicData)`, `applyHeroStatModifier({int attackAcc})`, `TraitSystem.onTurnStart/onTurnEnd/onCardPlayed`, `StatusEffectProcessor.processPlayerStatuses/processEnemyStatuses`, `EffectResolver.resolveCard` — tous existants.
- Produces: aucun code de production.

- [ ] **Step 1: Écrire les tests**

Create `test/unit/stat_gains_characterization_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat/status_effect_processor.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/game/services/effects/effect_strategy.dart';
import 'package:roguelike_card_game/game/systems/trait_system.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

/// Fige le comportement des gains d'armure, de mana et de puissance tel qu'il
/// était avant leur passage par `StatGains` (spec P-41, §4.1). Ces tests
/// passent sur le code d'origine et restent inchangés après la conversion :
/// c'est la preuve que le lot A ne change rien au jeu.
///
/// Couverts ailleurs : l'intention « défense » d'un ennemi
/// (`combat_controller_test.dart`) et l'armure d'une carte du tutoriel
/// (`tutorial/tutorial_engine_test.dart`).
void main() {
  // Une Maîtrise d'Armure non nulle : elle ne doit s'ajouter qu'aux passifs.
  const paladin = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
    armorMastery: 3,
    passiveTrait: 'regen_armor',
  );

  const metallicize = StatusEffect(
    id: 'armor_regen',
    name: 'Metallisation',
    type: StatusType.buff,
    value: 3,
    duration: 2,
  );

  late ProviderContainer container;
  late RunController run;

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
  });

  tearDown(() => container.dispose());

  EntityStats heroStats() => run.currentState.heroStats;

  CardInstance card(
    CardType type,
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
        target: CardTarget.self,
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
      container.read(combatProvider.notifier),
      null,
      container.read(effectRegistryProvider),
    );
    expect(played, isTrue);
  }

  RelicData relic(String effectType, int value) => RelicData(
        id: 'test_relic',
        trigger: RelicTrigger.startOfTurn,
        effectType: effectType,
        value: value,
        rarity: RelicRarity.common,
        emoji: '*',
      );

  PassiveData passive(RelicTrigger trigger, String effectType, int value) =>
      PassiveData(
        id: 'test_passive',
        trigger: trigger,
        effectType: effectType,
        value: value,
      );

  group('armure hors passifs : la valeur seule, jamais la Maitrise', () {
    setUp(() => run.startNewRun(paladin));

    test('carte', () {
      play(card(CardType.skill, const [CardEffect(type: 'armor', value: 10)]));
      expect(heroStats().armure, 10);
    });

    test('rune hardened sur une carte sans effet d armure', () {
      play(card(CardType.attack, const [], runes: const ['hardened:1']));
      expect(heroStats().armure, 2);
    });

    test('relique gain_armor', () {
      run.applyRelicEffect(relic('gain_armor', 4));
      expect(heroStats().armure, 4);
    });

    test('relique charge_armor_turn : a la quatrieme charge', () {
      final incense = relic('charge_armor_turn', 6);
      for (var i = 0; i < 3; i++) {
        run.applyRelicEffect(incense);
      }
      expect(heroStats().armure, 0);

      run.applyRelicEffect(incense);
      expect(heroStats().armure, 6);
    });

    test('statut armor_regen du heros', () {
      final stats = StatusEffectProcessor.processPlayerStatuses(
        heroStats().addStatus(metallicize),
      );
      expect(stats.armure, 3);
    });

    test('statut armor_regen d un ennemi', () {
      final enemyStats = EntityStats(
        maxPv: 20,
        currentPv: 20,
        armure: 1,
        attackPower: 2,
        statuses: const [metallicize],
      );
      expect(StatusEffectProcessor.processEnemyStatuses(enemyStats).armure, 4);
    });
  });

  group('armure des passifs : la valeur plus la Maitrise', () {
    test('gain_armor en debut de tour', () {
      run.startNewRun(paladin, passive(RelicTrigger.startOfTurn, 'gain_armor', 2));
      TraitSystem.onTurnStart(run);
      expect(heroStats().armure, 2 + 3);
    });

    test('gain_armor en fin de tour', () {
      run.startNewRun(paladin, passive(RelicTrigger.endOfTurn, 'gain_armor', 2));
      TraitSystem.onTurnEnd(run);
      expect(heroStats().armure, 2 + 3);
    });

    test('berserker_armor : par tranche de 10 PV manquants', () {
      run.startNewRun(
        paladin,
        passive(RelicTrigger.startOfTurn, 'berserker_armor', 1),
      );
      run.takeDamage(25);
      TraitSystem.onTurnStart(run);
      expect(heroStats().armure, 2 * 1 + 3);
    });

    test('berserker_armor a pleine vie : rien, pas meme la Maitrise', () {
      run.startNewRun(
        paladin,
        passive(RelicTrigger.startOfTurn, 'berserker_armor', 1),
      );
      TraitSystem.onTurnStart(run);
      expect(heroStats().armure, 0);
    });

    test('spell_armor : sur une Competence seulement', () {
      run.startNewRun(
        paladin,
        passive(RelicTrigger.onCardPlayed, 'spell_armor', 1),
      );

      TraitSystem.onCardPlayed(run, card(CardType.attack, const []));
      expect(heroStats().armure, 0);

      TraitSystem.onCardPlayed(run, card(CardType.skill, const []));
      expect(heroStats().armure, 1 + 3);
    });
  });

  group('mana : aucun plafond', () {
    setUp(() => run.startNewRun(paladin));

    test('carte gain_mana', () {
      play(card(CardType.skill, const [CardEffect(type: 'gain_mana', value: 2)]));
      expect(heroStats().currentMana, 3 + 2);
    });

    test('rune eco', () {
      play(card(CardType.skill, const [], runes: const ['eco:1']));
      expect(heroStats().currentMana, 3 + 1);
    });

    test('relique gain_mana hors debut de run', () {
      run.applyRelicEffect(relic('gain_mana', 2));
      expect(heroStats().currentMana, 3 + 2);
    });
  });

  group('puissance d attaque par progression', () {
    setUp(() => run.startNewRun(paladin));

    test('un gain, puis un retrait de meme valeur', () {
      run.applyHeroStatModifier(attackAcc: 4);
      expect(heroStats().attackPower, 4);

      run.applyHeroStatModifier(attackAcc: -4);
      expect(heroStats().attackPower, 0);
    });
  });
}
```

- [ ] **Step 2: Vérifier qu'ils passent sur le code d'origine**

Run: `flutter test test/unit/stat_gains_characterization_test.dart`
Expected: PASS, 15 tests (`+15: All tests passed!`). Un échec signifie que le test décrit mal le code : corriger le test, jamais le code.

- [ ] **Step 3: Commit**

```bash
git add test/unit/stat_gains_characterization_test.dart
git commit -F- <<'EOF'
test(stats): figer le comportement des gains avant leur passage unique

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 7: `StatGains`, la fonction pure

**Files:**
- Create: `lib/game/systems/stat_gains.dart`
- Test: `test/unit/stat_gains_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `EntityStats` avec `attackPower`, `skillPower`, `alterationPower`, `effectiveArmorMastery` (Tasks 3-4).
- Produces:
  - `enum GainResource { armor, mana, attackPower, skillPower, alterationPower }`
  - `enum GainSource { card, rune, passive, relic, status, progression, enemyIntent }`
  - `class StatGain { const StatGain(GainResource resource, int amount, GainSource source); }`
  - `static EntityStats StatGains.apply(EntityStats stats, StatGain gain)`

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/unit/stat_gains_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/stat_gains.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

void main() {
  EntityStats stats() => EntityStats(
        maxPv: 50,
        currentPv: 40,
        maxMana: 3,
        currentMana: 3,
        armure: 1,
        armorMastery: 3,
        attackPower: 2,
        lastActionWasCrit: true,
      );

  group('StatGains.apply', () {
    test('armure d une carte : la valeur seule', () {
      const gain = StatGain(GainResource.armor, 10, GainSource.card);
      expect(StatGains.apply(stats(), gain).armure, 1 + 10);
    });

    for (final source in GainSource.values.where((s) => s != GainSource.passive)) {
      test('armure de source ${source.name} : jamais de Maitrise', () {
        final gain = StatGain(GainResource.armor, 2, source);
        expect(StatGains.apply(stats(), gain).armure, 1 + 2);
      });
    }

    test('armure d un passif : la valeur plus la Maitrise', () {
      const gain = StatGain(GainResource.armor, 2, GainSource.passive);
      expect(StatGains.apply(stats(), gain).armure, 1 + 2 + 3);
    });

    test('la Maitrise d un passif compte le statut armor_mastery', () {
      final boosted = stats().addStatus(
        const StatusEffect(
          id: 'armor_mastery',
          name: 'Maitrise',
          type: StatusType.buff,
          value: 1,
          duration: 2,
        ),
      );
      const gain = StatGain(GainResource.armor, 2, GainSource.passive);
      expect(StatGains.apply(boosted, gain).armure, 1 + 2 + 3 + 1);
    });

    test('un passif de valeur 0 rend quand meme la Maitrise', () {
      const gain = StatGain(GainResource.armor, 0, GainSource.passive);
      expect(StatGains.apply(stats(), gain).armure, 1 + 3);
    });

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
      expect(after.armorMastery, 3);
      expect(after.lastActionWasCrit, isTrue);
    });
  });
}
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `flutter test test/unit/stat_gains_test.dart`
Expected: FAIL à la compilation — `Error when reading 'lib/game/systems/stat_gains.dart'`.

- [ ] **Step 3: Écrire `StatGains`**

Create `lib/game/systems/stat_gains.dart`:

```dart
import '../../models/entity_stats.dart';

/// La ressource qu'un gain augmente.
enum GainResource { armor, mana, attackPower, skillPower, alterationPower }

/// D'où vient un gain. C'est ce qui permet à une règle de ne viser qu'une
/// provenance : la Maîtrise d'Armure ne s'ajoute qu'aux gains `passive`.
enum GainSource {
  card,
  rune,
  passive,
  relic,
  status,

  /// Montée permanente d'une stat : récompense de niveau, événement, relique
  /// de début de run et son retrait (un gain négatif) — tout ce qui passe par
  /// `applyHeroStatModifier`.
  progression,
  enemyIntent,
}

/// Un gain décrit, pas encore appliqué.
class StatGain {
  final GainResource resource;
  final int amount;
  final GainSource source;

  const StatGain(this.resource, this.amount, this.source);
}

/// Le point de passage unique des gains d'armure, de mana et de puissance
/// (spec P-41, §4.1).
///
/// Aucun code n'accorde plus lui-même un gain à ces stats : il le décrit et le
/// confie à [apply], seul endroit à savoir quelles règles s'y appliquent. Une
/// seule exception, voulue par la spec : la remontée du mana courant qui suit
/// une hausse de `maxMana`, dans `applyHeroStatModifier`. Fonction pure, sans
/// provider : le tutoriel l'appelle comme le jeu (ADR-081).
/// `test/unit/stat_gain_single_passage_test.dart` refuse toute addition écrite
/// en ligne ailleurs.
abstract final class StatGains {
  static EntityStats apply(EntityStats stats, StatGain gain) {
    return switch (gain.resource) {
      GainResource.armor => stats.copyWith(
          armure: stats.armure + gain.amount + _masteryFor(stats, gain),
        ),
      GainResource.mana => stats.copyWith(
          currentMana: stats.currentMana + gain.amount,
        ),
      GainResource.attackPower => stats.copyWith(
          attackPower: stats.attackPower + gain.amount,
        ),
      GainResource.skillPower => stats.copyWith(
          skillPower: stats.skillPower + gain.amount,
        ),
      GainResource.alterationPower => stats.copyWith(
          alterationPower: stats.alterationPower + gain.amount,
        ),
    };
  }

  /// La Maîtrise d'Armure ne s'ajoute qu'aux gains des passifs : c'est sur ce
  /// périmètre qu'est calibrée la récompense *Forge d'Acier*
  /// (`level_up_reward_service.dart`). Sa refonte en bonus de passif est une
  /// décision de P-49 (spec P-41, §5.4).
  static int _masteryFor(EntityStats stats, StatGain gain) =>
      gain.source == GainSource.passive ? stats.effectiveArmorMastery : 0;
}
```

- [ ] **Step 4: Vérifier**

Run: `flutter test test/unit/stat_gains_test.dart` — Expected: PASS
Run: `dart analyze` — Expected: `No issues found!`
La suite complète n'est pas relancée ici : rien n'importe encore `stat_gains.dart`, et Task 8 la relance une fois les gains branchés (Global Constraints).

- [ ] **Step 5: Commit**

```bash
git add lib/game/systems/stat_gains.dart test/unit/stat_gains_test.dart
git commit -F- <<'EOF'
feat(stats): StatGains, point de passage unique des gains

Fonction pure, sans provider. Chaque gain porte sa source : la Maitrise
d Armure ne s ajoute qu aux gains des passifs, comme aujourd hui.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 8: Faire passer tous les gains par `StatGains`

**Périmètre.** Les 16 additions relevées le 2026-09-16 : les 13 gains du héros de la spec §4.1, le gain d'armure du tutoriel, et deux gains d'armure d'ennemi (statut `armor_regen`, intention « défense »). Une fois convertis, `setHeroStats` n'a plus aucun appelant dans `lib/` — seuls trois fichiers de test l'emploient pour préparer leurs PV : il est supprimé (`CLAUDE.md` : pas de code mort) et ces tests passent par `takeDamage` et `heal`.

**Le drapeau de critique.** `setHeroStats` remettait `lastActionWasCrit` à `false` à chaque appel ; `grant` ne le fait pas. C'est sans effet visible : le seul lecteur du drapeau, `combat_entity.dart:214`, ne le lit que lorsque les PV baissent, et toute perte de PV du héros en combat passe par `EntityStats.takeDamage`, qui l'écrit — attaque ennemie (`turn_phase_manager.dart:114`) comme poison (`status_effect_processor.dart:24`). Le coût en PV de `consumeResource`, qui ne l'écrirait pas, n'a plus d'appelant depuis P-40 (`ced306e`).

**Files:**
- Test: `test/unit/stat_gain_single_passage_test.dart` *(nouveau)*
- Modify: `lib/game/controllers/run/player_stats_manager.dart`, `lib/game/controllers/run_controller.dart`, `lib/game/systems/trait_system.dart`, `lib/game/services/effects/strategies.dart`, `lib/game/services/effect_resolver.dart`, `lib/game/controllers/combat/status_effect_processor.dart`, `lib/game/controllers/combat/turn_phase_manager.dart`, `lib/tutorial/tutorial_engine.dart`, `lib/models/entity_stats.dart:11`
- Modify (tests) : `test/unit/combat_controller_test.dart:535`, `test/unit/run_controller_test.dart:102`, `test/widget/rest_screen_test.dart:123-125`, `:150`

**Interfaces:**
- Consumes: `StatGain`, `GainResource`, `GainSource`, `StatGains.apply` (Task 7).
- Produces: `void RunController.grant(StatGain gain)` et `void PlayerStatsManager.grant(StatGain gain)`. **Supprime** `RunController.setHeroStats` et `PlayerStatsManager.setHeroStats`.

- [ ] **Step 1: Écrire le garde-fou qui échoue**

Create `test/unit/stat_gain_single_passage_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Aucune ligne de `lib/` n'ajoute à l'armure, au mana ou à une puissance par
/// une addition écrite à la main : tout gain passe par `StatGains.apply`
/// (spec P-41, §4.1). Un gain écrit ailleurs échapperait aux règles de classe,
/// comme les gains de cartes, de runes et de reliques échappaient à la
/// Maîtrise d'Armure, appliquée aux seuls passifs.
///
/// Le motif reconnaît l'addition écrite en ligne, dans les deux sens et sur
/// plusieurs lignes. Il ne voit pas une addition calculée dans une variable
/// locale, ou enveloppée dans un appel (`max(0, s.armure + g)`) : pour
/// celles-là, la revue reste le filet. Il ne voit donc pas non plus la seule
/// exception voulue par la spec : la remontée du mana courant qui suit une
/// hausse de `maxMana`, dans `applyHeroStatModifier`.
final _additiveGains = [
  // `armure: s.armure + g`, éventuellement entre parenthèses ou sur deux lignes.
  RegExp(r'\b(armure|currentMana|attackPower|skillPower|alterationPower)\s*:\s*\(?\s*[\w.\[\]!?]*\b\1\b\s*\+'),
  // `armure: g + s.armure`.
  RegExp(r'\b(armure|currentMana|attackPower|skillPower|alterationPower)\s*:[^,;{}]*?\+\s*[\w.\[\]!?]*\b\1\b'),
];

bool _isAdditiveGain(String source) =>
    _additiveGains.any((pattern) => pattern.hasMatch(source));

void main() {
  group('le motif du garde-fou', () {
    const gains = [
      ('une addition en ligne', 'copyWith(armure: stats.armure + gain)'),
      ('des operandes inverses', 'copyWith(armure: gain + stats.armure)'),
      ('un retour a la ligne', 'copyWith(\n  armure:\n      stats.armure + gain,\n)'),
      ('une addition entre parentheses', 'copyWith(currentMana: (stats.currentMana + gain).clamp(0, 9))'),
      ('un chemin indexe', 'copyWith(attackPower: enemies[i].stats.attackPower + 1)'),
    ];
    for (final (name, source) in gains) {
      test('reconnait $name', () => expect(_isAdditiveGain(source), isTrue));
    }

    const others = [
      ('une remise a zero', 'copyWith(armure: 0, currentPv: newPv)'),
      ('une restauration', 'copyWith(currentMana: stats.maxMana)'),
      ('une serialisation', "{'armure': armure, 'currentMana': currentMana}"),
      ('une depense', 'copyWith(currentMana: stats.currentMana - mana)'),
      ('une addition a une autre stat', 'copyWith(currentMana: stats.maxMana + bonus)'),
    ];
    for (final (name, source) in others) {
      test('ignore $name', () => expect(_isAdditiveGain(source), isFalse));
    }
  });

  test('tous les gains passent par StatGains.apply', () {
    final offenders = <String>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.endsWith('lib/game/systems/stat_gains.dart')) continue;
      final source = entity.readAsStringSync();
      for (final pattern in _additiveGains) {
        for (final match in pattern.allMatches(source)) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
          offenders.add('$path:$line');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
```

- [ ] **Step 2: Vérifier qu'il échoue sur les 16 sites**

Run: `flutter test test/unit/stat_gain_single_passage_test.dart`
Expected: les dix tests du motif passent ; `tous les gains passent par StatGains.apply` échoue, et sa raison liste **16 lignes** — `status_effect_processor.dart` (×2), `turn_phase_manager.dart` (×1), `player_stats_manager.dart` (×4), `strategies.dart` (×2), `effect_resolver.dart` (×2), `trait_system.dart` (×4), `tutorial_engine.dart` (×1).

- [ ] **Step 3: `grant` sur le contrôleur, suppression de `setHeroStats`**

In `lib/game/controllers/run/player_stats_manager.dart`:

Add the import after `import '../../../models/data/relic_data.dart';`:

```dart
import '../../systems/stat_gains.dart';
```

Replace the whole `setHeroStats` method:

```dart
  /// Modifie la valeur exacte d'un champ sans affecter les max (pour la récupération d'armure par ex)
  void setHeroStats({
    int? currentPv,
    int? armure,
    int? currentMana,
    int? armorMastery,
    bool? lastActionWasCrit,
  }) {
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: controller.currentState.heroStats.copyWith(
          currentPv: currentPv ?? controller.currentState.heroStats.currentPv,
          armure: armure ?? controller.currentState.heroStats.armure,
          currentMana: currentMana ?? controller.currentState.heroStats.currentMana,
          armorMastery: armorMastery ?? controller.currentState.heroStats.armorMastery,
          lastActionWasCrit: lastActionWasCrit ?? false,
        ),
      ),
    );
  }
```

with:

```dart
  /// Accorde au héros un gain d'armure, de mana ou de puissance : voir
  /// `StatGains`, seul endroit où un gain est calculé.
  void grant(StatGain gain) {
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: StatGains.apply(controller.currentState.heroStats, gain),
      ),
    );
  }
```

In `lib/game/controllers/run_controller.dart`:

Add the import after `import '../systems/trait_system.dart';`:

```dart
import '../systems/stat_gains.dart';
```

Replace the whole `setHeroStats` facade:

```dart
  /// Modifie la valeur exacte d'un champ sans affecter les max (pour la récupération d'armure par ex)
  void setHeroStats({
    int? currentPv,
    int? armure,
    int? currentMana,
    int? armorMastery,
    bool? lastActionWasCrit,
  }) {
    _playerStatsManager.setHeroStats(
      currentPv: currentPv,
      armure: armure,
      currentMana: currentMana,
      armorMastery: armorMastery,
      lastActionWasCrit: lastActionWasCrit,
    );
  }
```

with:

```dart
  /// Accorde au héros un gain d'armure, de mana ou de puissance, par le point
  /// de passage unique `StatGains` (spec P-41, §4.1).
  void grant(StatGain gain) {
    _playerStatsManager.grant(gain);
  }
```

- [ ] **Step 4: Convertir les gains du héros dans `PlayerStatsManager`**

Still in `lib/game/controllers/run/player_stats_manager.dart`:

In `applyHeroStatModifier`, replace:

```dart
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: currentStats.copyWith(
          maxPv: newMaxPv,
          currentPv: newCurrentPv,
          maxMana: newMaxMana,
          currentMana: newCurrentMana,
          attackPower: currentStats.attackPower + attackAcc,
          armorMastery: currentStats.armorMastery + armorAcc,
          luck: currentStats.luck + luckAcc,
          critChance: currentStats.critChance + critChanceAcc,
          critMultiplier: currentStats.critMultiplier + critDamageAcc,
        ),
      ),
    );
```

with:

```dart
    final modifiedStats = currentStats.copyWith(
      maxPv: newMaxPv,
      currentPv: newCurrentPv,
      maxMana: newMaxMana,
      currentMana: newCurrentMana,
      armorMastery: currentStats.armorMastery + armorAcc,
      luck: currentStats.luck + luckAcc,
      critChance: currentStats.critChance + critChanceAcc,
      critMultiplier: currentStats.critMultiplier + critDamageAcc,
    );

    controller.updateState(
      controller.currentState.copyWith(
        heroStats: StatGains.apply(
          modifiedStats,
          StatGain(GainResource.attackPower, attackAcc, GainSource.progression),
        ),
      ),
    );
```

In `applyRelicEffect`, replace:

```dart
        } else {
          controller.updateState(
            controller.currentState.copyWith(
              heroStats: controller.currentState.heroStats.copyWith(
                currentMana: controller.currentState.heroStats.currentMana + relic.value,
              ),
            ),
          );
        }
        break;
      case 'gain_armor':
        controller.updateState(
          controller.currentState.copyWith(
            heroStats: controller.currentState.heroStats.copyWith(
              armure: controller.currentState.heroStats.armure + relic.value,
            ),
          ),
        );
        break;
```

with:

```dart
        } else {
          grant(StatGain(GainResource.mana, relic.value, GainSource.relic));
        }
        break;
      case 'gain_armor':
        grant(StatGain(GainResource.armor, relic.value, GainSource.relic));
        break;
```

Replace:

```dart
          setHeroStats(armure: controller.currentState.heroStats.armure + relic.value);
```

with:

```dart
          grant(StatGain(GainResource.armor, relic.value, GainSource.relic));
```

- [ ] **Step 5: Convertir les gains des passifs**

Replace the whole content of `lib/game/systems/trait_system.dart` with:

```dart
import '../controllers/run_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/data/relic_data.dart';
import 'stat_gains.dart';

class TraitSystem {
  /// Appelé au début du tour du joueur
  static void onTurnStart(RunController controller) {
    final passive = controller.currentState.activePassive;
    if (passive == null) return;
    final stats = controller.currentState.heroStats;

    if (passive.trigger == RelicTrigger.startOfTurn) {
      if (passive.effectType == 'berserker_armor') {
        // Gagne X d'Armure (+Maîtrise) pour chaque tranche de 10 PV manquants
        final missingHp = stats.maxPv - stats.currentPv;
        final multiplier = missingHp ~/ 10;
        final armorGain = multiplier * passive.value;
        if (armorGain > 0) {
          controller.grant(
            StatGain(GainResource.armor, armorGain, GainSource.passive),
          );
        }
      } else if (passive.effectType == 'gain_armor') {
        controller.grant(
          StatGain(GainResource.armor, passive.value, GainSource.passive),
        );
      }
    }
  }

  /// Appelé à la fin du tour du joueur
  static void onTurnEnd(RunController controller) {
    final passive = controller.currentState.activePassive;
    if (passive == null) return;

    if (passive.trigger == RelicTrigger.endOfTurn) {
      if (passive.effectType == 'gain_armor') {
        controller.grant(
          StatGain(GainResource.armor, passive.value, GainSource.passive),
        );
      }
    }
  }

  /// Appelé lorsqu'une carte est jouée avec succès
  static void onCardPlayed(RunController controller, CardInstance card) {
    final passive = controller.currentState.activePassive;
    if (passive == null) return;

    if (passive.trigger == RelicTrigger.onCardPlayed) {
      if (passive.effectType == 'spell_armor') {
        if (card.data.type == CardType.skill) {
          controller.grant(
            StatGain(GainResource.armor, passive.value, GainSource.passive),
          );
        }
      }
    }
  }
}
```

La Maîtrise n'est plus ajoutée ici : `StatGains.apply` l'ajoute aux gains de source `passive`. Les variables `stats` d'`onTurnEnd` et d'`onCardPlayed` disparaissent avec leur seul usage.

- [ ] **Step 6: Convertir les gains des cartes et des runes**

In `lib/game/services/effects/strategies.dart`:

Add the import after `import '../../controllers/combat_controller.dart';`:

```dart
import '../../systems/stat_gains.dart';
```

Replace:

```dart
    final currentStats = runController.currentState.heroStats;
    runController.setHeroStats(armure: currentStats.armure + scaledValue);
```

with:

```dart
    runController.grant(
      StatGain(GainResource.armor, scaledValue, GainSource.card),
    );
```

Replace:

```dart
    final currentMana = runController.currentState.heroStats.currentMana;
    runController.setHeroStats(currentMana: currentMana + scaledValue);
```

with:

```dart
    runController.grant(
      StatGain(GainResource.mana, scaledValue, GainSource.card),
    );
```

In `lib/game/services/effect_resolver.dart`:

Add the import after `import '../controllers/combat_controller.dart';`:

```dart
import '../systems/stat_gains.dart';
```

Replace:

```dart
    if (extraMana > 0) {
      final currentMana = runController.currentState.heroStats.currentMana;
      runController.setHeroStats(currentMana: currentMana + extraMana);
    }
```

with:

```dart
    if (extraMana > 0) {
      runController.grant(
        StatGain(GainResource.mana, extraMana, GainSource.rune),
      );
    }
```

Replace:

```dart
    if (!hasArmorEffect && extraArmor > 0) {
      final currentStats = runController.currentState.heroStats;
      runController.setHeroStats(armure: currentStats.armure + extraArmor);
    }
```

with:

```dart
    if (!hasArmorEffect && extraArmor > 0) {
      runController.grant(
        StatGain(GainResource.armor, extraArmor, GainSource.rune),
      );
    }
```

- [ ] **Step 7: Convertir les gains des statuts, de l'ennemi et du tutoriel**

In `lib/game/controllers/combat/status_effect_processor.dart`:

Replace:

```dart
import '../../../models/entity_stats.dart';
import '../../../models/status_effect.dart';
```

with:

```dart
import '../../../models/entity_stats.dart';
import '../../../models/status_effect.dart';
import '../../systems/stat_gains.dart';
```

Replace both occurrences (edit with replace-all) of:

```dart
      updatedStats = updatedStats.copyWith(
        armure: updatedStats.armure + armorGain,
      );
```

with:

```dart
      updatedStats = StatGains.apply(
        updatedStats,
        StatGain(GainResource.armor, armorGain, GainSource.status),
      );
```

In `lib/game/controllers/combat/turn_phase_manager.dart`:

Add the import after `import 'status_effect_processor.dart';`:

```dart
import '../../systems/stat_gains.dart';
```

Replace:

```dart
        final updatedEnemy = enemy.copyWith(
          stats: enemy.stats.copyWith(
            armure: enemy.stats.armure + intent.value,
          ),
        );
```

with:

```dart
        final updatedEnemy = enemy.copyWith(
          stats: StatGains.apply(
            enemy.stats,
            StatGain(GainResource.armor, intent.value, GainSource.enemyIntent),
          ),
        );
```

In `lib/tutorial/tutorial_engine.dart`:

Replace:

```dart
import '../game/services/damage_pipeline.dart';
```

with:

```dart
import '../game/services/damage_pipeline.dart';
import '../game/systems/stat_gains.dart';
```

Replace:

```dart
        mockState.heroStats = mockState.heroStats.copyWith(
          armure: mockState.heroStats.armure + scaled,
        );
```

with:

```dart
        mockState.heroStats = StatGains.apply(
          mockState.heroStats,
          StatGain(GainResource.armor, scaled, GainSource.card),
        );
```

- [ ] **Step 8: Corriger le commentaire de la Maîtrise d'Armure**

In `lib/models/entity_stats.dart`, replace:

```dart
  final int armorMastery; // Bonus permanent ajouté à chaque gain d'armure
```

with:

```dart
  final int armorMastery; // Bonus permanent ajouté aux gains d'armure des passifs (voir StatGains)
```

- [ ] **Step 9: Réécrire les quatre préparations de test qui passaient par `setHeroStats`**

Chaque site part d'un `startNewRun`, à pleins PV et sans armure : les méthodes publiques `takeDamage` et `heal` y donnent le même état en une ligne, drapeau de critique compris.

In `test/unit/combat_controller_test.dart`, replace (le héros a 100 PV max, et `heal` plafonne au max) :

```dart
        runController.setHeroStats(currentPv: 100);
```

with:

```dart
        runController.heal(100);
```

In `test/unit/run_controller_test.dart`, replace (80 PV max) :

```dart
        runController.setHeroStats(currentPv: 60, armure: 0);
```

with:

```dart
        runController.takeDamage(20);
```

In `test/widget/rest_screen_test.dart`, replace:

```dart
      container.read(runProvider.notifier).setHeroStats(
        currentPv: maxPv - healAmount - 5,
      );
```

with:

```dart
      container.read(runProvider.notifier).takeDamage(healAmount + 5);
```

and replace:

```dart
      container.read(runProvider.notifier).setHeroStats(currentPv: maxPv - 1);
```

with:

```dart
      container.read(runProvider.notifier).takeDamage(1);
```

- [ ] **Step 10: Vérifier**

Run: `flutter test test/unit/stat_gain_single_passage_test.dart` — Expected: PASS
Run: `flutter test test/unit/stat_gains_characterization_test.dart` — Expected: PASS, **sans aucune modification depuis Task 6** (`git diff HEAD -- test/unit/stat_gains_characterization_test.dart` n'affiche rien).
Run: `git grep -nw setHeroStats -- lib test` — Expected: aucune sortie. (Sans `-w`, le motif trouverait aussi `resetHeroStatsForDemo`, une API du tutoriel sans rapport.)
Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+876: All tests passed!` (811 + 65 tests nouveaux) ; Task 9 reprend ce total.

- [ ] **Step 11: Commit**

```bash
git add -u lib test
git add test/unit/stat_gain_single_passage_test.dart
git commit -F- <<'EOF'
refactor(stats): tous les gains passent par StatGains

Seize additions converties : treize gains du heros, le gain d armure du
tutoriel et deux gains d armure d ennemi. setHeroStats n a plus d appelant
et disparait. Un test refuse toute nouvelle addition en ligne hors de
StatGains ; les tests de caracterisation, inchanges, prouvent que le jeu
n a pas bouge.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 9: Vérification finale et livraison

**Files:**
- Modify: `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md` (statut)
- Géré par skills : `.obsidian_vault/`, `docs/ROADMAP.md`

**Interfaces:**
- Consumes: tout le lot.
- Produces: une branche prête à la PR.

- [ ] **Step 1: Vérifications propres au lot**

Aucun fichier de `lib/` ni de `test/` n'a changé depuis la vérification complète de Task 8 Step 10 : ne relancer ni `dart analyze` ni la suite, reprendre le total qu'elle a affiché.
Run: `git grep -nwE "effectiveAttaque|setHeroStats|bonusAttack" -- lib test` — Expected: aucune sortie.
Run: `git grep -nE "\.attaque\b|\battaque:" -- lib test` — Expected: aucune sortie.

- [ ] **Step 2: Mettre à jour le statut de la spec**

In `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md`, replace:

```markdown
Statut : **Design validé, non implémenté** — découpé en quatre lots (A → D) et un chantier frère (P-49)
```

with:

```markdown
Statut : **Lot A implémenté** (branche `feat/p41-lot-a`) — lots B à D et chantier frère P-49 non implémentés
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md
git commit -F- <<'EOF'
docs(P-41): lot A implemente

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
EOF
```

- [ ] **Step 4: Synchroniser la mémoire du projet**

Invoke the `memory-bank-sync` skill. Ce qu'il doit consigner :
- un ADR pour le point de passage unique à source étiquetée, les règles de puissance (`PowerRules`) et la chaîne de migration de sauvegarde sous sa nouvelle clé ;
- dans `docs/ROADMAP.md`, section P-13 : cocher « Chaîne de migration de la sauvegarde de run — *P-41, lot A* » ; dans le tableau des lots de P-41 : marquer **P-41 A** livré ;
- les métriques de `progress.md`, que le skill re-mesure lui-même.

- [ ] **Step 5: Note de version — décision du propriétaire**

**Ne pas invoquer `patch-notes-writer` sans l'accord explicite du propriétaire.** Le lot ne change rien au jeu. Ses seules conséquences observables : une partie sauvegardée par ce build n'est plus proposée par les versions antérieures du site, au lieu d'y être effacée ; une partie écrite par une version plus récente est conservée, avec un message à l'accueil. La version que visent les prochains lots est tenue dans `docs/ROADMAP.md`, paragraphe « La note `0.5.1` n'attend plus P-42 » ; demander au propriétaire si ces conséquences méritent une ligne dans la prochaine note, ou attendent le premier lot visible.

- [ ] **Step 6: Terminer la branche**

Invoke the `superpowers:finishing-a-development-branch` skill.

---

## Suites relevées, hors du lot A

Constatées en préparant ce plan et à sa revue ; elles ne changent rien tant que `skillPower` et `alterationPower` valent 0, mais deviendront réelles avec les lots suivants :

1. **Le budget de rencontre ne compte que `attackPower`.** `EncounterSystem` estime la puissance du joueur par `playerAttaque * 10` (`encounter_system.dart:98`), alimenté par `heroStats.attackPower` (`game_screen.dart:260`). Un Mage à forte `alterationPower` y paraîtra faible. → **lot C**, quand les récompenses rendent ces stats non nulles.
2. **L'aperçu des statuts sur une carte n'inclut pas `alterationPower`.** Les dégâts prévus l'intègrent (Task 5), pas l'intensité d'un poison. Quatre constructeurs de description, dans trois fichiers, en sont responsables : `card_component.dart`, `card_text_renderer.dart` (deux fois) et `ui_card/ui_card_helpers.dart` ; la règle à y lire est `PowerRules.statusBonusFor`. → **au plus tard la partie 2 du lot C**, qui rend `alterationPower` non nulle : sans quoi les cartes afficheraient un poison inférieur à celui appliqué.
3. **Un retrait de relique est un gain négatif de source `progression`** (`applyHeroStatModifier(attackAcc: -value)`). Quand le lot B posera la conversion du Mage, il faudra décider si un retrait est converti comme l'a été le gain (spec §7.1). → **lot B**.
4. **`alterationPower` ne fait rien sur `freeze`.** La valeur de `freeze` n'est jamais lue : seules comptent sa présence (`enemy_instance.dart:28`) et sa durée (`turn_phase_manager.dart:118-119`). `shock`, lui, ajoute sa valeur aux dégâts (`damage_pipeline.dart:42`). → **lot B ou C** : exclure `freeze` de la règle, ou faire porter la puissance sur sa durée.
5. **Les règles de classe devront atteindre chaque site de gain.** Au lot B, les `statRules` entrent dans `StatGains.apply` comme paramètre **obligatoire** : chaque site décide explicitement, et le compilateur les désigne tous. `processPlayerStatuses` les reçoit de son appelant, `RunController.startTurn` ; un ennemi passe une liste vide (spec §4.1). → **lot B**.
6. **Le coût en PV de `consumeResource` est du code mort.** Aucun appelant ne passe `hpPercent` depuis `ced306e` (P-40). → à supprimer, ou à reprendre par P-44 si des cartes à coût en PV y sont retenues.
