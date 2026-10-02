import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/shop_state.dart';
import '../../models/data/card_data.dart';
import '../../models/data/game_data_registry.dart';
import '../../models/card_instance.dart';
import '../services/forge_rune_rules.dart';
import 'run_controller.dart';
import 'deck_controller.dart';
import 'inventory_controller.dart';

class ShopController extends Notifier<ShopState> {
  @override
  ShopState build() {
    return const ShopState();
  }

  /// Helper pour calculer le prix d'une carte selon sa rareté et ses upgrades (+20 Or par upgrade)
  static int getCardPrice(CardInstance card) {
    int basePrice;
    switch (card.rarity) {
      case CardRarity.common:
        basePrice = 25;
        break;
      case CardRarity.uncommon:
        basePrice = 50;
        break;
      case CardRarity.rare:
        basePrice = 100;
        break;
      case CardRarity.epic:
        basePrice = 150;
        break;
      case CardRarity.legendary:
        basePrice = 200;
        break;
      case CardRarity.unique:
        basePrice = 999;
        break;
    }
    return basePrice + (card.forgeUpgrades.length * 20);
  }

  List<CardData> _getEligibleCards(List<CardData> allCards) {
    final heroClassId = ref.read(runProvider).heroClassId;
    return allCards.where((c) => c.isOfferableTo(heroClassId)).toList();
  }

