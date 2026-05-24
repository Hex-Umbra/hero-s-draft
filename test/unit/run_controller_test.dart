import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

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

    test('Relic system: addRelic, startOfRun effect, trigger application and stacking', () {
      final controller = RunController();
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

      // 1. startOfRun trigger is applied immediately
      const luckyClover = RelicData(
        id: 'lucky_clover',
        name: 'Trèfle Enchanté',
        description: '+1 Chance',
        trigger: RelicTrigger.startOfRun,
        effectType: 'gain_luck',
        value: 1,
        rarity: RelicRarity.epic,
        emoji: '🍀',
      );

      expect(controller.state.heroStats.luck, 0);
      controller.addRelic(luckyClover);
      expect(controller.state.heroStats.luck, 1);
      expect(controller.state.relics.length, 1);

      // Stacking lucky clover gives +1 luck again
      controller.addRelic(luckyClover);
      expect(controller.state.heroStats.luck, 2);
      expect(controller.state.relics.length, 2);

      // 2. Combat triggers and stacking
      const talisman = RelicData(
        id: 'iron_talisman',
        name: 'Talisman de Fer',
        description: 'Gagne 2 armure',
        trigger: RelicTrigger.startOfTurn,
        effectType: 'gain_armor',
        value: 2,
        rarity: RelicRarity.common,
        emoji: '🪙',
      );

      controller.addRelic(talisman);
      controller.addRelic(talisman); // Stack x2

      expect(controller.state.heroStats.armure, 0);
      
      // Trigger startOfTurn relics
      controller.applyRelics(RelicTrigger.startOfTurn);
      // Stacking 2 x 2 armure = 4 armure
      expect(controller.state.heroStats.armure, 4);
    });
  });
}
