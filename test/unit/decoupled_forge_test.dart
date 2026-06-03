import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

void main() {
  group('Decoupled Forge Unit Tests', () {
    test('Capacity limit calculation works as expected based on rarity', () {
      final baseCard = CardData(
        id: 'test_card',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        baseMaxForgeUpgrades: 2,
        effects: [],
      );

      // Common card capacity = 2 + 0 = 2
      final commonInstance = CardInstance(data: baseCard, rarity: CardRarity.common);
      final commonCapacity = commonInstance.data.baseMaxForgeUpgrades + commonInstance.rarity.index;
      expect(commonCapacity, 2);

      // Epic card capacity = 2 + 3 = 5
      final epicInstance = CardInstance(data: baseCard, rarity: CardRarity.epic);
      final epicCapacity = epicInstance.data.baseMaxForgeUpgrades + epicInstance.rarity.index;
      expect(epicCapacity, 5);
    });

    test('addForgeUpgrade correctly adds an upgrade to the master deck card', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cardData = CardData(
        id: 'strike',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      );

      final card = CardInstance(data: cardData);
      final deckNotifier = container.read(deckProvider.notifier);

      deckNotifier.initializeStarterDeck([card]);

      // Initially no upgrades
      expect(container.read(deckProvider).masterDeck.first.forgeUpgrades, isEmpty);

      // Add a sharp:1 upgrade
      deckNotifier.addForgeUpgrade(card.uniqueId, 'sharp:1');

      final updatedCard = container.read(deckProvider).masterDeck.first;
      expect(updatedCard.forgeUpgrades, contains('sharp:1'));
      expect(updatedCard.forgeUpgrades.length, 1);
    });
  });
}
