import 'dart:math';
import '../models/map_node.dart';
import 'map/map_node_generator.dart';
import 'map/map_connection_builder.dart';
import 'map/map_validator.dart';
import 'map/map_content_placer.dart';

class MapGeneratorService {
  static final Random _random = Random();

  /// Generates a procedural map as a Directed Acyclic Graph.
  /// [floors] is the height of the map.
  /// [maxWidth] is the maximum number of nodes per floor.
  static List<MapNode> generateMap({int floors = 10, int maxWidth = 5, int act = 1}) {
    final middleFloor = floors ~/ 2;

    // 1. Create nodes for each floor
    final nodesByFloor = MapNodeGenerator.generateRawNodes(
      floors: floors,
      maxWidth: maxWidth,
      middleFloor: middleFloor,
      random: _random,
    );

    // Flatten all nodes
    List<MapNode> allNodes = [];
    for (var floor in nodesByFloor) {
      allNodes.addAll(floor);
    }

    // 2. Create connections between floors
    MapConnectionBuilder.buildConnections(
      nodesByFloor: nodesByFloor,
      floors: floors,
      random: _random,
    );

    // 3. Balance quotas and apply anti-repetition rules
    MapValidator.optimizeMapTypes(
      allNodes: allNodes,
      floors: floors,
      random: _random,
    );

    // 4. Place special events
    MapContentPlacer.placeSpecialEvents(
      allNodes: allNodes,
      act: act,
      random: _random,
    );

    return allNodes;
  }
}
