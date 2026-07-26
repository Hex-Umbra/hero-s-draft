# Accélération du Scaling de Difficulté Ennemi — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tighten the cadence of the existing enemy difficulty scaling (act-factor bracket and tier-unlock bracket) so difficulty ramps up noticeably faster while never plateauing, without touching player power, budget formulas, or the enemy-count cap.

**Architecture:** Two `static const int` values in `EncounterSystem` (`lib/game/systems/encounter_system.dart`) drive the entire curve — `_actBracketSize` (HP/damage geometric bracket period) and `_tierUnlockBracketSize` (enemy tier unlock period). Every consumer (`getHpActFactor`, `getDamageActFactor`, `getUnlockedTier`, and everything downstream in `generateEnemiesForLevel`/`combat_debug_logger.dart`) already reads these constants — no call-site changes are needed, only the constants and the doc comments that describe them in prose.

**Tech Stack:** Dart / Flutter, `flutter_test`, `dart analyze`.

## Global Constraints

- No change to `_hpBracketGrowthRate` (1.35), `_dmgBracketGrowthRate` (1.25), `_hpIntraBracketStep` (0.05), `_dmgIntraBracketStep` (0.03), or `maxTierAuthored` (3) — spec §2/§4.
- No change to `calculateBudget` (`ExpectedPower`/`BaseBudget`/`FinalBudget`/`PowerModifier`/`NodeMultiplier`) — spec §4.
- No change to `getMaxEnemiesForNormalCombat/Elite/Boss` (ADR-071 enemy-count cap) — spec §4.
- No change to player-side stats/power (no nerf) — spec §2.
- `dart analyze` must report zero issues after every task (project-wide rule, `CLAUDE.md`).
- `flutter test` must pass in full after every task — regressions in unrelated suites are not acceptable collateral.

---

### Task 1: Accelerate the HP/Damage act-factor bracket (5 → 2 acts)

**Files:**
- Modify: `lib/game/systems/encounter_system.dart:19-51`
- Test: `test/encounter_system_test.dart:427-482`

**Interfaces:**
- Consumes: nothing new — `getActBracket(int act)`, `getActPositionInBracket(int act)`, `getHpActFactor(int act)`, `getDamageActFactor(int act)` already exist with these exact signatures.
- Produces: same signatures, new numeric behavior. `getEnemyLevel`, `getUnlockedTier`, `generateEnemiesForLevel` are untouched by this task and keep consuming `getHpActFactor`/`getDamageActFactor` exactly as before.

- [ ] **Step 1: Update the bracket-dependent tests to the new expected values (RED)**

Replace the five tests in the `Act bracket factor & tier unlock helpers` group that depend on `_actBracketSize` (lines 427-482 of `test/encounter_system_test.dart`) with:

```dart
    test('getHpMultiplier no longer double-counts act — act only moves through the bracket factor', () {
      expect(
        EncounterSystem.getHpMultiplier(enemyLevel: 1, act: 1, isBoss: false, isElite: false),
        closeTo(1.0, 0.0001),
      );
      expect(
        EncounterSystem.getHpMultiplier(enemyLevel: 1, act: 3, isBoss: false, isElite: false),
        closeTo(1.35, 0.0001),
      );
    });

    test('getDamageMultiplier no longer double-counts act — act only moves through the bracket factor', () {
      expect(
        EncounterSystem.getDamageMultiplier(enemyLevel: 1, act: 1, isBoss: false, isElite: false),
        closeTo(1.0, 0.0001),
      );
      expect(
        EncounterSystem.getDamageMultiplier(enemyLevel: 1, act: 3, isBoss: false, isElite: false),
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
      // (1 + 0.06 * 3) * 4.4840334375 (act 11 bracket factor, 2-act bracket) * 1.5 (elite) = 7.936739184375
      expect(result, closeTo(7.936739184375, 0.0001));
    });

    test('getHpActFactor ramps gently within a 2-act bracket then jumps geometrically', () {
      expect(EncounterSystem.getHpActFactor(1), closeTo(1.0, 0.0001));
      expect(EncounterSystem.getHpActFactor(2), closeTo(1.05, 0.0001));
      expect(EncounterSystem.getHpActFactor(3), closeTo(1.35, 0.0001));
      expect(EncounterSystem.getHpActFactor(5), closeTo(1.8225, 0.0001));
      expect(EncounterSystem.getHpActFactor(6), closeTo(1.913625, 0.0001));
      expect(EncounterSystem.getHpActFactor(10), closeTo(3.4875815625, 0.0001));
      expect(EncounterSystem.getHpActFactor(11), closeTo(4.4840334375, 0.0001));
      expect(EncounterSystem.getHpActFactor(15), closeTo(8.1721509398, 0.0001));
    });

    test('getDamageActFactor ramps gently within a 2-act bracket then jumps geometrically', () {
      expect(EncounterSystem.getDamageActFactor(1), closeTo(1.0, 0.0001));
      expect(EncounterSystem.getDamageActFactor(2), closeTo(1.03, 0.0001));
      expect(EncounterSystem.getDamageActFactor(3), closeTo(1.25, 0.0001));
      expect(EncounterSystem.getDamageActFactor(5), closeTo(1.5625, 0.0001));
      expect(EncounterSystem.getDamageActFactor(6), closeTo(1.609375, 0.0001));
      expect(EncounterSystem.getDamageActFactor(10), closeTo(2.5146484375, 0.0001));
      expect(EncounterSystem.getDamageActFactor(11), closeTo(3.0517578125, 0.0001));
      expect(EncounterSystem.getDamageActFactor(15), closeTo(4.7683715820, 0.0001));
    });
```

