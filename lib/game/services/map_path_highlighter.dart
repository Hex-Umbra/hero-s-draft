import '../../models/map_node.dart';

/// Calcule le chemin (noeuds + connexions) reliant un noeud survolé au
/// noeud actuel du joueur, pour la surbrillance interactive de MapScreen.
class MapPathHighlighter {
  const MapPathHighlighter._();

  /// Remonte récursivement depuis [targetId] vers [startId] en peuplant
  /// [pathNodes]/[pathConnections]. Retourne `true` si un chemin existe.
  static bool findPathToCurrent(
    String targetId,
    String? startId,
    List<MapNode> allNodes,
    Set<String> pathNodes,
    Set<(String, String)> pathConnections,
  ) {
    // Si on a atteint le point de départ (ou l'étage 0 si on n'a pas commencé)
    if (targetId == startId ||
        (startId == null && targetId.startsWith('node_0_'))) {
      pathNodes.add(targetId);
      return true;
    }

    // Trouver tous les parents (noeuds de l'étage précédent qui pointent vers targetId)
    bool foundPath = false;

    // Optimisation : seuls les noeuds de l'étage précédent peuvent être parents
    final targetNode = allNodes.firstWhere((n) => n.id == targetId);
    final targetFloor = targetNode.floor;
    if (targetFloor == 0) return false;

    final parents = allNodes.where((n) {
      return n.floor == targetFloor - 1 && n.connections.contains(targetId);
    });

    for (var parent in parents) {
      if (findPathToCurrent(
        parent.id,
        startId,
        allNodes,
        pathNodes,
        pathConnections,
      )) {
        pathNodes.add(targetId);
        pathNodes.add(parent.id);
        pathConnections.add((parent.id, targetId));
        foundPath = true;
      }
    }

    return foundPath;
  }
}
