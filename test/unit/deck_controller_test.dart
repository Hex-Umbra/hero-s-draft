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
      'drawCards remélange désormais la défausse quand la pioche est vide',
      () {
        final cardA = _card('strike');
        final cardB = _card('defend');

        notifier.initializeStarterDeck([cardA, cardB]);
        notifier.state = notifier.state.copyWith(
          drawPile: [cardA],
          hand: [],
          discardPile: [cardB],
        );

        notifier.drawCards(2, maxHandSize: 10);

        // Comportement inversé par P-02 : cardB ne reste plus bloquée en défausse.
        expect(notifier.state.hand.length, 2);
        expect(notifier.state.drawPile, isEmpty);
        expect(notifier.state.discardPile, isEmpty);
        expect(notifier.state.reshuffleCount, 1);
      },
    );

    test('la défausse rejoint la pioche sans appel manuel', () {
      final cardA = _card('strike');
      final cardB = _card('defend');

      notifier.initializeStarterDeck([cardA, cardB]);
      notifier.state = notifier.state.copyWith(
        drawPile: [cardA],
        hand: [],
        discardPile: [cardB],
      );

      // Une seule carte demandée : la pioche se vide, pas de remélange.
      notifier.drawCards(1, maxHandSize: 10);
      expect(notifier.state.reshuffleCount, 0);
      expect(notifier.state.discardPile.length, 1);

      // La suivante déclenche le remélange.
      notifier.drawCards(1, maxHandSize: 10);
      expect(notifier.state.hand.length, 2);
      expect(notifier.state.discardPile, isEmpty);
      expect(notifier.state.reshuffleCount, 1);
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
        // handSize: 0 — on veut observer l'ordre brut de la pioche, sans
        // qu'une main d'ouverture en retire les dernières cartes.
        notifier.startCombat(handSize: 0, maxHandSize: 10);
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

  group('DeckNotifier — moteur de pioche', () {
    late ProviderContainer container;
    late DeckNotifier notifier;

    setUp(() {
      container = ProviderContainer(
        overrides: [deckRandomProvider.overrideWithValue(Random(42))],
      );
      notifier = container.read(deckProvider.notifier);
    });

    tearDown(() => container.dispose());

    /// Invariant central : aucune carte ne se perd ni ne se duplique.
    void expectConservation(DeckState s) {
      expect(
        s.drawPile.length + s.hand.length + s.discardPile.length + s.exhaustPile.length,
        s.masterDeck.length,
        reason: 'masterDeck != draw + hand + discard + exhaust',
      );
    }

    test('remélange à sec au milieu d\'une pioche', () {
      final cards = List.generate(10, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);
      notifier.state = notifier.state.copyWith(
        drawPile: cards.sublist(0, 3),
        hand: [],
        discardPile: cards.sublist(3, 10),
      );

      notifier.drawCards(5, maxHandSize: 10);

      expect(notifier.state.hand.length, 5);
      expect(notifier.state.drawPile.length, 5);
      expect(notifier.state.discardPile, isEmpty);
      expect(notifier.state.reshuffleCount, 1);
      expectConservation(notifier.state);
    });

    test('deck totalement épuisé : sortie propre, aucune exception', () {
      final cards = List.generate(3, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);
      notifier.state = notifier.state.copyWith(
        drawPile: [],
        hand: [],
        discardPile: [],
        exhaustPile: cards,
      );

      notifier.drawCards(3, maxHandSize: 10);

      expect(notifier.state.hand, isEmpty);
      expect(notifier.state.reshuffleCount, 0);
      expectConservation(notifier.state);
    });

    test('arrêt net sur main pleine : aucune pile touchée, aucun remélange', () {
      final cards = List.generate(10, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);
      notifier.state = notifier.state.copyWith(
        drawPile: [],
        hand: cards.sublist(0, 3),
        discardPile: cards.sublist(3, 10),
      );

      notifier.drawCards(2, maxHandSize: 3);

      expect(notifier.state.hand.length, 3);
      expect(notifier.state.drawPile, isEmpty);
      expect(notifier.state.discardPile.length, 7);
      // L'assertion qui distingue « arrêt net » de « carte consommée vers la défausse » :
      // la seconde aurait remélangé les 7 cartes pour ne rien donner au joueur.
      expect(notifier.state.reshuffleCount, 0);
      expectConservation(notifier.state);
    });

    test('pioche partielle : on prend ce qui existe puis on s\'arrête', () {
      final cards = List.generate(4, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);
      notifier.state = notifier.state.copyWith(
        drawPile: cards.sublist(0, 2),
        hand: [],
        discardPile: [],
        exhaustPile: cards.sublist(2, 4),
      );

      notifier.drawCards(5, maxHandSize: 10);

      expect(notifier.state.hand.length, 2);
      expect(notifier.state.drawPile, isEmpty);
      expect(notifier.state.reshuffleCount, 0);
      expectConservation(notifier.state);
    });

    test('reshuffleCount s\'incrémente exactement une fois par remélange', () {
      final cards = List.generate(4, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);
      notifier.state = notifier.state.copyWith(
        drawPile: [],
        hand: [],
        discardPile: cards,
      );

      notifier.drawCards(4, maxHandSize: 10);
      expect(notifier.state.reshuffleCount, 1);

      // Tour suivant : on renvoie tout en défausse et on repioche.
      notifier.discardHand();
      notifier.drawCards(4, maxHandSize: 10);
      expect(notifier.state.reshuffleCount, 2);
      expectConservation(notifier.state);
    });

    test('startCombat constitue la pioche et tire la main d\'ouverture', () {
      final cards = List.generate(10, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);

      notifier.startCombat(handSize: 5, maxHandSize: 10);

      expect(notifier.state.hand.length, 5);
      expect(notifier.state.drawPile.length, 5);
      expect(notifier.state.discardPile, isEmpty);
      expect(notifier.state.exhaustPile, isEmpty);
      expect(notifier.state.reshuffleCount, 0);
      expectConservation(notifier.state);
    });

    test('startCombat repart d\'un état propre et remet reshuffleCount à 0', () {
      final cards = List.generate(6, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);

      // État sale hérité d'un combat précédent.
      notifier.state = notifier.state.copyWith(
        drawPile: [],
        hand: cards.sublist(0, 2),
        discardPile: cards.sublist(2, 4),
        exhaustPile: cards.sublist(4, 6),
        reshuffleCount: 4,
      );

      notifier.startCombat(handSize: 5, maxHandSize: 10);

      expect(notifier.state.hand.length, 5);
      expect(notifier.state.drawPile.length, 1);
      expect(notifier.state.discardPile, isEmpty);
      expect(notifier.state.exhaustPile, isEmpty);
      expect(notifier.state.reshuffleCount, 0);
      expectConservation(notifier.state);
    });

    test('startCombat respecte maxHandSize', () {
      final cards = List.generate(10, (i) => _card('c$i'));
      notifier.initializeStarterDeck(cards);

      notifier.startCombat(handSize: 5, maxHandSize: 3);

      expect(notifier.state.hand.length, 3);
      expect(notifier.state.drawPile.length, 7);
      expectConservation(notifier.state);
    });
  });
}