- [ ] **Step 2: Run the test file to confirm the new expectations fail against current code**

Run: `flutter test test/encounter_system_test.dart --plain-name "Act bracket factor"`
Expected: Multiple FAIL — actual values still reflect the 5-act bracket (e.g. `getHpActFactor(3)` currently returns `1.10...`, not `1.35`).

- [ ] **Step 3: Shrink the bracket period and update its doc comments**

In `lib/game/systems/encounter_system.dart`, change line 23 and the doc comments at lines 27, 30, and 33-35:

```dart
  static const int _actBracketSize = 2;
  static const int _tierUnlockBracketSize = 10;
  static const int maxTierAuthored = 3;

  /// Which 2-act difficulty bracket this act falls in (0 for acts 1-2, 1 for acts 3-4, ...).
  static int getActBracket(int act) => ((act - 1) / _actBracketSize).floor();

  /// Position within the current 2-act bracket (0 to 1).
  static int getActPositionInBracket(int act) => (act - 1) % _actBracketSize;

  /// Combined act factor for HP: a geometric jump every 2 acts, plus a gentle
  /// ramp that resets each bracket. Replaces the old direct `(1 + 0.35*(act-1))`
  /// term, which double-counted the act inside `enemyLevel` as well.
```

(Only `_actBracketSize` and the three doc comments change in this step — `_tierUnlockBracketSize` stays `10` until Task 2.)

- [ ] **Step 4: Run the full test file to confirm everything passes**

