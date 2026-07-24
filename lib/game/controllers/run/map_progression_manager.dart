import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/map_node.dart';
import '../../../services/map_generator_service.dart';
import '../run_controller.dart';
import '../skill_controller.dart';
import '../checkpoint_controller.dart';

class MapProgressionManager {
  final RunController controller;
  final Ref ref;

  MapProgressionManager(this.controller, this.ref);

  /// Sélectionne un nœud sur la carte et déplace le joueur
  void travelToNode(String nodeId) {
    controller.updateState(
      controller.currentState.copyWith(currentNodeId: nodeId),
    );
  }

  /// Marque le nœud actuel comme complété
  void completeCurrentNode() {
    if (controller.currentState.currentNodeId == null) return;

    MapNode? completedNode;
    final updatedNodes = controller.currentState.mapNodes.map((node) {
      if (node.id == controller.currentState.currentNodeId) {
        node.isCompleted = true;
        completedNode = node;
      }
      return node;
    }).toList();

    // Reset de l'armure et nettoyage des statuts à la fin du combat pour préserver les passifs
    controller.updateState(
      controller.currentState.copyWith(
        mapNodes: updatedNodes,
        heroStats: controller.currentState.heroStats.copyWith(armure: 0, statuses: []),
      ),
    );

    if (completedNode != null && completedNode!.type == MapNodeType.boss) {
      advanceToNextWorld();
    }

    ref.read(checkpointProvider.notifier).bump();
  }

  void advanceToNextWorld() {
    final nextAct = controller.currentState.act + 1;
    final newMap = MapGeneratorService.generateMap(act: nextAct);
    controller.updateState(
      controller.currentState.copyWith(
        mapNodes: newMap,
        act: nextAct,
        resetCurrentNode: true, // Reset la position pour le nouveau monde
      ),
    );
  }

  /// Avance d'un niveau (après avoir drafté)
  void nextLevel() {
    final currentStats = controller.currentState.heroStats;
    controller.updateState(
      controller.currentState.copyWith(
        currentLevel: controller.currentState.currentLevel + 1,
        heroStats: currentStats.copyWith(currentMana: currentStats.maxMana),
      ),
    );
    // Réinitialise les cooldowns à chaque nouveau niveau
    ref.read(skillProvider.notifier).resetCooldowns();
  }
}
