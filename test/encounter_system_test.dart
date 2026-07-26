import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/systems/encounter_system.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';

void main() {
  group('EncounterSystem & Wave Reserve Tests', () {
    const slimeData = EnemyData(
      id: 'slime',
      nameEn: 'Slime',
      maxHp: 18,
      baseDamage: 4,
      spritePath: 'slime.png',
      tier: 1,
      critChance: 5,
    );

    const goblinData = EnemyData(
      id: 'goblin',
      nameEn: 'Goblin',
      maxHp: 28,
      baseDamage: 5,
      spritePath: 'goblin.png',
      tier: 1,
      critChance: 10,
    );

    const squeletteData = EnemyData(
      id: 'squelette',
      nameEn: 'Skeleton',
      maxHp: 22,
      baseDamage: 8,
      spritePath: 'skeleton.png',
      tier: 2,
      critChance: 10,
    );

    final paladinHero = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      iconPath: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      luck: 0,
      armorMastery: 0,
      passiveTrait: 'regenArmor',
    );

    test('calculateCombatRating computes threat score correctly', () {
      // Test rating for simple standard slime at level 1, act 1
      // Enemy Level: playerLevel 1 + (act 1 - 1) * 2 + nodeModifier 0 = 1
      // hpMultiplier = (1.0 + 0.06 * 0) * (1.0 + 0.20 * 0) * 1.0 = 1.0
      // damageMultiplier = (1.0 + 0.04 * 0) * (1.0 + 0.15 * 0) * 1.0 = 1.0
      // hpScale = 18 * 1.0 = 18
      // damageScale = 4 * 1.0 = 4
      // Rating = (tier 1 * 15.0) + (18 / 4.0) + 0 + (4 * 2.0) * (1.0 + 5 / 100) = 15 + 4.5 + 8.4 = 27.9
      final rating = EncounterSystem.calculateCombatRating(
        data: slimeData,
        enemyLevel: 1,
        act: 1,
        isBoss: false,
        isElite: false,
      );
      expect(rating, closeTo(27.9, 0.01));
    });

    test('generateEnemiesForLevel respects budget strictly', () {
      // Given player stats:
      // PlayerPower = 100 + (0 * 10) + (3 * 15) + (0 * 5) = 145
      // ExpectedPower = 145 + (0 * 15) + (0 * 20) = 145
      // BaseBudget = 40 + (0 * 10) + (0 * 25) = 40
      // PowerRatio = 145 / 145 = 1.0
      // PowerModifier = 1.0
      // FinalBudget = 40 * 1.0 * 1.0 = 40
      
      final enemies = EncounterSystem.generateEnemiesForLevel(
        1, // level
        [slimeData, goblinData, squeletteData],
        nodeType: MapNodeType.combat,
        playerLevel: 1,
        act: 1,
        playerMaxHp: 100,
        playerAttaque: 0,
        playerMaxMana: 3,
        playerRelicsCount: 0,
      );

      // Verify that the sum of ratings of all generated enemies is <= 40
      double totalRating = 0;
      for (var enemy in enemies) {
        totalRating += EncounterSystem.calculateCombatRating(
          data: enemy,
          enemyLevel: 1,
          act: 1,
          isBoss: false,
          isElite: false,
        );
      }
      expect(totalRating, lessThanOrEqualTo(40.0));
      expect(enemies, isNotEmpty);
    });

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

    test('generateEnemiesForLevel caps normal-combat enemy count at act 3 (tracks the per-act formula, not just act 1)', () {
      final enemies = EncounterSystem.generateEnemiesForLevel(
        1,
        List.generate(20, (index) => slimeData),
        nodeType: MapNodeType.combat,
        playerLevel: 1,
        act: 3,
        playerMaxHp: 500,
        playerAttaque: 20,
        playerMaxMana: 10,
        playerRelicsCount: 10,
        playerCardsCount: 20,
      );
      expect(enemies.length, EncounterSystem.getMaxEnemiesForNormalCombat(3));
      expect(enemies.length, 3);
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

    test('isBoss calculation logic in generateEnemiesForLevel and CombatController', () {
      final container = ProviderContainer();
      final combatController = container.read(combatProvider.notifier);

      // Case 1: Node type is combat, level is 10 (multiple of 10)
      // Since node type is explicitly MapNodeType.combat, isBoss should be false.
      combatController.initializeCombat(
        10,
        MapNodeType.combat,
        [slimeData],
        playerLevel: 1,
        act: 1,
        playerMaxHp: 100,
        playerAttaque: 0,
        playerMaxMana: 3,
        playerRelicsCount: 0,
      );
      expect(combatController.currentState.enemies.isNotEmpty, isTrue);
      expect(combatController.currentState.enemies.every((e) => e.isBoss), isFalse);

      // Case 2: Node type is null, level is 10 (multiple of 10)
      // Since node type is null and level is 10, isBoss should be true.
      combatController.initializeCombat(
        10,
        null,
        [slimeData],
        playerLevel: 1,
        act: 1,
        playerMaxHp: 100,
        playerAttaque: 0,
        playerMaxMana: 3,
        playerRelicsCount: 0,
      );
      expect(combatController.currentState.enemies.isNotEmpty, isTrue);
      expect(combatController.currentState.enemies.every((e) => e.isBoss), isTrue);

      // Case 3: Node type is boss, level is 9 (not multiple of 10)
      // Since node type is MapNodeType.boss, isBoss should be true.
      combatController.initializeCombat(
        9,
        MapNodeType.boss,
        [slimeData],
        playerLevel: 1,
        act: 1,
        playerMaxHp: 100,
        playerAttaque: 0,
        playerMaxMana: 3,
        playerRelicsCount: 0,
      );
      expect(combatController.currentState.enemies.isNotEmpty, isTrue);
      expect(combatController.currentState.enemies.every((e) => e.isBoss), isTrue);
    });


    test('CombatController splits active and pending reserve enemies (wave reserve)', () {
      final container = ProviderContainer();
      final combatController = container.read(combatProvider.notifier);

      combatController.initializeCombat(
        1,
        MapNodeType.combat,
        List.generate(20, (index) => slimeData), // 20 slimes available
        playerLevel: 1,
        act: 1,
        playerMaxHp: 200,
        playerAttaque: 10,
        playerMaxMana: 5,
        playerRelicsCount: 5,
      );

      // Active enemies should be max 5
      expect(combatController.currentState.enemies.length, lessThanOrEqualTo(5));
      // Remaining generated enemies should be placed in pendingEnemies
      expect(combatController.currentState.enemies.length + combatController.currentState.pendingEnemies.length, greaterThan(0));
    });

    test('CombatController wave-reserve split still works when the new act-scaled cap allows more than 5 enemies', () {
      final container = ProviderContainer();
      final combatController = container.read(combatProvider.notifier);

      // At act 6, normal-combat cap is 6 (getMaxEnemiesForNormalCombat(6) == 6) —
      // with a big enough budget this should generate more than 5 enemies,
      // exercising the existing 5-active/reserve split with the new cap logic.
      combatController.initializeCombat(
        1,
        MapNodeType.combat,
        List.generate(20, (index) => slimeData),
        playerLevel: 1,
        act: 6,
        playerMaxHp: 500,
        playerAttaque: 20,
        playerMaxMana: 10,
        playerRelicsCount: 10,
        playerCardsCount: 20,
      );

      expect(combatController.currentState.enemies.length, lessThanOrEqualTo(5));
      expect(combatController.currentState.pendingEnemies, isNotEmpty);
    });

    test('Wave replenishment pulls from reserve when active enemies are defeated', () {
      final container = ProviderContainer();
      final combatController = container.read(combatProvider.notifier);
      final runController = container.read(runProvider.notifier);
      runController.startNewRun(paladinHero);

      final active1 = EnemyInstance(
        id: 'active_1',
        data: slimeData,
        stats: EntityStats(maxPv: 18, currentPv: 18, armure: 0, attaque: 4),
      );
      final active2 = EnemyInstance(
        id: 'active_2',
        data: slimeData,
        stats: EntityStats(maxPv: 18, currentPv: 18, armure: 0, attaque: 4),
      );
      final reserve1 = EnemyInstance(
        id: 'reserve_1',
        data: goblinData,
        stats: EntityStats(maxPv: 28, currentPv: 28, armure: 0, attaque: 5),
      );
      final reserve2 = EnemyInstance(
        id: 'reserve_2',
        data: goblinData,
        stats: EntityStats(maxPv: 28, currentPv: 28, armure: 0, attaque: 5),
      );

      combatController.state = CombatState(
        enemies: [active1, active2],
        pendingEnemies: [reserve1, reserve2],
        defeatedEnemies: const [],
        turnPhase: TurnPhase.player,
        isCombatEnded: false,
        isVictory: false,
      );

      // 1. Defeat active_1 (set its PV to 0)
      combatController.updateEnemyStats(
        'active_1',
        EntityStats(maxPv: 18, currentPv: 0, armure: 0, attaque: 4),
      );

      // Trigger cleanDeadEnemies by starting enemy turn
      combatController.startEnemyTurn();

      // Since active_1 was defeated, it should be in defeatedEnemies,
      // and reserve_1 (first in pending list) should be pulled into enemies!
      expect(combatController.currentState.enemies.any((e) => e.id == 'active_2'), isTrue);
      expect(combatController.currentState.enemies.any((e) => e.id == 'reserve_1'), isTrue);
      expect(combatController.currentState.enemies.any((e) => e.id == 'active_1'), isFalse);
      expect(combatController.currentState.enemies.length, 2);

      expect(combatController.currentState.pendingEnemies.length, 1);
      expect(combatController.currentState.pendingEnemies.first.id, 'reserve_2');

      expect(combatController.currentState.defeatedEnemies.length, 1);
      expect(combatController.currentState.defeatedEnemies.first.id, 'active_1');

      // The pulled enemy should have its initial intent rolled
      final pulledEnemy = combatController.currentState.enemies.firstWhere((e) => e.id == 'reserve_1');
      expect(pulledEnemy.currentIntent, isNotNull);

      // 2. Defeat both remaining enemies
      combatController.updateEnemyStats(
        'active_2',
        EntityStats(maxPv: 18, currentPv: 0, armure: 0, attaque: 4),
      );
      combatController.updateEnemyStats(
        'reserve_1',
        EntityStats(maxPv: 28, currentPv: 0, armure: 0, attaque: 5),
      );

      combatController.startEnemyTurn();

      // Both active_2 and reserve_1 died. Since reserve_2 is in pending,
      // reserve_2 should be pulled, and the combat should NOT be ended yet.
      expect(combatController.currentState.enemies.length, 1);
      expect(combatController.currentState.enemies.first.id, 'reserve_2');
      expect(combatController.currentState.pendingEnemies.isEmpty, isTrue);
      expect(combatController.currentState.isCombatEnded, isFalse);

      // 3. Defeat the last reserve enemy
      combatController.updateEnemyStats(
        'reserve_2',
        EntityStats(maxPv: 28, currentPv: 0, armure: 0, attaque: 5),
      );
      combatController.startEnemyTurn();

      // All enemies dead and no pending. Victory!
      expect(combatController.currentState.enemies.isEmpty, isTrue);
      expect(combatController.currentState.isCombatEnded, isTrue);
      expect(combatController.currentState.isVictory, isTrue);
    });
  });

  group('Act bracket factor & tier unlock helpers', () {
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

    test('calculateBudget includes playerCardsCount in playerPower and the (act-1)*10 bonus in finalBudget', () {
      final budget = EncounterSystem.calculateBudget(
        playerLevel: 3,
        act: 2,
        playerMaxHp: 100,
        playerAttaque: 0,
        playerMaxMana: 3,
        playerRelicsCount: 2,
        playerCardsCount: 10,
        isBoss: false,
        isElite: true,
      );

      // playerPower = 100 + (0*10) + (3*15) + (2*5) + (10*2) = 175
      expect(budget.playerPower, closeTo(175.0, 0.0001));
      // expectedPower = 145 + (3-1)*15 + (2-1)*20 = 195
      expect(budget.expectedPower, closeTo(195.0, 0.0001));
      // baseBudget = 40 + (3-1)*10 + (2-1)*25 = 85
      expect(budget.baseBudget, closeTo(85.0, 0.0001));
      // powerRatio = 175/195, powerModifier = 1 + (powerRatio-1)*0.5
      expect(budget.powerRatio, closeTo(175.0 / 195.0, 0.0001));
      expect(budget.powerModifier, closeTo(0.9487179487179488, 0.0001));
      expect(budget.nodeMultiplier, closeTo(1.5, 0.0001));
      // finalBudget = 85 * 0.9487179487179488 * 1.5 + (2-1)*10 = 130.9615384615385
      expect(budget.finalBudget, closeTo(130.9615384615385, 0.001));
    });

    test('calculateBudget matches the zero-cards, act-1 baseline used elsewhere', () {
      final budget = EncounterSystem.calculateBudget(
        playerLevel: 1,
        act: 1,
        playerMaxHp: 100,
        playerAttaque: 0,
        playerMaxMana: 3,
        playerRelicsCount: 0,
        playerCardsCount: 0,
        isBoss: false,
        isElite: false,
      );
      expect(budget.playerPower, closeTo(145.0, 0.0001));
      expect(budget.expectedPower, closeTo(145.0, 0.0001));
      expect(budget.baseBudget, closeTo(40.0, 0.0001));
      expect(budget.nodeMultiplier, closeTo(1.0, 0.0001));
      expect(budget.finalBudget, closeTo(40.0, 0.0001));
    });
  });
}
