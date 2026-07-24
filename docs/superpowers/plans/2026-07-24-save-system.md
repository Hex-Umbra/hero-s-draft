# Système de Sauvegarde de Run Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist an active run (RunState, DeckState, InventoryState, SkillState) to `shared_preferences` at map-level checkpoints, and let the player resume it from the Home screen after closing the app.

**Architecture:** A static `SaveService` (mirrors the existing `TutorialProgressService` pattern) reads/writes the four Riverpod state slices as one versioned JSON blob. A `checkpointProvider`/`autosaveOrchestratorProvider` pair triggers `SaveService.save()` automatically whenever `MapProgressionManager.completeCurrentNode()` or `PlayerStatsManager.decrementPendingDrafts()` runs — the two existing methods already called by every node-resolution screen (combat, shop, rest, event, forge fusion, relic exchange, level-up draft). No UI screen needs to know the save system exists.

**Tech Stack:** Flutter, Riverpod 2.x (`Notifier`/`NotifierProvider`), `shared_preferences` (already a dependency), Dart 3 records for multi-value returns.

## Global Constraints

- `dart analyze` must stay at 0 issues after every task (per project convention).
- `flutter test` must stay at 100% green after every task.
- No mid-combat persistence: `CombatState` is never serialized (per spec §2).
- Single save slot, one `shared_preferences` key (per spec §2).
- Game content (cards/relics/passives/forge upgrades) is always re-resolved by ID from `GameDataRegistry` at load time, never trusted from the embedded save blob (per spec §4).
- All new Flutter-widget-facing strings go through `lib/l10n/app_en.arb` / `app_fr.arb`, never hardcoded (per CLAUDE.md).

## Deviations From the Approved Spec (flagged for visibility)

Two details differ from the literal spec wording, discovered while reading the real code — both preserve the spec's *intent*:

1. **Checkpoint trigger location.** The spec's §5 lists 7 UI screens as "bump" call sites. Reading the code shows all 6 node-resolution screens (`ShopScreen`, `RestScreen`, `EventScreen`, `ForgeFusionScreen`, `RelicExchangeScreen`, `GameScreen` combat victory) already funnel through the single existing method `RunController.completeCurrentNode()` → `MapProgressionManager.completeCurrentNode()`. The 7th case (Level-Up draft) funnels through `RunController.decrementPendingDrafts()` → `PlayerStatsManager.decrementPendingDrafts()`. Putting the `bump()` call in these 2 manager methods instead of 7 screen files is more DRY and impossible to forget when a future screen reuses these methods. Same trigger semantics, fewer, safer integration points.
2. **"Victoire finale" save-clearing.** The spec says to clear the save "à la victoire finale (retour au menu principal) ou à la mort du héros." Reading `MapProgressionManager.advanceToNextWorld()` shows acts increment indefinitely with no terminal "you won the game" state in the current code — only death (`RunState.isDead`) ends a run. This plan therefore only wires `SaveService.clear()` to the death flow in `GameScreen`, since that is the only terminal state that exists today.

---

### Task 1: Catalog lookup helpers + missing-item reporting primitives

**Files:**
- Create: `lib/models/missing_save_item.dart`
- Modify: `lib/models/data/card_data.dart`
- Modify: `lib/models/data/relic_data.dart`
- Modify: `lib/models/data/passive_data.dart`
- Modify: `lib/models/data/forge_upgrade_data.dart`
- Test: `test/unit/save_catalog_lookups_test.dart`

**Interfaces:**
- Consumes: `GameDataRegistry.instance` (existing static singleton, `lib/models/data/game_data_registry.dart`), the existing `ForgeUpgradeData.getById` pattern (`lib/models/data/forge_upgrade_data.dart:84-92`) as the template to mirror.
- Produces: `MissingSaveItem({id, nameFr, nameEn, category})` (with value equality), `CardData.getById(String id) -> CardData?`, `RelicData.getById(String id) -> RelicData?`, `PassiveData.getById(String id) -> PassiveData?`, `ForgeUpgradeData.filterValidRefs(List<dynamic>? raw) -> (List<String>, List<MissingSaveItem>)`. All of these are consumed by Tasks 3, 4, 5.

- [ ] **Step 1: Write the failing test for `MissingSaveItem` equality**

```dart
// test/unit/save_catalog_lookups_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/missing_save_item.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

void main() {
  group('MissingSaveItem', () {
    test('two items with the same fields are equal', () {
      const a = MissingSaveItem(
        id: 'kunai',
        nameFr: 'Croc Kunaï',
        nameEn: 'Kunai Fang',
        category: 'relic',
      );
      const b = MissingSaveItem(
        id: 'kunai',
        nameFr: 'Croc Kunaï',
        nameEn: 'Kunai Fang',
        category: 'relic',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/save_catalog_lookups_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:roguelike_card_game/models/missing_save_item.dart'`

- [ ] **Step 3: Create `MissingSaveItem`**

```dart
// lib/models/missing_save_item.dart
class MissingSaveItem {
  final String id;
  final String nameFr;
  final String nameEn;
  final String category;

  const MissingSaveItem({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MissingSaveItem &&
          other.id == id &&
          other.nameFr == nameFr &&
          other.nameEn == nameEn &&
          other.category == category);

  @override
  int get hashCode => Object.hash(id, nameFr, nameEn, category);

  @override
  String toString() =>
      'MissingSaveItem(id: $id, category: $category, nameFr: $nameFr, nameEn: $nameEn)';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/save_catalog_lookups_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/models/missing_save_item.dart test/unit/save_catalog_lookups_test.dart
git commit -m "feat(save): add MissingSaveItem value type"
```

- [ ] **Step 6: Write the failing tests for the three `getById` helpers**

```dart
// Add inside test/unit/save_catalog_lookups_test.dart, inside main()
  group('Catalog getById helpers', () {
    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        skills: [],
        cards: [
          const CardData(
            id: 'strike_basic',
            cost: 1,
            type: CardType.attack,
            category: CardCategory.global,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            effects: [],
          ),
        ],
        events: [],
        passives: [
          const PassiveData(
            id: 'regenArmor',
            trigger: RelicTrigger.endOfTurn,
            effectType: 'gain_armor',
            value: 2,
          ),
        ],
        relics: [
          const RelicData(
            id: 'kunai',
            trigger: RelicTrigger.onAttackPlayed,
            effectType: 'kunai_charge',
            value: 1,
            rarity: RelicRarity.rare,
            emoji: '🗡️',
          ),
        ],
        forgeUpgrades: [],
      );
    });

    test('CardData.getById finds an existing card', () {
      expect(CardData.getById('strike_basic')?.id, 'strike_basic');
    });

    test('CardData.getById returns null for an unknown id', () {
      expect(CardData.getById('does_not_exist'), isNull);
    });

    test('RelicData.getById finds an existing relic', () {
      expect(RelicData.getById('kunai')?.id, 'kunai');
    });

    test('RelicData.getById returns null for an unknown id', () {
      expect(RelicData.getById('does_not_exist'), isNull);
    });

    test('PassiveData.getById finds an existing passive', () {
      expect(PassiveData.getById('regenArmor')?.id, 'regenArmor');
    });

    test('PassiveData.getById returns null for an unknown id', () {
      expect(PassiveData.getById('does_not_exist'), isNull);
    });
  });
```

- [ ] **Step 7: Run tests to verify they fail**

Run: `flutter test test/unit/save_catalog_lookups_test.dart`
Expected: FAIL — `The method 'getById' isn't defined for the class 'CardData'` (and similarly for `RelicData`, `PassiveData`)

- [ ] **Step 8: Add `CardData.getById`**

```dart
// lib/models/data/card_data.dart
// Add import at top of file:
import 'game_data_registry.dart';

// Add inside class CardData, after the toJson getter:
  static CardData? getById(String id) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return null;
    try {
      return registry.cards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
```

- [ ] **Step 9: Add `RelicData.getById`**

```dart
// lib/models/data/relic_data.dart
// Add import at top of file:
import 'game_data_registry.dart';

// Add inside class RelicData, after the fromJson factory:
  static RelicData? getById(String id) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return null;
    try {
      return registry.relics.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
```

