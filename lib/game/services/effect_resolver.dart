import 'dart:math';

import '../../models/card_instance.dart';
import '../../models/combat_state.dart';
import '../../models/data/card_data.dart';
import '../../models/effective_card.dart';
import '../../models/entity_stats.dart';
import '../../models/status_effect.dart';
import '../controllers/run_controller.dart';
import '../systems/cost_rules.dart';
import '../systems/power_rules.dart';
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

  /// La seule règle d'accessibilité d'une carte (A10) : le mana courant,
  /// runes appliquées ; les coûts en PV et en Armure de la donnée, que ni la
  /// rareté ni une rune ne changent (D40). `canPlayCard` et
  /// `CardComponent.canAfford` la lisent.
  static bool canAfford(CardInstance card, EntityStats heroStats) =>
      heroStats.canPay(
        mana: card.currentCost,
        hp: card.data.hpCost,
        armor: card.data.armorCost,
      );

  /// Vérifie si la carte peut être jouée : ses coûts, puis les deux règles
  /// d'aujourd'hui — une carte Statut ne se joue pas, une cible unique exige
  /// un ennemi.
  static bool canPlayCard(
    CardInstance card,
    RunState runState,
    String? selectedEnemyId,
  ) {
    if (!canAfford(card, runState.heroStats)) return false;
    if (card.data.type == CardType.status) return false;
    if (card.data.target == CardTarget.singleEnemy && selectedEnemyId == null) {
      return false;
    }
    return true;
  }

  /// Joue une carte, dans l'ordre de spec §4.7 : (1) refusée, rien n'est
  /// écrit ; (2) le paiement ; (3) les effets ; (4) l'écho ; (5)
  /// *Transfusion*. Une carte payée se résout jusqu'au bout. [random] tire le
  /// jet de l'écho ; `Random()` par défaut.
  static bool resolveCard(
    CardInstance card,
    RunController runController,
    DeckNotifier deckController,
    CombatController combatController,
    String? selectedEnemyId,
    EffectRegistry registry, {
    Random? random,
  }) {
    // 1.
    if (!canPlayCard(card, runController.currentState, selectedEnemyId)) {
      return false;
    }

    // 2. Une écriture, hors du pipeline. Le contrôle de l'étape 1 porte sur
    // le même état : le débit réussit.
    final hpCost = card.data.hpCost;
    if (!runController.consumeResource(
      mana: card.currentCost,
      hp: hpCost,
      armor: card.data.armorCost,
    )) {
      return false;
    }

    // 3. et 4. Une seconde résolution au plus, sans coût ni second jet (A19).
    // Elle ne rejoue pas la carte : les piles et les événements « carte
    // jouée » restent au contrôleur (P-3 (a)).
    final effective = card.effective;
    void resolveOnce() => _resolveEffects(card, effective, runController,
        deckController, combatController, selectedEnemyId, registry);
    resolveOnce();
    if (effective.echoChance > 0 &&
        (random ?? Random()).nextInt(100) < effective.echoChance) {
      resolveOnce();
    }

    // 5. La moitié du coût en PV, la demie vers le haut, une fois (A20).
    if (hpCost > 0 && effective.hpRefundPercent > 0) {
      runController.refundHp((effective.hpRefundPercent * hpCost + 50) ~/ 100);
    }
    return true;
  }

  /// Une résolution complète des effets de [effective], dans l'ordre (spec
  /// P-44 lot 1, §4.7) : chaque valeur gagne son terme `scaleWith`, lu à cet
  /// instant, et le premier `apply_status` — celui d'une rune compris — gagne
  /// seul la Puissance de statut (Q11, A15).
  static void _resolveEffects(
    CardInstance card,
    EffectiveCard effective,
    RunController runController,
    DeckNotifier deckController,
    CombatController combatController,
    String? selectedEnemyId,
    EffectRegistry registry,
  ) {
    var statusBonusPending = true;
    for (final effect in [...effective.addedEffects, ...effective.effects]) {
      final heroStats = runController.currentState.heroStats;
      var value = effect.value +
          scaleTerm(
            effect,
            hero: heroStats,
            combat: combatController.currentState,
            targetId: selectedEnemyId,
          );
      // Le drapeau tombe au premier statut, que le bonus vaille 0 ou non.
      if (effect.type == 'apply_status' && statusBonusPending) {
        value += heroStats.statusBonusFor(card.data.target);
        statusBonusPending = false;
      }
      registry.get(effect.type)?.resolve(
            card: card,
            effect: effect,
            scaledValue: value,
            runController: runController,
            deckController: deckController,
            combatController: combatController,
            selectedEnemyId: selectedEnemyId,
          );
    }
  }

  /// Ce que la croissance de [effect] ajoute à sa valeur : 0 sans `scaleWith`,
  /// sinon le terme de la quantité que sa source lit (spec P-44 lot 1, §4.2).
  /// Lue par la résolution, et par l'affichage du badge.
  static int scaleTerm(
    CardEffect effect, {
    required EntityStats hero,
    required CombatState combat,
    String? targetId,
  }) {
    final scale = effect.scaleWith;
    if (scale == null) return 0;
    final target =
        combat.enemies.where((e) => e.id == targetId).firstOrNull?.stats;
    final quantity = switch (scale.source) {
      ScaleSource.armor => hero.armure,
      ScaleSource.missingHp => hero.maxPv - hero.currentPv,
      ScaleSource.cardsPlayedThisTurn => combat.cardsPlayedThisTurn,
      ScaleSource.enemiesAlive =>
        combat.enemies.where((e) => e.stats.currentPv > 0).length,
      ScaleSource.targetStatus => target?.statuses
              .where((s) => s.id == scale.statusId)
              .fold<int>(0, (sum, s) => sum + s.value) ??
          0,
      ScaleSource.targetMissingHp =>
        target == null ? 0 : target.maxPv - target.currentPv,
    };
    return scale.termFor(quantity);
  }
}
