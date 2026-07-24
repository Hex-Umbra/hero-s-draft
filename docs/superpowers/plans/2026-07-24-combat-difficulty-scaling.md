# Combat Difficulty Scaling (Staircase + Tier Unlock) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current double-counted, unbounded act-scaling formula in `EncounterSystem` with a bracket-based (5-act) accelerating difficulty curve and a 10-act enemy-tier unlock, per `docs/superpowers/specs/2026-07-24-combat-difficulty-scaling-design.md`.

**Architecture:** `EncounterSystem` (`lib/game/systems/encounter_system.dart`) gains pure static helpers for the act-bracket factor and tier unlock; `enemyLevel` drops its act term entirely (level and act become fully independent inputs); `generateEnemiesForLevel` filters its enemy pool by unlocked tier before budget-based selection. `combat_controller.dart` and `combat_debug_logger.dart` get the minimal call-site/label updates this requires. No changes to the enemy-count budget formulas (`ExpectedPower`/`BaseBudget`) or to the debug-log/actual-value drift bug — both are explicitly out of scope per the spec.

**Tech Stack:** Dart / Flutter, `flutter_test` for unit tests, existing `EncounterSystem`/`CombatController` architecture.

## Global Constraints

- `dart analyze` must be clean (zero issues) after every task, before considering it done.
- No dead code, unused imports, or commented-out blocks.
- No changes to `ExpectedPower`, `BaseBudget`, `finalBudget`, or the debug-log/actual-value drift (playerCardsCount/`+(act-1)*10`) — out of scope per spec section 4.
- No changes to boss/elite multipliers (`1.5` elite, `3.0` boss, `1.0` custom boss) or to the `CombatRating`/budget selection algorithm itself.
- Debug prints stay gated behind `kDebugMode` (existing pattern in `combat_debug_logger.dart`).
- Keep all new static helpers public on `EncounterSystem` (existing convention — `test/encounter_system_test.dart` calls them directly as an external test file).

---

## File Structure

- **Modify `lib/game/systems/encounter_system.dart`**: add act-bracket/tier constants and helper methods (`getActBracket`, `getActPositionInBracket`, `getHpActFactor`, `getDamageActFactor`, `getUnlockedTier`); drop the `act` parameter from `getEnemyLevel`; rewrite `getHpMultiplier`/`getDamageMultiplier` to use the new act-factor helpers; filter `availableEnemies` by unlocked tier inside `generateEnemiesForLevel`.
- **Modify `lib/game/controllers/combat_controller.dart`**: drop the now-removed `act:` argument from its `EncounterSystem.getEnemyLevel(...)` call.
- **Modify `lib/game/services/combat_debug_logger.dart`**: update the one hardcoded formula-description string for `enemyLevel` so it no longer claims a formula that was just removed.
- **Modify `test/encounter_system_test.dart`**: add new test groups for the act-bracket/tier helpers, the updated `getEnemyLevel`, the updated `getHpMultiplier`/`getDamageMultiplier`, and the tier-filtered `generateEnemiesForLevel`.

No new files are created — this is a self-contained change to one system and its two call sites.

---

### Task 1: Act-bracket factor and tier-unlock helpers

**Files:**
- Modify: `lib/game/systems/encounter_system.dart` (add constants + helpers after the `_rng` field, before `getEnemyLevel`)
- Test: `test/encounter_system_test.dart` (new group)

**Interfaces:**
- Produces (used by Task 3 and Task 4):
  - `static int EncounterSystem.getActBracket(int act)`
  - `static int EncounterSystem.getActPositionInBracket(int act)`
  - `static double EncounterSystem.getHpActFactor(int act)`
  - `static double EncounterSystem.getDamageActFactor(int act)`
  - `static int EncounterSystem.getUnlockedTier(int act)`
  - `static const int EncounterSystem.maxTierAuthored` (value `3`)

- [ ] **Step 1: Write the failing tests**

