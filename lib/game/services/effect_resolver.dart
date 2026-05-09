import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/status_effect.dart';
import '../../data/models/entity_stats.dart';
import '../controllers/run_controller.dart';
import '../controllers/deck_controller.dart';
import '../components/entities/enemy_card.dart';

class EffectResolver {
  /// Helper pour crÃ©er un StatusEffect Ã  partir des donnÃ©es de la carte
  static StatusEffect? _createStatus(String statusId, int value, int duration) {
    switch (statusId) {
      case 'poison':
        return StatusEffect(id: 'poison', name: 'Poison', type: StatusType.debuff, value: value, duration: duration);
      case 'strength':
        return StatusEffect(id: 'strength', name: 'Force', type: StatusType.buff, value: value, duration: duration);
      case 'weakness':
        return StatusEffect(id: 'weakness', name: 'Faiblesse', type: StatusType.debuff, value: value, duration: duration);
      case 'vulnerable':
        return StatusEffect(id: 'vulnerable', name: 'VunÃ©rable', type: StatusType.debuff, value: value, duration: duration);
      case 'strength_regen':
        return StatusEffect(id: 'strength_regen', name: 'Ã‰veil de Force', type: StatusType.buff, value: value, duration: duration);
      case 'armor_regen':
        return StatusEffect(id: 'armor_regen', name: 'MÃ©tallisation', type: StatusType.buff, value: value, duration: duration);
      default:
        return null;
    }
  }

  /// VÃ©rifie si la carte peut Ãªtre jouÃ©e
  static bool canPlayCard(CardInstance card, RunState runState, EnemyCard? selectedEnemy) {
    // VÃ©rification du mana
    if (runState.heroStats.currentMana < card.currentCost) {
      return false;
    }

    // Interdiction de jouer les statuts
    if (card.data.type == CardType.status) {
      return false;
    }

    // VÃ©rification de la cible
    if (card.data.target == CardTarget.singleEnemy && selectedEnemy == null) {
      return false;
    }

    return true;
  }

  /// RÃ©sout les effets d'une carte sur le joueur et les ennemis
  /// Retourne true si les effets ont dÃ©clenchÃ© une attaque (pour la riposte)
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

    // Consomme le mana
    runController.consumeResource(mana: card.currentCost);

    // Applique les effets
    for (var effect in card.data.effects) {
      // Calcul de la valeur rÃ©elle selon le niveau de la carte (+50% par niveau supplÃ©mentaire)
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
          final currentArmor = runController.currentState.heroStats.armure;
          runController.setHeroStats(armure: currentArmor + scaledValue);
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

    return true; // La carte a Ã©tÃ© jouÃ©e avec succÃ¨s
  }

  /// Calcule les dÃ©gÃ¢ts finaux (influencÃ© par la force et les debuffs)
  static int _calculateDamage(int baseDamage, EntityStats attackerStats) {
    int totalDamage = baseDamage + attackerStats.effectiveAttaque;
    
    // Application de la faiblesse (-25% dÃ©gÃ¢ts)
    final weakness = attackerStats.statuses.where((s) => s.id == 'weakness').toList();
    if (weakness.isNotEmpty) {
      totalDamage = (totalDamage * 0.75).round();
    }

    return totalDamage;
  }
}
