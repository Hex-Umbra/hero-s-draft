import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/combat_state.dart';
import '../../../models/enemy_instance.dart';
import '../../../models/enemy_intent.dart';
import '../../../models/status_effect.dart';
import '../run_controller.dart';
import '../combat_controller.dart';
import '../deck_controller.dart';
import 'status_effect_processor.dart';
import '../../services/damage_pipeline.dart';
import '../../game_constants.dart';

class TurnPhaseManager {
  final CombatController controller;
  final Ref ref;

  TurnPhaseManager(this.controller, this.ref);

  /// Ouvre le combat côté joueur : nettoyage des statuts, mana au max,
  /// reliques `startOfCombat`, puis main d'ouverture.
  ///
  /// L'ordre est celui d'avant P-02 et doit le rester : `startCombat()`
  /// déclenche les reliques, la pioche vient après.
  void startPlayerCombat() {
    final runController = ref.read(runProvider.notifier);
    final deckController = ref.read(deckProvider.notifier);

    if (kDebugMode && ref.read(deckProvider).masterDeck.isEmpty) {
      debugPrint('startPlayerCombat: masterDeck vide — '
          'StarterDeckDraftScreen a-t-il été court-circuité ?');
    }

    runController.startCombat();
    deckController.startCombat(
      handSize: runController.currentState.cardsPerTurn,
      maxHandSize: GameConstants.maxHandSize,
    );
  }

  /// Ouvre un tour joueur : mana, armure, reliques `startOfTurn`, statuts,
  /// cooldowns et passifs, puis pioche.
  ///
  /// L'ordre est celui d'avant P-02 et doit le rester : inverser les deux
  /// appels décalerait toute relique `startOfTurn` d'un tour.
  void startPlayerTurn() {
    final runController = ref.read(runProvider.notifier);

    runController.startTurn();
    ref.read(deckProvider.notifier).drawCards(
          runController.currentState.cardsPerTurn,
          maxHandSize: GameConstants.maxHandSize,
        );
  }

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
