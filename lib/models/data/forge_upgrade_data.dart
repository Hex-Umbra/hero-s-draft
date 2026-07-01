import 'game_data_registry.dart';

class ForgeUpgradeData {
  final String id;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final String icon;
  final String color;
  final List<String> pools;
  final List<String>? eligibleCardTypes;
  final bool requiresExhaust;
  final int valueMultiplier;
  final int weight;
  final String emoji;

  const ForgeUpgradeData({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.icon,
    required this.color,
    required this.pools,
    this.eligibleCardTypes,
    this.requiresExhaust = false,
    this.valueMultiplier = 1,
    this.weight = 10,
    this.emoji = '🔮',
  });

  factory ForgeUpgradeData.fromJson(Map<String, dynamic> json) {
    return ForgeUpgradeData(
      id: json['id'] as String,
      nameEn: json['name_en'] as String? ?? '',
      nameFr: json['name_fr'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      descriptionFr: json['description_fr'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      color: json['color'] as String? ?? '',
      pools: List<String>.from(json['pools'] as List? ?? []),
      eligibleCardTypes: json['eligibleCardTypes'] != null
          ? List<String>.from(json['eligibleCardTypes'] as List)
          : null,
      requiresExhaust: json['requiresExhaust'] as bool? ?? false,
      valueMultiplier: json['valueMultiplier'] as int? ?? 1,
      weight: json['weight'] as int? ?? 10,
      emoji: json['emoji'] as String? ?? '🔮',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_fr': nameFr,
      'description_en': descriptionEn,
      'description_fr': descriptionFr,
      'icon': icon,
      'color': color,
      'pools': pools,
      if (eligibleCardTypes != null) 'eligibleCardTypes': eligibleCardTypes,
      'requiresExhaust': requiresExhaust,
      'valueMultiplier': valueMultiplier,
      'weight': weight,
      'emoji': emoji,
    };
  }

  String getName(String locale) {
    return locale == 'fr' ? nameFr : nameEn;
  }

  String getDescription(int tier, String locale) {
    final template = locale == 'fr' ? descriptionFr : descriptionEn;
    final val = tier * valueMultiplier;
    return template
        .replaceAll('{tier}', tier.toString())
        .replaceAll('{val}', val.toString());
  }

  static ForgeUpgradeData? getById(String id) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return null;
    try {
      return registry.forgeUpgrades.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }
}
