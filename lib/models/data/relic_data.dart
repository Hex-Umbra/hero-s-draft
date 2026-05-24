enum RelicTrigger {
  startOfRun,
  startOfCombat,
  startOfTurn,
  endOfTurn,
  onCardPlayed,
  onEnemyKilled,
}

enum RelicRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class RelicData {
  final String id;
  final String name;
  final String description;
  final RelicTrigger trigger;
  final String effectType; // ex: 'gain_energy', 'gain_strength', 'heal_on_kill'
  final int value;
  final RelicRarity rarity;
  final String emoji;

  const RelicData({
    required this.id,
    required this.name,
    required this.description,
    required this.trigger,
    required this.effectType,
    required this.value,
    required this.rarity,
    required this.emoji,
  });

  factory RelicData.fromJson(Map<String, dynamic> json) {
    return RelicData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      trigger: RelicTrigger.values.firstWhere((e) => e.name == json['trigger']),
      effectType: json['effectType'] as String,
      value: json['value'] as int,
      rarity: RelicRarity.values.firstWhere((e) => e.name == json['rarity']),
      emoji: json['emoji'] as String? ?? '🪙',
    );
  }
}
