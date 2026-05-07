import 'dart:math';
import 'package:flame/extensions.dart';
import '../models/map_node.dart';

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

      // Special case: Boss floor always has 1 node
      if (y == floors - 1) {
        rowWidth = 1;
      }

      for (int x = 0; x < rowWidth; x++) {
        final id = 'node_${y}_$x';
        final type = _getRandomNodeType(y, floors);
        
        // Spread nodes horizontally
        final posX = (x + 0.5) * (1000 / rowWidth);
        final posY = (floors - 1 - y) * 200.0; // Bottom to top

        floorNodes.add(MapNode(
          id: id,
          type: y == floors - 1 ? MapNodeType.boss : type,
          connections: [],
          position: Vector2(posX, posY),
        ));
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
        int nextIndexBase = (i * nextFloor.length / currentFloor.length).floor();
        
        // Connect to 1 or 2 nodes in the next floor
        int numConnections = 1 + _random.nextInt(2);
        Set<int> targets = {};
        
        for (int j = 0; j < numConnections; j++) {
          int offset = _random.nextInt(3) - 1; // -1, 0, or 1
          int targetIdx = (nextIndexBase + offset).clamp(0, nextFloor.length - 1);
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

    return allNodes;
  }

  static MapNodeType _getRandomNodeType(int floor, int totalFloors) {
    if (floor == 0) return MapNodeType.combat; // Start with combat
    
    double r = _random.nextDouble();
    if (r < 0.6) return MapNodeType.combat;      // 60% Combat
    if (r < 0.75) return MapNodeType.event;     // 15% Event
    if (r < 0.85) return MapNodeType.shop;      // 10% Shop
    if (r < 0.95) return MapNodeType.rest;      // 10% Rest
    return MapNodeType.elite;                    // 5% Elite
  }
}
