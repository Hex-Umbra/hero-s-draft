class SkillData {
  final String id;
  final String name;
  final int manaCost;
  final String effectType;
  final int effectValue;

  const SkillData({
    required this.id,
    required this.name,
    required this.manaCost,
    required this.effectType,
    required this.effectValue,
  });

  factory SkillData.fromJson(Map<String, dynamic> json) {
    return SkillData(
      id: json['id'] as String,
      name: json['name'] as String,
      manaCost: json['manaCost'] as int,
      effectType: json['effectType'] as String,
      effectValue: json['effectValue'] as int,
    );
  }
}