Add this new group inside `test/encounter_system_test.dart`, right after the existing `group('EncounterSystem & Wave Reserve Tests', ...)` closing (i.e. as a sibling top-level group inside `main()`):

```dart
  group('Act bracket factor & tier unlock helpers', () {
    test('getHpActFactor ramps gently within a 5-act bracket then jumps geometrically', () {
      expect(EncounterSystem.getHpActFactor(1), closeTo(1.0, 0.0001));
      expect(EncounterSystem.getHpActFactor(5), closeTo(1.2, 0.0001));
      expect(EncounterSystem.getHpActFactor(6), closeTo(1.35, 0.0001));
      expect(EncounterSystem.getHpActFactor(10), closeTo(1.62, 0.0001));
      expect(EncounterSystem.getHpActFactor(11), closeTo(1.8225, 0.0001));
      expect(EncounterSystem.getHpActFactor(15), closeTo(2.187, 0.0001));
    });

    test('getDamageActFactor ramps gently within a 5-act bracket then jumps geometrically', () {
      expect(EncounterSystem.getDamageActFactor(1), closeTo(1.0, 0.0001));
      expect(EncounterSystem.getDamageActFactor(5), closeTo(1.12, 0.0001));
      expect(EncounterSystem.getDamageActFactor(6), closeTo(1.25, 0.0001));
      expect(EncounterSystem.getDamageActFactor(10), closeTo(1.4, 0.0001));
      expect(EncounterSystem.getDamageActFactor(11), closeTo(1.5625, 0.0001));
      expect(EncounterSystem.getDamageActFactor(15), closeTo(1.75, 0.0001));
    });

    test('getUnlockedTier stays at 1 for acts 1-10, unlocks 2 at act 11, unlocks 3 at act 21, then caps', () {
      expect(EncounterSystem.getUnlockedTier(1), 1);
      expect(EncounterSystem.getUnlockedTier(10), 1);
      expect(EncounterSystem.getUnlockedTier(11), 2);
      expect(EncounterSystem.getUnlockedTier(20), 2);
      expect(EncounterSystem.getUnlockedTier(21), 3);
      expect(EncounterSystem.getUnlockedTier(30), 3);
      expect(EncounterSystem.getUnlockedTier(31), 3);
      expect(EncounterSystem.getUnlockedTier(100), 3);
    });
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/encounter_system_test.dart`
Expected: FAIL to compile — `getHpActFactor`, `getDamageActFactor`, and `getUnlockedTier` are not defined on `EncounterSystem`.

- [ ] **Step 3: Implement the helpers**

In `lib/game/systems/encounter_system.dart`, right after `static final Random _rng = Random();` and before `getEnemyLevel`, add:

