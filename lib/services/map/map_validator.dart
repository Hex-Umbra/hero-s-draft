import 'dart:math';
import '../../models/map_node.dart';
import '../../game/game_constants.dart';

class MapValidator {
  static void optimizeMapTypes({
    required List<MapNode> allNodes,
    required int floors,
    required Random random,
  }) {
    for (int iter = 0; iter < 15; iter++) {
      balanceQuotas(allNodes: allNodes, floors: floors, random: random);

      bool changedAny = false;
      for (var node in allNodes) {
        if (node.type == MapNodeType.elite || node.type == MapNodeType.rest) {
          if (hasThreeConsecutive(node, allNodes, node.type, 1)) {
            final chain = getChainOfThree(node, allNodes, node.type);
            for (var chainNode in chain) {
              final y = chainNode.floor;
              final middleFloor = floors ~/ 2;
              if (y != 0 && y != middleFloor && y != floors - 2 && y != floors - 1) {
                final choices = [MapNodeType.combat, MapNodeType.shop, MapNodeType.event];
                chainNode.type = choices[random.nextInt(choices.length)];
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
    balanceQuotas(allNodes: allNodes, floors: floors, random: random);
  }

  static void balanceQuotas({
    required List<MapNode> allNodes,
    required int floors,
    required Random random,
  }) {
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
          final y = node.floor;
          final middleFloor = floors ~/ 2;
          if (y == 0 || y == middleFloor || y == floors - 2 || y == floors - 1) continue;

          final currentType = node.type;
          final currentMin = GameConstants.nodeQuotas[currentType]?.min ?? 0;
          if ((counts[currentType] ?? 0) > currentMin) {
            final originalType = node.type;
            node.type = deficientType;
            bool createsViolation = false;
            if (deficientType == MapNodeType.elite || deficientType == MapNodeType.rest) {
              for (var n in allNodes) {
                if (n.type == deficientType) {
                  if (hasThreeConsecutive(n, allNodes, deficientType, 1)) {
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
            final y = node.floor;
            final middleFloor = floors ~/ 2;
            if (y == 0 || y == middleFloor || y == floors - 2 || y == floors - 1) continue;

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
            final y = node.floor;
            final middleFloor = floors ~/ 2;
            if (y == 0 || y == middleFloor || y == floors - 2 || y == floors - 1) continue;
            if (node.type == excessiveType) {
              final originalType = node.type;
              node.type = targetType;
              bool createsViolation = false;
              if (targetType == MapNodeType.elite || targetType == MapNodeType.rest) {
                for (var n in allNodes) {
                  if (n.type == targetType) {
                    if (hasThreeConsecutive(n, allNodes, targetType, 1)) {
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
              final y = node.floor;
              final middleFloor = floors ~/ 2;
              if (y == 0 || y == middleFloor || y == floors - 2 || y == floors - 1) continue;
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

  static bool hasThreeConsecutive(
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
        if (hasThreeConsecutive(pred, allNodes, targetType, currentChainLength + 1)) {
          return true;
        }
      }
    }
    return false;
  }

  static List<MapNode> getChainOfThree(
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
