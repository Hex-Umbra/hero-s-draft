import 'dart:math';
import '../../../models/card_instance.dart';
import '../../../models/data/card_data.dart';
import '../../controllers/run_controller.dart';
import '../../controllers/deck_controller.dart';
import '../../controllers/combat_controller.dart';
import '../../systems/stat_gains.dart';
import '../../systems/power_rules.dart';
import '../damage_pipeline.dart';
import '../effect_resolver.dart';
import '../../game_constants.dart';
import '../../../services/audio/audio_providers.dart';
import '../../../services/audio/game_moment.dart';
import 'effect_strategy.dart';

class DamageEffectStrategy implements EffectStrategy {
  @override
  void resolve({
    required CardInstance card,
    required CardEffect effect,
    required int scaledValue,
    required RunController runController,
    required DeckNotifier deckController,
    required CombatController combatController,
    required String? selectedEnemyId,
  }) {
    int dealt = 0;

    if (card.data.target == CardTarget.singleEnemy && selectedEnemyId != null) {
      final enemyIndex = combatController.currentState.enemies.indexWhere(
        (e) => e.id == selectedEnemyId,
      );
      if (enemyIndex != -1) {
        final enemy = combatController.currentState.enemies[enemyIndex];
        final (finalDmg, isCrit) = DamagePipeline.calculate(
          initialDamage: scaledValue + runController.currentState.heroStats.damageBonusFor(card.data.type),
          attackerStats: runController.currentState.heroStats,
          defenderStats: enemy.stats,
        );
        combatController.updateEnemyStats(
          selectedEnemyId,
          enemy.stats.takeDamage(finalDmg, isCrit: isCrit),
        );
        dealt += finalDmg;
      }
    } else if (card.data.target == CardTarget.allEnemies) {
      for (var enemy in combatController.currentState.enemies) {
        final (individualDmg, isCrit) = DamagePipeline.calculate(
          initialDamage: scaledValue + runController.currentState.heroStats.damageBonusFor(card.data.type),
          attackerStats: runController.currentState.heroStats,
          defenderStats: enemy.stats,
        );
        combatController.updateEnemyStats(
          enemy.id,
          enemy.stats.takeDamage(individualDmg, isCrit: isCrit),
        );
        dealt += individualDmg;
      }
    }

    _payLifesteal(runController, dealt);
  }

  /// Le soin du Vol de vie, après la résolution des dégâts (spec P-41, §1.2).
  ///
  /// Une fois par carte et jamais plus que les dégâts réellement infligés : sur
  /// une carte qui frappe tout le monde, le total sert de plafond, sinon le
  /// même statut soignerait autant de fois qu'il y a d'ennemis.
  void _payLifesteal(RunController runController, int dealt) {
    if (dealt <= 0) return;
    final buffs = runController.currentState.heroStats.statuses
        .where((s) => s.id == 'lifesteal');
    if (buffs.isEmpty) return;
    runController.heal(min(buffs.first.value, dealt));
  }
}

class HealEffectStrategy implements EffectStrategy {
  @override
  void resolve({
    required CardInstance card,
    required CardEffect effect,
    required int scaledValue,
    required RunController runController,
    required DeckNotifier deckController,
    required CombatController combatController,
    required String? selectedEnemyId,
  }) {
    int healVal = scaledValue;
    final heroStats = runController.currentState.heroStats;
    final random = Random();
    bool isCrit = false;
    if (random.nextInt(100) < heroStats.effectiveCritChance) {
      healVal = (healVal * heroStats.critMultiplier).round();
      isCrit = true;
    }
    runController.heal(healVal, isCrit: isCrit);
  }
}

class ArmorEffectStrategy implements EffectStrategy {
  @override
  void resolve({
    required CardInstance card,
    required CardEffect effect,
    required int scaledValue,
    required RunController runController,
    required DeckNotifier deckController,
    required CombatController combatController,
    required String? selectedEnemyId,
  }) {
    runController.grant(
      StatGain(GainResource.armor, scaledValue, GainSource.card),
    );
  }
}

class GainManaEffectStrategy implements EffectStrategy {
  @override
  void resolve({
    required CardInstance card,
    required CardEffect effect,
    required int scaledValue,
    required RunController runController,
    required DeckNotifier deckController,
    required CombatController combatController,
    required String? selectedEnemyId,
  }) {
    runController.grant(
      StatGain(GainResource.mana, scaledValue, GainSource.card),
    );
    runController.ref.read(audioDirectorProvider).onMoment(GameMoment.manaGain);
  }
}

class DrawEffectStrategy implements EffectStrategy {
  @override
  void resolve({
    required CardInstance card,
    required CardEffect effect,
    required int scaledValue,
    required RunController runController,
    required DeckNotifier deckController,
    required CombatController combatController,
    required String? selectedEnemyId,
  }) {
    deckController.drawCards(scaledValue, maxHandSize: GameConstants.maxHandSize);
  }
}

class ApplyStatusEffectStrategy implements EffectStrategy {
  @override
  void resolve({
    required CardInstance card,
    required CardEffect effect,
    required int scaledValue,
    required RunController runController,
    required DeckNotifier deckController,
    required CombatController combatController,
    required String? selectedEnemyId,
  }) {
    if (effect.statusId != null) {
      // Le ciblage se lit sur la carte, pas sur l'effet : `CardEffect` n'en a pas.
      final status = EffectResolver.createStatus(
        effect.statusId!,
        scaledValue +
            runController.currentState.heroStats.statusBonusFor(card.data.target),
        effect.duration ?? 1,
      );
      if (status != null) {
        if (card.data.target == CardTarget.singleEnemy && selectedEnemyId != null) {
          final enemyIndex = combatController.currentState.enemies
              .indexWhere((e) => e.id == selectedEnemyId);
          if (enemyIndex != -1) {
            final enemy = combatController.currentState.enemies[enemyIndex];
            combatController.updateEnemyStats(
              selectedEnemyId,
              enemy.stats.addStatus(status),
            );
          }
        } else if (card.data.target == CardTarget.allEnemies) {
          for (var enemy in combatController.currentState.enemies) {
            combatController.updateEnemyStats(
              enemy.id,
              enemy.stats.addStatus(status),
            );
          }
        } else if (card.data.target == CardTarget.self) {
          runController.addStatus(status);
        }
      }
    }
  }
}
