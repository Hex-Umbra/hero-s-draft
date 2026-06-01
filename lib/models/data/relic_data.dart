enum RelicTrigger {
  startOfRun,
  startOfCombat,
  startOfTurn,
  endOfTurn,
  onCardPlayed,
  onEnemyKilled,
}

enum RelicRarity { common, uncommon, rare, epic, legendary }

class RelicData {
  final String id;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final RelicTrigger trigger;
  final String effectType; // ex: 'gain_energy', 'gain_strength', 'heal_on_kill'
  final int value;
  final RelicRarity rarity;
  final String emoji;

  const RelicData({
    required this.id,
    this.nameEn = '',
    this.nameFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    required this.trigger,
    required this.effectType,
    required this.value,
    required this.rarity,
    required this.emoji,
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;
  String getDescription(String locale) =>
      locale == 'fr' ? descriptionFr : descriptionEn;

  factory RelicData.fromJson(Map<String, dynamic> json) {
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

    return RelicData(
      id: json['id'] as String,
      nameEn: nEn,
      nameFr: nFr,
      descriptionEn: dEn,
      descriptionFr: dFr,
      trigger: RelicTrigger.values.firstWhere((e) => e.name == json['trigger']),
      effectType: json['effectType'] as String,
      value: json['value'] as int,
      rarity: RelicRarity.values.firstWhere((e) => e.name == json['rarity']),
      emoji: json['emoji'] as String? ?? '🪙',
    );
  }
}
