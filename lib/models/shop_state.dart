import '../../models/data/card_data.dart';
import 'card_instance.dart';

class ShopState {
  final List<CardData> cardsForSale;
  final bool purchasedHeal;
  final List<CardInstance> cloneOptions;

  const ShopState({
    this.cardsForSale = const [],
    this.purchasedHeal = false,
    this.cloneOptions = const [],
  });

  ShopState copyWith({
    List<CardData>? cardsForSale,
    bool? purchasedHeal,
    List<CardInstance>? cloneOptions,
  }) {
    return ShopState(
      cardsForSale: cardsForSale ?? this.cardsForSale,
      purchasedHeal: purchasedHeal ?? this.purchasedHeal,
      cloneOptions: cloneOptions ?? this.cloneOptions,
    );
  }
}
