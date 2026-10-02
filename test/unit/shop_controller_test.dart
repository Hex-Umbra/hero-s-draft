import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/shop_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

import 'shipped_data.dart';

void main() {
  group('ShopController Unit Tests', () {
    late ProviderContainer container;
    late ShopController shopController;
    late RunController runController;
    late InventoryController inventoryController;
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
      classCard: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      luck: 0,
      mastery: 0,
    );

    setUp(() {
      container = ProviderContainer();
      shopController = container.read(shopProvider.notifier);
      runController = container.read(runProvider.notifier);
      inventoryController = container.read(inventoryProvider.notifier);
      deckNotifier = container.read(deckProvider.notifier);

      // Démarrer une run (initialise l'or à 50)
      runController.startNewRun(dummyHero);
      // Donner 100 pièces d'or par défaut
      inventoryController.gainGold(50); // 50 de base + 50 = 100
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

    test(
      'buyCard successfully spends gold, removes card from shop, and adds it to deck',
      () {
        inventoryController.gainGold(500); // Donner de l'or supplémentaire pour ce test
        shopController.initializeShop(testCardPool, 0);
        final cardToBuy = shopController.state.cardsForSale.first;
        final price = ShopController.getCardPrice(cardToBuy);
        final initialGold = inventoryController.state.gold;

        final success = shopController.buyCard(
          cardToBuy,
          price,
        );

        expect(success, true);
        expect(inventoryController.state.gold, initialGold - price);
        expect(shopController.state.cardsForSale.contains(cardToBuy), false);
        expect(
          deckNotifier.state.masterDeck.any((c) => c.data.id == cardToBuy.data.id),
          true,
        );
      },
    );

    test('buyCard fails and does not modify state if gold is insufficient', () {
      shopController.initializeShop(testCardPool, 0);
      final cardToBuy = shopController.state.cardsForSale.firstWhere(
        (c) => c.rarity == CardRarity.rare,
        orElse: () => CardInstance(data: testCardPool[2]),
      );

      // Mettre l'or à 0
      inventoryController.spendGold(inventoryController.state.gold);

      final success = shopController.buyCard(
        cardToBuy,
        100, // Prix rare
      );

      expect(success, false);
      expect(inventoryController.state.gold, 0);
      // Reste dans la boutique si l'achat a échoué (s'il y était initialement)
      shopController.initializeShop([cardToBuy.data], 0);
      final tryAgain = shopController.buyCard(
        cardToBuy,
        100,
      );
      expect(tryAgain, false);
      expect(shopController.state.cardsForSale.any((c) => c.data.id == cardToBuy.data.id), true);
    });

    test('buyHeal heals the hero and blocks further heal purchases', () {
      // Blesser le héros
      runController.takeDamage(40);
      expect(runController.state.heroStats.currentPv, 60);

      // Achat du soin
      final success = shopController.buyHeal(
        30,
        30,
      );

      expect(success, true);
      expect(runController.state.heroStats.currentPv, 90);
      expect(inventoryController.state.gold, 70); // 100 - 30 = 70
      expect(shopController.state.purchasedHeal, true);

      // Tenter un second achat de soin
      final success2 = shopController.buyHeal(
        30,
        30,
      );
      expect(success2, false);
      expect(runController.state.heroStats.currentPv, 90); // inchangé
      expect(inventoryController.state.gold, 70); // inchangé
    });

    test(
      'expandShop expands cards list and increments run bonus expansion',
      () {
        shopController.initializeShop(testCardPool.sublist(0, 3), 0);
        expect(shopController.state.cardsForSale.length, 3);
        expect(inventoryController.state.bonusShopCards, 0);

        final success = shopController.expandShop(
          10,
          testCardPool,
        );

        expect(success, true);
        expect(inventoryController.state.bonusShopCards, 1);
        // Contient maintenant 4 cartes
        expect(shopController.state.cardsForSale.length, 4);
      },
    );

    test('rerollCards refreshes cards with new draw', () {
      shopController.initializeShop(testCardPool, 0);

      final success = shopController.rerollCards(
        15,
        testCardPool,
        0,
      );

      expect(success, true);
      expect(inventoryController.state.gold, 85); // 100 - 15 = 85
      // La liste de cartes a été régénérée
      expect(shopController.state.cardsForSale.length, 3);
    });

    test('purgeCard successfully purges card from deck', () {
      final cardToPurge = CardInstance(data: testCardPool[0]);
      deckNotifier.initializeStarterDeck([cardToPurge]);
      expect(deckNotifier.state.masterDeck.length, 1);

      final success = shopController.purgeCard(
        75,
        cardToPurge,
      );

      expect(success, true);
      expect(inventoryController.state.gold, 25); // 100 - 75 = 25
      expect(deckNotifier.state.masterDeck.isEmpty, true);
    });

    test('cloneCard successfully clones card in master deck', () {
      final cardToClone = CardInstance(data: testCardPool[0]);
      deckNotifier.initializeStarterDeck([cardToClone]);
      expect(deckNotifier.state.masterDeck.length, 1);

      // Le prix de base est maintenant de 150 Or, donnons 100 Or de plus (100 de base + 100 = 200 Or)
      inventoryController.gainGold(100);

      final success = shopController.cloneCard(
        cardToClone,
      );

      expect(success, true);
      expect(inventoryController.state.gold, 50); // 200 - 150 = 50
      expect(deckNotifier.state.masterDeck.length, 2);
      expect(deckNotifier.state.masterDeck[0].data.id, testCardPool[0].id);
      expect(deckNotifier.state.masterDeck[1].data.id, testCardPool[0].id);
    });

    test('cloneCard price doubles on subsequent purchases and resets on clearCloneOptions', () {
      final cardToClone = CardInstance(data: testCardPool[0]);
      deckNotifier.initializeStarterDeck([cardToClone]);

      // Prix initial est 150 Or. Donnons-nous beaucoup d'or pour pouvoir faire plusieurs achats.
      inventoryController.gainGold(2000); // 100 + 2000 = 2100 Or

      expect(shopController.state.clonePrice, 150);

      // Premier clone
      var success = shopController.cloneCard(cardToClone);
      expect(success, true);
      expect(shopController.state.clonePrice, 300);
      expect(shopController.state.clonePurchasedCount, 1);

      // Deuxième clone
      success = shopController.cloneCard(cardToClone);
      expect(success, true);
      expect(shopController.state.clonePrice, 600);
      expect(shopController.state.clonePurchasedCount, 2);

      // Troisième clone
      success = shopController.cloneCard(cardToClone);
      expect(success, true);
      expect(shopController.state.clonePrice, 1200);
      expect(shopController.state.clonePurchasedCount, 3);

      // Réinitialisation de la boutique (sortie du shop)
      shopController.clearCloneOptions();
      expect(shopController.state.clonePrice, 150);
      expect(shopController.state.clonePurchasedCount, 0);
    });

    test('la rarete tiree en boutique monte au plus jusqu a legendaire', () {
      runController.updateState(container.read(runProvider).copyWith(act: 3));
      const epicCard = CardData(
        id: 'epic_strike',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.epic,
        target: CardTarget.singleEnemy,
        effects: [],
      );

      // A l'acte 3 : moitie sans hausse, 40 % a +1, 10 % a +2 plafonne.
      final rolled = <CardRarity>{};
      for (var i = 0; i < 200; i++) {
        shopController.initializeShop(const [epicCard], 0);
        rolled.addAll(shopController.state.cardsForSale.map((c) => c.rarity));
      }

      expect(rolled, {CardRarity.epic, CardRarity.legendary});
    });

    test('la boutique ne pose une premiere rune qu eligible a la carte', () {
      // Les runes et les cartes livrees ; le registre vide le remplace en
      // sortie, comme au cas suivant.
      addTearDown(
        () => GameDataRegistry(
          enemies: const [],
          heroes: const [],
          cards: const [],
          events: const [],
          passives: const [],
          relics: const [],
          forgeUpgrades: const [],
        ),
      );
      final catalog = shippedRuneRegistry(shippedRuneIds()).forgeUpgrades;
      final cards = shippedNeutralCards();
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      var checked = 0;
      for (var i = 0; i < 200; i++) {
        shopController.initializeShop(cards, 0);
        for (final card in shopController.state.cardsForSale) {
          if (card.forgeUpgrades.isEmpty) continue;
          checked++;
          final (id, _) = ForgeUpgradeData.parseRef(card.forgeUpgrades.first)!;
          final rune = catalog.singleWhere((r) => r.id == id);
          expect(
            ForgeRuneRules.isEligible(
                rune, card.copyWith(forgeUpgrades: const []), catalog),
            isTrue,
            reason: '${card.data.id} : ${card.forgeUpgrades}',
          );
        }
      }
      // Garde contre un test qui passerait à vide.
      expect(checked, greaterThan(0));
    });

    test('une rune plafonnee n est jamais tiree au-dessus de son plafond', () {
      addTearDown(
        () => GameDataRegistry(
          enemies: const [],
          heroes: const [],
          cards: const [],
          events: const [],
          passives: const [],
          relics: const [],
          forgeUpgrades: const [],
        ),
      );
      // Cumulable, comme eco aujourd'hui : le tirage la monterait a 2 ou 3.
      GameDataRegistry(
        enemies: const [],
        heroes: const [],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [
          ForgeUpgradeData(
            id: 'capped',
            nameEn: 'Capped',
            nameFr: 'Plafonnee',
            descriptionEn: '',
            descriptionFr: '',
            icon: '',
            color: '',
            pools: ['common', 'uncommon', 'rare'],
            maxLevel: 1,
          ),
        ],
      );
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      final rolled = <String>{};
      for (var i = 0; i < 200; i++) {
        shopController.initializeShop(testCardPool, 0);
        for (final card in shopController.state.cardsForSale) {
          rolled.addAll(card.forgeUpgrades);
        }
      }

      expect(rolled, {'capped:1'});
    });

    test('une pre-forgee ne porte que des runes eligibles a ses runes deja '
        'tirees, jamais au-dela d un plafond (spec P-43 E1, A12)', () {
      addTearDown(
        () => GameDataRegistry(
          enemies: const [],
          heroes: const [],
          cards: const [],
          events: const [],
          passives: const [],
          relics: const [],
          forgeUpgrades: const [],
        ),
      );
      final catalog = shippedRuneRegistry(shippedRuneIds()).forgeUpgrades;
      final cards = shippedNeutralCards();
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      for (var i = 0; i < 300; i++) {
        shopController.initializeShop(cards, 0);
        for (final card in shopController.state.cardsForSale) {
          for (var n = 0; n < card.forgeUpgrades.length; n++) {
            final (id, _) = ForgeUpgradeData.parseRef(card.forgeUpgrades[n])!;
            final before = card.copyWith(
                forgeUpgrades: card.forgeUpgrades.sublist(0, n));
            expect(
              ForgeRuneRules.isEligible(
                  catalog.singleWhere((r) => r.id == id), before, catalog),
              isTrue,
              reason: '${card.data.id} : ${card.forgeUpgrades}',
            );
          }
          ForgeUpgradeData.levelsOf(card.forgeUpgrades).forEach((id, level) {
            final cap = catalog.singleWhere((r) => r.id == id).maxLevel;
            expect(level, lessThanOrEqualTo(cap ?? level),
                reason: '${card.data.id} : ${card.forgeUpgrades}');
          });
        }
      }
    });

    test('une Concentration pre-forgee porte au plus une rune, Veloce', () {
      addTearDown(
        () => GameDataRegistry(
          enemies: const [],
          heroes: const [],
          cards: const [],
          events: const [],
          passives: const [],
          relics: const [],
          forgeUpgrades: const [],
        ),
      );
      shippedRuneRegistry(shippedRuneIds());
      final concentration = shippedCard('concentration');
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      final carried = <String>{};
      for (var i = 0; i < 300; i++) {
        shopController.initializeShop([concentration], 0);
        for (final card in shopController.state.cardsForSale) {
          if (card.forgeUpgrades.isNotEmpty) {
            carried.add(card.forgeUpgrades.join(','));
          }
        }
      }

      expect(carried, {'quick:1'});
    });

    // D28, D3, D48 : une pre-forgee porte au plus `fusionRank` runes,
    // distinctes, eligibles au rang de sa rarete (spec P-43 E2, §4.9, §8).
    test('une pre-forgee porte au plus fusionRank runes, distinctes, et jamais '
        'Econome ni Veloce sous la rare', () {
      addTearDown(
        () => GameDataRegistry(
          enemies: const [],
          heroes: const [],
          cards: const [],
          events: const [],
          passives: const [],
          relics: const [],
          forgeUpgrades: const [],
        ),
      );
      shippedRuneRegistry(shippedRuneIds());
      final cards = shippedNeutralCards();
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      var runed = 0;
      var rareOrAbove = 0;
      for (var i = 0; i < 300; i++) {
        shopController.initializeShop(cards, 0);
        for (final card in shopController.state.cardsForSale) {
          if (card.rarity.fusionRank >= 2) rareOrAbove++;
          final ids = [
            for (final ref in card.forgeUpgrades)
              ForgeUpgradeData.parseRef(ref)!.$1,
          ];
          final reason = '${card.data.id} ${card.rarity.name} : '
              '${card.forgeUpgrades}';
          // Une commune, de rang 0, n'en porte aucune.
          expect(ids.length, lessThanOrEqualTo(card.rarity.fusionRank),
              reason: reason);
          expect(ids.toSet(), hasLength(ids.length), reason: reason);
          if (card.rarity.fusionRank < 2) {
            expect(ids, isNot(contains('eco')), reason: reason);
            expect(ids, isNot(contains('quick')), reason: reason);
          }
          if (ids.isNotEmpty) runed++;
        }
      }
      // Gardes contre un test qui passerait a vide : des cartes runees, et
      // des cartes de rang 2 au moins, ou la borne et Econome s'eprouvent.
      expect(runed, greaterThan(0));
      expect(rareOrAbove, greaterThan(0));
    });

    // Le tirage de la fusion, sans ciblage par rarete (D68 ; spec P-43 E2,
    // A12, §4.9) : une peu commune recoit l'une ou l'autre rune.
    test('une pre-forgee tire parmi toutes les runes eligibles, a leur poids',
        () {
      addTearDown(
        () => GameDataRegistry(
          enemies: const [],
          heroes: const [],
          cards: const [],
          events: const [],
          passives: const [],
          relics: const [],
          forgeUpgrades: const [],
        ),
      );
      GameDataRegistry(
        enemies: const [],
        heroes: const [],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [
          ForgeUpgradeData(
            id: 'alpha',
            nameEn: 'Alpha',
            nameFr: 'Alpha',
            descriptionEn: '',
            descriptionFr: '',
            icon: '',
            color: '',
            pools: ['rare'],
          ),
          ForgeUpgradeData(
            id: 'beta',
            nameEn: 'Beta',
            nameFr: 'Beta',
            descriptionEn: '',
            descriptionFr: '',
            icon: '',
            color: '',
            pools: ['common'],
          ),
        ],
      );
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      final onUncommon = <String>{};
      for (var i = 0; i < 300; i++) {
        shopController.initializeShop(testCardPool, 0);
        for (final card in shopController.state.cardsForSale) {
          if (card.rarity != CardRarity.uncommon) continue;
          onUncommon.addAll([
            for (final ref in card.forgeUpgrades)
              ForgeUpgradeData.parseRef(ref)!.$1,
          ]);
        }
      }

      expect(onUncommon, {'alpha', 'beta'});
    });

    group('filtre de classe sur le pool de boutique', () {
      const mageHero = HeroData(
        id: 'mage',
        nameEn: 'Mage',
        nameFr: 'Mage',
        classCard: 'mage.png',
        maxHp: 80,
        maxMana: 4,
        luck: 0,
        mastery: 0,
      );

      CardData signature(String heroClassId) => CardData(
            id: 'signature_$heroClassId',
            cost: 2,
            type: CardType.attack,
            category: CardCategory.characterSpecific,
            heroClass: heroClassId,
            rarity: CardRarity.rare,
            target: CardTarget.singleEnemy,
            effects: const [],
          );

      final mixedPool = [
        ...testCardPool,
        signature('mage'),
        signature('paladin'),
        signature('berserker'),
      ];

      test('la boutique d un mage ne propose jamais la signature d une autre classe', () {
        runController.startNewRun(mageHero);

        final offered = <String>{};
        for (var i = 0; i < 200; i++) {
          shopController.initializeShop(mixedPool, 0);
          offered.addAll(shopController.state.cardsForSale.map((c) => c.data.id));
        }

        expect(offered, isNot(contains('signature_paladin')));
        expect(offered, isNot(contains('signature_berserker')));
      });

      test('la boutique d un mage propose bien sa propre signature', () {
        runController.startNewRun(mageHero);

        final offered = <String>{};
        for (var i = 0; i < 200; i++) {
          shopController.initializeShop(mixedPool, 0);
          offered.addAll(shopController.state.cardsForSale.map((c) => c.data.id));
        }

        expect(offered, contains('signature_mage'));
      });
    });
  });
}
