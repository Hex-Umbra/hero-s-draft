import 'package:flutter/foundation.dart';

import '../../models/entity_stats.dart';
import '../../services/save_service.dart' show RefReader;
import '../controllers/debug_taint_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/run_controller.dart';

/// Mutations d'etat reservees au menu de debug.
///
/// Calquee sur `SaveService` : une classe statique qui recoit un `RefReader` et
/// compose les controleurs, sans detenir d'etat. Elle n'appelle que des
/// methodes deja publiques — celles que le systeme de sauvegarde avait deja
/// rendues necessaires.
///
/// Chaque methode publique est gardee par `kDebugMode`. C'est la seconde garde,
/// celle qui tient meme si un appel echappait un jour a celle de l'interface.
class DebugActions {
  const DebugActions._();

  static void _taint(RefReader read) {
    read(debugTaintProvider.notifier).taint();
  }

  /// Point de mutation unique de `RunState`. L'appelant decrit le changement
  /// avec `copyWith` ; la garde et la contamination sont traitees ici, une
  /// seule fois.
  static void updateRun(RefReader read, RunState Function(RunState) mutate) {
    if (!kDebugMode) return;
    final controller = read(runProvider.notifier);
    controller.updateState(mutate(controller.currentState));
    _taint(read);
  }

  /// Raccourci pour les champs d'`EntityStats`, imbriques dans `RunState`.
  static void updateHeroStats(
    RefReader read,
    EntityStats Function(EntityStats) mutate,
  ) {
    updateRun(read, (s) => s.copyWith(heroStats: mutate(s.heroStats)));
  }

  /// L'or vit sur `InventoryState`, pas sur `RunState`.
  static void setGold(RefReader read, int gold) {
    if (!kDebugMode) return;
    read(
      inventoryProvider.notifier,
    ).hydrate(read(inventoryProvider).copyWith(gold: gold));
    _taint(read);
  }

  /// Acte suivant **avec** regeneration de la carte et perte de la position.
  /// A ne proposer que hors combat.
  static void advanceToNextAct(RefReader read) {
    if (!kDebugMode) return;
    read(runProvider.notifier).advanceToNextWorld();
    _taint(read);
  }
}
