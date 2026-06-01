import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

void main() {
  group('RunController & RunState Tests', () {
    test(
      'RunState constructor sets default bonusShopCards to 0 in inventory',
      () {
        final container = ProviderContainer();
        final inventoryState = container.read(inventoryProvider);
        expect(inventoryState.bonusShopCards, 0);
      },
    );

    test(
      'buyShopExpansion increments bonusShopCards correctly in inventory',
      () {
        final container = ProviderContainer();
        final inventoryController = container.read(inventoryProvider.notifier);
        expect(container.read(inventoryProvider).bonusShopCards, 0);

        inventoryController.buyShopExpansion();
        expect(container.read(inventoryProvider).bonusShopCards, 1);

        inventoryController.buyShopExpansion();
        expect(container.read(inventoryProvider).bonusShopCards, 2);
      },
    );

    test(
      'startNewRun resets bonusShopCards to 0 and gold to 50 in inventory',
      () {
        final container = ProviderContainer();
        final runController = container.read(runProvider.notifier);
        final inventoryController = container.read(inventoryProvider.notifier);

        inventoryController.buyShopExpansion();
        expect(container.read(inventoryProvider).bonusShopCards, 1);

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

        runController.startNewRun(dummyHero);
        expect(container.read(inventoryProvider).bonusShopCards, 0);
        expect(container.read(inventoryProvider).gold, 50);
      },
    );

    test(
      'Berserker armor passive triggers at start of combat when player has missing HP and resets at end of combat',
      () {
        final container = ProviderContainer();
        final runController = container.read(runProvider.notifier);

        const berserkerHero = HeroData(
          id: 'berserker',
          nameEn: 'Berserker',
          nameFr: 'Berserker',
          descriptionEn: 'A raging warrior',
          descriptionFr: 'Un guerrier enragé',
          iconPath: 'berserker.png',
          maxHp: 80,
          maxMana: 3,
          baseDamage: 6,
          luck: 0,
          armorMastery: 1,
          passiveTrait: 'berserkerArmor',
        );

        runController.startNewRun(berserkerHero);

        // Set missing HP: 80 max HP, set current to 60 (20 missing HP)
        runController.setHeroStats(currentPv: 60, armure: 0);

        // Travel to a node to have currentNodeId set
        runController.travelToNode('node_1');

        // At the start of combat, the passive should trigger:
        // Missing HP = 20. Gain = 20 ~/ 10 = 2 armor.
        // Total gain = 2 + armorMastery (1) = 3 armor.
        runController.startCombat();

        expect(runController.state.heroStats.armure, 3);

        // When the node is completed, armor should reset to 0
        runController.completeCurrentNode();
        expect(runController.state.heroStats.armure, 0);
      },
    );

    test(
      'Relic system: addRelic, startOfRun effect, trigger application and stacking',
      () {
        final container = ProviderContainer();
        final runController = container.read(runProvider.notifier);
        final inventoryController = container.read(inventoryProvider.notifier);

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
        runController.startNewRun(dummyHero);

        // 1. startOfRun trigger is applied immediately
        const luckyClover = RelicData(
          id: 'lucky_clover',
          nameEn: 'Lucky Clover',
          nameFr: 'Trèfle Enchanté',
          descriptionEn: '+1 Luck',
          descriptionFr: '+1 Chance',
          trigger: RelicTrigger.startOfRun,
          effectType: 'gain_luck',
          value: 1,
          rarity: RelicRarity.epic,
          emoji: '🍀',
        );

        expect(runController.state.heroStats.luck, 0);
        inventoryController.addRelic(luckyClover);
        expect(runController.state.heroStats.luck, 1);
        expect(inventoryController.state.relics.length, 1);

        // Stacking lucky clover gives +1 luck again
        inventoryController.addRelic(luckyClover);
        expect(runController.state.heroStats.luck, 2);
        expect(inventoryController.state.relics.length, 2);

        // 2. Combat triggers and stacking
        const talisman = RelicData(
          id: 'iron_talisman',
          nameEn: 'Iron Talisman',
          nameFr: 'Talisman de Fer',
          descriptionEn: 'Gain 2 armor',
          descriptionFr: 'Gagne 2 armure',
          trigger: RelicTrigger.startOfTurn,
          effectType: 'gain_armor',
          value: 2,
          rarity: RelicRarity.common,
          emoji: '🪙',
        );

        inventoryController.addRelic(talisman);
        inventoryController.addRelic(talisman); // Stack x2

        expect(runController.state.heroStats.armure, 0);

        // Trigger startOfTurn relics
        runController.applyRelics(RelicTrigger.startOfTurn);
        // Stacking 2 x 2 armure = 4 armure
        expect(runController.state.heroStats.armure, 4);
      },
    );
  });
}
