import 'package:uuid/uuid.dart';
import 'data/card_data.dart';

class CardInstance {
  final String uniqueId;
  final CardData data;
  final CardRarity rarity;
  final List<String> forgeUpgrades;
  final int? temporaryCost;

  CardInstance({
    String? uniqueId,
    required this.data,
    CardRarity? rarity,
    List<String>? forgeUpgrades,
    this.temporaryCost,
  })  : uniqueId = uniqueId ?? const Uuid().v4(),
        rarity = rarity ?? data.rarity,
        forgeUpgrades = forgeUpgrades != null
            ? List<String>.unmodifiable(forgeUpgrades)
            : const <String>[];

  int get currentCost => temporaryCost ?? data.cost;

  double get rarityMultiplier {
    switch (rarity) {
      case CardRarity.common:
        return 1.0;
      case CardRarity.uncommon:
        return 1.2;
      case CardRarity.rare:
        return 1.4;
      case CardRarity.epic:
        return 1.6;
      case CardRarity.legendary:
        return 2.0;
      case CardRarity.unique:
        return 1.0;
    }
  }

  CardInstance copyWith({
    String? uniqueId,
    CardData? data,
    CardRarity? rarity,
    List<String>? forgeUpgrades,
    int? temporaryCost,
    bool clearTemporaryCost = false,
  }) {
    return CardInstance(
      uniqueId: uniqueId ?? this.uniqueId,
      data: data ?? this.data,
      rarity: rarity ?? this.rarity,
      forgeUpgrades: forgeUpgrades ?? this.forgeUpgrades,
      temporaryCost: clearTemporaryCost ? null : (temporaryCost ?? this.temporaryCost),
    );
  }
}
