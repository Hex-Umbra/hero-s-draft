import 'data/relic_data.dart';

class InventoryState {
  final int gold;
  final List<RelicData> relics;
  final int bonusShopCards;

  const InventoryState({
    this.gold = 0,
    this.relics = const [],
    this.bonusShopCards = 0,
  });

  InventoryState copyWith({
    int? gold,
    List<RelicData>? relics,
    int? bonusShopCards,
  }) {
    return InventoryState(
      gold: gold ?? this.gold,
      relics: relics ?? this.relics,
      bonusShopCards: bonusShopCards ?? this.bonusShopCards,
    );
  }
}
