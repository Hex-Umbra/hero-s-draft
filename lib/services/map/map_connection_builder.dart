import 'dart:math';
import '../../models/map_node.dart';

class MapConnectionBuilder {
  static void buildConnections({
    required List<List<MapNode>> nodesByFloor,
    required int floors,
    required Random random,
  }) {
    for (int y = 0; y < floors - 1; y++) {
      List<MapNode> currentFloor = nodesByFloor[y];
      List<MapNode> nextFloor = nodesByFloor[y + 1];

      for (int i = 0; i < currentFloor.length; i++) {
        MapNode node = currentFloor[i];

        // Ensure each node has at least one connection
        // Connect to nodes within a certain range to avoid long horizontal lines
        int nextIndexBase = (i * nextFloor.length / currentFloor.length).floor();

        // Connect to 1 or 2 nodes in the next floor
        int numConnections = 1 + random.nextInt(2);
        Set<int> targets = {};

        for (int j = 0; j < numConnections; j++) {
          int offset = random.nextInt(3) - 1; // -1, 0, or 1
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
  }
}
