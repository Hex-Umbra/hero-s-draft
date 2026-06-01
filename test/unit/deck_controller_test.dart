import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

void main() {
  group('DeckNotifier Tests', () {
    test(
      'drawCards draws up to active drawPile size mid-turn and does not shuffle discard',
      () {
        final notifier = DeckNotifier();
        final cardA = CardInstance(
          data: const CardData(
            id: 'strike',
            nameEn: 'Strike',
            nameFr: 'Frappe',
            descriptionEn: 'd',
            descriptionFr: 'd',
            cost: 1,
            type: CardType.attack,
            category: CardCategory.global,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            effects: [],
          ),
        );
        final cardB = CardInstance(
          data: const CardData(
            id: 'defend',
            nameEn: 'Defend',
            nameFr: 'Défense',
            descriptionEn: 'd',
            descriptionFr: 'd',
            cost: 1,
            type: CardType.skill,
            category: CardCategory.global,
            rarity: CardRarity.common,
            target: CardTarget.self,
            effects: [],
          ),
        );

        notifier.initializeStarterDeck([cardA, cardB]);
        notifier.initializeCombat();

        // Clear piles to set up specific scenario
        notifier.state = notifier.state.copyWith(
          drawPile: [cardA],
          hand: [],
          discardPile: [cardB],
        );

        // Draw 2 cards mid-turn
        notifier.drawCards(2);

        // Should only draw cardA from drawPile, and NOT shuffle cardB
        expect(notifier.state.hand.length, 1);
        expect(notifier.state.hand.first.uniqueId, cardA.uniqueId);
        expect(notifier.state.drawPile.isEmpty, isTrue);
        expect(notifier.state.discardPile.length, 1);
        expect(notifier.state.discardPile.first.uniqueId, cardB.uniqueId);
      },
    );

    test('shuffleDiscardIntoDraw manually merges discard into draw pile', () {
      final notifier = DeckNotifier();
      final cardA = CardInstance(
        data: const CardData(
          id: 'strike',
          nameEn: 'Strike',
          nameFr: 'Frappe',
          descriptionEn: 'd',
          descriptionFr: 'd',
          cost: 1,
          type: CardType.attack,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: [],
        ),
      );
      final cardB = CardInstance(
        data: const CardData(
          id: 'defend',
          nameEn: 'Defend',
          nameFr: 'Défense',
          descriptionEn: 'd',
          descriptionFr: 'd',
          cost: 1,
          type: CardType.skill,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.self,
          effects: [],
        ),
      );

      notifier.initializeStarterDeck([cardA, cardB]);
      notifier.initializeCombat();

      // Clear draw, put cardB in discard
      notifier.state = notifier.state.copyWith(
        drawPile: [cardA],
        hand: [],
        discardPile: [cardB],
      );

      notifier.shuffleDiscardIntoDraw();

      expect(notifier.state.drawPile.length, 2);
      expect(notifier.state.discardPile.isEmpty, isTrue);
      expect(
        notifier.state.drawPile.any((c) => c.uniqueId == cardA.uniqueId),
        isTrue,
      );
      expect(
        notifier.state.drawPile.any((c) => c.uniqueId == cardB.uniqueId),
        isTrue,
      );
    });
  });
}
