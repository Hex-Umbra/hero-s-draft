import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/shop_state.dart';
import '../../models/data/card_data.dart';
import '../../models/card_instance.dart';
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
    return allCards
        .where((c) =>
            c.type != CardType.status &&
            c.rarity != CardRarity.unique)
        .toList();
  }

  /// Helper pour obtenir les upgrades éligibles selon le pool de rareté et le type de carte
  List<String> _getEligibleUpgradesForPool(CardInstance card, String poolName, List<String> currentRolls) {
    List<String> poolUpgrades;
    if (poolName == 'common') {
      poolUpgrades = ['sharp', 'hardened', 'burning', 'freezing', 'shocking'];
    } else if (poolName == 'uncommon') {
      poolUpgrades = [
        'sharp',
        'hardened',
        'burning',
        'freezing',
        'shocking',
        'quick',
      ];
    } else {
      // rare
      poolUpgrades = [
        'sharp',
        'hardened',
        'burning',
        'freezing',
        'shocking',
        'quick',
        'eco',
        'enduring',
      ];
    }

    final eligible = <String>[];
    for (final id in poolUpgrades) {
      final alreadyHas = card.forgeUpgrades.any((u) => u.split(':')[0] == id) ||
          currentRolls.any((u) => u.split(':')[0] == id);
      if (alreadyHas) continue;

      // Exclusions spécifiques au type de carte:
      if (card.data.type == CardType.skill) {
        if (id == 'sharp' || id == 'burning' || id == 'freezing' || id == 'shocking') {
          continue;
        }
      }
      if (card.data.type == CardType.power) {
        if (id != 'eco' && id != 'quick' && id != 'enduring') {
          continue;
        }
      }

      if ((id == 'burning' || id == 'freezing' || id == 'shocking') &&
          card.data.type != CardType.attack) {
        continue;
      }
      if (id == 'enduring' && !card.data.isExhaust) {
        continue;
      }

      eligible.add(id);
    }
    return eligible;
  }

  /// Helper privé pour tirer un ID d'upgrade aléatoire compatible
  String? _rollUpgradeId(CardInstance card, Random rand, List<String> excludedIdsInCurrentRolls) {
    final r = rand.nextInt(100);
    String targetPool;
    if (card.rarity == CardRarity.common) {
      targetPool = 'common';
    } else if (card.rarity == CardRarity.uncommon) {
      targetPool = r < 75 ? 'common' : 'uncommon';
    } else {
      targetPool = r < 65 ? 'common' : (r < 90 ? 'uncommon' : 'rare');
    }

    List<String> poolOrder = ['rare', 'uncommon', 'common'];
    int startIndex = poolOrder.indexOf(targetPool);
    if (startIndex == -1) startIndex = 2;

    for (int i = startIndex; i < poolOrder.length; i++) {
      final pool = poolOrder[i];
      final eligible = _getEligibleUpgradesForPool(card, pool, excludedIdsInCurrentRolls);
      if (eligible.isNotEmpty) {
        return eligible[rand.nextInt(eligible.length)];
      }
    }

    for (final pool in poolOrder) {
      final eligible = _getEligibleUpgradesForPool(card, pool, excludedIdsInCurrentRolls);
      if (eligible.isNotEmpty) {
        return eligible[rand.nextInt(eligible.length)];
      }
    }
    return null;
  }

  /// Helper privé pour générer un upgrade de forge aléatoire avec son tier
  String _rollRandomUpgrade(CardInstance card, List<String> existingUpgrades, Random rng) {
    final excludedIds = existingUpgrades.map((u) => u.split(':')[0]).toList();
    String? rolledId = _rollUpgradeId(card, rng, excludedIds);
    rolledId ??= _rollUpgradeId(card, rng, []);
    rolledId ??= 'sharp';

    int tier = 1;
    if (rolledId != 'enduring') {
      final t = rng.nextInt(100);
      if (t < 80) {
        tier = 1;
      } else if (t < 95) {
        tier = 2;
      } else {
        tier = 3;
      }
    }
    return '$rolledId:$tier';
  }

  /// Helper pour tirer la rareté finale d'une carte selon l'acte
  CardRarity _rollRarity(CardRarity baseRarity, int act, Random rng) {
    if (baseRarity == CardRarity.unique) return baseRarity;

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

    if (increase == 0) return baseRarity;

    final rarities = CardRarity.values;
    int baseIndex = rarities.indexOf(baseRarity);
    int targetIndex = baseIndex + increase;

    int maxIndex = rarities.indexOf(CardRarity.legendary);
    if (targetIndex > maxIndex) {
      targetIndex = maxIndex;
    }

    return rarities[targetIndex];
  }

  /// Helper privé réalisant la génération complète d'une instance de carte pour la boutique
  CardInstance _generateShopCardInstance(CardData data, int act, Random rng) {
    final finalRarity = _rollRarity(data.rarity, act, rng);

    var instance = CardInstance(
      data: data,
      rarity: finalRarity,
    );

    final int rarityIndex = CardRarity.values.indexOf(finalRarity);
    final int maxUpgrades = data.baseMaxForgeUpgrades + rarityIndex;

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

    if (upgradesToRoll > 0) {
      final List<String> upgrades = [];
      for (int i = 0; i < upgradesToRoll; i++) {
        final newUpgrade = _rollRandomUpgrade(instance, upgrades, rng);
        upgrades.add(newUpgrade);
      }
      instance = instance.copyWith(forgeUpgrades: upgrades);
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