- [ ] **Step 10: Add `PassiveData.getById`**

```dart
// lib/models/data/passive_data.dart
// Add import at top of file, alongside the existing 'relic_data.dart' import:
import 'game_data_registry.dart';

// Add inside class PassiveData, after the fromJson factory:
  static PassiveData? getById(String id) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return null;
    try {
      return registry.passives.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
```

- [ ] **Step 11: Run tests to verify they pass**

Run: `flutter test test/unit/save_catalog_lookups_test.dart`
Expected: PASS (all 7 tests so far)

- [ ] **Step 12: Commit**

```bash
git add lib/models/data/card_data.dart lib/models/data/relic_data.dart lib/models/data/passive_data.dart test/unit/save_catalog_lookups_test.dart
git commit -m "feat(save): add getById lookups to CardData, RelicData, PassiveData"
```

- [ ] **Step 13: Write the failing test for `ForgeUpgradeData.filterValidRefs`**

```dart
// Add inside test/unit/save_catalog_lookups_test.dart, inside main()
  group('ForgeUpgradeData.filterValidRefs', () {
    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        skills: [],
        cards: [],
        events: [],
        passives: [],
        relics: [],
        forgeUpgrades: [
          const ForgeUpgradeData(
            id: 'enduring',
            nameEn: 'Enduring',
            nameFr: 'Increvable',
            descriptionEn: 'Never exhausts.',
            descriptionFr: "N'est jamais épuisée.",
            icon: 'shield_rounded',
            color: 'blueAccent',
            pools: ['common'],
          ),
        ],
      );
    });

    test('keeps refs whose id resolves and drops refs whose id does not', () {
      final (kept, missing) = ForgeUpgradeData.filterValidRefs([
        'enduring:1',
        'removed_upgrade:2',
      ]);

      expect(kept, ['enduring:1']);
      expect(missing, [
        const MissingSaveItem(
          id: 'removed_upgrade',
          nameFr: 'removed_upgrade',
          nameEn: 'removed_upgrade',
          category: 'forgeUpgrade',
        ),
      ]);
    });

    test('handles a null input list gracefully', () {
      final (kept, missing) = ForgeUpgradeData.filterValidRefs(null);
      expect(kept, isEmpty);
      expect(missing, isEmpty);
    });
  });
```

- [ ] **Step 14: Run test to verify it fails**

Run: `flutter test test/unit/save_catalog_lookups_test.dart`
Expected: FAIL — `The method 'filterValidRefs' isn't defined for the class 'ForgeUpgradeData'`

- [ ] **Step 15: Add `ForgeUpgradeData.filterValidRefs`**

```dart
// lib/models/data/forge_upgrade_data.dart
// Add import at top of file:
import '../missing_save_item.dart';

// Add inside class ForgeUpgradeData, after getById:
  static (List<String>, List<MissingSaveItem>) filterValidRefs(
    List<dynamic>? raw,
  ) {
    final kept = <String>[];
    final missing = <MissingSaveItem>[];
    for (final entry in (raw ?? const [])) {
      final ref = entry as String;
      final id = ref.split(':').first;
      if (getById(id) != null) {
        kept.add(ref);
      } else {
        missing.add(
          MissingSaveItem(
            id: id,
            nameFr: id,
            nameEn: id,
            category: 'forgeUpgrade',
          ),
        );
      }
    }
    return (kept, missing);
  }
```

- [ ] **Step 16: Run tests to verify they pass**

Run: `flutter test test/unit/save_catalog_lookups_test.dart`
Expected: PASS (all 9 tests)

- [ ] **Step 17: Run static analysis**

Run: `dart analyze lib/models/missing_save_item.dart lib/models/data/card_data.dart lib/models/data/relic_data.dart lib/models/data/passive_data.dart lib/models/data/forge_upgrade_data.dart`
Expected: `No issues found!`

- [ ] **Step 18: Commit**

```bash
git add lib/models/data/forge_upgrade_data.dart test/unit/save_catalog_lookups_test.dart
git commit -m "feat(save): add ForgeUpgradeData.filterValidRefs for save rehydration"
```

---

### Task 2: `SkillState` serialization

**Files:**
- Modify: `lib/models/skill_state.dart`
- Test: `test/unit/skill_state_persistence_test.dart`

**Interfaces:**
- Consumes: nothing new (no catalog references in `SkillState`).
- Produces: `SkillState.toJson() -> Map<String, dynamic>`, `SkillState.fromJson(Map<String, dynamic>) -> SkillState`. Consumed by Task 7 (`SaveService`).

- [ ] **Step 1: Write the failing round-trip test**

```dart
// test/unit/skill_state_persistence_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/skill_state.dart';

void main() {
  group('SkillState persistence', () {
    test('toJson/fromJson round-trips cooldowns', () {
      const state = SkillState(skill1Cooldown: 2, skill2Cooldown: 0);

      final json = state.toJson();
      final restored = SkillState.fromJson(json);

      expect(restored.skill1Cooldown, 2);
      expect(restored.skill2Cooldown, 0);
    });

    test('fromJson defaults missing fields to 0', () {
      final restored = SkillState.fromJson(const {});
      expect(restored.skill1Cooldown, 0);
      expect(restored.skill2Cooldown, 0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/skill_state_persistence_test.dart`
Expected: FAIL — `The method 'toJson' isn't defined for the class 'SkillState'`

- [ ] **Step 3: Add `toJson`/`fromJson` to `SkillState`**

```dart
// lib/models/skill_state.dart
class SkillState {
  final int skill1Cooldown;
  final int skill2Cooldown;

  const SkillState({this.skill1Cooldown = 0, this.skill2Cooldown = 0});

  SkillState copyWith({int? skill1Cooldown, int? skill2Cooldown}) {
    return SkillState(
      skill1Cooldown: skill1Cooldown ?? this.skill1Cooldown,
      skill2Cooldown: skill2Cooldown ?? this.skill2Cooldown,
    );
  }

  Map<String, dynamic> toJson() => {
        'skill1Cooldown': skill1Cooldown,
        'skill2Cooldown': skill2Cooldown,
      };

  factory SkillState.fromJson(Map<String, dynamic> json) => SkillState(
        skill1Cooldown: json['skill1Cooldown'] as int? ?? 0,
        skill2Cooldown: json['skill2Cooldown'] as int? ?? 0,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/skill_state_persistence_test.dart`
Expected: PASS

- [ ] **Step 5: Run static analysis**

Run: `dart analyze lib/models/skill_state.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/models/skill_state.dart test/unit/skill_state_persistence_test.dart
git commit -m "feat(save): add SkillState serialization"
```

---

### Task 3: `InventoryState` serialization with relic name-snapshot

**Files:**
- Modify: `lib/models/inventory_state.dart`
- Test: `test/unit/inventory_state_persistence_test.dart`

**Interfaces:**
- Consumes: `RelicData.getById(String) -> RelicData?` (Task 1), `MissingSaveItem` (Task 1).
- Produces: `InventoryState.toJson() -> Map<String, dynamic>`, `InventoryState.fromJsonWithReport(Map<String, dynamic>) -> (InventoryState, List<MissingSaveItem>)`. Consumed by Task 7.

- [ ] **Step 1: Write the failing tests**

