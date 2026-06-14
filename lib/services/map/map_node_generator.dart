import 'dart:math';
import 'package:flame/extensions.dart';
import '../../models/map_node.dart';

class MapNodeGenerator {
  static MapNodeType getRandomNodeType(int floor, int totalFloors, Random random) {
    if (floor == 0) return MapNodeType.combat; // Start with combat

    double r = random.nextDouble();
    if (r < 0.6) return MapNodeType.combat; // 60% Combat
    if (r < 0.75) return MapNodeType.event; // 15% Event
    if (r < 0.85) return MapNodeType.shop; // 10% Shop
    if (r < 0.95) return MapNodeType.rest; // 10% Rest
    return MapNodeType.elite; // 5% Elite
  }

  static List<List<MapNode>> generateRawNodes({
    required int floors,
    required int maxWidth,
    required int middleFloor,
    required Random random,
  }) {
    List<List<MapNode>> nodesByFloor = [];

    for (int y = 0; y < floors; y++) {
      List<MapNode> floorNodes = [];
      int rowWidth = 2 + random.nextInt(maxWidth - 1); // 2 to maxWidth nodes

      // Special case: Chokepoint at middle floor
      if (y == middleFloor) {
        rowWidth = 1;
      }

      // Special case: Boss floor always has 3 nodes
      if (y == floors - 1) {
        rowWidth = 3;
      }

      for (int x = 0; x < rowWidth; x++) {
        final id = 'node_${y}_$x';
        MapNodeType type = getRandomNodeType(y, floors, random);
        String? bossEnemyId;
        BossRewardType? bossRewardType;

        // Force structure rules
        if (y == middleFloor) {
          // Chokepoint is always Elite
          type = MapNodeType.elite;
        } else if (y == floors - 2) {
          // Guaranteed Rest before boss
          type = MapNodeType.rest;
        } else if (y == floors - 1) {
          type = MapNodeType.boss;
          if (x == 0) {
            bossRewardType = BossRewardType.cards;
          } else if (x == 1) {
            bossRewardType = BossRewardType.doubleXp;
          } else if (x == 2) {
            bossRewardType = BossRewardType.improvedRelic;
          }
        }

        // Spread nodes horizontally
        final posX = (x + 0.5) * (1000 / rowWidth);
        final posY = (floors - 1 - y) * 200.0; // Bottom to top

        floorNodes.add(
          MapNode(
            id: id,
            floor: y,
            type: type,
            connections: [],
            position: Vector2(posX, posY),
            bossEnemyId: bossEnemyId,
            bossRewardType: bossRewardType,
          ),
        );
      }
      nodesByFloor.add(floorNodes);
    }

    return nodesByFloor;
  }
}
