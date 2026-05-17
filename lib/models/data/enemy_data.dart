import '../enemy_intent.dart';

class EnemyData {
  final String id;
  final String name;
  final int maxHp;
  final int baseDamage;
  final String spritePath;
  final int tier;
  final List<EnemyIntent>? intents;

  const EnemyData({
    required this.id,
    required this.name,
    required this.maxHp,
    required this.baseDamage,
    required this.spritePath,
    this.tier = 1,
    this.intents,
  });

  factory EnemyData.fromJson(Map<String, dynamic> json) {
    var intentsJson = json['intents'] as List?;
    List<EnemyIntent>? parsedIntents;
    if (intentsJson != null) {
      parsedIntents =
          intentsJson.map((e) => EnemyIntent.fromJson(e)).toList();
    }

    return EnemyData(
      id: json['id'] as String,
      name: json['name'] as String,
      maxHp: json['maxHp'] as int,
      baseDamage: json['baseDamage'] as int,
      spritePath: json['spritePath'] as String,
      tier: json['tier'] as int? ?? 1,
      intents: parsedIntents,
    );
  }
}
