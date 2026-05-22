import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  group('RunController & RunState Tests', () {
    test('RunState constructor sets default bonusShopCards to 0', () {
      final controller = RunController();
      expect(controller.state.bonusShopCards, 0);
    });

    test('buyShopExpansion increments bonusShopCards correctly', () {
      final controller = RunController();
      expect(controller.state.bonusShopCards, 0);

      controller.buyShopExpansion();
      expect(controller.state.bonusShopCards, 1);

      controller.buyShopExpansion();
      expect(controller.state.bonusShopCards, 2);
    });

    test('startNewRun resets bonusShopCards to 0', () {
      final controller = RunController();
      controller.buyShopExpansion();
      expect(controller.state.bonusShopCards, 1);

      const dummyHero = HeroData(
        id: 'paladin',
        name: 'Paladin',
        description: 'A holy knight',
        iconPath: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        baseDamage: 5,
        luck: 0,
        armorMastery: 0,
        passiveTrait: 'regenArmor',
      );

      controller.startNewRun(dummyHero);
      expect(controller.state.bonusShopCards, 0);
    });

    test('Berserker armor passive triggers at start of combat when player has missing HP and resets at end of combat', () {
      final controller = RunController();
      
      const berserkerHero = HeroData(
        id: 'berserker',
        name: 'Berserker',
        description: 'A raging warrior',
        iconPath: 'berserker.png',
        maxHp: 80,
        maxMana: 3,
        baseDamage: 6,
        luck: 0,
        armorMastery: 1,
        passiveTrait: 'berserkerArmor',
      );

      controller.startNewRun(berserkerHero);
      
      // Set missing HP: 80 max HP, set current to 60 (20 missing HP)
      controller.setHeroStats(currentPv: 60, armure: 0);
      
      // Travel to a node to have currentNodeId set
      controller.travelToNode('node_1');
      
      // At the start of combat, the passive should trigger:
      // Missing HP = 20. Gain = 20 ~/ 10 = 2 armor.
      // Total gain = 2 + armorMastery (1) = 3 armor.
      controller.startCombat();
      
      expect(controller.state.heroStats.armure, 3);
      
      // When the node is completed, armor should reset to 0
      controller.completeCurrentNode();
      expect(controller.state.heroStats.armure, 0);
    });
  });
}