```dart
// test/unit/inventory_state_persistence_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/inventory_state.dart';
import 'package:roguelike_card_game/models/missing_save_item.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

void main() {
  group('InventoryState persistence', () {
    const kunai = RelicData(
      id: 'kunai',
      nameFr: 'Croc Kunaï',
      nameEn: 'Kunai Fang',
      trigger: RelicTrigger.onAttackPlayed,
      effectType: 'kunai_charge',
      value: 1,
      rarity: RelicRarity.rare,
      emoji: '🗡️',
    );

    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        skills: [],
        cards: [],
        events: [],
        passives: [],
        relics: [kunai],
        forgeUpgrades: [],
      );
    });

    test('toJson/fromJsonWithReport round-trips gold, relics and bonusShopCards', () {
      const state = InventoryState(
        gold: 120,
        relics: [kunai],
        bonusShopCards: 2,
      );

      final json = state.toJson();
      final (restored, missing) = InventoryState.fromJsonWithReport(json);

      expect(restored.gold, 120);
      expect(restored.bonusShopCards, 2);
      expect(restored.relics.map((r) => r.id), ['kunai']);
      expect(missing, isEmpty);
    });

    test('drops a relic whose id no longer resolves and reports it', () {
      final json = {
        'gold': 50,
        'relics': [
          {'id': 'kunai', 'nameFr': 'Croc Kunaï', 'nameEn': 'Kunai Fang'},
          {'id': 'removed_relic', 'nameFr': 'Vieille Amulette', 'nameEn': 'Old Amulet'},
        ],
        'bonusShopCards': 0,
      };

      final (restored, missing) = InventoryState.fromJsonWithReport(json);

      expect(restored.relics.map((r) => r.id), ['kunai']);
      expect(missing, [
        const MissingSaveItem(
          id: 'removed_relic',
          nameFr: 'Vieille Amulette',
          nameEn: 'Old Amulet',
          category: 'relic',
        ),
      ]);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/inventory_state_persistence_test.dart`
Expected: FAIL — `The method 'toJson' isn't defined for the class 'InventoryState'`

- [ ] **Step 3: Add `toJson`/`fromJsonWithReport` to `InventoryState`**

```dart
// lib/models/inventory_state.dart
import 'data/relic_data.dart';
import 'missing_save_item.dart';

class InventoryState {
  final int gold;
  final List<RelicData> relics;
  final int bonusShopCards;

  const InventoryState({
    this.gold = 0,
    this.relics = const [],
    this.bonusShopCards = 0,
  });

  InventoryState copyWith({
    int? gold,
    List<RelicData>? relics,
    int? bonusShopCards,
  }) {
    return InventoryState(
      gold: gold ?? this.gold,
      relics: relics ?? this.relics,
      bonusShopCards: bonusShopCards ?? this.bonusShopCards,
    );
  }

  Map<String, dynamic> toJson() => {
        'gold': gold,
        'relics': relics
            .map((r) => {'id': r.id, 'nameFr': r.nameFr, 'nameEn': r.nameEn})
            .toList(),
        'bonusShopCards': bonusShopCards,
      };

  static (InventoryState, List<MissingSaveItem>) fromJsonWithReport(
    Map<String, dynamic> json,
  ) {
    final missing = <MissingSaveItem>[];
    final relics = <RelicData>[];

    for (final entry in (json['relics'] as List<dynamic>? ?? const [])) {
      final map = entry as Map<String, dynamic>;
      final id = map['id'] as String;
      final relic = RelicData.getById(id);
      if (relic != null) {
        relics.add(relic);
      } else {
        missing.add(
          MissingSaveItem(
            id: id,
            nameFr: map['nameFr'] as String? ?? id,
            nameEn: map['nameEn'] as String? ?? id,
            category: 'relic',
          ),
        );
      }
    }

    return (
      InventoryState(
        gold: json['gold'] as int? ?? 0,
        relics: relics,
        bonusShopCards: json['bonusShopCards'] as int? ?? 0,
      ),
      missing,
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/inventory_state_persistence_test.dart`
Expected: PASS

- [ ] **Step 5: Run static analysis**

Run: `dart analyze lib/models/inventory_state.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/models/inventory_state.dart test/unit/inventory_state_persistence_test.dart
git commit -m "feat(save): add InventoryState serialization with relic name snapshots"
```

---

### Task 4: `DeckState` serialization with card/forge-upgrade rehydration

**Files:**
- Modify: `lib/game/controllers/deck_controller.dart`
- Test: `test/unit/deck_state_persistence_test.dart`

**Interfaces:**
- Consumes: `CardData.getById(String) -> CardData?` (Task 1), `ForgeUpgradeData.filterValidRefs(List<dynamic>?) -> (List<String>, List<MissingSaveItem>)` (Task 1), `MissingSaveItem` (Task 1), existing `CardInstance.toJson()`/`CardInstance.fromJson()`/`CardInstance.copyWith()` (`lib/models/card_instance.dart`).
- Produces: `DeckState.toJson() -> Map<String, dynamic>`, `DeckState.fromJsonWithReport(Map<String, dynamic>) -> (DeckState, List<MissingSaveItem>)`. Consumed by Task 7.

- [ ] **Step 1: Write the failing tests**

```dart
// test/unit/deck_state_persistence_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/missing_save_item.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

void main() {
  group('DeckState persistence', () {
    const strike = CardData(
      id: 'strike_basic',
      nameFr: 'Frappe',
      nameEn: 'Strike',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [],
    );

    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        skills: [],
        cards: [strike],
        events: [],
        passives: [],
        relics: [],
        forgeUpgrades: [
          const ForgeUpgradeData(
            id: 'sharp',
            nameEn: 'Sharp',
            nameFr: 'Tranchant',
            descriptionEn: '+{val} Damage',
            descriptionFr: '+{val} Dégâts',
            icon: 'hardware_rounded',
            color: 'redAccent',
            pools: ['common'],
          ),
        ],
      );
    });

    test('toJson/fromJsonWithReport round-trips piles and re-resolves fresh CardData', () {
      final card = CardInstance(
        uniqueId: 'card-1',
        data: strike,
        forgeUpgrades: const ['sharp:1'],
      );
      final state = DeckState(masterDeck: [card], drawPile: [card]);

      final json = state.toJson();
      final (restored, missing) = DeckState.fromJsonWithReport(json);

      expect(restored.masterDeck.single.uniqueId, 'card-1');
      expect(restored.masterDeck.single.data.id, 'strike_basic');
      expect(restored.masterDeck.single.forgeUpgrades, ['sharp:1']);
      expect(restored.drawPile.single.uniqueId, 'card-1');
      expect(missing, isEmpty);
    });

    test('drops a card whose CardData id no longer resolves and reports it', () {
      final removedCard = CardInstance(
        uniqueId: 'card-2',
        data: const CardData(
          id: 'removed_card',
          nameFr: 'Vieille Carte',
          nameEn: 'Old Card',
          cost: 1,
          type: CardType.attack,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: [],
        ),
      );
      final json = DeckState(masterDeck: [removedCard]).toJson();

      final (restored, missing) = DeckState.fromJsonWithReport(json);

      expect(restored.masterDeck, isEmpty);
      expect(missing, [
        const MissingSaveItem(
          id: 'removed_card',
          nameFr: 'Vieille Carte',
          nameEn: 'Old Card',
          category: 'card',
        ),
      ]);
    });

    test('drops a forge upgrade whose id no longer resolves and reports it, keeping the card', () {
      final card = CardInstance(
        uniqueId: 'card-3',
        data: strike,
        forgeUpgrades: const ['sharp:1', 'removed_upgrade:1'],
      );
      final json = DeckState(masterDeck: [card]).toJson();

      final (restored, missing) = DeckState.fromJsonWithReport(json);

      expect(restored.masterDeck.single.forgeUpgrades, ['sharp:1']);
      expect(missing, [
        const MissingSaveItem(
          id: 'removed_upgrade',
          nameFr: 'removed_upgrade',
          nameEn: 'removed_upgrade',
          category: 'forgeUpgrade',
        ),
      ]);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/deck_state_persistence_test.dart`
Expected: FAIL — `The method 'toJson' isn't defined for the class 'DeckState'`

- [ ] **Step 3: Add `toJson`/`fromJsonWithReport` to `DeckState`**

