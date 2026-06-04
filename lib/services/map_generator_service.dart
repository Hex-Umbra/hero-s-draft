import 'dart:math';
import 'package:flame/extensions.dart';
import '../models/map_node.dart';
import '../game/game_constants.dart';

class MapGeneratorService {
  static final Random _random = Random();

  /// Generates a procedural map as a Directed Acyclic Graph.
  /// [floors] is the height of the map.
  /// [maxWidth] is the maximum number of nodes per floor.
  static List<MapNode> generateMap({int floors = 10, int maxWidth = 5}) {
    List<MapNode> allNodes = [];
    List<List<MapNode>> nodesByFloor = [];

    // 1. Create nodes for each floor
    for (int y = 0; y < floors; y++) {
      List<MapNode> floorNodes = [];
      int rowWidth = 2 + _random.nextInt(maxWidth - 1); // 2 to maxWidth nodes

      // Special case: Chokepoint at middle floor
      if (y == 5) {
        rowWidth = 1;
      }

      // Special case: Boss floor always has 3 nodes
      if (y == floors - 1) {
        rowWidth = 3;
      }

      for (int x = 0; x < rowWidth; x++) {
        final id = 'node_${y}_$x';
        MapNodeType type = _getRandomNodeType(y, floors);
        String? bossEnemyId;

        // Force structure rules
        if (y == 5) {
          // Chokepoint is always Elite
          type = MapNodeType.elite;
        } else if (y == floors - 2) {
          // Guaranteed Rest before boss
          type = MapNodeType.rest;
        } else if (y == floors - 1) {
          type = MapNodeType.boss;
          if (x == 0) bossEnemyId = 'boss_card_giver';
          if (x == 1) bossEnemyId = 'boss_xp_multiplier';
          if (x == 2) bossEnemyId = 'boss_relic_improved';
        }

        // Spread nodes horizontally
        final posX = (x + 0.5) * (1000 / rowWidth);
        final posY = (floors - 1 - y) * 200.0; // Bottom to top

        floorNodes.add(
          MapNode(
            id: id,
            type: type,
            connections: [],
            position: Vector2(posX, posY),
            bossEnemyId: bossEnemyId,
          ),
        );
      }
      nodesByFloor.add(floorNodes);
      allNodes.addAll(floorNodes);
    }

    // 2. Create connections between floors
    for (int y = 0; y < floors - 1; y++) {
      List<MapNode> currentFloor = nodesByFloor[y];
      List<MapNode> nextFloor = nodesByFloor[y + 1];

      for (int i = 0; i < currentFloor.length; i++) {
        MapNode node = currentFloor[i];

        // Ensure each node has at least one connection
        // Connect to nodes within a certain range to avoid long horizontal lines
        int nextIndexBase = (i * nextFloor.length / currentFloor.length)
            .floor();

        // Connect to 1 or 2 nodes in the next floor
        int numConnections = 1 + _random.nextInt(2);
        Set<int> targets = {};

        for (int j = 0; j < numConnections; j++) {
          int offset = _random.nextInt(3) - 1; // -1, 0, or 1
          int targetIdx = (nextIndexBase + offset).clamp(
            0,
            nextFloor.length - 1,
          );
          targets.add(targetIdx);
        }

        for (int targetIdx in targets) {
          node.connections.add(nextFloor[targetIdx].id);
        }
      }

      // Ensure every node in nextFloor is reachable
      for (int j = 0; j < nextFloor.length; j++) {
        bool reachable = false;
        for (var node in currentFloor) {
          if (node.connections.contains(nextFloor[j].id)) {
            reachable = true;
            break;
          }
        }

        if (!reachable) {
          // Connect the closest node from current floor
          int sourceIdx = (j * currentFloor.length / nextFloor.length).floor();
          currentFloor[sourceIdx].connections.add(nextFloor[j].id);
        }
      }
    }

    // Balance quotas and apply anti-repetition rules
    _optimizeMapTypes(allNodes, floors);

    return allNodes;
  }

  static MapNodeType _getRandomNodeType(int floor, int totalFloors) {
    if (floor == 0) return MapNodeType.combat; // Start with combat

    double r = _random.nextDouble();
    if (r < 0.6) return MapNodeType.combat; // 60% Combat
    if (r < 0.75) return MapNodeType.event; // 15% Event
    if (r < 0.85) return MapNodeType.shop; // 10% Shop
    if (r < 0.95) return MapNodeType.rest; // 10% Rest
    return MapNodeType.elite; // 5% Elite
  }

  static void _optimizeMapTypes(List<MapNode> allNodes, int floors) {
    for (int iter = 0; iter < 15; iter++) {
      _balanceQuotas(allNodes, floors);

      bool changedAny = false;
      for (var node in allNodes) {
        if (node.type == MapNodeType.elite || node.type == MapNodeType.rest) {
          if (_hasThreeConsecutive(node, allNodes, node.type, 1)) {
            final chain = _getChainOfThree(node, allNodes, node.type);
            for (var chainNode in chain) {
              final y = int.parse(chainNode.id.split('_')[1]);
              if (y != 0 && y != 5 && y != floors - 2 && y != floors - 1) {
                final choices = [MapNodeType.combat, MapNodeType.shop, MapNodeType.event];
                chainNode.type = choices[_random.nextInt(choices.length)];
                changedAny = true;
                break;
              }
            }
            if (changedAny) break;
          }
        }
      }

      if (!changedAny) break;
    }
    _balanceQuotas(allNodes, floors);
  }

