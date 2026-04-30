class EnemyData {
  final String id;
  final String name;
  final int maxHp;
  final int baseDamage;
  final String spritePath;

  const EnemyData({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.baseDamage,
    required this.spritePath,
  });

  factory EnemyData.fromJson(Map<String, dynamic> json) {
    return EnemyData(
      id: json['id'] as String,
      name: json['name'] as String,
      maxHp: json['maxHp'] as int,
      baseDamage: json['baseDamage'] as int,
      spritePath: json['spritePath'] as String,
    );
  }
}