```dart
// lib/game/controllers/deck_controller.dart
// Add these imports alongside the existing ones at the top of the file:
import '../../models/missing_save_item.dart';
import '../../models/data/forge_upgrade_data.dart';

// Modify class DeckState: add the two methods after copyWith()
class DeckState {
  final List<CardInstance> masterDeck;
  final List<CardInstance> drawPile;
  final List<CardInstance> hand;
  final List<CardInstance> discardPile;
  final List<CardInstance> exhaustPile;

  const DeckState({
    this.masterDeck = const [],
    this.drawPile = const [],
    this.hand = const [],
    this.discardPile = const [],
    this.exhaustPile = const [],
  });

  DeckState copyWith({
    List<CardInstance>? masterDeck,
    List<CardInstance>? drawPile,
    List<CardInstance>? hand,
    List<CardInstance>? discardPile,
    List<CardInstance>? exhaustPile,
  }) {
    return DeckState(
      masterDeck: masterDeck ?? this.masterDeck,
      drawPile: drawPile ?? this.drawPile,
      hand: hand ?? this.hand,
      discardPile: discardPile ?? this.discardPile,
      exhaustPile: exhaustPile ?? this.exhaustPile,
    );
  }

  Map<String, dynamic> toJson() => {
        'masterDeck': masterDeck.map((c) => c.toJson()).toList(),
        'drawPile': drawPile.map((c) => c.toJson()).toList(),
        'hand': hand.map((c) => c.toJson()).toList(),
        'discardPile': discardPile.map((c) => c.toJson()).toList(),
        'exhaustPile': exhaustPile.map((c) => c.toJson()).toList(),
      };

  static (List<CardInstance>, List<MissingSaveItem>) _decodePile(
    List<dynamic>? rawPile,
  ) {
    final kept = <CardInstance>[];
    final missing = <MissingSaveItem>[];

    for (final entry in (rawPile ?? const [])) {
      final instance = CardInstance.fromJson(entry as Map<String, dynamic>);
      final freshData = CardData.getById(instance.data.id);
      if (freshData == null) {
        missing.add(
          MissingSaveItem(
            id: instance.data.id,
            nameFr: instance.data.nameFr,
            nameEn: instance.data.nameEn,
            category: 'card',
          ),
        );
        continue;
      }
      final (validUpgrades, upgradesMissing) =
          ForgeUpgradeData.filterValidRefs(instance.forgeUpgrades);
      missing.addAll(upgradesMissing);
      kept.add(instance.copyWith(data: freshData, forgeUpgrades: validUpgrades));
    }

    return (kept, missing);
  }

  static (DeckState, List<MissingSaveItem>) fromJsonWithReport(
    Map<String, dynamic> json,
  ) {
    final missing = <MissingSaveItem>[];

    final (masterDeck, m1) = _decodePile(json['masterDeck'] as List<dynamic>?);
    final (drawPile, m2) = _decodePile(json['drawPile'] as List<dynamic>?);
    final (hand, m3) = _decodePile(json['hand'] as List<dynamic>?);
    final (discardPile, m4) = _decodePile(json['discardPile'] as List<dynamic>?);
    final (exhaustPile, m5) = _decodePile(json['exhaustPile'] as List<dynamic>?);
    missing
      ..addAll(m1)
      ..addAll(m2)
      ..addAll(m3)
      ..addAll(m4)
      ..addAll(m5);

    return (
      DeckState(
        masterDeck: masterDeck,
        drawPile: drawPile,
        hand: hand,
        discardPile: discardPile,
        exhaustPile: exhaustPile,
      ),
      missing,
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/deck_state_persistence_test.dart`
Expected: PASS

- [ ] **Step 5: Run static analysis**

Run: `dart analyze lib/game/controllers/deck_controller.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/game/controllers/deck_controller.dart test/unit/deck_state_persistence_test.dart
git commit -m "feat(save): add DeckState serialization with card and forge-upgrade rehydration"
```

---

### Task 5: `RunState` serialization

**Files:**
- Modify: `lib/game/controllers/run_controller.dart`
- Test: `test/unit/run_state_persistence_test.dart`

**Interfaces:**
- Consumes: `PassiveData.getById(String) -> PassiveData?` (Task 1), `ForgeUpgradeData.filterValidRefs` (Task 1), `MissingSaveItem` (Task 1), existing `EntityStats.toJson()`/`fromJson()` (`lib/models/entity_stats.dart`), existing `MapNode.toJson()`/`fromJson()` (`lib/models/map_node.dart`).
- Produces: `RunState.toJson() -> Map<String, dynamic>`, `RunState.fromJsonWithReport(Map<String, dynamic>) -> (RunState, List<MissingSaveItem>)`. Consumed by Task 7.

- [ ] **Step 1: Write the failing tests**

```dart
// test/unit/run_state_persistence_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/missing_save_item.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

void main() {
  group('RunState persistence', () {
    const regenArmor = PassiveData(
      id: 'regenArmor',
      nameFr: "Régénération d'Armure",
      nameEn: 'Armor Regeneration',
      trigger: RelicTrigger.endOfTurn,
      effectType: 'gain_armor',
      value: 2,
    );

    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        skills: [],
        cards: [],
        events: [],
        passives: [regenArmor],
        relics: [],
        forgeUpgrades: [
          const ForgeUpgradeData(
            id: 'enduring',
            nameEn: 'Enduring',
            nameFr: 'Increvable',
            descriptionEn: 'Never exhausts.',
            descriptionFr: "N'est jamais épuisée.",
            icon: 'shield_rounded',
            color: 'blueAccent',
            pools: ['common'],
          ),
        ],
      );
    });

    RunState buildRunState() => RunState(
          currentLevel: 5,
          act: 2,
          heroClassId: 'paladin',
          passiveTrait: 'regenArmor',
          activePassive: regenArmor,
          heroStats: EntityStats(
            maxPv: 80,
            currentPv: 60,
            maxMana: 4,
            currentMana: 4,
            armure: 0,
            attaque: 0,
          ),
          mapNodes: const [],
          currentNodeId: 'floor_3_node_1',
          forgeSlots: const ['enduring:1'],
          forgeTargetCardId: 'card-1',
          forgeTargetSessions: const {
            'card-1': ['enduring:1'],
          },
          bonusForgeSlots: 1,
          pendingDrafts: 2,
        );

    test('toJson/fromJsonWithReport round-trips every field', () {
      final json = buildRunState().toJson();
      final (restored, missing) = RunState.fromJsonWithReport(json);

      expect(restored.currentLevel, 5);
      expect(restored.act, 2);
      expect(restored.heroClassId, 'paladin');
      expect(restored.passiveTrait, 'regenArmor');
      expect(restored.activePassive?.id, 'regenArmor');
      expect(restored.heroStats.currentPv, 60);
      expect(restored.currentNodeId, 'floor_3_node_1');
      expect(restored.forgeSlots, ['enduring:1']);
      expect(restored.forgeTargetCardId, 'card-1');
      expect(restored.forgeTargetSessions, {
        'card-1': ['enduring:1'],
      });
      expect(restored.bonusForgeSlots, 1);
      expect(restored.pendingDrafts, 2);
      expect(missing, isEmpty);
    });

    test('falls back to PassiveData.fallback and reports a missing passive', () {
      final json = buildRunState().toJson();
      json['activePassiveId'] = 'removed_passive';
      json['activePassiveNameFr'] = 'Passif Retiré';
      json['activePassiveNameEn'] = 'Removed Passive';

      final (restored, missing) = RunState.fromJsonWithReport(json);

      expect(restored.activePassive?.id, 'none');
      expect(missing, [
        const MissingSaveItem(
          id: 'removed_passive',
          nameFr: 'Passif Retiré',
          nameEn: 'Removed Passive',
          category: 'passive',
        ),
      ]);
    });

    test('drops a missing forge upgrade id from forgeSlots and reports it', () {
      final json = buildRunState().toJson();
      json['forgeSlots'] = ['enduring:1', 'removed_upgrade:2'];

      final (restored, missing) = RunState.fromJsonWithReport(json);

      expect(restored.forgeSlots, ['enduring:1']);
      expect(missing, [
        const MissingSaveItem(
          id: 'removed_upgrade',
          nameFr: 'removed_upgrade',
          nameEn: 'removed_upgrade',
          category: 'forgeUpgrade',
        ),
      ]);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/run_state_persistence_test.dart`
Expected: FAIL — `The method 'toJson' isn't defined for the class 'RunState'`

- [ ] **Step 3: Add `toJson`/`fromJsonWithReport` to `RunState`**