  /// Tire une rune pour [card], qui porte déjà les runes tirées avant elle :
  /// une parmi celles que le prédicat accepte au rang de la carte, pondérées
  /// par `weight` — le tirage de la fusion (spec P-43 E2, A12, §4.9). `null`
  /// s'il ne lui en reste aucune : la carte en reçoit une de moins. Son niveau
  /// est tiré 80 · 15 · 5 %, puis borné par le plafond de la rune (D72) ; la
  /// carte n'en porte aucun niveau, le prédicat refusant une rune portée.
  String? _rollRandomUpgrade(CardInstance card, Random rng) {
    final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];
    final drawn = ForgeRuneRules.drawRunes(card, catalog, rng, count: 1);
    if (drawn.isEmpty) return null;
    final rune = catalog.firstWhere((r) => r.id == drawn.single);
    final roll = rng.nextInt(100);
    final tier = roll < 80 ? 1 : (roll < 95 ? 2 : 3);
    return '${rune.id}:${rune.boundLevel(tier)}';
  }

  /// Helper pour tirer la rareté finale d'une carte selon l'acte
  CardRarity _rollRarity(CardRarity baseRarity, int act, Random rng) {
    int increase = 0;
    final roll = rng.nextInt(100);
    if (act == 1) {
      if (roll < 10) {
        increase = 1;
      }
    } else if (act == 2) {
      if (roll < 25) {
        increase = 1;
      }
    } else {
      if (roll < 10) {
        increase = 2;
      } else if (roll < 50) {
        increase = 1;
      }
    }

    // Monte l'échelle marche par marche : elle s'arrête d'elle-même à
    // `legendary`, et une carte `unique`, hors échelle, ne monte pas.
    var rarity = baseRarity;
    for (var i = 0; i < increase; i++) {
      rarity = rarity.next ?? rarity;
    }
    return rarity;
  }

  /// Helper privé réalisant la génération complète d'une instance de carte pour la boutique
  CardInstance _generateShopCardInstance(CardData data, int act, Random rng) {
    final finalRarity = _rollRarity(data.rarity, act, rng);

    var instance = CardInstance(
      data: data,
      rarity: finalRarity,
    );

    // Une pré-forgée porte au plus autant de runes que sa rareté a demandé
    // de fusions — une commune n'en porte aucune (D28 ; spec P-43 E2, §4.9).
    final int maxUpgrades = finalRarity.fusionRank;

    int upgradesToRoll = 0;
    final rollUpgrade = rng.nextInt(100);
    if (act == 2) {
      if (rollUpgrade < 15) {
        upgradesToRoll = 1;
      }
    } else if (act >= 3) {
      if (rollUpgrade < 10) {
        upgradesToRoll = 2;
      } else if (rollUpgrade < 40) {
        upgradesToRoll = 1;
      }
    }

    if (upgradesToRoll > maxUpgrades) {
      upgradesToRoll = maxUpgrades;
    }

    for (int i = 0; i < upgradesToRoll; i++) {
      final newUpgrade = _rollRandomUpgrade(instance, rng);
      // Une carte à qui ne reste aucune rune éligible en reçoit moins (A12).
      if (newUpgrade == null) break;
      instance = instance.copyWith(
        forgeUpgrades: [...instance.forgeUpgrades, newUpgrade],
      );
    }

    return instance;
  }

  /// Initialise la boutique avec une sélection aléatoire de cartes de jeu
  void initializeShop(List<CardData> allCards, int bonusShopCards) {
    final List<CardData> eligibleCards = _getEligibleCards(allCards);

    if (eligibleCards.isEmpty) {
      state = const ShopState(cardsForSale: [], purchasedHeal: false);
      return;
    }

    final rng = Random();
    final List<CardData> shuffled = List.from(eligibleCards)..shuffle(rng);
    final count = min(shuffled.length, 3 + bonusShopCards);

    final int act = ref.read(runProvider).act;
    final List<CardInstance> generatedInstances = shuffled
        .take(count)
        .map((cardData) => _generateShopCardInstance(cardData, act, rng))
        .toList();

    state = ShopState(
      cardsForSale: generatedInstances,
      purchasedHeal: false,
      cloneOptions: const [],
      clonePurchasedCount: 0,
    );
  }

  /// Achète une carte spécifique de la boutique
  bool buyCard(CardInstance card, int price) {
    final inventoryController = ref.read(inventoryProvider.notifier);
    final deckNotifier = ref.read(deckProvider.notifier);
    if (inventoryController.spendGold(price)) {
      state = state.copyWith(
        cardsForSale: state.cardsForSale.where((c) => c.uniqueId != card.uniqueId).toList(),
      );
      deckNotifier.addCardToMasterDeck(card);
      return true;
    }
    return false;
  }

  /// Achète un soin dans la boutique
  bool buyHeal(int price, int amount) {
    if (state.purchasedHeal) return false;

    final inventoryController = ref.read(inventoryProvider.notifier);
    final runController = ref.read(runProvider.notifier);
    if (inventoryController.spendGold(price)) {
      runController.heal(amount);
      state = state.copyWith(purchasedHeal: true);
      return true;
    }
    return false;
  }

  /// Achète une expansion de boutique pour ajouter une carte au stock
  bool expandShop(int price, List<CardData> allCards) {
    final inventoryController = ref.read(inventoryProvider.notifier);
    if (inventoryController.spendGold(price)) {
      inventoryController.buyShopExpansion();

      final eligibleCards = _getEligibleCards(allCards);
      final existingIds = state.cardsForSale.map((c) => c.data.id).toSet();
      final available = eligibleCards
          .where((c) => !existingIds.contains(c.id))
          .toList();

      if (available.isNotEmpty) {
        final rng = Random();
        final newCardData = available[rng.nextInt(available.length)];
        final int act = ref.read(runProvider).act;
        final newInstance = _generateShopCardInstance(newCardData, act, rng);
        state = state.copyWith(cardsForSale: [...state.cardsForSale, newInstance]);
      }
      return true;
    }
    return false;
  }

  /// Renouvelle l'ensemble des cartes en vente contre paiement
  bool rerollCards(int price, List<CardData> allCards, int bonusShopCards) {
    final inventoryController = ref.read(inventoryProvider.notifier);
    if (inventoryController.spendGold(price)) {
      final eligibleCards = _getEligibleCards(allCards);

      if (eligibleCards.isEmpty) return true;

      final rng = Random();
      final List<CardData> shuffled = List.from(eligibleCards)..shuffle(rng);
      final count = min(shuffled.length, 3 + bonusShopCards);

      final int act = ref.read(runProvider).act;
      final List<CardInstance> generatedInstances = shuffled
          .take(count)
          .map((cardData) => _generateShopCardInstance(cardData, act, rng))
          .toList();

      state = state.copyWith(cardsForSale: generatedInstances);
      return true;
    }
    return false;
  }

  /// Retire définitivement une carte du deck contre paiement
  bool purgeCard(int price, CardInstance card) {
    final inventoryController = ref.read(inventoryProvider.notifier);
    final deckNotifier = ref.read(deckProvider.notifier);
    if (inventoryController.spendGold(price)) {
      deckNotifier.removeCardFromMasterDeck(card);
      return true;
    }
    return false;
  }

  /// Duplique une carte sélectionnée contre paiement (Miroir Magique)
  bool cloneCard(CardInstance card) {
    final price = state.clonePrice;
    final inventoryController = ref.read(inventoryProvider.notifier);
    final deckNotifier = ref.read(deckProvider.notifier);
    if (inventoryController.spendGold(price)) {
      deckNotifier.addCardToMasterDeck(
        CardInstance(
          data: card.data,
          rarity: card.rarity,
          forgeUpgrades: List.from(card.forgeUpgrades),
        ),
      );
      state = state.copyWith(
        clonePurchasedCount: state.clonePurchasedCount + 1,
      );
      return true;
    }
    return false;
  }

  /// Définit les options persistantes pour le clonage de cartes
  void setCloneOptions(List<CardInstance> options) {
    state = state.copyWith(cloneOptions: options);
  }

  /// Nettoie les options de clonage et réinitialise le coût du miroir à 0
  void clearCloneOptions() {
    state = state.copyWith(
      cloneOptions: const [],
      clonePurchasedCount: 0,
    );
  }
}

final shopProvider = NotifierProvider<ShopController, ShopState>(ShopController.new);
