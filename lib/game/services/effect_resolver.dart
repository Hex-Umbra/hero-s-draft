
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/status_effect.dart';
import '../controllers/run_controller.dart';
import '../controllers/deck_controller.dart';
import '../controllers/combat_controller.dart';
import 'effects/effect_strategy.dart';
import '../game_constants.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/game_moment.dart';

class EffectResolver {

  /// Helper pour créer un StatusEffect à partir des données de la carte
  static StatusEffect? createStatus(String statusId, int value, int duration) {
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

  /// Vérifie si la carte peut être jouée.
  ///
  /// [ref] est optionnel : seul l'appel interne depuis [resolveCard] le
  /// fournit, pour émettre `GameMoment.insufficientMana` au refus. Le
  /// laisser absent ne change aucune règle de jeu — seulement l'absence de
  /// ce retour audio pour cet appelant précis.
  static bool canPlayCard(
    CardInstance card,
    RunState runState,
    String? selectedEnemyId, {
    Ref? ref,
  }) {
    if (runState.heroStats.currentMana < card.currentCost) {
      ref?.read(audioDirectorProvider).onMoment(GameMoment.insufficientMana);
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
    if (!canPlayCard(
      card,
      runController.currentState,
      selectedEnemyId,
      ref: runController.ref,
    )) {
      return false;
    }

    runController.consumeResource(mana: card.currentCost);

    int extraDamage = 0;
    int extraArmor = 0;
    int extraDraw = 0;
    int extraMana = 0;
    int elementBurn = 0;
    int elementFreeze = 0;
    int elementShock = 0;

    for (var upgrade in card.forgeUpgrades) {
      final parts = upgrade.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final k = int.tryParse(parts[1]) ?? 0;
      if (k <= 0) continue;
      switch (id) {
        case 'sharp':
          extraDamage += 2 * k;
          break;
        case 'hardened':
          extraArmor += 2 * k;
          break;
        case 'quick':
          extraDraw += k;
          break;
        case 'eco':
          extraMana += k;
          break;
        case 'burning':
          elementBurn += k;
          break;
        case 'freezing':
          elementFreeze += k;
          break;
        case 'shocking':
          elementShock += k;
          break;
      }
    }

    if (extraDraw > 0) {
      deckController.drawCards(extraDraw, maxHandSize: GameConstants.maxHandSize);
    }
    if (extraMana > 0) {
      final currentMana = runController.currentState.heroStats.currentMana;
      runController.setHeroStats(currentMana: currentMana + extraMana);
    }

    // Apply elemental statuses if this is an Attack card
    if (card.data.type == CardType.attack) {
      final List<StatusEffect> extraStatuses = [];
      if (elementBurn > 0) {
        final st = createStatus('burn', elementBurn, elementBurn);
        if (st != null) extraStatuses.add(st);
      }
      if (elementFreeze > 0) {
        final st = createStatus('freeze', elementFreeze, elementFreeze);
        if (st != null) extraStatuses.add(st);
      }
      if (elementShock > 0) {
        final st = createStatus('shock', elementShock, elementShock);
        if (st != null) extraStatuses.add(st);
      }

      if (extraStatuses.isNotEmpty) {
        if (card.data.target == CardTarget.singleEnemy && selectedEnemyId != null) {
          final enemyIndex = combatController.currentState.enemies
              .indexWhere((e) => e.id == selectedEnemyId);
          if (enemyIndex != -1) {
            final enemy = combatController.currentState.enemies[enemyIndex];
            combatController.updateEnemyStats(
              enemy.id,
              enemy.stats.copyWith(
                statuses: [...enemy.stats.statuses, ...extraStatuses],
              ),
            );
          }
        } else if (card.data.target == CardTarget.allEnemies) {
          for (var enemy in combatController.currentState.enemies) {
            combatController.updateEnemyStats(
              enemy.id,
              enemy.stats.copyWith(
                statuses: [...enemy.stats.statuses, ...extraStatuses],
              ),
            );
          }
        }
      }
    }

    for (var effect in card.data.effects) {
      final int baseValue = effect.value;
      int scaledValue = (baseValue * card.rarityMultiplier).round();
      if (effect.type == 'damage') {
        scaledValue += extraDamage;
      } else if (effect.type == 'armor') {
        scaledValue += extraArmor;
      }

      final strategy = registry.get(effect.type);
      if (strategy != null) {
        strategy.resolve(
          card: card,
          effect: effect,
          scaledValue: scaledValue,
          runController: runController,
          deckController: deckController,
          combatController: combatController,
          selectedEnemyId: selectedEnemyId,
        );
      }
    }

    final hasArmorEffect = card.data.effects.any((e) => e.type == 'armor');
    if (!hasArmorEffect && extraArmor > 0) {
      final currentStats = runController.currentState.heroStats;
      runController.setHeroStats(armure: currentStats.armure + extraArmor);
    }

    return true;
  }
}