```dart
// lib/game/controllers/run_controller.dart
// Add these imports alongside the existing ones at the top of the file:
import '../../models/missing_save_item.dart';
import '../../models/data/forge_upgrade_data.dart';

// Modify class RunState: add the two methods after copyWith()
// (the rest of the class — fields, getters, constructor, copyWith — is unchanged)
  Map<String, dynamic> toJson() => {
        'currentLevel': currentLevel,
        'act': act,
        'heroStats': heroStats.toJson(),
        'heroClassId': heroClassId,
        'mapNodes': mapNodes.map((n) => n.toJson()).toList(),
        'currentNodeId': currentNodeId,
        'passiveTrait': passiveTrait,
        'activePassiveId': activePassive?.id,
        'activePassiveNameFr': activePassive?.nameFr,
        'activePassiveNameEn': activePassive?.nameEn,
        'forgeSlots': forgeSlots,
        'forgeTargetCardId': forgeTargetCardId,
        'forgeTargetSessions': forgeTargetSessions,
        'bonusForgeSlots': bonusForgeSlots,
        'pendingDrafts': pendingDrafts,
      };

  static (RunState, List<MissingSaveItem>) fromJsonWithReport(
    Map<String, dynamic> json,
  ) {
    final missing = <MissingSaveItem>[];

    final (forgeSlots, forgeSlotsMissing) =
        ForgeUpgradeData.filterValidRefs(json['forgeSlots'] as List<dynamic>?);
    missing.addAll(forgeSlotsMissing);

    final rawSessions =
        json['forgeTargetSessions'] as Map<String, dynamic>? ?? const {};
    final forgeTargetSessions = <String, List<String>>{};
    rawSessions.forEach((cardId, refs) {
      final (upgrades, sessionMissing) =
          ForgeUpgradeData.filterValidRefs(refs as List<dynamic>?);
      forgeTargetSessions[cardId] = upgrades;
      missing.addAll(sessionMissing);
    });

    final activePassiveId = json['activePassiveId'] as String?;
    PassiveData? activePassive;
    if (activePassiveId != null) {
      activePassive = PassiveData.getById(activePassiveId);
      if (activePassive == null) {
        missing.add(
          MissingSaveItem(
            id: activePassiveId,
            nameFr: json['activePassiveNameFr'] as String? ?? activePassiveId,
            nameEn: json['activePassiveNameEn'] as String? ?? activePassiveId,
            category: 'passive',
          ),
        );
        activePassive = PassiveData.fallback(
          json['passiveTrait'] as String? ?? '',
        );
      }
    }

    final run = RunState(
      currentLevel: json['currentLevel'] as int,
      act: json['act'] as int? ?? 1,
      heroStats: EntityStats.fromJson(json['heroStats'] as Map<String, dynamic>),
      heroClassId: json['heroClassId'] as String,
      mapNodes: (json['mapNodes'] as List<dynamic>? ?? const [])
          .map((n) => MapNode.fromJson(n as Map<String, dynamic>))
          .toList(),
      currentNodeId: json['currentNodeId'] as String?,
      passiveTrait: json['passiveTrait'] as String?,
      activePassive: activePassive,
      forgeSlots: forgeSlots,
      forgeTargetCardId: json['forgeTargetCardId'] as String?,
      forgeTargetSessions: forgeTargetSessions,
      bonusForgeSlots: json['bonusForgeSlots'] as int? ?? 0,
      pendingDrafts: json['pendingDrafts'] as int? ?? 0,
    );

    return (run, missing);
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/run_state_persistence_test.dart`
Expected: PASS

- [ ] **Step 5: Run static analysis**

Run: `dart analyze lib/game/controllers/run_controller.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/game/controllers/run_controller.dart test/unit/run_state_persistence_test.dart
git commit -m "feat(save): add RunState serialization"
```

---

### Task 6: `hydrate()` on each Notifier

**Files:**
- Modify: `lib/game/controllers/run_controller.dart`
- Modify: `lib/game/controllers/deck_controller.dart`
- Modify: `lib/game/controllers/inventory_controller.dart`
- Modify: `lib/game/controllers/skill_controller.dart`
- Test: `test/unit/notifier_hydrate_test.dart`

**Interfaces:**
- Consumes: `RunState`, `DeckState`, `InventoryState`, `SkillState` (all existing).
- Produces: `RunController.hydrate(RunState)`, `DeckNotifier.hydrate(DeckState)`, `InventoryController.hydrate(InventoryState)`, `SkillController.hydrate(SkillState)` — each simply replaces `state`. Consumed by Task 7 (`SaveService.load`).

- [ ] **Step 1: Write the failing tests**

```dart
// test/unit/notifier_hydrate_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/skill_controller.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/skill_state.dart';
import 'package:roguelike_card_game/models/inventory_state.dart';

void main() {
  group('Notifier.hydrate', () {
    test('RunController.hydrate replaces the state wholesale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(runProvider.notifier);

      final hydrated = RunState(
        currentLevel: 9,
        act: 3,
        heroClassId: 'berserker',
        heroStats: EntityStats(maxPv: 50, currentPv: 10, armure: 0, attaque: 5),
      );
      controller.hydrate(hydrated);

      expect(container.read(runProvider).currentLevel, 9);
      expect(container.read(runProvider).heroClassId, 'berserker');
    });

    test('DeckNotifier.hydrate replaces the state wholesale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(deckProvider.notifier);

      controller.hydrate(const DeckState());
      expect(container.read(deckProvider).masterDeck, isEmpty);
    });

    test('InventoryController.hydrate replaces the state wholesale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(inventoryProvider.notifier);

      controller.hydrate(const InventoryState(gold: 999));
      expect(container.read(inventoryProvider).gold, 999);
    });

    test('SkillController.hydrate replaces the state wholesale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(skillProvider.notifier);

      controller.hydrate(const SkillState(skill1Cooldown: 3));
      expect(container.read(skillProvider).skill1Cooldown, 3);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/notifier_hydrate_test.dart`
Expected: FAIL — `The method 'hydrate' isn't defined for the class 'RunController'` (and similarly for the other 3 controllers)

- [ ] **Step 3: Add `hydrate` to `RunController`**

```dart
// lib/game/controllers/run_controller.dart
// Add inside class RunController, right after updateState():
  /// Remplace intégralement l'état par une sauvegarde chargée
  void hydrate(RunState savedState) {
    state = savedState;
  }
```

- [ ] **Step 4: Add `hydrate` to `DeckNotifier`**

```dart
// lib/game/controllers/deck_controller.dart
// Add inside class DeckNotifier, right after clearDeck():
  /// Remplace intégralement l'état par une sauvegarde chargée
  void hydrate(DeckState savedState) {
    state = savedState;
  }
```

- [ ] **Step 5: Add `hydrate` to `InventoryController`**

```dart
// lib/game/controllers/inventory_controller.dart
// Add inside class InventoryController, right after the build() method:
  /// Remplace intégralement l'état par une sauvegarde chargée
  void hydrate(InventoryState savedState) {
    state = savedState;
  }
```

- [ ] **Step 6: Add `hydrate` to `SkillController`**

```dart
// lib/game/controllers/skill_controller.dart
// Add inside class SkillController, right after the build() method:
  /// Remplace intégralement l'état par une sauvegarde chargée
  void hydrate(SkillState savedState) {
    state = savedState;
  }
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test test/unit/notifier_hydrate_test.dart`
Expected: PASS

- [ ] **Step 8: Run static analysis**

