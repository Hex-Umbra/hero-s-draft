import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/status_effect.dart';
import '../../data/models/entity_stats.dart';
import '../controllers/run_controller.dart';
import '../controllers/deck_controller.dart';
import '../controllers/combat_controller.dart';
import '../components/entities/enemy_card.dart';

class EffectResolver {
  /// Helper pour créer un StatusEffect à partir des données de la carte
  static StatusEffect? _createStatus(String statusId, int value, int duration) {
    switch (statusId) {
      case 'poison':
        return StatusEffect(
          id: 'poison',
          name: 'Poison',
          type: StatusType.debuff,
          value: value,
          duration: duration,
        );
      case 'strength':
        return StatusEffect(
          id: 'strength',
          name: 'Attaque',
          type: StatusType.buff,
          value: value,
          duration: duration,
        );
      case 'weakness':
        return StatusEffect(
          id: 'weakness',
          name: 'Faiblesse',
          type: StatusType.debuff,
          value: value,
          duration: duration,
        );
      case 'vulnerable':
        return StatusEffect(
          id: 'vulnerable',
          name: 'Vulnérable',
          type: StatusType.debuff,
          value: value,
          duration: duration,
        );
      case 'strength_regen':
        return StatusEffect(
          id: 'strength_regen',
          name: 'Éveil d\'Attaque',
          type: StatusType.buff,
          value: value,
          duration: duration,
        );
      case 'armor_regen':
        return StatusEffect(
          id: 'armor_regen',
          name: 'Métallisation',
          type: StatusType.buff,
          value: value,
          duration: duration,
        );
      default:
        return null;
    }
  }

  /// Vérifie si la carte peut être jouée (Nouvelle version découplée - Étape 3)
  static bool canPlayCardState(
    CardInstance card,
    RunState runState,
    String? selectedEnemyId,
  ) {
    if (runState.heroStats.currentMana < card.currentCost) {
      return false;
    }
    if (card.data.type == CardType.status) {
      return false;
    }
    if (card.data.target == CardTarget.singleEnemy && selectedEnemyId == null) {
      return false;
    }
    return true;
  }

  /// Vérifie si la carte peut être jouée (Ancienne version Flame pour compatibilité temporaire)
  static bool canPlayCard(
    CardInstance card,
    RunState runState,
    EnemyCard? selectedEnemy,
  ) {
    return canPlayCardState(card, runState, selectedEnemy != null ? 'temp_id' : null);
  }

  /// Résout les effets d'une carte (Nouvelle version découplée - Étape 3)
  static bool resolveCardState(
    CardInstance card,
    RunController runController,
    DeckNotifier deckController,
    CombatController combatController,
    String? selectedEnemyId,
  ) {
    if (!canPlayCardState(card, runController.currentState, selectedEnemyId)) {
      return false;
    }

    runController.consumeResource(mana: card.currentCost);

    for (var effect in card.data.effects) {
      final int baseValue = effect.value;
      final int scaledValue = (baseValue * (1 + (card.level - 1) * 0.5)).round();

      switch (effect.type) {
        case 'damage':
          if (card.data.target == CardTarget.singleEnemy && selectedEnemyId != null) {
            final enemyIndex = combatController.currentState.enemies
                .indexWhere((e) => e.id == selectedEnemyId);
            if (enemyIndex != -1) {
              final enemy = combatController.currentState.enemies[enemyIndex];
              int dmg = _calculateDamage(scaledValue, runController.currentState.heroStats);
              combatController.updateEnemyStats(selectedEnemyId, enemy.stats.takeDamage(dmg));
            }
          } else if (card.data.target == CardTarget.allEnemies) {
            int dmg = _calculateDamage(scaledValue, runController.currentState.heroStats);
            for (var enemy in combatController.currentState.enemies) {
              combatController.updateEnemyStats(enemy.id, enemy.stats.takeDamage(dmg));
            }
          }
          break;
        case 'heal':
          runController.heal(scaledValue);
          break;
        case 'armor':
          final currentStats = runController.currentState.heroStats;
          runController.setHeroStats(armure: currentStats.armure + scaledValue);
          break;
        case 'gain_mana':
          final currentMana = runController.currentState.heroStats.currentMana;
          runController.setHeroStats(currentMana: currentMana + scaledValue);
          break;
        case 'draw':
          deckController.drawCards(scaledValue);
          break;
        case 'apply_status':
          if (effect.statusId != null) {
            final status = _createStatus(effect.statusId!, scaledValue, effect.duration ?? 1);
            if (status != null) {
              if (card.data.target == CardTarget.singleEnemy && selectedEnemyId != null) {
                final enemyIndex = combatController.currentState.enemies
                    .indexWhere((e) => e.id == selectedEnemyId);
                if (enemyIndex != -1) {
                  final enemy = combatController.currentState.enemies[enemyIndex];
                  combatController.updateEnemyStats(selectedEnemyId, enemy.stats.addStatus(status));
                }
              } else if (card.data.target == CardTarget.allEnemies) {
                for (var enemy in combatController.currentState.enemies) {
                  combatController.updateEnemyStats(enemy.id, enemy.stats.addStatus(status));
                }
              } else if (card.data.target == CardTarget.self) {
                runController.addStatus(status);
              }
            }
          }
          break;
      }
    }
    return true;
  }

