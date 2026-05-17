class HeroData {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int maxHp;
  final int maxMana;
  final int baseDamage;
  final int luck;
  final String? passiveTrait;

  const HeroData({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.maxHp,
    required this.maxMana,
    required this.baseDamage,
    this.luck = 0,
    this.passiveTrait,
  });

  factory HeroData.fromJson(Map<String, dynamic> json) {
    return HeroData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconPath: json['iconPath'] as String,
      maxHp: json['maxHp'] as int,
      maxMana: json['maxMana'] as int,
      baseDamage: json['baseDamage'] as int,
      luck: json['luck'] as int? ?? 0,
      passiveTrait: json['passiveTrait'] as String?,
    );
  }
}
