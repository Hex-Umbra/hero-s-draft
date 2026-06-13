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

  /// Helper pour calculer le prix d'une carte selon sa rareté
  static int getCardPrice(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return 25;
      case CardRarity.uncommon:
        return 50;
      case CardRarity.rare:
      case CardRarity.epic:
      case CardRarity.legendary:
        return 100;
      case CardRarity.unique:
        return 999;
    }
  }

  List<CardData> _getEligibleCards(List<CardData> allCards) {
    return allCards
        .where((c) =>
            c.type != CardType.status &&
            c.rarity != CardRarity.unique)
        .toList();
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

    state = ShopState(
      cardsForSale: shuffled.take(count).toList(),
      purchasedHeal: false,
    );
  }

  /// Achète une carte spécifique de la boutique
  bool buyCard(CardData card, int price) {
    final inventoryController = ref.read(inventoryProvider.notifier);
    final deckNotifier = ref.read(deckProvider.notifier);
    if (inventoryController.spendGold(price)) {
      state = state.copyWith(
        cardsForSale: state.cardsForSale.where((c) => c.id != card.id).toList(),
      );
      final instance = CardInstance(data: card);
      deckNotifier.addCardToMasterDeck(instance);
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
      final existingIds = state.cardsForSale.map((c) => c.id).toSet();
      final available = eligibleCards
          .where((c) => !existingIds.contains(c.id))
          .toList();

      if (available.isNotEmpty) {
        final rng = Random();
        final newCard = available[rng.nextInt(available.length)];
        state = state.copyWith(cardsForSale: [...state.cardsForSale, newCard]);
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

      state = state.copyWith(cardsForSale: shuffled.take(count).toList());
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

  /// Duplique une carte sélectionnée contre paiement
  bool cloneCard(int price, CardInstance card) {
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
      return true;
    }
    return false;
  }

  /// Définit les options persistantes pour le clonage de cartes
  void setCloneOptions(List<CardInstance> options) {
    state = state.copyWith(cloneOptions: options);
  }

  /// Nettoie les options de clonage
  void clearCloneOptions() {
    state = state.copyWith(cloneOptions: const []);
  }
}

final shopProvider = NotifierProvider<ShopController, ShopState>(ShopController.new);