Run: `dart analyze lib/game/controllers`
Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add lib/game/controllers/run_controller.dart lib/game/controllers/deck_controller.dart lib/game/controllers/inventory_controller.dart lib/game/controllers/skill_controller.dart test/unit/notifier_hydrate_test.dart
git commit -m "feat(save): add hydrate() to Run/Deck/Inventory/Skill notifiers"
```

---

### Task 7: `SaveService`

**Files:**
- Create: `lib/services/save_service.dart`
- Test: `test/unit/save_service_test.dart`

**Interfaces:**
- Consumes: `runProvider`/`RunController.hydrate` (Task 6), `deckProvider`/`DeckNotifier.hydrate` (Task 6), `inventoryProvider`/`InventoryController.hydrate` (Task 6), `skillProvider`/`SkillController.hydrate` (Task 6), `RunState.toJson`/`fromJsonWithReport` (Task 5), `DeckState.toJson`/`fromJsonWithReport` (Task 4), `InventoryState.toJson`/`fromJsonWithReport` (Task 3), `SkillState.toJson`/`fromJson` (Task 2), `MissingSaveItem` (Task 1).
- Produces: `RefReader` typedef (`T Function<T>(ProviderListenable<T> provider)`), `SaveLoadResult({success, missingItems})`, `SaveService.save(RefReader) -> Future<void>`, `SaveService.load(RefReader) -> Future<SaveLoadResult>`, `SaveService.clear() -> Future<void>`, `SaveService.hasSave() -> Future<bool>`. Every call site passes a `.read` tear-off (`ref.read`, `container.read`), never a `Ref`/`WidgetRef` object itself. Consumed by Task 8 (autosave orchestrator), Task 9 (clear on death), Task 10 (HomeScreen).

- [ ] **Step 1: Write the failing round-trip test**

```dart
// test/unit/save_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/services/save_service.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/skill_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  group('SaveService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('hasSave is false before any save exists', () async {
      expect(await SaveService.hasSave(), isFalse);
    });

    test('save then load round-trips run/inventory/skill state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const dummyHero = HeroData(
        id: 'paladin',
        nameEn: 'Paladin',
        nameFr: 'Paladin',
        descriptionEn: 'A holy knight',
        descriptionFr: 'Un saint chevalier',
        iconPath: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        baseDamage: 5,
        luck: 0,
        armorMastery: 0,
        passiveTrait: 'regenArmor',
      );
      container.read(runProvider.notifier).startNewRun(dummyHero);
      container.read(inventoryProvider.notifier).gainGold(37);
      container.read(skillProvider.notifier).triggerSkill1(2);

      await SaveService.save(container.read);
      expect(await SaveService.hasSave(), isTrue);

      final freshContainer = ProviderContainer();
      addTearDown(freshContainer.dispose);
      final result = await SaveService.load(freshContainer.read);

      expect(result.success, isTrue);
      expect(result.missingItems, isEmpty);
      expect(freshContainer.read(runProvider).heroClassId, 'paladin');
      expect(freshContainer.read(inventoryProvider).gold, 87); // 50 starting + 37
      expect(freshContainer.read(skillProvider).skill1Cooldown, 2);
    });

    test('clear removes the save', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await SaveService.save(container.read);
      expect(await SaveService.hasSave(), isTrue);

      await SaveService.clear();
      expect(await SaveService.hasSave(), isFalse);
    });

    test('load returns a failed result and clears storage on corrupted JSON', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('run_save_v1', 'not valid json {{{');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = await SaveService.load(container.read);

      expect(result.success, isFalse);
      expect(await SaveService.hasSave(), isFalse);
    });

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
  });
}
```

Note: `SaveService.save`/`load` only ever call `.read(...)` on what they receive — never `.watch`/`.listen`/anything else — so they are typed to accept a bare `RefReader` function (defined below as `typedef RefReader = T Function<T>(ProviderListenable<T> provider);`), not a `Ref` object. `Ref.read`, `WidgetRef.read`, and `ProviderContainer.read` all share this exact generic signature in riverpod 2.6.1, so a plain method tear-off (`ref.read`, `container.read`) satisfies it from every call site — inside a `Provider`/`Notifier` (which has a real `Ref`), inside a widget (which has a `WidgetRef`, a distinct type that does NOT implement `Ref`), and inside a test (a bare `ProviderContainer`, which also does not implement `Ref`). Passing an actual `Ref`-typed object here would not compile in a `ConsumerState` (its `ref` is `WidgetRef`) or in a plain unit test (a `ProviderContainer`), so every production call site below passes `ref.read` (or `container.read` in tests), never `ref` itself.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/save_service_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:roguelike_card_game/services/save_service.dart'`

- [ ] **Step 3: Create `SaveService`**

```dart
// lib/services/save_service.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/controllers/run_controller.dart';
import '../game/controllers/deck_controller.dart';
import '../game/controllers/inventory_controller.dart';
import '../game/controllers/skill_controller.dart';
import '../models/inventory_state.dart';
import '../models/skill_state.dart';
import '../models/missing_save_item.dart';

/// The subset of Ref/WidgetRef/ProviderContainer that SaveService needs:
/// a plain synchronous provider read. Accepting this instead of `Ref`
/// lets the same code run from a Notifier's `ref`, a widget's `WidgetRef`,
/// and a bare `ProviderContainer` in tests — none of which share a common
/// supertype in riverpod 2.6.1, but all of which expose this exact method.
typedef RefReader = T Function<T>(ProviderListenable<T> provider);

class SaveLoadResult {
  final bool success;
  final List<MissingSaveItem> missingItems;

  const SaveLoadResult({required this.success, this.missingItems = const []});
}

class SaveService {
  static const String _saveKey = 'run_save_v1';
  static const int _schemaVersion = 1;

  static Future<void> save(RefReader read) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'schemaVersion': _schemaVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'run': read(runProvider).toJson(),
      'deck': read(deckProvider).toJson(),
      'inventory': read(inventoryProvider).toJson(),
      'skills': read(skillProvider).toJson(),
    };
    await prefs.setString(_saveKey, jsonEncode(payload));
  }

  static Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_saveKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }

  static Future<SaveLoadResult> load(RefReader read) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null) {
      return const SaveLoadResult(success: false);
    }

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> ||
          decoded['schemaVersion'] != _schemaVersion) {
        throw const FormatException('Unsupported or missing schemaVersion');
      }
      json = decoded;
    } catch (_) {
      await clear();
      return const SaveLoadResult(success: false);
    }

    try {
      final skills = SkillState.fromJson(json['skills'] as Map<String, dynamic>);
      final (inventory, invMissing) = InventoryState.fromJsonWithReport(
        json['inventory'] as Map<String, dynamic>,
      );
      final (deck, deckMissing) = DeckState.fromJsonWithReport(
        json['deck'] as Map<String, dynamic>,
      );
      final (run, runMissing) = RunState.fromJsonWithReport(
        json['run'] as Map<String, dynamic>,
      );

      read(skillProvider.notifier).hydrate(skills);
      read(inventoryProvider.notifier).hydrate(inventory);
      read(deckProvider.notifier).hydrate(deck);
      read(runProvider.notifier).hydrate(run);

      return SaveLoadResult(
        success: true,
        missingItems: [...invMissing, ...deckMissing, ...runMissing],
      );
    } catch (_) {
      await clear();
      return const SaveLoadResult(success: false);
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/save_service_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Run static analysis**

Run: `dart analyze lib/services/save_service.dart`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/services/save_service.dart test/unit/save_service_test.dart
git commit -m "feat(save): add SaveService (save/load/clear/hasSave)"
```

---

### Task 8: Checkpoint autosave wiring

**Files:**
- Create: `lib/game/controllers/checkpoint_controller.dart`
- Modify: `lib/game/controllers/run/map_progression_manager.dart`
- Modify: `lib/game/controllers/run/player_stats_manager.dart`
- Modify: `lib/game/controllers/run/run_persistence_manager.dart`
- Modify: `lib/main.dart`
- Test: `test/unit/checkpoint_autosave_test.dart`

**Interfaces:**
- Consumes: `SaveService.save(RefReader)` (Task 7) — called as `SaveService.save(ref.read)`.
- Produces: `checkpointProvider` (`NotifierProvider<CheckpointNotifier, int>`) with `.bump()`, `autosaveOrchestratorProvider` (`Provider<void>`). No later task consumes these directly — they are the terminal wiring for the autosave feature.

- [ ] **Step 1: Write the failing test for the orchestrator**

```dart
// test/unit/checkpoint_autosave_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/services/save_service.dart';

void main() {
  group('Checkpoint autosave', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('bump() triggers exactly one save', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Force the orchestrator to start listening.
      container.read(autosaveOrchestratorProvider);

      expect(await SaveService.hasSave(), isFalse);

      container.read(checkpointProvider.notifier).bump();
      // Allow the async SaveService.save() Future kicked off by the listener to complete.
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isTrue);
    });

    test('two bumps still result in a single valid save (no crash on rapid succession)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(autosaveOrchestratorProvider);

      container.read(checkpointProvider.notifier).bump();
      container.read(checkpointProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/checkpoint_autosave_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart'`

