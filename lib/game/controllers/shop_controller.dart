import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/shop_state.dart';
import '../../models/data/card_data.dart';
import '../../models/card_instance.dart';
import 'run_controller.dart';
import 'deck_controller.dart';

class ShopController extends StateNotifier<ShopState> {
  ShopController() : super(const ShopState());

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
    }
  }

  /// Initialise la boutique avec une sélection aléatoire de cartes de jeu
  void initializeShop(List<CardData> allCards, int bonusShopCards) {
    final List<CardData> eligibleCards = allCards
        .where((c) => c.type != CardType.status)
        .toList();

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
  bool buyCard(
    CardData card,
    int price,
    RunController runController,
    DeckNotifier deckNotifier,
  ) {
    if (runController.spendGold(price)) {
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
  bool buyHeal(
    int price,
    int amount,
    RunController runController,
  ) {
    if (state.purchasedHeal) return false;

    if (runController.spendGold(price)) {
      runController.heal(amount);
      state = state.copyWith(purchasedHeal: true);
      return true;
    }
    return false;
  }

  /// Achète une expansion de boutique pour ajouter une carte au stock
  bool expandShop(
    int price,
    List<CardData> allCards,
    RunController runController,
  ) {
    if (runController.spendGold(price)) {
      runController.buyShopExpansion();

      final eligibleCards = allCards
          .where((c) => c.type != CardType.status)
          .toList();
      final existingIds = state.cardsForSale.map((c) => c.id).toSet();
      final available = eligibleCards.where((c) => !existingIds.contains(c.id)).toList();

      if (available.isNotEmpty) {
        final rng = Random();
        final newCard = available[rng.nextInt(available.length)];
        state = state.copyWith(
          cardsForSale: [...state.cardsForSale, newCard],
        );
      }
      return true;
    }
    return false;
  }

  /// Renouvelle l'ensemble des cartes en vente contre paiement
  bool rerollCards(
    int price,
    List<CardData> allCards,
    int bonusShopCards,
    RunController runController,
  ) {
    if (runController.spendGold(price)) {
      final eligibleCards = allCards
          .where((c) => c.type != CardType.status)
          .toList();

      if (eligibleCards.isEmpty) return true;

      final rng = Random();
      final List<CardData> shuffled = List.from(eligibleCards)..shuffle(rng);
      final count = min(shuffled.length, 3 + bonusShopCards);

      state = state.copyWith(
        cardsForSale: shuffled.take(count).toList(),
      );
      return true;
    }
    return false;
  }

  /// Retire définitivement une carte du deck contre paiement
  bool purgeCard(
    int price,
    CardInstance card,
    RunController runController,
    DeckNotifier deckNotifier,
  ) {
    if (runController.spendGold(price)) {
      deckNotifier.removeCardFromMasterDeck(card);
      return true;
    }
    return false;
  }

  /// Duplique une carte sélectionnée contre paiement
  bool cloneCard(
    int price,
    CardInstance card,
    RunController runController,
    DeckNotifier deckNotifier,
  ) {
    if (runController.spendGold(price)) {
      deckNotifier.addCardToMasterDeck(
        CardInstance(data: card.data, level: card.level),
      );
      return true;
    }
    return false;
  }
}

final shopProvider = StateNotifierProvider<ShopController, ShopState>((ref) {
  return ShopController();
});
