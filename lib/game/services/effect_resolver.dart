import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../controllers/run_controller.dart';
import '../components/entities/enemy_card.dart';

class EffectResolver {
  /// Vérifie si la carte peut être jouée
  static bool canPlayCard(CardInstance card, RunState runState, EnemyCard? selectedEnemy) {
    // Vérification du mana
    if (runState.heroStats.currentMana < card.currentCost) {
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

    bool triggerEnemyRiposte = false;

    // Applique les effets
    for (var effect in card.data.effects) {
      switch (effect.type) {
        case 'damage':
          if (card.data.target == CardTarget.singleEnemy && selectedEnemy != null) {
            int dmg = _calculateDamage(effect.value, runController.currentState.effectiveAttaque);
            selectedEnemy.updateStats(selectedEnemy.stats.takeDamage(dmg));
            triggerEnemyRiposte = true;
          } else if (card.data.target == CardTarget.allEnemies) {
            int dmg = _calculateDamage(effect.value, runController.currentState.effectiveAttaque);
            for (var enemy in enemyCards) {
              enemy.updateStats(enemy.stats.takeDamage(dmg));
            }
            triggerEnemyRiposte = true;
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
          // Géré par le DeckNotifier, mais on pourrait retourner une commande ou l'appeler ici
          // si on injecte le deckController. Pour simplifier, ça peut être géré en retour ou via events.
          break;
        // On ajoutera d'autres types d'effets au fur et à mesure (ex: poison, buff, etc.)
      }
    }

    return triggerEnemyRiposte;
  }

  /// Calcule les dégâts finaux (peut être influencé par la force du joueur)
  static int _calculateDamage(int baseDamage, int playerAttack) {
    // Pour l'instant on additionne la force du joueur à l'effet de la carte
    // Ou bien la valeur de l'effet EST le dégât et on rajoute juste l'attaque.
    return baseDamage + playerAttack;
  }
}
