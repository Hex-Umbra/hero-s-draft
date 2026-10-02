import 'package:uuid/uuid.dart';
import 'data/card_data.dart';
import 'effective_card.dart';

class CardInstance {
  final String uniqueId;
  final CardData data;
  final CardRarity rarity;
  final List<String> forgeUpgrades;

  CardInstance({
    String? uniqueId,
    required this.data,
    CardRarity? rarity,
    List<String>? forgeUpgrades,
  })  : uniqueId = uniqueId ?? const Uuid().v4(),
        rarity = rarity ?? data.rarity,
        forgeUpgrades = forgeUpgrades != null
            ? List<String>.unmodifiable(forgeUpgrades)
            : const <String>[];

  /// Le coût que la carte demande, ses runes appliquées (spec P-43 E2,
  /// §4.2).
  int get currentCost => effective.cost;

  /// La carte telle qu'elle se joue — sa rareté et ses runes appliquées, sur
  /// le catalogue du registre (spec P-43 E1, §4.2).
  EffectiveCard get effective =>
      EffectiveCard.withRunes(data, rarity, forgeUpgrades);

  /// La carte est-elle épuisée une fois jouée ? Un pouvoir l'est toujours ;
  /// une carte qu'une rune épuise aussi (`addExhaust`, D33), même si une
  /// autre lève l'épuisement (spec P-43 E2, A10) ; une carte `isExhaust` l'est
  /// sauf si une de ses runes lève l'épuisement, **quel que soit son niveau**
  /// (ADR-094 D4) : c'est la donnée de la rune qui le dit, plus son id.
  bool get exhaustsOnPlay {
    if (data.type == CardType.power) return true;
    final effective = this.effective;
    return effective.addsExhaust ||
        (data.isExhaust && !effective.removesExhaust);
  }
  CardInstance copyWith({
    String? uniqueId,
    CardData? data,
    CardRarity? rarity,
    List<String>? forgeUpgrades,
  }) {
    return CardInstance(
      uniqueId: uniqueId ?? this.uniqueId,
      data: data ?? this.data,
      rarity: rarity ?? this.rarity,
      forgeUpgrades: forgeUpgrades ?? this.forgeUpgrades,
    );
  }

  factory CardInstance.fromJson(Map<String, dynamic> json) {
    return CardInstance(
      uniqueId: json['uniqueId'] as String?,
      data: CardData.fromJson(json['data'] as Map<String, dynamic>),
      rarity: CardRarity.values.firstWhere((e) => e.name == json['rarity']),
      forgeUpgrades: (json['forgeUpgrades'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uniqueId': uniqueId,
        'data': data.toJson(),
        'rarity': rarity.name,
        'forgeUpgrades': forgeUpgrades,
      };
}
