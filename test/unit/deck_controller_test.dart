import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

CardInstance _card(String id) => CardInstance(
      data: CardData(
        id: id,
        nameEn: id,
        nameFr: id,
        cost: 1,
        type: CardType.skill,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.self,
        effects: const [],
      ),
    );

void main() {
  group('DeckNotifier Tests', () {
    late ProviderContainer container;
    late DeckNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(deckProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'drawCards draws up to active drawPile size mid-turn and does not shuffle discard',
      () {
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

    test('mergeCards successfully upgrades rarity and merges forge upgrades', () {
      final baseCardData = const CardData(
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
        baseMaxForgeUpgrades: 1,
      );

      final card1 = CardInstance(
        data: baseCardData,
        rarity: CardRarity.common,
        forgeUpgrades: ['sharp:1', 'hardened:1'],
      );
      final card2 = CardInstance(
        data: baseCardData,
        rarity: CardRarity.common,
        forgeUpgrades: ['sharp:1'],
      );
      final card3 = CardInstance(
        data: baseCardData,
        rarity: CardRarity.common,
        forgeUpgrades: [],
      );

      notifier.initializeStarterDeck([card1, card2, card3]);

      // Merge the 3 cards
      // The capacity of next rarity (Uncommon) is baseMaxForgeUpgrades (1) + nextRarityIndex (1) = 2.
      // Inherited list has ['sharp:1', 'hardened:1', 'sharp:1'].
      // Auto-fusion should consolidate them to ['sharp:2', 'hardened:1'] (2 upgrades).
      notifier.mergeCards(
        [card1.uniqueId, card2.uniqueId, card3.uniqueId],
        ['sharp:1', 'hardened:1', 'sharp:1'],
      );

      expect(notifier.state.masterDeck.length, 1);
      final mergedCard = notifier.state.masterDeck.first;
      expect(mergedCard.rarity, CardRarity.uncommon);
      expect(mergedCard.forgeUpgrades.length, 2);
      expect(mergedCard.forgeUpgrades.contains('sharp:2'), isTrue);
      expect(mergedCard.forgeUpgrades.contains('hardened:1'), isTrue);
    });

    test('mergeCards limits upgrades to the capacity of the next rarity level', () {
      final baseCardData = const CardData(
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
        baseMaxForgeUpgrades: 1,
      );

      final card1 = CardInstance(
        data: baseCardData,
        rarity: CardRarity.common,
        forgeUpgrades: ['sharp:1'],
      );
      final card2 = CardInstance(
        data: baseCardData,
        rarity: CardRarity.common,
        forgeUpgrades: ['hardened:1'],
      );
      final card3 = CardInstance(
        data: baseCardData,
        rarity: CardRarity.common,
        forgeUpgrades: ['quick:1'],
      );

      notifier.initializeStarterDeck([card1, card2, card3]);

      // Merge cards. Next rarity is Uncommon, capacity = 2.
      // We pass 3 upgrades: ['sharp:1', 'hardened:1', 'quick:1'].
      // Since capacity is 2, it should limit to 2 upgrades.
      notifier.mergeCards(
        [card1.uniqueId, card2.uniqueId, card3.uniqueId],
        ['sharp:1', 'hardened:1', 'quick:1'],
      );

      expect(notifier.state.masterDeck.length, 1);
      final mergedCard = notifier.state.masterDeck.first;
      expect(mergedCard.rarity, CardRarity.uncommon);
      // Upgrades should be limited to 2
      expect(mergedCard.forgeUpgrades.length, 2);
    });
  });

  group('DeckNotifier — aléatoire et compteur de remélange', () {
    test('deckRandomProvider rend le mélange déterministe', () {
      final cards = List.generate(10, (i) => _card('c$i'));

      List<String> orderWithSeed(int seed) {
        final container = ProviderContainer(
          overrides: [deckRandomProvider.overrideWithValue(Random(seed))],
        );
        addTearDown(container.dispose);
        final notifier = container.read(deckProvider.notifier);
        notifier.initializeStarterDeck(cards);
        notifier.initializeCombat();
        return notifier.state.drawPile.map((c) => c.uniqueId).toList();
      }

      expect(orderWithSeed(42), equals(orderWithSeed(42)));
      expect(orderWithSeed(42), isNot(equals(orderWithSeed(7))));
    });

    test('reshuffleCount vaut 0 par défaut et survit à la sérialisation', () {
      const state = DeckState(reshuffleCount: 3);
      final json = state.toJson();
      expect(json['reshuffleCount'], 3);

      final (restored, missing) = DeckState.fromJsonWithReport(json);
      expect(restored.reshuffleCount, 3);
      expect(missing, isEmpty);
    });

    test('reshuffleCount vaut 0 sur une sauvegarde antérieure à P-02', () {
      const state = DeckState();
      final legacy = Map<String, dynamic>.from(state.toJson())
        ..remove('reshuffleCount');

      final (restored, _) = DeckState.fromJsonWithReport(legacy);
      expect(restored.reshuffleCount, 0);
    });
  });
}