  static void _balanceQuotas(List<MapNode> allNodes, int floors) {
    for (int attempt = 0; attempt < 100; attempt++) {
      final Map<MapNodeType, int> counts = {
        MapNodeType.combat: 0,
        MapNodeType.elite: 0,
        MapNodeType.rest: 0,
        MapNodeType.shop: 0,
        MapNodeType.event: 0,
        MapNodeType.boss: 0,
      };
      for (var node in allNodes) {
        counts[node.type] = (counts[node.type] ?? 0) + 1;
      }

      MapNodeType? deficientType;
      for (var entry in GameConstants.nodeQuotas.entries) {
        final type = entry.key;
        final min = entry.value.min;
        if ((counts[type] ?? 0) < min) {
          deficientType = type;
          break;
        }
      }

      if (deficientType != null) {
        MapNode? candidate;
        // First try to find a candidate that does not create a 3-consecutive path
        for (var node in allNodes) {
          final y = int.parse(node.id.split('_')[1]);
          if (y == 0 || y == 5 || y == floors - 2 || y == floors - 1) continue;

          final currentType = node.type;
          final currentMin = GameConstants.nodeQuotas[currentType]?.min ?? 0;
          if ((counts[currentType] ?? 0) > currentMin) {
            final originalType = node.type;
            node.type = deficientType;
            bool createsViolation = false;
            if (deficientType == MapNodeType.elite || deficientType == MapNodeType.rest) {
              for (var n in allNodes) {
                if (n.type == deficientType) {
                  if (_hasThreeConsecutive(n, allNodes, deficientType, 1)) {
                    createsViolation = true;
                    break;
                  }
                }
              }
            }
            node.type = originalType;

            if (!createsViolation) {
              candidate = node;
              break;
            }
          }
        }

        // Fallback: if no candidate avoids violation, take any valid candidate to satisfy quota
        if (candidate == null) {
          for (var node in allNodes) {
            final y = int.parse(node.id.split('_')[1]);
            if (y == 0 || y == 5 || y == floors - 2 || y == floors - 1) continue;

            final currentType = node.type;
            final currentMin = GameConstants.nodeQuotas[currentType]?.min ?? 0;
            if ((counts[currentType] ?? 0) > currentMin) {
              candidate = node;
              break;
            }
          }
        }

        if (candidate != null) {
          candidate.type = deficientType;
          continue;
        } else {
          break;
        }
      }

      MapNodeType? excessiveType;
      for (var entry in GameConstants.nodeQuotas.entries) {
        final type = entry.key;
        final max = entry.value.max;
        if ((counts[type] ?? 0) > max) {
          excessiveType = type;
          break;
        }
      }

      if (excessiveType != null) {
        MapNode? candidate;
        MapNodeType? targetType;

        for (var entry in GameConstants.nodeQuotas.entries) {
          final type = entry.key;
          final max = entry.value.max;
          if ((counts[type] ?? 0) < max && type != excessiveType) {
            targetType = type;
            break;
          }
        }

        if (targetType != null) {
          // First try to find a candidate that does not create a 3-consecutive path
          for (var node in allNodes) {
            final y = int.parse(node.id.split('_')[1]);
            if (y == 0 || y == 5 || y == floors - 2 || y == floors - 1) continue;
            if (node.type == excessiveType) {
              final originalType = node.type;
              node.type = targetType;
              bool createsViolation = false;
              if (targetType == MapNodeType.elite || targetType == MapNodeType.rest) {
                for (var n in allNodes) {
                  if (n.type == targetType) {
                    if (_hasThreeConsecutive(n, allNodes, targetType, 1)) {
                      createsViolation = true;
                      break;
                    }
                  }
                }
              }
              node.type = originalType;

              if (!createsViolation) {
                candidate = node;
                break;
              }
            }
          }

          // Fallback: if no candidate avoids violation, take any valid candidate to balance quota
          if (candidate == null) {
            for (var node in allNodes) {
              final y = int.parse(node.id.split('_')[1]);
              if (y == 0 || y == 5 || y == floors - 2 || y == floors - 1) continue;
              if (node.type == excessiveType) {
                candidate = node;
                break;
              }
            }
          }
        }

        if (candidate != null && targetType != null) {
          candidate.type = targetType;
          continue;
        } else {
          break;
        }
      }

      break;
    }
  }

  static bool _hasThreeConsecutive(
    MapNode node,
    List<MapNode> allNodes,
    MapNodeType targetType,
    int currentChainLength,
  ) {
    if (node.type != targetType) {
      return false;
    }
    if (currentChainLength == 3) {
      return true;
    }

    final predecessors = allNodes.where((n) => n.connections.contains(node.id)).toList();
    for (var pred in predecessors) {
      if (pred.type == targetType) {
        if (_hasThreeConsecutive(pred, allNodes, targetType, currentChainLength + 1)) {
          return true;
        }
      }
    }
    return false;
  }

  static List<MapNode> _getChainOfThree(
    MapNode node,
    List<MapNode> allNodes,
    MapNodeType targetType,
  ) {
    List<MapNode> chain = [node];
    var predecessors = allNodes
        .where((n) => n.connections.contains(node.id) && n.type == targetType)
        .toList();
    if (predecessors.isNotEmpty) {
      var pred = predecessors.first;
      chain.add(pred);
      var predPredecessors = allNodes
          .where((n) => n.connections.contains(pred.id) && n.type == targetType)
          .toList();
      if (predPredecessors.isNotEmpty) {
        chain.add(predPredecessors.first);
      }
    }
    return chain;
  }
}