- [ ] **Step 3: Create `checkpointProvider` and `autosaveOrchestratorProvider`**

```dart
// lib/game/controllers/checkpoint_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/save_service.dart';

class CheckpointNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Signale qu'un nœud de la carte vient d'être résolu (combat, boutique,
  /// repos, event, forge, échange de reliques, ou draft de Level Up).
  void bump() => state = state + 1;
}

final checkpointProvider =
    NotifierProvider<CheckpointNotifier, int>(CheckpointNotifier.new);

/// Écoute checkpointProvider et déclenche une sauvegarde à chaque bump().
/// Doit être lu une fois au démarrage de l'app pour s'activer (voir main.dart).
final autosaveOrchestratorProvider = Provider<void>((ref) {
  ref.listen<int>(checkpointProvider, (previous, next) {
    SaveService.save(ref.read);
  });
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/checkpoint_autosave_test.dart`
Expected: PASS

- [ ] **Step 5: Wire `bump()` into `MapProgressionManager.completeCurrentNode()`**

```dart
// lib/game/controllers/run/map_progression_manager.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/map_node.dart';
import '../../../services/map_generator_service.dart';
import '../run_controller.dart';
import '../skill_controller.dart';
import '../checkpoint_controller.dart';

class MapProgressionManager {
  final RunController controller;
  final Ref ref;

  MapProgressionManager(this.controller, this.ref);

  /// Sélectionne un nœud sur la carte et déplace le joueur
  void travelToNode(String nodeId) {
    controller.updateState(
      controller.currentState.copyWith(currentNodeId: nodeId),
    );
  }

  /// Marque le nœud actuel comme complété
  void completeCurrentNode() {
    if (controller.currentState.currentNodeId == null) return;

    MapNode? completedNode;
    final updatedNodes = controller.currentState.mapNodes.map((node) {
      if (node.id == controller.currentState.currentNodeId) {
        node.isCompleted = true;
        completedNode = node;
      }
      return node;
    }).toList();

    // Reset de l'armure et nettoyage des statuts à la fin du combat pour préserver les passifs
    controller.updateState(
      controller.currentState.copyWith(
        mapNodes: updatedNodes,
        heroStats: controller.currentState.heroStats.copyWith(armure: 0, statuses: []),
      ),
    );

    if (completedNode != null && completedNode!.type == MapNodeType.boss) {
      advanceToNextWorld();
    }

    ref.read(checkpointProvider.notifier).bump();
  }

  void advanceToNextWorld() {
    final nextAct = controller.currentState.act + 1;
    final newMap = MapGeneratorService.generateMap(act: nextAct);
    controller.updateState(
      controller.currentState.copyWith(
        mapNodes: newMap,
        act: nextAct,
        resetCurrentNode: true, // Reset la position pour le nouveau monde
      ),
    );
  }

  /// Avance d'un niveau (après avoir drafté)
  void nextLevel() {
    final currentStats = controller.currentState.heroStats;
    controller.updateState(
      controller.currentState.copyWith(
        currentLevel: controller.currentState.currentLevel + 1,
        heroStats: currentStats.copyWith(currentMana: currentStats.maxMana),
      ),
    );
    // Réinitialise les cooldowns à chaque nouveau niveau
    ref.read(skillProvider.notifier).resetCooldowns();
  }
}
```

- [ ] **Step 6: Wire `bump()` into `PlayerStatsManager.decrementPendingDrafts()`**

```dart
// lib/game/controllers/run/player_stats_manager.dart
// Add import alongside the existing ones at the top of the file:
import '../checkpoint_controller.dart';

// Replace the existing decrementPendingDrafts() method with:
  void decrementPendingDrafts() {
    if (controller.currentState.pendingDrafts > 0) {
      controller.updateState(
        controller.currentState.copyWith(
          pendingDrafts: controller.currentState.pendingDrafts - 1,
        ),
      );
      ref.read(checkpointProvider.notifier).bump();
    }
  }
```

- [ ] **Step 7: Implement the `RunPersistenceManager` stub as a thin delegate**

```dart
// lib/game/controllers/run/run_persistence_manager.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/save_service.dart';
import '../run_controller.dart';

class RunPersistenceManager {
  final RunController controller;
  final Ref ref;

  RunPersistenceManager(this.controller, this.ref);

  /// Sauvegarde manuelle immédiate de la run en cours
  Future<void> saveRun() => SaveService.save(ref.read);

  /// Charge la sauvegarde existante, le cas échéant
  Future<SaveLoadResult> loadRun() => SaveService.load(ref.read);

  /// Supprime la sauvegarde en cours (mort du héros)
  Future<void> clearSavedRun() => SaveService.clear();
}
```

- [ ] **Step 8: Activate the orchestrator at app startup**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/widgets/notification_overlay.dart';
import 'game/controllers/checkpoint_controller.dart';

import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HerosDraftApp()));
}

class HerosDraftApp extends ConsumerWidget {
  const HerosDraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force l'activation de l'écoute d'autosave dès le démarrage de l'app.
    ref.watch(autosaveOrchestratorProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.darkNeonTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      home: const SplashScreen(),
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const GameNotificationOverlay(),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 9: Run the full test suite**

Run: `flutter test`
Expected: All tests PASS (no regressions in existing `run_controller_test.dart`, `map_screen_test.dart`, etc. from the `MapProgressionManager`/`PlayerStatsManager` edits)

- [ ] **Step 10: Run static analysis on the whole project**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 11: Commit**

```bash
git add lib/game/controllers/checkpoint_controller.dart lib/game/controllers/run/map_progression_manager.dart lib/game/controllers/run/player_stats_manager.dart lib/game/controllers/run/run_persistence_manager.dart lib/main.dart test/unit/checkpoint_autosave_test.dart
git commit -m "feat(save): autosave at every map checkpoint (node completion, level-up draft)"
```

---

### Task 9: Clear the save on death

**Files:**
- Modify: `lib/ui/screens/game_screen.dart`

**Interfaces:**
- Consumes: `SaveService.clear()` (Task 7, already unit-tested).
- Produces: nothing new consumed by later tasks.

No new automated test for this task: it wires two existing button handlers to an already-unit-tested `SaveService.clear()` call, with no new branching logic to verify in isolation. Regression safety comes from the full suite (Step 3) and from CLAUDE.md's manual-verification requirement (Step 4).

- [ ] **Step 1: Add the `SaveService` import**

```dart
// lib/ui/screens/game_screen.dart
// Add alongside the existing imports at the top of the file:
import '../../services/save_service.dart';
```

- [ ] **Step 2: Clear the save from both death-screen buttons**

```dart
// lib/ui/screens/game_screen.dart
// Replace this existing onPressed (the "Menu Principal" button):
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                      ).popUntil((route) => route.isFirst);
                                    },
                                    child: Text(l10n.mainMenu),
```

with:

```dart
                                    onPressed: () async {
                                      await SaveService.clear();
                                      if (!context.mounted) return;
                                      Navigator.of(
                                        context,
                                      ).popUntil((route) => route.isFirst);
                                    },
                                    child: Text(l10n.mainMenu),
```

```dart
// And replace this existing onPressed (the "Changer de Classe" button):
                                    onPressed: () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ClassSelectionScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(l10n.changeClass),
```

with:

```dart
                                    onPressed: () async {
                                      await SaveService.clear();
                                      if (!context.mounted) return;
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ClassSelectionScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(l10n.changeClass),
```

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: All tests PASS (no existing test exercises this exact button, so no regressions expected; this step guards against a typo breaking compilation)

- [ ] **Step 4: Run static analysis**

Run: `dart analyze lib/ui/screens/game_screen.dart`
Expected: `No issues found!`

- [ ] **Step 5: Manual verification (per CLAUDE.md UI-change policy)**

Run: `flutter run` (desktop or an emulator), play until the hero dies in combat, confirm the death overlay's two buttons still navigate correctly, then relaunch the app and confirm the "Continuer" button from Task 10 no longer appears on `HomeScreen` (i.e. the save was actually cleared).

- [ ] **Step 6: Commit**

```bash
git add lib/ui/screens/game_screen.dart
git commit -m "feat(save): clear the save when the run ends in death"
```

---

### Task 10: `HomeScreen` — Continuer / Nouvelle Partie / avertissement contenu manquant

**Files:**
- Modify: `lib/ui/screens/home_screen.dart`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`
- Test: `test/widget/home_screen_save_test.dart`

**Interfaces:**
- Consumes: `SaveService.hasSave()`, `SaveService.load(RefReader)`, `SaveService.clear()` (Task 7) — `load` is called as `SaveService.load(ref.read)` since `HomeScreen`'s `ref` is a `WidgetRef`, `MapScreen` (existing, `lib/ui/screens/map_screen.dart`), `ClassSelectionScreen` (existing).
- Produces: nothing consumed by later tasks (final UI task).

- [ ] **Step 1: Add the new localization keys (French)**

```json
// lib/l10n/app_fr.arb
// Insert these new keys right after the existing "cancel": "Annuler", line:
  "cancel": "Annuler",
  "continueGame": "Continuer",
  "newGameOverwriteTitle": "Nouvelle Partie",
  "newGameOverwriteMessage": "Une partie est en cours. La démarrer effacera définitivement votre progression actuelle. Continuer ?",
  "newGameOverwriteConfirm": "Écraser et continuer",
  "missingItemsTitle": "Sauvegarde restaurée",
  "missingItemsMessage": "Certains éléments ne sont plus disponibles suite à une mise à jour et ont été retirés : {items}. Votre progression a été conservée.",
  "ok": "OK",
```

- [ ] **Step 2: Add the new localization keys (English)**

```json
// lib/l10n/app_en.arb
// Insert these new keys right after the existing "mainMenu"/"changeClass" block, near "cancel" (search for the line "changeClass": "Change Class",):
  "cancel": "Cancel",
  "continueGame": "Continue",
  "newGameOverwriteTitle": "New Game",
  "newGameOverwriteMessage": "A game is currently in progress. Starting a new one will permanently erase your current progress. Continue?",
  "newGameOverwriteConfirm": "Overwrite and continue",
  "missingItemsTitle": "Save restored",
  "missingItemsMessage": "Some items are no longer available due to an update and have been removed: {items}. Your progress has been kept.",
  "ok": "OK",
```

Note: check `app_en.arb` for an existing `"cancel"` key first (mirroring the exact line found in `app_fr.arb:136`) before inserting — add it only if missing, to avoid a duplicate-key analyzer error.

- [ ] **Step 3: Run `flutter test` once to confirm ARB codegen succeeds**

Run: `flutter test test/unit/save_catalog_lookups_test.dart`
Expected: PASS — this indirectly forces `flutter gen-l10n` (triggered by `generate: true` in `pubspec.yaml`) to regenerate `AppLocalizations` with the new keys; a JSON syntax error in the ARB files would fail the whole test run with a codegen error instead of a normal test failure.

- [ ] **Step 4: Write the failing widget test**

```dart
// test/widget/home_screen_save_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/home_screen.dart';
import 'package:roguelike_card_game/services/save_service.dart';

Widget wrapHome() {
  final container = ProviderContainer();
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      home: const HomeScreen(),
    ),
  );
}

