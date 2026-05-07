import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/status_effect.dart';
import '../../data/models/entity_stats.dart';
import '../controllers/run_controller.dart';
import '../components/entities/enemy_card.dart';

class EffectResolver {
  /// Helper pour créer un StatusEffect à partir des données de la carte
  static StatusEffect? _createStatus(String statusId, int value, int duration) {
    switch (statusId) {
      case 'poison':
        return StatusEffect(id: 'poison', name: 'Poison', type: StatusType.debuff, value: value, duration: duration);
      case 'strength':
        return StatusEffect(id: 'strength', name: 'Force', type: StatusType.buff, value: value, duration: duration);
      case 'weakness':
        return StatusEffect(id: 'weakness', name: 'Faiblesse', type: StatusType.debuff, value: value, duration: duration);
      case 'vulnerable':
        return StatusEffect(id: 'vulnerable', name: 'Vulnérable', type: StatusType.debuff, value: value, duration: duration);
      case 'strength_regen':
        return StatusEffect(id: 'strength_regen', name: 'Éveil de Force', type: StatusType.buff, value: value, duration: duration);
      case 'armor_regen':
        return StatusEffect(id: 'armor_regen', name: 'Métallisation', type: StatusType.buff, value: value, duration: duration);
      default:
        return null;
    }
  }

  /// Vérifie si la carte peut être jouée
  static bool canPlayCard(CardInstance card, RunState runState, EnemyCard? selectedEnemy) {
    // Vérification du mana
    if (runState.heroStats.currentMana < card.currentCost) {
      return false;
    }

    // Interdiction de jouer les statuts
    if (card.data.type == CardType.status) {
      return false;
    }

    // Vérification de la cible
    if (card.data.target == CardTarget.singleEnemy && selectedEnemy == null) {
      return false;
    }

    return true;
  }

  /// Résout les effets d'une carte sur le joueur et les ennemis
  /// Retourne true si les effets ont déclenché une attaque (pour la riposte)
  static bool resolveCard(
    CardInstance card,
    RunController runController,
    List<EnemyCard> enemyCards,
    EnemyCard? selectedEnemy,
  ) {
    if (!canPlayCard(card, runController.currentState, selectedEnemy)) {
      return false;
    }

    // Consomme le mana
    runController.consumeResource(mana: card.currentCost);

    // Applique les effets
    for (var effect in card.data.effects) {
      switch (effect.type) {
        case 'damage':
          if (card.data.target == CardTarget.singleEnemy && selectedEnemy != null) {
            int dmg = _calculateDamage(effect.value, runController.currentState.heroStats);
            selectedEnemy.updateStats(selectedEnemy.stats.takeDamage(dmg));
          } else if (card.data.target == CardTarget.allEnemies) {
            int dmg = _calculateDamage(effect.value, runController.currentState.heroStats);
            for (var enemy in enemyCards) {
              enemy.updateStats(enemy.stats.takeDamage(dmg));
            }
          }
          break;
        case 'heal':
          runController.heal(effect.value);
          break;
        case 'armor':
          final currentArmor = runController.currentState.heroStats.armure;
          runController.setHeroStats(armure: currentArmor + effect.value);
          break;
        case 'draw':
          // Géré par le DeckNotifier
          break;
        case 'apply_status':
          if (effect.statusId != null) {
            final status = _createStatus(effect.statusId!, effect.value, effect.duration ?? 1);
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

    return true; // La carte a été jouée avec succès
  }

  /// Calcule les dégâts finaux (influencé par la force et les debuffs)
  static int _calculateDamage(int baseDamage, EntityStats attackerStats) {
    int totalDamage = baseDamage + attackerStats.effectiveAttaque;
    
    // Application de la faiblesse (-25% dégâts)
    final weakness = attackerStats.statuses.where((s) => s.id == 'weakness').toList();
    if (weakness.isNotEmpty) {
      totalDamage = (totalDamage * 0.75).round();
    }

    return totalDamage;
  }
}
