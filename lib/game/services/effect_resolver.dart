
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/status_effect.dart';
import '../controllers/run_controller.dart';
import '../controllers/deck_controller.dart';
import '../controllers/combat_controller.dart';
import 'effects/effect_strategy.dart';

class EffectResolver {

  /// Helper pour créer un StatusEffect à partir des données de la carte.
  ///
  /// [sourceId] est ce qui pose le statut (`StatusSource`). Seule la
  /// Puissance le retient : tout autre statut est posé sans source et fusionne
  /// comme avant — la portée de la règle s'écrit ici, une fois, pour le chemin
  /// des cartes (spec P-43 E0, A1 et §4.4).
  static StatusEffect? createStatus(
    String statusId,
    int value,
    int duration, {
    String? sourceId,
  }) {
    switch (statusId) {
      case 'poison':
        return StatusEffect(
          id: 'poison',
          name: 'Poison',
          type: StatusType.debuff,
          value: value,
          duration: duration,
        );
      case 'might':
        return StatusEffect(
          id: 'might',
          name: 'Puissance',
          type: StatusType.buff,
          value: value,
          duration: duration,
          sourceId: sourceId,
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
      case 'might_regen':
        return StatusEffect(
          id: 'might_regen',
          name: 'Éveil de Puissance',
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
      case 'burn':
        return StatusEffect(
          id: 'burn',
          name: 'Brûlure',
          type: StatusType.debuff,
          value: value,
          duration: duration,
        );
      case 'freeze':
        return StatusEffect(
          id: 'freeze',
          name: 'Gel',
          type: StatusType.debuff,
          value: value,
          duration: duration,
        );
      case 'shock':
        return StatusEffect(
          id: 'shock',
          name: 'Électrocution',
          type: StatusType.debuff,
          value: value,
          duration: duration,
        );
      default:
        return null;
    }
  }

  /// Vérifie si la carte peut être jouée
  static bool canPlayCard(
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

  /// Résout les effets d'une carte
  static bool resolveCard(
    CardInstance card,
    RunController runController,
    DeckNotifier deckController,
    CombatController combatController,
    String? selectedEnemyId,
    EffectRegistry registry,
  ) {
    if (!canPlayCard(card, runController.currentState, selectedEnemyId)) {
      return false;
    }

    runController.consumeResource(mana: card.currentCost);

    // Les effets que les runes ajoutent d'abord, puis ceux de la carte, à leur
    // valeur jouée — rareté et runes comprises : l'applicateur est seul à la
    // calculer, et les stratégies du registre seules à résoudre un effet,
    // ceux des runes compris (spec P-43 E1, A2, §4.4). Les statuts des runes
    // sont donc posés par `addStatus`, sans source (spec P-43 E0, A4).
    final effective = card.effective;
    for (final effect in [...effective.addedEffects, ...effective.effects]) {
      registry.get(effect.type)?.resolve(
            card: card,
            effect: effect,
            scaledValue: effect.value,
            runController: runController,
            deckController: deckController,
            combatController: combatController,
            selectedEnemyId: selectedEnemyId,
          );
    }

    return true;
  }
}