Run: `flutter test test/encounter_system_test.dart`
Expected: PASS — all tests green, including the ones untouched by this task (they don't depend on `_actBracketSize`).

- [ ] **Step 5: Commit**

```bash
git add lib/game/systems/encounter_system.dart test/encounter_system_test.dart
git commit -m "feat: accelerate HP/damage difficulty bracket from 5 to 2 acts"
```

---

### Task 2: Accelerate the enemy tier-unlock bracket (10 → 5 acts)

**Files:**
- Modify: `lib/game/systems/encounter_system.dart:24, 53-58`
- Test: `test/encounter_system_test.dart:183-212, 484-493`

**Interfaces:**
- Consumes: nothing new — `getUnlockedTier(int act)` and `generateEnemiesForLevel(...)` already exist with these exact signatures.
- Produces: same signatures, new numeric behavior. `maxTierAuthored` stays `3`.

- [ ] **Step 1: Update the tier-unlock tests to the new expected values (RED)**

Replace the `getUnlockedTier` test (lines 484-493 of `test/encounter_system_test.dart`) with:

```dart
    test('getUnlockedTier stays at 1 for acts 1-5, unlocks 2 at act 6, unlocks 3 at act 11, then caps', () {
      expect(EncounterSystem.getUnlockedTier(1), 1);
      expect(EncounterSystem.getUnlockedTier(5), 1);
      expect(EncounterSystem.getUnlockedTier(6), 2);
      expect(EncounterSystem.getUnlockedTier(10), 2);
      expect(EncounterSystem.getUnlockedTier(11), 3);
      expect(EncounterSystem.getUnlockedTier(15), 3);
      expect(EncounterSystem.getUnlockedTier(16), 3);
      expect(EncounterSystem.getUnlockedTier(100), 3);
    });
```

Replace the two tier-filter tests in `generateEnemiesForLevel` (lines 183-212) with:

```dart
    test('generateEnemiesForLevel excludes tier 2 enemies before act 6', () {
      final enemies = EncounterSystem.generateEnemiesForLevel(
        1,
        [slimeData, goblinData, squeletteData],
        nodeType: MapNodeType.combat,
        playerLevel: 5,
        act: 5,
        playerMaxHp: 100,
        playerAttaque: 0,
        playerMaxMana: 3,
        playerRelicsCount: 0,
      );
      expect(enemies.any((e) => e.tier > 1), isFalse);
    });

    test('generateEnemiesForLevel allows tier 2 enemies starting at act 6', () {
      final enemies = EncounterSystem.generateEnemiesForLevel(
        1,
        [squeletteData],
        nodeType: MapNodeType.combat,
        playerLevel: 5,
        act: 6,
        playerMaxHp: 300,
        playerAttaque: 0,
        playerMaxMana: 10,
        playerRelicsCount: 10,
      );
      expect(enemies, isNotEmpty);
      expect(enemies.every((e) => e.id == 'squelette'), isTrue);
    });
```

- [ ] **Step 2: Run the test file to confirm the new expectations fail against current code**

Run: `flutter test test/encounter_system_test.dart --plain-name "tier"`
Expected: FAIL — e.g. `getUnlockedTier(6)` currently returns `1` (10-act bracket), not `2`; the "excludes tier 2 enemies before act 6" test still finds tier-1-only enemies at act 5 today too (so that one may already pass), but "allows tier 2 enemies starting at act 6" currently fails because tier 2 doesn't unlock until act 11.

- [ ] **Step 3: Shrink the tier-unlock bracket and update its doc comment**

In `lib/game/systems/encounter_system.dart`, change line 24 and the doc comment at lines 53-54:

```dart
  static const int _tierUnlockBracketSize = 5;

  /// Highest enemy tier available at this act: tier 1 through act 5, tier 2
  /// from act 6, tier 3 from act 11, capped at [maxTierAuthored].
```

- [ ] **Step 4: Run the full test file to confirm everything passes**

Run: `flutter test test/encounter_system_test.dart`
Expected: PASS — all tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/game/systems/encounter_system.dart test/encounter_system_test.dart
git commit -m "feat: accelerate enemy tier unlock from 10 to 5 acts"
```

---

### Task 3: Full regression verification

**Files:** none (verification only — no source changes in this task).

**Interfaces:** N/A.

- [ ] **Step 1: Run the entire automated test suite**

Run: `flutter test`
Expected: PASS — every test in the suite green, including `test/unit/combat_debug_logger_test.dart` and any test that exercises `EncounterSystem` indirectly through `CombatController`.

- [ ] **Step 2: Run static analysis**

Run: `dart analyze`
Expected: `No issues found!`

If either step surfaces a failure, fix it before proceeding — do not start Task 4/5 with a red suite or a dirty analyzer (`Global Constraints`).

---

### Task 4: Update the Obsidian memory bank (business_analyst_product_manager persona)

Only start this task once Task 3 is fully green. This is the mandatory documentation step requested for the end of this plan.

**Files:**
- Modify (via the dispatched agent): `.obsidian_vault/_memory_bank/decisionLog.md`, `activeContext.md`, `progress.md`, `systemPatterns.md`, `productContext.md`.

**Interfaces:** N/A (documentation only, no code).

- [ ] **Step 1: Dispatch the business_analyst_product_manager persona via the Agent tool**

```
Agent({
  description: "Update memory bank for difficulty acceleration",
  subagent_type: "general-purpose",
  prompt: "Read `.agents/skills/business_analyst_product_manager.md` in full and adopt that persona exactly — follow its section 3 'Documentation Update Rules' to update the Obsidian memory bank at `.obsidian_vault/_memory_bank/`.

  What changed (already implemented, tested, `dart analyze` clean, on top of ADR-070/ADR-071):
  - `EncounterSystem._actBracketSize` changed from 5 to 2 (`lib/game/systems/encounter_system.dart`). The HP/damage geometric difficulty bracket (x1.35 HP / x1.25 Dégâts per bracket, +5%/+3% intra-bracket ramp — bases and ramp UNCHANGED) now advances every 2 acts instead of every 5.
  - `EncounterSystem._tierUnlockBracketSize` changed from 10 to 5. Enemy tier 2 now unlocks at Act 6 (was Act 11), tier 3 at Act 11 (was Act 21). `maxTierAuthored` stays 3.
  - Nothing else changed: budget formulas (`ExpectedPower`/`BaseBudget`/`FinalBudget`/`PowerModifier`), the ADR-071 enemy-count cap (`getMaxEnemiesForNormalCombat/Elite/Boss`), and player-side power are all untouched.
  - Rationale: playtest feedback showed the player scaling faster than enemies; this closes the gap by resettling the *cadence* of the existing ADR-070 curve, intentionally producing an unbounded exponential difficulty curve. HP factor at Act 25 goes from x3.99 (current) to x36.64 (new) — deliberately close to the pre-ADR-070 double-counting bug's magnitude, accepted as an explicit trade-off. The tier-1-only content window (Slime/Gobelin) shrinks from Acts 1-10 to Acts 1-5, aggravating the tier-1 content backlog already tracked in ADR-070/progress.md.
  - Full design rationale, trajectory tables, and the enemy-count-collapse analysis (budget grows linearly while per-enemy cost grows exponentially, so affordable enemy count per fight peaks ~Act 10-12 then falls) are in `docs/superpowers/specs/2026-07-26-difficulty-scaling-acceleration-design.md` — read it for the numbers before writing the ADR.
  - Add this as a new `ADR-072` entry in `decisionLog.md`, positioned above ADR-071 (most-recent-first ordering), following the same structure as ADR-070/071 (Statut, Contexte, Décision, Preuves dans le code, Conséquences). Update `activeContext.md` (current focus + accomplishments), `progress.md` (feature table + release history — this is v3.5.0, no patch note version reference needed since that's a separate task), `systemPatterns.md` and `productContext.md` (the inline formula/bracket descriptions that currently say '5-act' / 'act 11' / 'act 21' for this system).

  Report back a short summary of exactly which files you changed and which ADR number you used."
})
```

- [ ] **Step 2: Verify the memory bank changes**

Read back `.obsidian_vault/_memory_bank/decisionLog.md` (confirm the new ADR is present and numbered correctly, no contradiction with ADR-070/071) and skim the diffs of the other four files for consistency (no file should still say "5-act bracket" or "act 11"/"act 21" for this system after the update).

- [ ] **Step 3: Commit**

```bash
git add .obsidian_vault/_memory_bank
git commit -m "docs: record ADR-072 and refresh memory bank for accelerated difficulty scaling"
```

---

### Task 5: Write the player-facing patch note for v0.4.6 (patch_notes_writer persona)

Run this task after Task 4 (order requested by the user: docs update, then patch notes).

**Files:**
- Modify (via the dispatched agent): `assets/data/patch_notes.json` only.

**Interfaces:** N/A (content only, no code).

- [ ] **Step 1: Dispatch the patch_notes_writer persona via the Agent tool**

```
Agent({
  description: "Write v0.4.6 patch note for difficulty acceleration",
  subagent_type: "general-purpose",
  prompt: "Read `.agents/skills/patch_notes_writer.md` in full and adopt that persona exactly. Its normal Step 1 (reading `.gemini/antigravity/brain/.../*.md`) does not apply here — instead, use this summary as your source of truth for what shipped:

  - Enemy HP/damage difficulty now climbs faster with each Act: the geometric jump that used to happen every 5 Acts now happens every 2 Acts (same per-jump magnitude as before, just more frequent).
  - Enemy tiers unlock sooner: tougher tier-2 enemies (e.g. the Skeleton) now appear starting at Act 6 instead of Act 11, and tier-3 enemies at Act 11 instead of Act 21.
  - This is a deliberate balance change in response to player feedback that difficulty was falling behind player power growth — the intent is a difficulty curve that stays easy early on but keeps accelerating, without a ceiling.
  - Category: this is purely a balance change — use only the `Équilibrage` (⚖️) category, written for players (no mention of act-bracket constants, ADRs, or file names).
  - Version: write this entry as version `0.4.6` (explicit instruction — this is a PATCH bump per your own numbering rule §3.1, following directly after the current latest entry `0.4.5`). Use today's date in YYYY-MM-DD format for the `date` field.
  - Follow your own Execution Workflow (§4) for everything else: read `assets/data/patch_notes.json` first to confirm `0.4.5` is still the latest entry and to match established tone, prepend the new object at position [0], leave every existing entry untouched, validate the JSON, then report back a short summary.

  Do not touch any file other than `assets/data/patch_notes.json`."
})
```

- [ ] **Step 2: Verify the patch note**

Read `assets/data/patch_notes.json` and confirm: the new `0.4.6` entry is first, valid JSON, French, player-facing (no dev jargon, no act-bracket numbers), and every prior entry (starting with `0.4.5`) is byte-for-byte unchanged.

- [ ] **Step 3: Commit**

```bash
git add assets/data/patch_notes.json
git commit -m "docs: add v0.4.6 patch note for accelerated difficulty scaling"
```
