import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/combat_debug_logger.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/map_node.dart';

void main() {
  group('CombatDebugLogger Unit Tests', () {
    test('logCombatInitialization executes without errors', () {
      final mockEnemy = EnemyData(
        id: 'test_enemy',
        nameEn: 'Test Enemy',
        nameFr: 'Ennemi Test',
        maxHp: 50,
        baseDamage: 10,
        spritePath: 'enemy.png',
        tier: 1,
      );

      expect(() {
        CombatDebugLogger.logCombatInitialization(
          playerLevel: 1,
          act: 1,
          nodeType: MapNodeType.combat,
          playerMaxHp: 100,
          playerAttaque: 5,
          playerMaxMana: 3,
          playerRelicsCount: 2,
          playerCardsCount: 5,
          playerPower: 175.0,
          expectedPower: 145.0,
          baseBudget: 40.0,
          powerRatio: 1.2,
          powerModifier: 1.1,
          nodeMultiplier: 1.0,
          finalBudget: 44.0,
          enemyLevel: 1,
          hpMultiplier: 1.0,
          damageMultiplier: 1.0,
          maxEnemies: 1,
          enemyDataList: [mockEnemy],
          isBoss: false,
          isElite: false,
        );
      }, returnsNormally);
    });

    test('logCombatInitialization executes with null nodeType without errors', () {
      expect(() {
        CombatDebugLogger.logCombatInitialization(
          playerLevel: 1,
          act: 1,
          nodeType: null,
          playerMaxHp: 100,
          playerAttaque: 0,
          playerMaxMana: 3,
          playerRelicsCount: 0,
          playerCardsCount: 0,
          playerPower: 145.0,
          expectedPower: 145.0,
          baseBudget: 40.0,
          powerRatio: 1.0,
          powerModifier: 1.0,
          nodeMultiplier: 1.0,
          finalBudget: 40.0,
          enemyLevel: 1,
          hpMultiplier: 1.0,
          damageMultiplier: 1.0,
          maxEnemies: 1,
          enemyDataList: const [],
          isBoss: false,
          isElite: false,
        );
      }, returnsNormally);
    });
  });
}
