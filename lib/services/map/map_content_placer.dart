import 'dart:math';
import '../../models/map_node.dart';

class MapContentPlacer {
  static void placeSpecialEvents({
    required List<MapNode> allNodes,
    required int act,
    required Random random,
  }) {
    if (act >= 5 && (act % 5 == 0 || random.nextDouble() < 0.10)) {
      final eligibleNodes = allNodes.where((node) {
        final y = node.floor;
        return y == 2 || y == 3 || y == 4 || y == 6 || y == 7;
      }).toList();

      if (eligibleNodes.isNotEmpty) {
        final chosenNode = eligibleNodes[random.nextInt(eligibleNodes.length)];
        chosenNode.originalType = chosenNode.type;
        chosenNode.type = MapNodeType.relicExchange;
      }
    }

    // 25% chance to place a forgeFusion node on floors 3 to 7
    if (random.nextDouble() < 0.25) {
      final eligibleNodes = allNodes.where((node) {
        final floor = node.floor;
        return floor >= 3 &&
            floor <= 7 &&
            (node.type == MapNodeType.combat || node.type == MapNodeType.event);
      }).toList();

      if (eligibleNodes.isNotEmpty) {
        final chosenNode = eligibleNodes[random.nextInt(eligibleNodes.length)];
        chosenNode.originalType = chosenNode.type;
        chosenNode.type = MapNodeType.forgeFusion;
      }
    }
  }
}
