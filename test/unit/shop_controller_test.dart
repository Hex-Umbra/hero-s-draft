import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/shop_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  group('ShopController Unit Tests', () {
    late ShopController shopController;
    late RunController runController;
    late DeckNotifier deckNotifier;

    final List<CardData> testCardPool = [
      const CardData(
        id: 'c1',
        nameEn: 'Strike',
        nameFr: 'Frappe',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      ),
      const CardData(
        id: 'c2',
        nameEn: 'Defend',
        nameFr: 'Défense',
        cost: 1,
        type: CardType.skill,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.self,
        effects: [],
      ),
      const CardData(
        id: 'c3',
        nameEn: 'Rare Power',
        nameFr: 'Pouvoir Rare',
        cost: 2,
        type: CardType.power,
        category: CardCategory.global,
        rarity: CardRarity.rare,
        target: CardTarget.self,
        effects: [],
      ),
      const CardData(
        id: 'c4',
        nameEn: 'Uncommon attack',
        nameFr: 'Attaque Peu Commune',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.uncommon,
        target: CardTarget.singleEnemy,
        effects: [],
      ),
    ];

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
      passiveTrait: 'regenArmor',
    );

    setUp(() {
      shopController = ShopController();
      runController = RunController();
      deckNotifier = DeckNotifier();

      // Démarrer une run avec 100 pièces d'or
      runController.startNewRun(dummyHero);
      // Donner 100 pièces d'or par défaut
      runController.gainGold(50); // 50 de base + 50 = 100
    });

    test('initializeShop fills cardsForSale to 3 cards by default', () {
      shopController.initializeShop(testCardPool, 0);
      expect(shopController.state.cardsForSale.length, 3);
      expect(shopController.state.purchasedHeal, false);
    });

    test('initializeShop fills cardsForSale with bonus expansion cards', () {
      shopController.initializeShop(testCardPool, 1);
      expect(shopController.state.cardsForSale.length, 4);
    });

    test('buyCard successfully spends gold, removes card from shop, and adds it to deck', () {
      shopController.initializeShop(testCardPool, 0);
      final cardToBuy = shopController.state.cardsForSale.first;
      final price = ShopController.getCardPrice(cardToBuy.rarity);
      final initialGold = runController.state.gold;

      final success = shopController.buyCard(
        cardToBuy,
        price,
        runController,
        deckNotifier,
      );

      expect(success, true);
      expect(runController.state.gold, initialGold - price);
      expect(shopController.state.cardsForSale.contains(cardToBuy), false);
      expect(deckNotifier.state.masterDeck.any((c) => c.data.id == cardToBuy.id), true);
    });

    test('buyCard fails and does not modify state if gold is insufficient', () {
      shopController.initializeShop(testCardPool, 0);
      final cardToBuy = shopController.state.cardsForSale.firstWhere((c) => c.rarity == CardRarity.rare, orElse: () => testCardPool[2]);
      
      // Mettre l'or à 0
      runController.spendGold(runController.state.gold);

      final success = shopController.buyCard(
        cardToBuy,
        100, // Prix rare
        runController,
        deckNotifier,
      );

      expect(success, false);
      expect(runController.state.gold, 0);
      // Reste dans la boutique si l'achat a échoué (s'il y était initialement)
      shopController.initializeShop([cardToBuy], 0);
      final tryAgain = shopController.buyCard(cardToBuy, 100, runController, deckNotifier);
      expect(tryAgain, false);
      expect(shopController.state.cardsForSale.contains(cardToBuy), true);
    });

    test('buyHeal heals the hero and blocks further heal purchases', () {
      // Blesser le héros
      runController.takeDamage(40);
      expect(runController.state.heroStats.currentPv, 60);

      // Achat du soin
      final success = shopController.buyHeal(30, 30, runController);

      expect(success, true);
      expect(runController.state.heroStats.currentPv, 90);
      expect(runController.state.gold, 70); // 100 - 30 = 70
      expect(shopController.state.purchasedHeal, true);

      // Tenter un second achat de soin
      final success2 = shopController.buyHeal(30, 30, runController);
      expect(success2, false);
      expect(runController.state.heroStats.currentPv, 90); // inchangé
      expect(runController.state.gold, 70); // inchangé
    });

    test('expandShop expands cards list and increments run bonus expansion', () {
      shopController.initializeShop(testCardPool.sublist(0, 3), 0);
      expect(shopController.state.cardsForSale.length, 3);
      expect(runController.state.bonusShopCards, 0);

      final success = shopController.expandShop(10, testCardPool, runController);

      expect(success, true);
      expect(runController.state.bonusShopCards, 1);
      // Contient maintenant 4 cartes (la 4ème du pool a été ajoutée)
      expect(shopController.state.cardsForSale.length, 4);
    });

    test('rerollCards refreshes cards with new draw', () {
      shopController.initializeShop(testCardPool, 0);

      final success = shopController.rerollCards(15, testCardPool, 0, runController);

      expect(success, true);
      expect(runController.state.gold, 85); // 100 - 15 = 85
      // La liste de cartes a été régénérée
      expect(shopController.state.cardsForSale.length, 3);
    });

    test('purgeCard successfully purges card from deck', () {
      final cardToPurge = CardInstance(data: testCardPool[0]);
      deckNotifier.initializeStarterDeck([cardToPurge]);
      expect(deckNotifier.state.masterDeck.length, 1);

      final success = shopController.purgeCard(75, cardToPurge, runController, deckNotifier);

      expect(success, true);
      expect(runController.state.gold, 25); // 100 - 75 = 25
      expect(deckNotifier.state.masterDeck.isEmpty, true);
    });

    test('cloneCard successfully clones card in master deck', () {
      final cardToClone = CardInstance(data: testCardPool[0]);
      deckNotifier.initializeStarterDeck([cardToClone]);
      expect(deckNotifier.state.masterDeck.length, 1);

      final success = shopController.cloneCard(50, cardToClone, runController, deckNotifier);

      expect(success, true);
      expect(runController.state.gold, 50); // 100 - 50 = 50
      expect(deckNotifier.state.masterDeck.length, 2);
      expect(deckNotifier.state.masterDeck[0].data.id, testCardPool[0].id);
      expect(deckNotifier.state.masterDeck[1].data.id, testCardPool[0].id);
    });
  });
}