void main() {
  group('HomeScreen save/continue', () {
    testWidgets('CONTINUER is hidden when no save exists', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      expect(find.text('Continuer'), findsNothing);
    });

    testWidgets('CONTINUER appears when a save exists', (tester) async {
      SharedPreferences.setMockInitialValues({
        'run_save_v1': '{"schemaVersion":1,"run":{},"deck":{},"inventory":{},"skills":{}}',
      });
      // Seed a syntactically valid but minimal save purely to make hasSave() true;
      // the "Continuer" tap flow itself is exercised in SaveService's own unit tests.

      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      expect(find.text('Continuer'), findsOneWidget);
    });

    testWidgets('Nouvelle Partie shows a confirmation dialog when a save exists', (tester) async {
      SharedPreferences.setMockInitialValues({
        'run_save_v1': '{"schemaVersion":1,"run":{},"deck":{},"inventory":{},"skills":{}}',
      });

      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      await tester.tap(find.text('JOUER'));
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle Partie'), findsOneWidget);

      // Cancel so the test does not need to also stub ClassSelectionScreen navigation.
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(await SaveService.hasSave(), isTrue);
    });
  });
}
```

- [ ] **Step 5: Run test to verify it fails**

Run: `flutter test test/widget/home_screen_save_test.dart`
Expected: FAIL — `find.text('Continuer')` never appears since `HomeScreen` has no such button yet

- [ ] **Step 6: Update `HomeScreen`**

```dart
// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'class_selection_screen.dart';
import 'card_dictionary_screen.dart';
import 'patch_notes_screen.dart';
import 'map_screen.dart';
import '../../tutorial/tutorial_screen.dart';
import '../../tutorial/tutorial_progress_service.dart';
import '../../services/save_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _continueGame() async {
    final result = await SaveService.load(ref.read);
    if (!mounted) return;

    if (!result.success) {
      // The save was corrupted or unreadable; SaveService.load already
      // cleared it internally, so simply refresh this screen — the
      // "Continuer" button will disappear on rebuild.
      setState(() {});
      return;
    }

    if (result.missingItems.isNotEmpty) {
      final locale = Localizations.localeOf(context).languageCode;
      final names = result.missingItems
          .map((m) => locale == 'fr' ? m.nameFr : m.nameEn)
          .join(', ');
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.missingItemsTitle),
          content: Text(AppLocalizations.of(context)!.missingItemsMessage(names)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  Future<void> _startNewGame(bool hasSave) async {
    if (hasSave) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.newGameOverwriteTitle),
          content: Text(AppLocalizations.of(context)!.newGameOverwriteMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppLocalizations.of(context)!.newGameOverwriteConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await SaveService.clear();
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ClassSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "HERO'S DRAFT",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Roguelike Deckbuilder MVP",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 60),
            FutureBuilder<bool>(
              future: SaveService.hasSave(),
              builder: (context, snapshot) {
                final hasSave = snapshot.data ?? false;
                return Column(
                  children: [
                    if (hasSave)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 60,
                              vertical: 20,
                            ),
                            backgroundColor: Colors.green,
                            textStyle: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _continueGame,
                          child: Text(
                            AppLocalizations.of(context)!.continueGame,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 20,
                        ),
                        backgroundColor: Colors.blueAccent,
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _startNewGame(hasSave),
                      child: const Text(
                        'JOUER',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            FutureBuilder<bool>(
              future: TutorialProgressService.hasCompletedTutorial(),
              builder: (context, snapshot) {
                final isCompleted = snapshot.data ?? false;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        side: const BorderSide(color: Colors.white70, width: 2),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TutorialScreen(),
                          ),
                        );
                        // Refresh the UI to update the 'NEW' badge state
                        setState(() {});
                      },
                      child: const Text(
                        'TUTORIEL',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                    if (!isCompleted)
                      Positioned(
                        right: -10,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                side: const BorderSide(color: Colors.white70, width: 2),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CardDictionaryScreen(),
                  ),
                );
              },
              child: const Text(
                'DICTIONNAIRE',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                side: const BorderSide(
                  color: Colors.amberAccent,
                  width: 1.5,
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PatchNotesScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.article_outlined,
                    color: Colors.amberAccent,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'PATCH NOTES',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Run test to verify it passes**

Run: `flutter test test/widget/home_screen_save_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 8: Run the full test suite**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 9: Run static analysis on the whole project**

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 10: Manual verification (per CLAUDE.md UI-change policy)**

Run: `flutter run`. Start a run, play until at least one node is resolved (e.g. win a combat), fully close and relaunch the app, confirm "Continuer" appears on `HomeScreen` and correctly resumes on `MapScreen` with gold/deck/relics intact. Then tap "JOUER" and confirm the overwrite dialog appears and "Annuler" leaves the save untouched.

- [ ] **Step 11: Commit**

```bash
git add lib/ui/screens/home_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb test/widget/home_screen_save_test.dart
git commit -m "feat(save): add Continuer/Nouvelle Partie flow with missing-content warning to HomeScreen"
```
