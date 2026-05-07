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

    test('boss node is at the top (last floor) and is single', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);
      
      final bossNodes = nodes.where((n) => n.type == MapNodeType.boss).toList();
      expect(bossNodes.length, 1);
      
      final bossNode = bossNodes.first;
      // Because y position is calculated as (floors - 1 - y) * 200
      // So the top floor (y = floors - 1) will have posY = 0
      expect(bossNode.position.y, 0.0);
      expect(bossNode.connections.isEmpty, true);
    });

    test('all nodes except boss have at least one connection (no dead ends)', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);
      
      for (var node in nodes) {
        if (node.type != MapNodeType.boss) {
          expect(node.connections.isNotEmpty, true, reason: 'Node ${node.id} has no connections');
        }
      }
    });

    test('all nodes (except the first floor) are reachable (no isolated nodes)', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);
      
      // Determine bottom floor Y (floors - 1) * 200
      final bottomY = (10 - 1) * 200.0;
      
      // Get all nodes that are not in the first floor
      final notFirstFloorNodes = nodes.where((n) => n.position.y != bottomY).toList();
      
      for (var targetNode in notFirstFloorNodes) {
        bool isReachable = nodes.any((sourceNode) => sourceNode.connections.contains(targetNode.id));
        expect(isReachable, true, reason: 'Node ${targetNode.id} is not reachable from any node');
      }
    });

    test('first floor only contains combat nodes', () {
      final nodes = MapGeneratorService.generateMap(floors: 10, maxWidth: 5);
      
      final bottomY = (10 - 1) * 200.0;
      final firstFloorNodes = nodes.where((n) => n.position.y == bottomY).toList();
      
      for (var node in firstFloorNodes) {
        expect(node.type, MapNodeType.combat);
      }
    });
  });
}