```dart
  static const double _hpBracketGrowthRate = 1.35;
  static const double _dmgBracketGrowthRate = 1.25;
  static const double _hpIntraBracketStep = 0.05;
  static const double _dmgIntraBracketStep = 0.03;
  static const int _actBracketSize = 5;
  static const int _tierUnlockBracketSize = 10;
  static const int maxTierAuthored = 3;

  /// Which 5-act difficulty bracket this act falls in (0 for acts 1-5, 1 for acts 6-10, ...).
  static int getActBracket(int act) => ((act - 1) / _actBracketSize).floor();

  /// Position within the current 5-act bracket (0 to 4).
  static int getActPositionInBracket(int act) => (act - 1) % _actBracketSize;

  /// Combined act factor for HP: a geometric jump every 5 acts, plus a gentle
  /// ramp that resets each bracket. Replaces the old direct `(1 + 0.35*(act-1))`
  /// term, which double-counted the act inside `enemyLevel` as well.
  static double getHpActFactor(int act) {
    final bracket = getActBracket(act);
    final positionInBracket = getActPositionInBracket(act);
    final bracketMultiplier = pow(_hpBracketGrowthRate, bracket).toDouble();
    final intraBracketRamp = 1.0 + positionInBracket * _hpIntraBracketStep;
    return bracketMultiplier * intraBracketRamp;
  }

  /// Same as [getHpActFactor] but for damage, using the damage-specific rates.
  static double getDamageActFactor(int act) {
    final bracket = getActBracket(act);
    final positionInBracket = getActPositionInBracket(act);
    final bracketMultiplier = pow(_dmgBracketGrowthRate, bracket).toDouble();
    final intraBracketRamp = 1.0 + positionInBracket * _dmgIntraBracketStep;
    return bracketMultiplier * intraBracketRamp;
  }

  /// Highest enemy tier available at this act: tier 1 through act 10, tier 2
  /// from act 11, tier 3 from act 21, capped at [maxTierAuthored].
  static int getUnlockedTier(int act) {
    final unlocked = 1 + ((act - 1) / _tierUnlockBracketSize).floor();
    return unlocked > maxTierAuthored ? maxTierAuthored : unlocked;
  }

```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/encounter_system_test.dart`
Expected: PASS (all tests in the new group green; existing tests unaffected since nothing else was touched yet)

- [ ] **Step 5: Analyze and commit**

Run: `dart analyze`
Expected: No issues found.

```bash
git add lib/game/systems/encounter_system.dart test/encounter_system_test.dart
git commit -m "feat: add act-bracket and tier-unlock helpers to EncounterSystem"
```

---

### Task 2: `enemyLevel` drops the act term

**Files:**
- Modify: `lib/game/systems/encounter_system.dart` (`getEnemyLevel` method and its internal call inside `generateEnemiesForLevel`)
- Modify: `lib/game/controllers/combat_controller.dart` (its call to `EncounterSystem.getEnemyLevel`)
- Test: `test/encounter_system_test.dart` (new test)

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces (used by Task 3): `static int EncounterSystem.getEnemyLevel({required int playerLevel, required bool isBoss, required bool isElite})` — note `act` is **removed** from this signature.

- [ ] **Step 1: Write the failing test**

Add to `test/encounter_system_test.dart`, inside the `group('Act bracket factor & tier unlock helpers', ...)` block added in Task 1:

```dart
    test('getEnemyLevel depends only on player level and node type, never on act', () {
      expect(
        EncounterSystem.getEnemyLevel(playerLevel: 3, isBoss: false, isElite: false),
        3,
      );
      expect(
        EncounterSystem.getEnemyLevel(playerLevel: 3, isBoss: false, isElite: true),
        4,
      );
      expect(
        EncounterSystem.getEnemyLevel(playerLevel: 3, isBoss: true, isElite: false),
        5,
      );
    });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/encounter_system_test.dart`
Expected: FAIL to compile — `getEnemyLevel` currently requires an `act` argument that this call doesn't provide.

- [ ] **Step 3: Update `getEnemyLevel` and its call sites**

In `lib/game/systems/encounter_system.dart`, replace:

```dart
  /// Calculates the enemy level based on player parameters.
  static int getEnemyLevel({
    required int playerLevel,
    required int act,
    required bool isBoss,
    required bool isElite,
  }) {
    int nodeModifier = 0;
    if (isBoss) {
      nodeModifier = 2;
    } else if (isElite) {
      nodeModifier = 1;
    }
    return max(1, playerLevel + (act - 1) * 2 + nodeModifier);
  }
```

with:

```dart
  /// Calculates the enemy level based on player level and node type only.
  /// Act no longer contributes here — it is handled exclusively by
  /// [getHpActFactor]/[getDamageActFactor] to avoid double-counting.
  static int getEnemyLevel({
    required int playerLevel,
    required bool isBoss,
    required bool isElite,
  }) {
    int nodeModifier = 0;
    if (isBoss) {
      nodeModifier = 2;
    } else if (isElite) {
      nodeModifier = 1;
    }
    return max(1, playerLevel + nodeModifier);
  }
