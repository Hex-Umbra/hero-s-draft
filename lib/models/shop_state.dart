import 'card_instance.dart';

/// L'étal de la boutique, tiré une fois par nœud de boutique et retenu,
/// achats compris, jusqu'à ce que le nœud courant de la run change (spec P-43
/// E2, A11, §4.9).
class ShopState {
  final List<CardInstance> cardsForSale;
  final bool purchasedHeal;
  final List<CardInstance> cloneOptions;
  final int clonePurchasedCount;

  /// La copie d'une carte du deck (D46) : même rareté, sans ses runes ;
  /// `null` si le deck n'a aucune carte copiable, ou une fois achetée.
  final CardInstance? deckCopy;

  /// Le nœud courant de la run pour lequel l'étal a été tiré ; `null` sans
  /// nœud courant.
  final String? nodeId;

  const ShopState({
    this.cardsForSale = const [],
    this.purchasedHeal = false,
    this.cloneOptions = const [],
    this.clonePurchasedCount = 0,
    this.deckCopy,
    this.nodeId,
  });

  int get clonePrice => 150 << clonePurchasedCount;

  /// [removeDeckCopy] retire la copie du deck de l'étal, une fois achetée.
  ShopState copyWith({
    List<CardInstance>? cardsForSale,
    bool? purchasedHeal,
    List<CardInstance>? cloneOptions,
    int? clonePurchasedCount,
    bool removeDeckCopy = false,
  }) {
    return ShopState(
      cardsForSale: cardsForSale ?? this.cardsForSale,
      purchasedHeal: purchasedHeal ?? this.purchasedHeal,
      cloneOptions: cloneOptions ?? this.cloneOptions,
      clonePurchasedCount: clonePurchasedCount ?? this.clonePurchasedCount,
      deckCopy: removeDeckCopy ? null : deckCopy,
      nodeId: nodeId,
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
