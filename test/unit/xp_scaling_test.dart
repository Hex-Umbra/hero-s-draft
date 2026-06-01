import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  group('XP and Level Up Unit Tests', () {
    late ProviderContainer container;
    late RunController runController;

    final testHero = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Paladin',
      descriptionEn: 'Holy knight',
      descriptionFr: 'Chevalier sacre',
      iconPath: 'paladin.png',
      maxHp: 80,
      maxMana: 3,
      baseDamage: 5,
      luck: 1,
      armorMastery: 0,
    );

    setUp(() {
      container = ProviderContainer();
      runController = container.read(runProvider.notifier);
      runController.startNewRun(testHero);
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial stats set level 1 and 0 XP', () {
      final stats = runController.currentState.heroStats;
      expect(stats.level, 1);
      expect(stats.xp, 0);
      expect(stats.xpToNextLevel, 100);
    });

    test('gainXp adds XP and retains correct values without level up', () {
      final leveledUp = runController.gainXp(50);
      expect(leveledUp, isFalse);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 1);
      expect(stats.xp, 50);
      expect(stats.xpToNextLevel, 100);
    });

    test('gainXp triggers level up and calculates new threshold with carry-over', () {
      // Gain 120 XP -> should level up to 2 with 20 XP carry-over
      // Level 2 threshold is 100 * 1.5 = 150 XP
      final leveledUp = runController.gainXp(120);
      expect(leveledUp, isTrue);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 2);
      expect(stats.xp, 20);
      expect(stats.xpToNextLevel, 150);
    });

    test('gainXp handles multiple consecutive level ups from a single large XP yield', () {
      // Level 1 -> 2: needs 100 XP
      // Level 2 -> 3: needs 150 XP (Total 250 XP to reach Level 3)
      // Gain 280 XP -> should level up to 3 with 30 XP carry-over
      // Level 3 threshold is 100 * 1.5 * 1.5 = 225 XP
      final leveledUp = runController.gainXp(280);
      expect(leveledUp, isTrue);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 3);
      expect(stats.xp, 30);
      expect(stats.xpToNextLevel, 225);
    });
  });

  group('Enemy Level & Stats Scaling Unit Tests', () {
    final slimeData = const EnemyData(
      id: 'slime',
      maxHp: 20,
      baseDamage: 5,
      spritePath: 'slime.png',
      tier: 1,
      xp: 30,
    );

    test('Enemy level calculates correctly based on player level, act and node type', () {
      final combatController = CombatController();

      // Case 1: Player Lvl 1, Act 1, Normal Combat -> Enemy Lvl 1
      combatController.initializeCombat(
        1,
        MapNodeType.combat,
        [slimeData],
        playerLevel: 1,
        act: 1,
      );
      expect(combatController.currentState.enemies.first.stats.level, 1);
      expect(combatController.currentState.enemies.first.stats.maxPv, 20); // 20 * 1.0

      // Case 2: Player Lvl 2, Act 1, Elite Combat -> Enemy Lvl 3 (playerLvl 2 + actMod 0 + eliteMod 1)
      combatController.initializeCombat(
        1,
        MapNodeType.elite,
        [slimeData],
        playerLevel: 2,
        act: 1,
      );
      expect(combatController.currentState.enemies.first.stats.level, 3);
      // HP multiplier = (1.0 + 0.12 * (3-1)) * 1.5 = 1.24 * 1.5 = 1.86
      // maxPv = (20 * 1.86).round() = 37
      expect(combatController.currentState.enemies.first.stats.maxPv, 37);

      // Case 3: Player Lvl 3, Act 2, Boss Combat -> Enemy Lvl 7 (playerLvl 3 + actMod (2-1)*2=2 + bossMod 2)
      combatController.initializeCombat(
        1,
        MapNodeType.boss,
        [slimeData],
        playerLevel: 3,
        act: 2,
      );
      expect(combatController.currentState.enemies.first.stats.level, 7);
    });
  });
}
