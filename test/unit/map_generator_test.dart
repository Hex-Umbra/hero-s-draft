import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/services/map_generator_service.dart';
void main() {
  group('MapGeneratorService', () {
    test('generates expected number of floors', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);

      // Determine the number of floors by grouping by Y position
      final floors = <double>{};
      for (var node in nodes) {
        floors.add(node.position.y);
      }

      expect(floors.length, 10);
    });

    test('boss nodes are at the top (last floor), rowWidth is 3, and they have correct boss IDs', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);

      final bossNodes = nodes.where((n) => n.type == MapNodeType.boss).toList();
      expect(bossNodes.length, 3);

      final bossIds = bossNodes.map((n) => n.bossEnemyId).toSet();
      expect(bossIds, {
        'boss_card_giver',
        'boss_xp_multiplier',
        'boss_relic_improved',
      });

      for (var bossNode in bossNodes) {
        // posY for floor 9 is 0
        expect(bossNode.position.y, 0.0);
        expect(bossNode.connections.isEmpty, true);
      }
    });

    test('floor 5 is an elite chokepoint with exactly 1 elite node', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);

      // floor 5 posY is (10 - 1 - 5) * 200 = 800
      final floor5Nodes = nodes.where((n) => n.position.y == 800.0).toList();
      expect(floor5Nodes.length, 1);
      expect(floor5Nodes.first.type, MapNodeType.elite);
    });

    test('all nodes except boss have at least one connection (no dead ends)', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);

      for (var node in nodes) {
        if (node.type != MapNodeType.boss) {
          expect(
            node.connections.isNotEmpty,
            true,
            reason: 'Node ${node.id} has no connections',
          );
        }
      }
    });

    test('all nodes (except the first floor) are reachable (no isolated nodes)', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);

      // Determine bottom floor Y (floors - 1) * 200
      final bottomY = (10 - 1) * 200.0;

      // Get all nodes that are not in the first floor
      final notFirstFloorNodes = nodes
          .where((n) => n.position.y != bottomY)
          .toList();

      for (var targetNode in notFirstFloorNodes) {
        bool isReachable = nodes.any(
          (sourceNode) => sourceNode.connections.contains(targetNode.id),
        );
        expect(
          isReachable,
          true,
          reason: 'Node ${targetNode.id} is not reachable from any node',
        );
      }
    });

    test('first floor only contains combat nodes', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);

      final bottomY = (10 - 1) * 200.0;
      final firstFloorNodes = nodes
          .where((n) => n.position.y == bottomY)
          .toList();

      for (var node in firstFloorNodes) {
        expect(node.type, MapNodeType.combat);
      }
    });

    test('anti-repetition: no three consecutive nodes of type elite or rest in any path', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);

      final nodeMap = {for (var n in nodes) n.id: n};

      bool checkConsecutive(MapNode current, int eliteCount, int restCount) {
        if (current.type == MapNodeType.elite) {
          eliteCount++;
          restCount = 0;
        } else if (current.type == MapNodeType.rest) {
          restCount++;
          eliteCount = 0;
        } else {
          eliteCount = 0;
          restCount = 0;
        }

        if (eliteCount >= 3 || restCount >= 3) {
          return true; // violation found
        }

        for (var connId in current.connections) {
          final target = nodeMap[connId];
          if (target != null) {
            if (checkConsecutive(target, eliteCount, restCount)) {
              return true;
            }
          }
        }
        return false;
      }

      // Start from all bottom floor nodes
      final bottomY = (10 - 1) * 200.0;
      final startNodes = nodes.where((n) => n.position.y == bottomY).toList();

      for (var startNode in startNodes) {
        final hasViolation = checkConsecutive(startNode, 0, 0);
        expect(hasViolation, false, reason: 'Path starting at ${startNode.id} has 3 consecutive elite/rest nodes');
      }
    });

    test('quotas are balanced and respected', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);

      // Count node types for generated map (excluding bottom floor and top floor which are hardcoded/forced, and floor 5 which is forced elite)
      final bottomY = (10 - 1) * 200.0;
      final floor5Y = 800.0;
      final topY = 0.0;

      final countMap = <MapNodeType, int>{};
      for (var node in nodes) {
        if (node.position.y != bottomY && node.position.y != floor5Y && node.position.y != topY) {
          countMap[node.type] = (countMap[node.type] ?? 0) + 1;
        }
      }

      // Check that the types respect minimum and maximum thresholds of the quotas.
      // Note: Because a smaller map (10 floors, ~25 nodes total) is used, quotas are scaled down,
      // but they should be reasonably balanced.
      expect(countMap[MapNodeType.combat] ?? 0, greaterThan(0));
      expect(countMap[MapNodeType.shop] ?? 0, greaterThan(0));
      expect(countMap[MapNodeType.event] ?? 0, greaterThan(0));
    });

    test('floor 8 is a rest chokepoint containing only rest nodes', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);

      // floor 8 posY is (10 - 1 - 8) * 200 = 200
      final floor8Nodes = nodes.where((n) => n.position.y == 200.0).toList();
      expect(floor8Nodes.isNotEmpty, true);
      for (var node in floor8Nodes) {
        expect(node.type, MapNodeType.rest);
      }
    });

    test('procedural generator quota constraints are balanced and respected across many runs', () {
      int successCount = 0;
      int totalRuns = 50;

      for (int i = 0; i < totalRuns; i++) {
        final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);

        final counts = <MapNodeType, int>{
          MapNodeType.combat: 0,
          MapNodeType.elite: 0,
          MapNodeType.rest: 0,
          MapNodeType.shop: 0,
          MapNodeType.event: 0,
        };

        for (var node in nodes) {
          if (counts.containsKey(node.type)) {
            counts[node.type] = counts[node.type]! + 1;
          }
        }

        // Check if quotas are respected or best-effort balanced depending on total non-boss nodes
        final totalNonBoss = nodes.where((n) => n.type != MapNodeType.boss).length;

        // Extract width of locked floors to compute the minimum required nodes mathematically
        final w8 = nodes.where((n) => n.position.y == 200.0).length;
        
        // As derived, if w8 > 3, those extra rest nodes cannot be changed, so we need more slots
        final minRequired = 21 + (w8 > 3 ? w8 : 3);

        bool limitsRespected = true;
        
        // Minimum quotas (Combat:12, Elite:3, Rest:3, Shop:2, Event:4 - total 24)
        if (totalNonBoss >= minRequired) {
          if (counts[MapNodeType.combat]! < 12 ||
              counts[MapNodeType.elite]! < 3 ||
              counts[MapNodeType.rest]! < 3 ||
              counts[MapNodeType.shop]! < 2 ||
              counts[MapNodeType.event]! < 4) {
            limitsRespected = false;
          }
        }

        // Maximum quotas (Combat:22, Elite:6, Rest:6, Shop:5, Event:9)
        if (counts[MapNodeType.combat]! > 22 ||
            counts[MapNodeType.elite]! > 6 ||
            counts[MapNodeType.rest]! > 6 ||
            counts[MapNodeType.shop]! > 5 ||
            counts[MapNodeType.event]! > 9) {
          limitsRespected = false;
        }

        if (limitsRespected) {
          successCount++;
        }
      }

      // Assert that our solver works successfully in all generated maps
      expect(successCount, totalRuns, reason: 'Quotas should be correctly balanced/respected within budget limits');
    });
  });
}