```

Then, inside `generateEnemiesForLevel` in the same file, find:

```dart
    final int enemyLevel = getEnemyLevel(
      playerLevel: playerLevel,
      act: act,
      isBoss: isBoss,
      isElite: isElite,
    );
```

and remove the `act: act,` line.

In `lib/game/controllers/combat_controller.dart`, find:

```dart
    final int enemyLevel = EncounterSystem.getEnemyLevel(
      playerLevel: playerLevel,
      act: act,
      isBoss: isBoss,
      isElite: isElite,
    );
```

and remove the `act: act,` line there too.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/encounter_system_test.dart`
Expected: PASS

Run: `flutter test test/unit/combat_debug_logger_test.dart`
Expected: PASS (unaffected — it only feeds pre-computed values into the logger)

- [ ] **Step 5: Analyze and commit**

Run: `dart analyze`
Expected: No issues found.

```bash
git add lib/game/systems/encounter_system.dart lib/game/controllers/combat_controller.dart test/encounter_system_test.dart
git commit -m "fix: stop double-counting act inside enemyLevel"
```

---

### Task 3: `getHpMultiplier`/`getDamageMultiplier` use the act-bracket factor

**Files:**
- Modify: `lib/game/systems/encounter_system.dart` (`getHpMultiplier`, `getDamageMultiplier`)
- Test: `test/encounter_system_test.dart` (new tests)

**Interfaces:**
- Consumes: `getHpActFactor`/`getDamageActFactor` from Task 1, `getEnemyLevel` (no `act` param) from Task 2.
- Produces: `getHpMultiplier`/`getDamageMultiplier` keep their existing signature (`enemyLevel`, `act`, `isBoss`, `isElite`, `isCustomBoss`) — only their internal formula changes. No other file calls these with a different shape, so no other call sites need edits.

- [ ] **Step 1: Write the failing tests**

Add to `test/encounter_system_test.dart`, inside the same `group('Act bracket factor & tier unlock helpers', ...)` block:

```dart
    test('getHpMultiplier no longer double-counts act — act only moves through the bracket factor', () {
      expect(
        EncounterSystem.getHpMultiplier(enemyLevel: 1, act: 1, isBoss: false, isElite: false),
        closeTo(1.0, 0.0001),
      );
      expect(
        EncounterSystem.getHpMultiplier(enemyLevel: 1, act: 6, isBoss: false, isElite: false),
        closeTo(1.35, 0.0001),
      );
    });

    test('getDamageMultiplier no longer double-counts act — act only moves through the bracket factor', () {
      expect(
        EncounterSystem.getDamageMultiplier(enemyLevel: 1, act: 1, isBoss: false, isElite: false),
        closeTo(1.0, 0.0001),
      );
      expect(
        EncounterSystem.getDamageMultiplier(enemyLevel: 1, act: 6, isBoss: false, isElite: false),
        closeTo(1.25, 0.0001),
      );
    });

    test('getHpMultiplier combines enemy level, act bracket and elite multiplier correctly', () {
      final enemyLevel = EncounterSystem.getEnemyLevel(
        playerLevel: 3,
        isBoss: false,
        isElite: true,
      );
      final result = EncounterSystem.getHpMultiplier(
        enemyLevel: enemyLevel,
        act: 11,
        isBoss: false,
        isElite: true,
      );
      // enemyLevel = 3 + 1 (elite) = 4
      // (1 + 0.06 * 3) * 1.8225 (act 11 bracket factor) * 1.5 (elite) = 3.225825
      expect(result, closeTo(3.225825, 0.0001));
    });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/encounter_system_test.dart`
Expected: FAIL — the act-6 and act-11 assertions fail because the current formula still applies `(1 + 0.35*(act-1))`/`(1 + 0.25*(act-1))` directly instead of the bracket factor (e.g. act 6 currently yields `2.75`, not `1.35`, for HP).

- [ ] **Step 3: Update the formulas**

In `lib/game/systems/encounter_system.dart`, replace:

