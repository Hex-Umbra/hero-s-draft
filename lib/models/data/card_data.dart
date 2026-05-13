enum CardType { attack, skill, power, status }

enum CardCategory { global, characterSpecific }

enum CardRarity { common, uncommon, rare, epic }

enum CardTarget { singleEnemy, allEnemies, self, none }

class CardEffect {
  final String type;
  final int value;
  final String? statusId;
  final int? duration;

  const CardEffect({
    required this.type,
    required this.value,
    this.statusId,
    this.duration,
  });

  factory CardEffect.fromJson(Map<String, dynamic> json) {
    return CardEffect(
      type: json['type'] as String,
      value: json['value'] as int,
      statusId: json['statusId'] as String?,
      duration: json['duration'] as int?,
    );
  }
}

class CardData {
  final String id;
  final String name;
  final String description;
  final int cost;
  final CardType type;
  final CardCategory category;
  final String? heroClass;
  final CardRarity rarity;
  final CardTarget target;
  final String? spritePath;
  final String? animation; // Type d'animation (ex: 'melee', 'magic', 'buff')
  final List<CardEffect> effects;

  const CardData({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.type,
    required this.category,
    this.heroClass,
    required this.rarity,
    required this.target,
    this.spritePath,
    this.animation,
    required this.effects,
  });

  factory CardData.fromJson(Map<String, dynamic> json) {
    return CardData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      cost: json['cost'] as int,
      type: CardType.values.firstWhere((e) => e.name == json['type']),
      category: CardCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => CardCategory.global,
      ),
      heroClass: json['heroClass'] as String?,
      rarity: CardRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => CardRarity.common,
      ),
      target: CardTarget.values.firstWhere(
        (e) => e.name == json['target'],
        orElse: () => CardTarget.singleEnemy,
      ),
      spritePath: json['spritePath'] as String?,
      animation: json['animation'] as String?,
      effects:
          (json['effects'] as List<dynamic>?)
              ?.map((e) => CardEffect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
