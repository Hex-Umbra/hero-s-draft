import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  group('InventoryController Unit Tests', () {
    late ProviderContainer container;
    late InventoryController inventoryController;
    late RunController runController;

    const dummyHero = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Paladin',
      iconPath: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
      luck: 0,
      armorMastery: 0,
      passiveTrait: 'regen_armor',
    );

    setUp(() {
      container = ProviderContainer();
      inventoryController = container.read(inventoryProvider.notifier);
      runController = container.read(runProvider.notifier);
      runController.startNewRun(dummyHero);
    });

    test('Initial gold is 50 from startNewRun', () {
      expect(inventoryController.state.gold, 50);
      expect(inventoryController.state.relics.isEmpty, true);
      expect(inventoryController.state.bonusShopCards, 0);
    });

    test('gainGold increases gold correctly', () {
      inventoryController.gainGold(30);
      expect(inventoryController.state.gold, 80);
    });

    test(
      'spendGold decreases gold on success and returns true, returns false on failure',
      () {
        final success = inventoryController.spendGold(30);
        expect(success, true);
        expect(inventoryController.state.gold, 20);

        final failure = inventoryController.spendGold(30);
        expect(failure, false);
        expect(inventoryController.state.gold, 20); // unchanged
      },
    );

    test(
      'addRelic adds relic and triggers startOfRun effect if trigger is startOfRun',
      () {
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

        expect(inventoryController.state.relics.contains(luckyClover), true);
        expect(runController.state.heroStats.luck, 1);
      },
    );

    test('buyShopExpansion increments bonusShopCards correctly', () {
      inventoryController.buyShopExpansion();
      expect(inventoryController.state.bonusShopCards, 1);
    });

    test('reset clears gold, relics, and expansion bonus', () {
      inventoryController.gainGold(50);
      inventoryController.buyShopExpansion();
      inventoryController.reset(initialGold: 10, initialBonusShopCards: 2);

      expect(inventoryController.state.gold, 10);
      expect(inventoryController.state.bonusShopCards, 2);
      expect(inventoryController.state.relics.isEmpty, true);
    });
  });
}
