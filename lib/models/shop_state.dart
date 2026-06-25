import 'card_instance.dart';

class ShopState {
  final List<CardInstance> cardsForSale;
  final bool purchasedHeal;
  final List<CardInstance> cloneOptions;
  final int clonePurchasedCount;

  const ShopState({
    this.cardsForSale = const [],
    this.purchasedHeal = false,
    this.cloneOptions = const [],
    this.clonePurchasedCount = 0,
  });

  int get clonePrice => 150 << clonePurchasedCount;

  ShopState copyWith({
    List<CardInstance>? cardsForSale,
    bool? purchasedHeal,
    List<CardInstance>? cloneOptions,
    int? clonePurchasedCount,
  }) {
    return ShopState(
      cardsForSale: cardsForSale ?? this.cardsForSale,
      purchasedHeal: purchasedHeal ?? this.purchasedHeal,
      cloneOptions: cloneOptions ?? this.cloneOptions,
      clonePurchasedCount: clonePurchasedCount ?? this.clonePurchasedCount,
    );
  }

  factory ShopState.fromJson(Map<String, dynamic> json) {
    return ShopState(
      cardsForSale: (json['cardsForSale'] as List<dynamic>?)
              ?.map((e) => CardInstance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      purchasedHeal: json['purchasedHeal'] as bool? ?? false,
      cloneOptions: (json['cloneOptions'] as List<dynamic>?)
              ?.map((e) => CardInstance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      clonePurchasedCount: json['clonePurchasedCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'cardsForSale': cardsForSale.map((e) => e.toJson()).toList(),
        'purchasedHeal': purchasedHeal,
        'cloneOptions': cloneOptions.map((e) => e.toJson()).toList(),
        'clonePurchasedCount': clonePurchasedCount,
      };
}
