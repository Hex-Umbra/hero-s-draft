import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/combat_state.dart';
import '../../../models/enemy_instance.dart';
import '../../../models/enemy_intent.dart';
import '../../../models/status_effect.dart';
import '../run_controller.dart';
import '../combat_controller.dart';
import 'status_effect_processor.dart';
import '../../services/damage_pipeline.dart';

class TurnPhaseManager {
  final CombatController controller;
  final Ref ref;

  TurnPhaseManager(this.controller, this.ref);

  /// Début du tour de l'ennemi (application des statuts autonomes)
  void startEnemyTurn() {
    controller.updateState(
      controller.currentState.copyWith(turnPhase: TurnPhase.enemy),
    );

    final List<EnemyInstance> updatedEnemies = [];
    for (var enemy in controller.currentState.enemies) {
      final updatedStats = StatusEffectProcessor.processEnemyStatuses(enemy.stats);
      updatedEnemies.add(enemy.copyWith(stats: updatedStats));
    }

    controller.updateState(
      controller.currentState.copyWith(enemies: updatedEnemies),
    );

    // Nettoyer les morts (par exemple à cause du poison de début de tour)
    controller.cleanDeadEnemies();
  }

  /// Fin de la phase ennemie : roll intents et retour au joueur
  void endEnemyTurn() {
    final List<EnemyInstance> rolledEnemies = controller.currentState.enemies
        .map((enemy) => controller.rollIntent(enemy))
        .toList();

    controller.updateState(
      controller.currentState.copyWith(
        enemies: rolledEnemies,
        turnPhase: TurnPhase.player,
        turnCount: controller.currentState.turnCount + 1,
      ),
    );
  }

  /// Applique l'effet de l'intention d'un ennemi
  void resolveEnemyIntent(String enemyId) {
    final runController = ref.read(runProvider.notifier);
    final index = controller.currentState.enemies.indexWhere((e) => e.id == enemyId);
    if (index == -1) return;
    final enemy = controller.currentState.enemies[index];

    final intent = enemy.effectiveIntent;
    if (intent == null) return;

    switch (intent.type) {
      case IntentType.attack:
        final hasFreeze = enemy.stats.statuses.any((s) => s.id == 'freeze');

        final (dmg, isCrit) = DamagePipeline.calculate(
          initialDamage: intent.value,
          attackerStats: enemy.stats,
          defenderStats: runController.currentState.heroStats,
        );

        runController.takeDamage(dmg, isCrit: isCrit);

        if (hasFreeze) {
          final updatedStatuses = enemy.stats.statuses.map((s) {
            if (s.id == 'freeze') {
              return s.copyWith(duration: s.duration - 1);
            }
            return s;
          }).where((s) => s.duration > 0).toList();

          final updatedEnemy = enemy.copyWith(
            stats: enemy.stats.copyWith(statuses: updatedStatuses),
          );
          controller.updateEnemy(updatedEnemy);
        }
        break;
      case IntentType.defend:
        final updatedEnemy = enemy.copyWith(
          stats: enemy.stats.copyWith(
            armure: enemy.stats.armure + intent.value,
          ),
        );
        controller.updateEnemy(updatedEnemy);
        break;
      case IntentType.buff:
        final updatedEnemy = enemy.copyWith(
          stats: enemy.stats.addStatus(
            StatusEffect(
              id: 'strength',
              name: 'Attaque',
              type: StatusType.buff,
              value: intent.value,
              duration: 99,
            ),
          ),
        );
        controller.updateEnemy(updatedEnemy);
        break;
      case IntentType.debuffDeck:
        break;
    }
  }
}
