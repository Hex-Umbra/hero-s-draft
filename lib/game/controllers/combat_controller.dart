import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/entity_stats.dart';
import '../../../models/card_instance.dart';
import '../../../models/combat_state.dart';
import '../../../models/enemy_instance.dart';
import '../../../models/enemy_intent.dart';
import '../../../models/data/enemy_data.dart';
import '../../../models/data/relic_data.dart';
import '../../../models/status_effect.dart';
import '../../../models/map_node.dart';
import '../systems/encounter_system.dart';
import '../systems/trait_system.dart';
import '../services/effect_resolver.dart';
import 'run_controller.dart';
import 'deck_controller.dart';

class CombatController extends StateNotifier<CombatState> {
  CombatController() : super(const CombatState());

  CombatState get currentState => state;

  /// Génère les ennemis via EncounterSystem et initialise l'état du combat
  void initializeCombat(
    int level,
    MapNodeType? nodeType,
    List<EnemyData> availableEnemies, {
    int playerLevel = 1,
    int act = 1,
  }) {
    final enemyDataList = EncounterSystem.generateEnemiesForLevel(
      level,
      availableEnemies,
      nodeType: nodeType,
    );

    final bool isBoss =
        nodeType == MapNodeType.boss || (level > 0 && level % 10 == 0);
    final bool isElite = nodeType == MapNodeType.elite;

    // 1. Déterminer le niveau de l'ennemi (minimum 1)
    int nodeModifier = 0;
    if (isBoss) {
      nodeModifier = 2;
    } else if (isElite) {
      nodeModifier = 1;
    }
    final int enemyLevel = max(1, playerLevel + (act - 1) * 2 + nodeModifier);

    // 2. Calculer les multiplicateurs de mise à l'échelle
    final double nodeMultiplier = isBoss ? 3.0 : (isElite ? 1.5 : 1.0);
    final double hpMultiplier =
        (1.0 + 0.12 * (enemyLevel - 1)) *
        (1.0 + 0.40 * (act - 1)) *
        nodeMultiplier;
    final double damageMultiplier =
        (1.0 + 0.08 * (enemyLevel - 1)) *
        (1.0 + 0.30 * (act - 1)) *
        nodeMultiplier;

    final List<EnemyInstance> enemies = [];
    for (var data in enemyDataList) {
      final stats = EntityStats(
        maxPv: (data.maxHp * hpMultiplier).round(),
        currentPv: (data.maxHp * hpMultiplier).round(),
        armure: 0,
        attaque: (data.baseDamage * damageMultiplier).round(),
        level: enemyLevel,
      );

      var enemy = EnemyInstance(data: data, stats: stats, isBoss: isBoss);

      enemy = _rollIntent(enemy);
      enemies.add(enemy);
    }

    state = CombatState(
      enemies: enemies,
      turnPhase: TurnPhase.player,
      turnCount: 1,
      selectedEnemyId: null,
      isCombatEnded: false,
      isVictory: false,
    );
  }

  /// Sélectionne l'ennemi ciblé par le joueur
  void selectEnemy(String? enemyId) {
    state = state.copyWith(
      selectedEnemyId: enemyId,
      clearSelectedEnemy: enemyId == null,
    );
  }

  /// Met à jour les statistiques d'un ennemi spécifique
  void updateEnemyStats(String enemyId, EntityStats newStats) {
    state = state.copyWith(
      enemies: state.enemies.map((enemy) {
        if (enemy.id != enemyId) return enemy;
        return enemy.copyWith(stats: newStats);
      }).toList(),
    );
  }

  /// Applique le jeu d'une carte par le joueur
  void applyPlayerCardPlay(
    CardInstance card,
    RunController runController,
    DeckNotifier deckController,
  ) {
    // 1. Résolution des effets
    final success = EffectResolver.resolveCard(
      card,
      runController,
      deckController,
      this,
      state.selectedEnemyId,
    );

    if (success) {
      // 2. Transmettre au deck que la carte est jouée
      deckController.playCard(card);

      // 3. Déclencher les traits passifs
      TraitSystem.onCardPlayed(runController, card);

      // 4. Déclencher les reliques liées aux cartes jouées
      runController.applyRelics(RelicTrigger.onCardPlayed);

      // 5. Nettoyer les morts
      _cleanDeadEnemies(runController);
    }
  }

  /// Applique l'effet de l'intention d'un ennemi
  void resolveEnemyIntent(String enemyId, RunController runController) {
    final index = state.enemies.indexWhere((e) => e.id == enemyId);
    if (index == -1) return;
    final enemy = state.enemies[index];

    final intent = enemy.effectiveIntent;
    if (intent == null) return;

    switch (intent.type) {
      case IntentType.attack:
        int dmg = intent.value;
        if (enemy.stats.statuses.any((s) => s.id == 'freeze')) {
          dmg = (intent.value * 0.5).round();
        }
        runController.takeDamage(dmg);
        break;
      case IntentType.defend:
        final updatedEnemy = enemy.copyWith(
          stats: enemy.stats.copyWith(
            armure: enemy.stats.armure + intent.value,
          ),
        );
        _updateEnemy(updatedEnemy);
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
        _updateEnemy(updatedEnemy);
        break;
      case IntentType.debuffDeck:
        break;
    }
  }

