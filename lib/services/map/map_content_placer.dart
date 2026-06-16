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
        chosenNode.type = MapNodeType.relicExchange;
      }
    }
  }
}
