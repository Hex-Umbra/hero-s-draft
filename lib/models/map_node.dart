import 'package:flame/extensions.dart';

enum MapNodeType { combat, elite, shop, rest, event, boss, relicExchange, forgeFusion }

enum BossRewardType { cards, doubleXp, improvedRelic }

class MapNode {
  final String id;
  final int floor;
  MapNodeType type;
  final List<String> connections;
  final Vector2 position;
  bool isCompleted;
  final String? bossEnemyId;
  final BossRewardType? bossRewardType;
  MapNodeType? originalType;

  MapNode({
    required this.id,
    required this.floor,
    required this.type,
    required this.connections,
    required this.position,
    this.isCompleted = false,
    this.bossEnemyId,
    this.bossRewardType,
    this.originalType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'floor': floor,
      'type': type.name,
      'connections': connections,
      'position': [position.x, position.y],
      'isCompleted': isCompleted,
      'bossEnemyId': bossEnemyId,
      'bossRewardType': bossRewardType?.name,
      'originalType': originalType?.name,
    };
  }

  factory MapNode.fromJson(Map<String, dynamic> json) {
    return MapNode(
      id: json['id'] as String,
      floor: json['floor'] as int? ?? int.parse((json['id'] as String).split('_')[1]),
      type: MapNodeType.values.firstWhere((e) => e.name == json['type']),
      connections: List<String>.from(json['connections'] as List),
      position: Vector2(
        (json['position'] as List)[0] as double,
        (json['position'] as List)[1] as double,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      bossEnemyId: json['bossEnemyId'] as String?,
      bossRewardType: json['bossRewardType'] == null
          ? null
          : BossRewardType.values.firstWhere((e) => e.name == json['bossRewardType']),
      originalType: json['originalType'] == null
          ? null
          : MapNodeType.values.firstWhere((e) => e.name == json['originalType']),
    );
  }
}

