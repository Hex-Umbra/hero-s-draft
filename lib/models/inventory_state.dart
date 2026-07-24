import 'data/relic_data.dart';
import 'missing_save_item.dart';

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

  Map<String, dynamic> toJson() => {
        'gold': gold,
        'relics': relics
            .map((r) => {'id': r.id, 'nameFr': r.nameFr, 'nameEn': r.nameEn})
            .toList(),
        'bonusShopCards': bonusShopCards,
      };

  static (InventoryState, List<MissingSaveItem>) fromJsonWithReport(
    Map<String, dynamic> json,
  ) {
    final missing = <MissingSaveItem>[];
    final relics = <RelicData>[];

    for (final entry in (json['relics'] as List<dynamic>? ?? const [])) {
      final map = entry as Map<String, dynamic>;
      final id = map['id'] as String;
      final relic = RelicData.getById(id);
      if (relic != null) {
        relics.add(relic);
      } else {
        missing.add(
          MissingSaveItem(
            id: id,
            nameFr: map['nameFr'] as String? ?? id,
            nameEn: map['nameEn'] as String? ?? id,
            category: 'relic',
          ),
        );
      }
    }

    return (
      InventoryState(
        gold: json['gold'] as int? ?? 0,
        relics: relics,
        bonusShopCards: json['bonusShopCards'] as int? ?? 0,
      ),
      missing,
    );
  }
}
