import 'package:uuid/uuid.dart';
import '../data/models/entity_stats.dart';
import 'data/enemy_data.dart';
import 'enemy_intent.dart';

class EnemyInstance {
  final String id;
  final EnemyData data;
  final EntityStats stats;
  final EnemyIntent? currentIntent;
  final int intentStep;
  final bool isBoss;

  EnemyInstance({
    String? id,
    required this.data,
    required this.stats,
    this.currentIntent,
    this.intentStep = 0,
    this.isBoss = false,
  }) : id = id ?? const Uuid().v4();

  EnemyInstance copyWith({
    String? id,
    EnemyData? data,
    EntityStats? stats,
    EnemyIntent? currentIntent,
    int? intentStep,
    bool? isBoss,
    bool clearIntent = false,
  }) {
    return EnemyInstance(
      id: id ?? this.id,
      data: data ?? this.data,
      stats: stats ?? this.stats,
      currentIntent: clearIntent ? null : (currentIntent ?? this.currentIntent),
      intentStep: intentStep ?? this.intentStep,
      isBoss: isBoss ?? this.isBoss,
    );
  }

  factory EnemyInstance.fromJson(Map<String, dynamic> json) {
    return EnemyInstance(
      id: json['id'] as String,
      data: EnemyData.fromJson(json['data'] as Map<String, dynamic>),
      stats: EntityStats.fromJson(json['stats'] as Map<String, dynamic>),
      currentIntent: json['currentIntent'] != null
          ? EnemyIntent.fromJson(json['currentIntent'] as Map<String, dynamic>)
          : null,
      intentStep: json['intentStep'] as int? ?? 0,
      isBoss: json['isBoss'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': {
          'id': data.id,
          'name': data.name,
          'maxHp': data.maxHp,
          'baseDamage': data.baseDamage,
          'spritePath': data.spritePath,
          'tier': data.tier,
          'intents': data.intents?.map((i) => i.toJson()).toList(),
        },
        'stats': stats.toJson(),
        'currentIntent': currentIntent?.toJson(),
        'intentStep': intentStep,
        'isBoss': isBoss,
      };
}
