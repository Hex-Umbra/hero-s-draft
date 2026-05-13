import 'package:flame/extensions.dart';

enum MapNodeType { combat, elite, shop, rest, event, boss }

class MapNode {
  final String id;
  final MapNodeType type;
  final List<String> connections;
  final Vector2 position;
  bool isCompleted;

  MapNode({
    required this.id,
    required this.type,
    required this.connections,
    required this.position,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'connections': connections,
      'position': [position.x, position.y],
      'isCompleted': isCompleted,
    };
  }

  factory MapNode.fromJson(Map<String, dynamic> json) {
    return MapNode(
      id: json['id'] as String,
      type: MapNodeType.values.firstWhere((e) => e.name == json['type']),
      connections: List<String>.from(json['connections'] as List),
      position: Vector2(
        (json['position'] as List)[0] as double,
        (json['position'] as List)[1] as double,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