  /// Début du tour de l'ennemi (application des statuts autonomes)
  void startEnemyTurn(RunController runController) {
    state = state.copyWith(turnPhase: TurnPhase.enemy);

    final List<EnemyInstance> updatedEnemies = [];
    for (var enemy in state.enemies) {
      int poisonDamage = 0;
      int strengthGain = 0;
      int armorGain = 0;
      int burnDamage = 0;

      for (var status in enemy.stats.statuses) {
        if (status.id == 'poison') {
          poisonDamage += status.value;
        } else if (status.id == 'strength_regen') {
          strengthGain += status.value;
        } else if (status.id == 'armor_regen') {
          armorGain += status.value;
        } else if (status.id == 'burn') {
          burnDamage += status.value;
        }
      }

      EntityStats updatedStats = enemy.stats;
      if (poisonDamage > 0) {
        updatedStats = updatedStats.takeDamage(poisonDamage);
      }
      if (burnDamage > 0) {
        updatedStats = updatedStats.takeDamage(burnDamage);
      }
      if (strengthGain > 0) {
        updatedStats = updatedStats.addStatus(
          StatusEffect(
            id: 'strength',
            name: 'Attaque',
            type: StatusType.buff,
            value: strengthGain,
            duration: 1,
          ),
        );
      }
      if (armorGain > 0) {
        updatedStats = updatedStats.copyWith(
          armure: updatedStats.armure + armorGain,
        );
      }

      // Tick statuts
      updatedStats = updatedStats.tickStatuses();

      updatedEnemies.add(enemy.copyWith(stats: updatedStats));
    }

    state = state.copyWith(enemies: updatedEnemies);

    // Nettoyer les morts (par exemple à cause du poison de début de tour)
    _cleanDeadEnemies(runController);
  }

  /// Fin de la phase ennemie : roll intents et retour au joueur
  void endEnemyTurn() {
    final List<EnemyInstance> rolledEnemies = state.enemies
        .map((enemy) => _rollIntent(enemy))
        .toList();

    state = state.copyWith(
      enemies: rolledEnemies,
      turnPhase: TurnPhase.player,
      turnCount: state.turnCount + 1,
    );
  }

  /// Décrémente la durée des statuts de l'ennemi
  void tickEnemyStatuses(String enemyId) {
    state = state.copyWith(
      enemies: state.enemies.map((enemy) {
        if (enemy.id != enemyId) return enemy;
        return enemy.copyWith(stats: enemy.stats.tickStatuses());
      }).toList(),
    );
  }

  /// Calcule et attribue la prochaine intention de l'ennemi
  void rollIntentForEnemy(String enemyId) {
    state = state.copyWith(
      enemies: state.enemies.map((enemy) {
        if (enemy.id != enemyId) return enemy;
        return _rollIntent(enemy);
      }).toList(),
    );
  }

  /// Nettoie les ennemis décédés et met à jour les indicateurs de fin de combat
  void _cleanDeadEnemies(RunController runController) {
    final List<EnemyInstance> remainingEnemies = [];
    final List<EnemyInstance> newlyKilledEnemies = [];
    int killedCount = 0;

    for (var enemy in state.enemies) {
      if (enemy.stats.currentPv <= 0) {
        killedCount++;
        newlyKilledEnemies.add(enemy);
        runController.onEnemyKilled();
      } else {
        remainingEnemies.add(enemy);
      }
    }

    if (killedCount > 0) {
      String? nextSelected = state.selectedEnemyId;
      if (nextSelected != null &&
          !remainingEnemies.any((e) => e.id == nextSelected)) {
        nextSelected = null;
      }

      final bool isCombatEnded = remainingEnemies.isEmpty;
      final bool isVictory = isCombatEnded;

      state = state.copyWith(
        enemies: remainingEnemies,
        defeatedEnemies: [...state.defeatedEnemies, ...newlyKilledEnemies],
        selectedEnemyId: nextSelected,
        clearSelectedEnemy: nextSelected == null,
        isCombatEnded: isCombatEnded,
        isVictory: isVictory,
      );
    }
  }

  /// Met à jour l'instance interne d'un ennemi
  void _updateEnemy(EnemyInstance updatedEnemy) {
    state = state.copyWith(
      enemies: state.enemies
          .map((e) => e.id == updatedEnemy.id ? updatedEnemy : e)
          .toList(),
    );
  }

  /// Calcule l'intention suivante d'un ennemi
  EnemyInstance _rollIntent(EnemyInstance enemy) {
    final data = enemy.data;
    EnemyIntent nextIntent;
    int nextStep = enemy.intentStep;

    if (data.intents != null && data.intents!.isNotEmpty) {
      nextIntent = data.intents![enemy.intentStep];
      nextStep = (enemy.intentStep + 1) % data.intents!.length;
    } else {
      final random = Random();
      final roll = random.nextInt(100);

      if (roll < 60) {
        nextIntent = EnemyIntent(
          type: IntentType.attack,
          value: data.baseDamage,
        );
      } else if (roll < 85) {
        nextIntent = EnemyIntent(
          type: IntentType.defend,
          value: 5 + random.nextInt(6),
        );
      } else {
        nextIntent = EnemyIntent(type: IntentType.buff, value: 2);
      }
    }
    return enemy.copyWith(currentIntent: nextIntent, intentStep: nextStep);
  }
}

final combatProvider = StateNotifierProvider<CombatController, CombatState>((
  ref,
) {
  return CombatController();
});