```dart
  /// Calculates the HP scaling multiplier.
  static double getHpMultiplier({
    required int enemyLevel,
    required int act,
    required bool isBoss,
    required bool isElite,
    bool isCustomBoss = false,
  }) {
    final double bossHpMultiplier = isBoss ? (isCustomBoss ? 1.0 : 3.0) : (isElite ? 1.5 : 1.0);
    return (1.0 + 0.06 * (enemyLevel - 1)) *
        (1.0 + 0.35 * (act - 1)) *
        bossHpMultiplier;
  }

  /// Calculates the damage scaling multiplier.
  static double getDamageMultiplier({
    required int enemyLevel,
    required int act,
    required bool isBoss,
    required bool isElite,
    bool isCustomBoss = false,
  }) {
    final double bossDmgMultiplier = isBoss ? (isCustomBoss ? 1.0 : 3.0) : (isElite ? 1.5 : 1.0);
    return (1.0 + 0.04 * (enemyLevel - 1)) *
        (1.0 + 0.25 * (act - 1)) *
        bossDmgMultiplier;
  }
```

with:

```dart
  /// Calculates the HP scaling multiplier.
  static double getHpMultiplier({
    required int enemyLevel,
    required int act,
    required bool isBoss,
    required bool isElite,
    bool isCustomBoss = false,
  }) {
    final double bossHpMultiplier = isBoss ? (isCustomBoss ? 1.0 : 3.0) : (isElite ? 1.5 : 1.0);
    return (1.0 + 0.06 * (enemyLevel - 1)) *
        getHpActFactor(act) *
        bossHpMultiplier;
  }

  /// Calculates the damage scaling multiplier.
  static double getDamageMultiplier({
    required int enemyLevel,
    required int act,
    required bool isBoss,
    required bool isElite,
    bool isCustomBoss = false,
  }) {
    final double bossDmgMultiplier = isBoss ? (isCustomBoss ? 1.0 : 3.0) : (isElite ? 1.5 : 1.0);
    return (1.0 + 0.04 * (enemyLevel - 1)) *
        getDamageActFactor(act) *
        bossDmgMultiplier;
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/encounter_system_test.dart`
Expected: PASS

- [ ] **Step 5: Analyze and commit**

Run: `dart analyze`
Expected: No issues found.

```bash
git add lib/game/systems/encounter_system.dart test/encounter_system_test.dart
git commit -m "fix: derive HP/damage act scaling from the bracket factor, not a raw linear term"
```

---

### Task 4: Filter the enemy pool by unlocked tier

**Files:**
- Modify: `lib/game/systems/encounter_system.dart` (`generateEnemiesForLevel`)
- Test: `test/encounter_system_test.dart` (new tests)

**Interfaces:**
- Consumes: `getUnlockedTier` from Task 1.
- Produces: `generateEnemiesForLevel` keeps its existing public signature — only its internal candidate pool changes, so `combat_controller.dart`'s call site is unaffected.

- [ ] **Step 1: Write the failing tests**

Add to `test/encounter_system_test.dart`, inside the existing `group('EncounterSystem & Wave Reserve Tests', ...)` block (it already has `slimeData`, `goblinData`, `squeletteData` — tiers 1, 1, 2 — defined at the top, so reuse them):

