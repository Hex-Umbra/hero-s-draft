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
  });
}
