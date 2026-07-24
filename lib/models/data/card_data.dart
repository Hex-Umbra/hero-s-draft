import 'package:flutter/foundation.dart';
import 'game_data_registry.dart';

enum CardType { attack, skill, power, status }

enum CardCategory { global, characterSpecific }

enum CardRarity { common, uncommon, rare, epic, legendary, unique }

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

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
        if (statusId != null) 'statusId': statusId,
        if (duration != null) 'duration': duration,
      };
}

class CardData {
  final String id;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final int cost;
  final CardType type;
  final CardCategory category;
  final String? heroClass;
  final CardRarity rarity;
  final CardTarget target;
  final String? spritePath;
  final String? animation; // Type d'animation (ex: 'melee', 'magic', 'buff')
  final bool isExhaust;
  final List<CardEffect> effects;
  final int baseMaxForgeUpgrades;

  const CardData({
    required this.id,
    this.nameEn = '',
    this.nameFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    required this.cost,
    required this.type,
    required this.category,
    this.heroClass,
    required this.rarity,
    required this.target,
    this.spritePath,
    this.animation,
    this.isExhaust = false,
    required this.effects,
    this.baseMaxForgeUpgrades = 1,
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;
  String getDescription(String locale) =>
      locale == 'fr' ? descriptionFr : descriptionEn;

  factory CardData.fromJson(Map<String, dynamic> json) {
    final nEn = json['name_en'] as String? ?? json['name'] as String? ?? '';
    final nFr = json['name_fr'] as String? ?? json['name'] as String? ?? '';
    final dEn =
        json['description_en'] as String? ??
        json['description'] as String? ??
        '';
    final dFr =
        json['description_fr'] as String? ??
        json['description'] as String? ??
        '';

    return CardData(
      id: json['id'] as String,
      nameEn: nEn,
      nameFr: nFr,
      descriptionEn: dEn,
      descriptionFr: dFr,
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
      isExhaust: json['isExhaust'] as bool? ?? false,
      effects:
          (json['effects'] as List<dynamic>?)
              ?.map((e) => CardEffect.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      baseMaxForgeUpgrades: json['baseMaxForgeUpgrades'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_en': nameEn,
        'name_fr': nameFr,
        'description_en': descriptionEn,
        'description_fr': descriptionFr,
        'cost': cost,
        'type': type.name,
        'category': category.name,
        if (heroClass != null) 'heroClass': heroClass,
        'rarity': rarity.name,
        'target': target.name,
        if (spritePath != null) 'spritePath': spritePath,
        if (animation != null) 'animation': animation,
        'isExhaust': isExhaust,
        'effects': effects.map((e) => e.toJson()).toList(),
        'baseMaxForgeUpgrades': baseMaxForgeUpgrades,
      };

  static CardData? getById(String id) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return null;
    try {
      return registry.cards.firstWhere((c) => c.id == id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CardData.getById: no card found for id "$id" ($e)');
      }
      return null;
    }
  }
}
