import '../../models/data/card_data.dart';

class ShopState {
  final List<CardData> cardsForSale;
  final bool purchasedHeal;

  const ShopState({
    this.cardsForSale = const [],
    this.purchasedHeal = false,
  });

  ShopState copyWith({
    List<CardData>? cardsForSale,
    bool? purchasedHeal,
  }) {
    return ShopState(
      cardsForSale: cardsForSale ?? this.cardsForSale,
      purchasedHeal: purchasedHeal ?? this.purchasedHeal,
    );
  }
}