```dart
    test('generateEnemiesForLevel excludes tier 2 enemies before act 11', () {
      final enemies = EncounterSystem.generateEnemiesForLevel(
        1,
        [slimeData, goblinData, squeletteData],
        nodeType: MapNodeType.combat,
        playerLevel: 5,
        act: 10,
        playerMaxHp: 100,
        playerAttaque: 0,
        playerMaxMana: 3,
        playerRelicsCount: 0,
      );
      expect(enemies.any((e) => e.tier > 1), isFalse);
    });

    test('generateEnemiesForLevel allows tier 2 enemies starting at act 11', () {
      final enemies = EncounterSystem.generateEnemiesForLevel(
        1,
        [squeletteData],
        nodeType: MapNodeType.combat,
        playerLevel: 5,
        act: 11,
        playerMaxHp: 300,
        playerAttaque: 0,
        playerMaxMana: 10,
        playerRelicsCount: 10,
      );
      expect(enemies, isNotEmpty);
      expect(enemies.every((e) => e.id == 'squelette'), isTrue);
    });

    test('generateEnemiesForLevel falls back to the full pool if the tier filter would empty it', () {
      // Only a tier-2 enemy is available, but act 1 only unlocks tier 1 —
      // must not crash and must not return an empty list.
      final enemies = EncounterSystem.generateEnemiesForLevel(
        1,
        [squeletteData],
        nodeType: MapNodeType.combat,
        playerLevel: 5,
        act: 1,
        playerMaxHp: 300,
        playerAttaque: 0,
        playerMaxMana: 10,
        playerRelicsCount: 10,
      );
      expect(enemies, isNotEmpty);
    });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/encounter_system_test.dart`
Expected: FAIL — `generateEnemiesForLevel` currently has no tier filtering, so tier-2 `squeletteData` can be selected at act 10 (first test fails).

- [ ] **Step 3: Filter the pool by unlocked tier**

In `lib/game/systems/encounter_system.dart`, inside `generateEnemiesForLevel`, find the block right before the enemy-selection loop:

```dart
    double calculateCombatRatingForEnemy(EnemyData data) {
      return calculateCombatRating(
        data: data,
        enemyLevel: enemyLevel,
        act: act,
        isBoss: isBoss,
        isElite: isElite,
      );
    }

    final List<EnemyData> generatedEnemies = [];
    double remainingBudget = finalBudget;

    // Choose enemies without exceeding remaining budget
    while (remainingBudget > 0 && generatedEnemies.length < 10) {
      final candidates = availableEnemies.where((enemy) {
        final rating = calculateCombatRatingForEnemy(enemy);
        return rating <= remainingBudget;
      }).toList();

      if (candidates.isEmpty) {
        break;
      }

      final chosen = candidates[_rng.nextInt(candidates.length)];
      generatedEnemies.add(chosen);
      remainingBudget -= calculateCombatRatingForEnemy(chosen);
    }

    // Fallback if no enemies could fit into budget: choose the one with the lowest combat rating
    if (generatedEnemies.isEmpty && availableEnemies.isNotEmpty) {
      EnemyData lowest = availableEnemies.first;
      double lowestRating = calculateCombatRatingForEnemy(lowest);
      for (int i = 1; i < availableEnemies.length; i++) {
        final r = calculateCombatRatingForEnemy(availableEnemies[i]);
        if (r < lowestRating) {
          lowestRating = r;
          lowest = availableEnemies[i];
        }
      }
      generatedEnemies.add(lowest);
    }

    return generatedEnemies;
```

and replace it with:

