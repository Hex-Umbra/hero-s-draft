# Act-Scaling Enemy Count Caps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cap the number of enemies `EncounterSystem.generateEnemiesForLevel` can generate, per node type (normal/elite/boss), each growing by +1 on its own act-based step (every act / every 2 acts / every 5 acts), per `docs/superpowers/specs/2026-07-25-enemy-count-scaling-design.md`.

**Architecture:** `EncounterSystem` gains three small public functions (`getMaxEnemiesForNormalCombat`, `getMaxEnemiesForElite`, `getMaxEnemiesForBoss`), backed by one private step-formula helper. `generateEnemiesForLevel`'s existing enemy-selection loop swaps its hardcoded `< 10` bound for whichever of these three applies to the current node type. Nothing else about the selection algorithm, budget formulas, or wave/reserve system changes.

**Tech Stack:** Dart / Flutter, `flutter_test`, existing `EncounterSystem` architecture (`lib/game/systems/encounter_system.dart`).

## Global Constraints

- `dart analyze` must be clean (zero issues) after every task.
- No dead code, unused imports, or commented-out blocks.
- No changes to `calculateBudget`/`ExpectedPower`/`BaseBudget`/`FinalBudget`/`PowerModifier` — this plan only changes the upper bound on `generatedEnemies.length`, never the budget math (spec §4).
- No changes to `getUnlockedTier` or the tier-filtering logic in `generateEnemiesForLevel`.
- No changes to the enemy-selection algorithm itself (candidate filtering by `rating <= remainingBudget`, random choice, lowest-`CombatRating` fallback) beyond the loop's stopping bound.
- No changes to the active/reserve wave system (`CombatController`'s `enemies`/`pendingEnemies` split, max 5 active) — it already absorbs any total above 5 without modification.
- No ultimate ceiling on the new caps — growth is unbounded by design (spec §3.4).
- New static helpers on `EncounterSystem` must be public (existing convention — `test/encounter_system_test.dart` is an external test file that calls them directly).

---

## File Structure

- **Modify `lib/game/systems/encounter_system.dart`**: add `_maxEnemiesFromStep` (private helper) and `getMaxEnemiesForNormalCombat` / `getMaxEnemiesForElite` / `getMaxEnemiesForBoss` (public, act-scaled step formulas); swap the hardcoded `10` in `generateEnemiesForLevel`'s selection loop for the node-type-appropriate one of these three.
- **Modify `test/encounter_system_test.dart`**: add tests for the three new functions and for the cap actually taking effect inside `generateEnemiesForLevel`.

No other file changes — `combat_controller.dart` and `combat_debug_logger.dart` are untouched, since `generateEnemiesForLevel`'s public signature doesn't change.

---

### Task 1: Act-scaled max-enemy-count helpers

**Files:**
- Modify: `lib/game/systems/encounter_system.dart` (add constants + helpers, right after `getUnlockedTier` and before `calculateBudget`)
- Test: `test/encounter_system_test.dart` (new tests in the existing `group('Act bracket factor & tier unlock helpers', ...)` block)

**Interfaces:**
- Produces (used by Task 2):
  - `static int EncounterSystem.getMaxEnemiesForNormalCombat(int act)`
  - `static int EncounterSystem.getMaxEnemiesForElite(int act)`
  - `static int EncounterSystem.getMaxEnemiesForBoss(int act)`

- [ ] **Step 1: Write the failing tests**

Add these three tests inside `test/encounter_system_test.dart`, in the existing `group('Act bracket factor & tier unlock helpers', ...)` block (anywhere inside it — e.g. right after the `getUnlockedTier` test):

```dart
    test('getMaxEnemiesForNormalCombat grows by 1 every act, starting at 1, unbounded', () {
      expect(EncounterSystem.getMaxEnemiesForNormalCombat(1), 1);
      expect(EncounterSystem.getMaxEnemiesForNormalCombat(2), 2);
      expect(EncounterSystem.getMaxEnemiesForNormalCombat(5), 5);
      expect(EncounterSystem.getMaxEnemiesForNormalCombat(11), 11);
    });

    test('getMaxEnemiesForElite grows by 1 every 2 acts, starting at 1, unbounded', () {
      expect(EncounterSystem.getMaxEnemiesForElite(1), 1);
      expect(EncounterSystem.getMaxEnemiesForElite(2), 1);
      expect(EncounterSystem.getMaxEnemiesForElite(3), 2);
      expect(EncounterSystem.getMaxEnemiesForElite(5), 3);
      expect(EncounterSystem.getMaxEnemiesForElite(6), 3);
      expect(EncounterSystem.getMaxEnemiesForElite(11), 6);
    });

    test('getMaxEnemiesForBoss grows by 1 every 5 acts, starting at 1, unbounded', () {
      expect(EncounterSystem.getMaxEnemiesForBoss(1), 1);
      expect(EncounterSystem.getMaxEnemiesForBoss(5), 1);
      expect(EncounterSystem.getMaxEnemiesForBoss(6), 2);
      expect(EncounterSystem.getMaxEnemiesForBoss(10), 2);
      expect(EncounterSystem.getMaxEnemiesForBoss(11), 3);
    });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/encounter_system_test.dart`
Expected: FAIL to compile — `getMaxEnemiesForNormalCombat`, `getMaxEnemiesForElite`, and `getMaxEnemiesForBoss` are not defined on `EncounterSystem`.

- [ ] **Step 3: Implement the helpers**

In `lib/game/systems/encounter_system.dart`, find:

```dart
  /// Highest enemy tier available at this act: tier 1 through act 10, tier 2
  /// from act 11, tier 3 from act 21, capped at [maxTierAuthored].
  static int getUnlockedTier(int act) {
    final unlocked = 1 + ((act - 1) / _tierUnlockBracketSize).floor();
    return unlocked > maxTierAuthored ? maxTierAuthored : unlocked;
  }

  /// Computes the combat budget breakdown (player power vs. expected power,
```

and insert the new constants/helpers between the two, so it reads:

```dart
  /// Highest enemy tier available at this act: tier 1 through act 10, tier 2
  /// from act 11, tier 3 from act 21, capped at [maxTierAuthored].
  static int getUnlockedTier(int act) {
    final unlocked = 1 + ((act - 1) / _tierUnlockBracketSize).floor();
    return unlocked > maxTierAuthored ? maxTierAuthored : unlocked;
  }

  static const int _normalCombatEnemyStep = 1;
  static const int _eliteEnemyStep = 2;
  static const int _bossEnemyStep = 5;

  /// Shared step formula: 1 enemy at act 1, +1 every [stepSize] acts,
  /// unbounded (no ceiling — see spec §3.4 for why this stays safe long-term).
  static int _maxEnemiesFromStep(int act, int stepSize) =>
      1 + ((act - 1) / stepSize).floor();

  /// Max enemies generated for a normal combat node: +1 every act.
  static int getMaxEnemiesForNormalCombat(int act) =>
      _maxEnemiesFromStep(act, _normalCombatEnemyStep);

  /// Max enemies generated for an elite node: +1 every 2 acts.
  static int getMaxEnemiesForElite(int act) =>
      _maxEnemiesFromStep(act, _eliteEnemyStep);

  /// Max enemies generated for a boss node: +1 every 5 acts.
  static int getMaxEnemiesForBoss(int act) =>
      _maxEnemiesFromStep(act, _bossEnemyStep);

  /// Computes the combat budget breakdown (player power vs. expected power,
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/encounter_system_test.dart`
Expected: PASS

- [ ] **Step 5: Analyze and commit**

Run: `dart analyze`
Expected: No issues found.

```bash
git add lib/game/systems/encounter_system.dart test/encounter_system_test.dart
git commit -m "feat: add act-scaled max-enemy-count helpers to EncounterSystem"
```

---

### Task 2: Wire the cap into the enemy-selection loop

**Files:**
- Modify: `lib/game/systems/encounter_system.dart` (`generateEnemiesForLevel`'s selection loop)
- Test: `test/encounter_system_test.dart` (new tests in the existing `group('EncounterSystem & Wave Reserve Tests', ...)` block, reusing `slimeData`)

**Interfaces:**
- Consumes: `getMaxEnemiesForNormalCombat`/`getMaxEnemiesForElite`/`getMaxEnemiesForBoss` from Task 1.
- Produces: `generateEnemiesForLevel` keeps its exact existing public signature — only its internal loop bound changes, so no other file needs edits.

- [ ] **Step 1: Write the failing tests**

Add these three tests inside `test/encounter_system_test.dart`, in the existing `group('EncounterSystem & Wave Reserve Tests', ...)` block (it already defines `slimeData` near the top — reuse it, don't redefine):

```dart
    test('generateEnemiesForLevel caps normal-combat enemy count at getMaxEnemiesForNormalCombat(act)', () {
      // Deliberately huge player stats so the budget alone would fit far more
      // than 1 Slime (CR ~27.9 unscaled) — only the new cap should stop it at 1.
      final enemies = EncounterSystem.generateEnemiesForLevel(
        1,
        List.generate(20, (index) => slimeData),
        nodeType: MapNodeType.combat,
        playerLevel: 1,
        act: 1,
        playerMaxHp: 500,
        playerAttaque: 20,
        playerMaxMana: 10,
        playerRelicsCount: 10,
        playerCardsCount: 20,
      );
      expect(enemies.length, EncounterSystem.getMaxEnemiesForNormalCombat(1));
      expect(enemies.length, 1);
    });

    test('generateEnemiesForLevel caps elite enemy count at getMaxEnemiesForElite(act)', () {
      // Same oversized budget, but at act 3 (elite cap = 2) and node type elite.
      final enemies = EncounterSystem.generateEnemiesForLevel(
        1,
        List.generate(20, (index) => slimeData),
        nodeType: MapNodeType.elite,
        playerLevel: 1,
        act: 3,
        playerMaxHp: 500,
        playerAttaque: 20,
        playerMaxMana: 10,
        playerRelicsCount: 10,
        playerCardsCount: 20,
      );
      expect(enemies.length, EncounterSystem.getMaxEnemiesForElite(3));
      expect(enemies.length, 2);
    });

    test('generateEnemiesForLevel caps boss enemy count at getMaxEnemiesForBoss(act)', () {
      // Same oversized budget, node type boss, act 1 (boss cap = 1).
      final enemies = EncounterSystem.generateEnemiesForLevel(
        1,
        List.generate(20, (index) => slimeData),
        nodeType: MapNodeType.boss,
        playerLevel: 1,
        act: 1,
        playerMaxHp: 500,
        playerAttaque: 20,
        playerMaxMana: 10,
        playerRelicsCount: 10,
        playerCardsCount: 20,
      );
      expect(enemies.length, EncounterSystem.getMaxEnemiesForBoss(1));
      expect(enemies.length, 1);
    });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/encounter_system_test.dart`
Expected: FAIL — with today's hardcoded `< 10` bound and these oversized player stats, all three scenarios generate more enemies than the new cap allows (budget comfortably fits 5+ Slimes in each case), so `enemies.length` will be greater than the expected 1 / 2 / 1.

- [ ] **Step 3: Wire the cap into the loop**

In `lib/game/systems/encounter_system.dart`, inside `generateEnemiesForLevel`, find:

```dart
    final List<EnemyData> generatedEnemies = [];
    double remainingBudget = finalBudget;

    // Choose enemies without exceeding remaining budget
    while (remainingBudget > 0 && generatedEnemies.length < 10) {
```

and replace it with:

```dart
    final int maxEnemies = isBoss
        ? getMaxEnemiesForBoss(act)
        : (isElite ? getMaxEnemiesForElite(act) : getMaxEnemiesForNormalCombat(act));

    final List<EnemyData> generatedEnemies = [];
    double remainingBudget = finalBudget;

    // Choose enemies without exceeding remaining budget or the act-scaled cap
    while (remainingBudget > 0 && generatedEnemies.length < maxEnemies) {
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/encounter_system_test.dart`
Expected: PASS (including the pre-existing `'generateEnemiesForLevel respects budget strictly'` test, which is unaffected — level 1/act 1/normal already only ever fit 1 enemy under its budget, matching `getMaxEnemiesForNormalCombat(1) == 1`)

- [ ] **Step 5: Analyze and commit**

Run: `dart analyze`
Expected: No issues found.

```bash
git add lib/game/systems/encounter_system.dart test/encounter_system_test.dart
git commit -m "feat: cap generated enemy count per node type, growing with acts"
```

---

### Task 3: Full regression pass

**Files:** none (verification only)

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: All tests pass. Pay particular attention to `test/encounter_system_test.dart` (new + existing tests) and any test exercising `CombatController.initializeCombat` with `MapNodeType.elite`/`MapNodeType.boss` at act > 1, since those are the scenarios this plan changes behavior for.

- [ ] **Step 2: Run static analysis**

Run: `dart analyze`
Expected: No issues found.

- [ ] **Step 3: Confirm nothing left uncommitted**

Run: `git status`
Expected: Clean working tree — both tasks already committed their own changes. If anything is uncommitted here, it means a fix was needed during this verification pass; commit it with a message describing what regression it addresses.