  /// Résout les effets d'une carte (Ancienne version Flame pour compatibilité temporaire)
  static bool resolveCard(
    CardInstance card,
    RunController runController,
    DeckNotifier deckController,
    List<EnemyCard> enemyCards,
    EnemyCard? selectedEnemy,
  ) {
    if (!canPlayCard(card, runController.currentState, selectedEnemy)) {
      return false;
    }

    runController.consumeResource(mana: card.currentCost);

    for (var effect in card.data.effects) {
      final int baseValue = effect.value;
      final int scaledValue = (baseValue * (1 + (card.level - 1) * 0.5)).round();

      switch (effect.type) {
        case 'damage':
          if (card.data.target == CardTarget.singleEnemy && selectedEnemy != null) {
            int dmg = _calculateDamage(scaledValue, runController.currentState.heroStats);
            selectedEnemy.updateStats(selectedEnemy.stats.takeDamage(dmg));
          } else if (card.data.target == CardTarget.allEnemies) {
            int dmg = _calculateDamage(scaledValue, runController.currentState.heroStats);
            for (var enemy in enemyCards) {
              enemy.updateStats(enemy.stats.takeDamage(dmg));
            }
          }
          break;
        case 'heal':
          runController.heal(scaledValue);
          break;
        case 'armor':
          final currentStats = runController.currentState.heroStats;
          runController.setHeroStats(armure: currentStats.armure + scaledValue);
          break;
        case 'gain_mana':
          final currentMana = runController.currentState.heroStats.currentMana;
          runController.setHeroStats(currentMana: currentMana + scaledValue);
          break;
        case 'draw':
          deckController.drawCards(scaledValue);
          break;
        case 'apply_status':
          if (effect.statusId != null) {
            final status = _createStatus(effect.statusId!, scaledValue, effect.duration ?? 1);
            if (status != null) {
              if (card.data.target == CardTarget.singleEnemy && selectedEnemy != null) {
                selectedEnemy.updateStats(selectedEnemy.stats.addStatus(status));
              } else if (card.data.target == CardTarget.allEnemies) {
                for (var enemy in enemyCards) {
                  enemy.updateStats(enemy.stats.addStatus(status));
                }
              } else if (card.data.target == CardTarget.self) {
                runController.addStatus(status);
              }
            }
          }
          break;
      }
    }
    return true;
  }

  /// Calcule les dégâts finaux (influencé par la force et les debuffs)
  static int _calculateDamage(int baseDamage, EntityStats attackerStats) {
    int totalDamage = baseDamage + attackerStats.effectiveAttaque;

    final weakness = attackerStats.statuses
        .where((s) => s.id == 'weakness')
        .toList();
    if (weakness.isNotEmpty) {
      totalDamage = (totalDamage * 0.75).round();
    }

    return totalDamage;
  }
}