```dart
    double calculateCombatRatingForEnemy(EnemyData data) {
      return calculateCombatRating(
        data: data,
        enemyLevel: enemyLevel,
        act: act,
        isBoss: isBoss,
        isElite: isElite,
      );
    }

    // Restrict the candidate pool to enemies whose tier is unlocked at this
    // act. Fall back to the unfiltered list if that would leave nothing to
    // pick from (e.g. only high-tier content was passed in for a low act).
    final int unlockedTier = getUnlockedTier(act);
    final eligibleEnemies =
        availableEnemies.where((enemy) => enemy.tier <= unlockedTier).toList();
    final List<EnemyData> enemyPool =
        eligibleEnemies.isNotEmpty ? eligibleEnemies : availableEnemies;

    final List<EnemyData> generatedEnemies = [];
    double remainingBudget = finalBudget;

    // Choose enemies without exceeding remaining budget
    while (remainingBudget > 0 && generatedEnemies.length < 10) {
      final candidates = enemyPool.where((enemy) {
        final rating = calculateCombatRatingForEnemy(enemy);
        return rating <= remainingBudget;
      }).toList();

      if (candidates.isEmpty) {
        break;
      }

      final chosen = candidates[_rng.nextInt(candidates.length)];
      generatedEnemies.add(chosen);
      remainingBudget -= calculateCombatRatingForEnemy(chosen);
    }

    // Fallback if no enemies could fit into budget: choose the one with the lowest combat rating
    if (generatedEnemies.isEmpty && enemyPool.isNotEmpty) {
      EnemyData lowest = enemyPool.first;
      double lowestRating = calculateCombatRatingForEnemy(lowest);
      for (int i = 1; i < enemyPool.length; i++) {
        final r = calculateCombatRatingForEnemy(enemyPool[i]);
        if (r < lowestRating) {
          lowestRating = r;
          lowest = enemyPool[i];
        }
      }
      generatedEnemies.add(lowest);
    }

    return generatedEnemies;
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/encounter_system_test.dart`
Expected: PASS (including the pre-existing `'generateEnemiesForLevel respects budget strictly'` test, which is unaffected since it doesn't assert on which specific enemies are chosen)

- [ ] **Step 5: Analyze and commit**

Run: `dart analyze`
Expected: No issues found.

```bash
git add lib/game/systems/encounter_system.dart test/encounter_system_test.dart
git commit -m "feat: gate enemy tier availability by act (tier 2 at act 11, tier 3 at act 21)"
```

---

### Task 5: Keep the debug-log formula description in sync

**Files:**
- Modify: `lib/game/services/combat_debug_logger.dart`

**Interfaces:**
- Consumes: nothing new — `logCombatInitialization` keeps its exact existing signature.
- Produces: nothing new — purely a string-literal fix so the printed formula description matches the formula from Task 2 instead of describing a term that no longer exists.

- [ ] **Step 1: Update the stale formula description**

In `lib/game/services/combat_debug_logger.dart`, find:

```dart
    buffer.writeln(buildLine('  • Enemy Level: max(1, playerLevel + (act - 1) * 2 + nodeModifier) = $enemyLevel'));
```

and replace it with:

```dart
    buffer.writeln(buildLine('  • Enemy Level: max(1, playerLevel + nodeModifier) = $enemyLevel'));
```

(This is the only hardcoded formula string in this file that referenced the now-removed act term inside `enemyLevel`. The `NodeMultiplier`, `HP scaling multiplier`, and `Damage scaling multiplier` lines print values only, with no formula text to correct. Fixing the broader log/actual-value drift documented in the spec — `playerCardsCount` and `+(act-1)*10` — is explicitly out of scope for this plan.)

- [ ] **Step 2: Run the debug logger tests to verify nothing broke**

Run: `flutter test test/unit/combat_debug_logger_test.dart`
Expected: PASS (both existing smoke tests only assert `returnsNormally`, so the string change can't break them — this step just confirms no typo introduced a syntax error)

- [ ] **Step 3: Analyze and commit**

Run: `dart analyze`
Expected: No issues found.

```bash
git add lib/game/services/combat_debug_logger.dart
git commit -m "docs: fix debug log formula description to match the act-independent enemyLevel"
```

---

### Task 6: Full regression pass

**Files:** none (verification only)

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: All tests pass, including `test/encounter_system_test.dart`, `test/unit/combat_debug_logger_test.dart`, and every other existing test file (none of which reference `EncounterSystem.getEnemyLevel`, `getHpMultiplier`, or `getDamageMultiplier` outside the files already touched — confirmed via repo-wide search during planning).

- [ ] **Step 2: Run static analysis**

Run: `dart analyze`
Expected: No issues found.

- [ ] **Step 3: Confirm nothing left uncommitted**

Run: `git status`
Expected: Clean working tree — every task already committed its own changes. If anything is uncommitted here, it means a fix was needed during this verification pass; commit it with a message describing what regression it addresses.
