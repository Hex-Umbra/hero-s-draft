import 'dart:math';
import '../../../models/card_instance.dart';
import '../../../models/data/card_data.dart';
import '../../controllers/run_controller.dart';
import '../../controllers/deck_controller.dart';
import '../../controllers/combat_controller.dart';
import '../damage_pipeline.dart';
import '../effect_resolver.dart';
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
    if (card.data.target == CardTarget.singleEnemy && selectedEnemyId != null) {
      final enemyIndex = combatController.currentState.enemies.indexWhere(
        (e) => e.id == selectedEnemyId,
      );
      if (enemyIndex != -1) {
        final enemy = combatController.currentState.enemies[enemyIndex];
        final (finalDmg, isCrit) = DamagePipeline.calculate(
          initialDamage: scaledValue + runController.currentState.heroStats.effectiveAttaque,
          attackerStats: runController.currentState.heroStats,
          defenderStats: enemy.stats,
        );
        combatController.updateEnemyStats(
          selectedEnemyId,
          enemy.stats.takeDamage(finalDmg, isCrit: isCrit),
        );
      }
    } else if (card.data.target == CardTarget.allEnemies) {
      for (var enemy in combatController.currentState.enemies) {
        final (individualDmg, isCrit) = DamagePipeline.calculate(
          initialDamage: scaledValue + runController.currentState.heroStats.effectiveAttaque,
          attackerStats: runController.currentState.heroStats,
          defenderStats: enemy.stats,
        );
        combatController.updateEnemyStats(
          enemy.id,
          enemy.stats.takeDamage(individualDmg, isCrit: isCrit),
        );
      }
    }
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
    final currentStats = runController.currentState.heroStats;
    runController.setHeroStats(armure: currentStats.armure + scaledValue);
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
    final currentMana = runController.currentState.heroStats.currentMana;
    runController.setHeroStats(currentMana: currentMana + scaledValue);
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
    deckController.drawCards(scaledValue);
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
      final status = EffectResolver.createStatus(
        effect.statusId!,
        scaledValue,
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
