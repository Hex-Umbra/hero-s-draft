import 'dart:math';
import '../../../models/card_instance.dart';
import '../../../models/data/card_data.dart';
import '../../../models/effective_card.dart';
import '../../../models/enemy_instance.dart';
import '../../../models/entity_stats.dart';
import '../../../models/status_effect.dart';
import '../../controllers/run_controller.dart';
import '../../controllers/deck_controller.dart';
import '../../controllers/combat_controller.dart';
import '../../systems/stat_gains.dart';
import '../../systems/power_rules.dart';
import '../damage_pipeline.dart';
import '../effect_resolver.dart';
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
    // Les runes de la carte : critique, perforation, éclaboussure.
    final effective = card.effective;

    for (var hit = 0; hit < effect.hits; hit++) {
      // Les ennemis sont relus à chaque coup : un mort ne reçoit plus rien.
      final living = combatController.currentState.enemies
          .where((e) => e.stats.currentPv > 0);
      final targets = switch (card.data.target) {
        CardTarget.singleEnemy =>
          living.where((e) => e.id == selectedEnemyId).toList(),
        CardTarget.allEnemies => living.toList(),
        _ => <EnemyInstance>[],
      };
      // Une cible unique morte ou absente : les coups restants sont perdus.
      if (targets.isEmpty) break;

      for (final enemy in targets) {
        final heroStats = runController.currentState.heroStats;
        // La part de Puissance du coup, arrondie vers le bas (A13).
        final might =
            (heroStats.damageBonusFor(card.data.type) * effect.mightRatio +
                    1e-9)
                .floor();
        final initialDamage = scaledValue + might;
        dealt += _strike(
          combatController,
          effective,
          enemy,
          heroStats,
          initialDamage,
        );
        // Ricochant : la cible frappée, les autres ennemis vivants prennent
        // leur part du coup (spec §4.6, A17).
        if (card.data.target == CardTarget.singleEnemy &&
            effective.splashPercent > 0) {
          final base = max(
            1,
            (effective.splashPercent * initialDamage + 50) ~/ 100,
          );
          final others = combatController.currentState.enemies
              .where((e) => e.id != enemy.id && e.stats.currentPv > 0)
              .toList();
          for (final other in others) {
            dealt += _strike(
              combatController,
              effective,
              other,
              heroStats,
              base,
            );
          }
        }
      }
    }

    _payLifesteal(runController, dealt);
    _payRuneLifesteal(runController, effective, dealt);
  }

  /// Un coup de [initialDamage] sur [enemy] : le pipeline contre **ses**
  /// statuts, puis l'Armure, perforation de la carte comprise. Rend les dégâts
  /// de pipeline, ceux que le vol de vie compte.
  int _strike(
    CombatController combatController,
    EffectiveCard effective,
    EnemyInstance enemy,
    EntityStats heroStats,
    int initialDamage,
  ) {
    final (finalDmg, isCrit) = DamagePipeline.calculate(
      initialDamage: initialDamage,
      attackerStats: heroStats,
      defenderStats: enemy.stats,
      critChanceBonus: effective.critChanceBonus,
    );
    combatController.updateEnemyStats(
      enemy.id,
      enemy.stats.takeDamage(
        finalDmg,
        isCrit: isCrit,
        armorPiercePercent: effective.armorPiercePercent,
        armorPierceFloor: effective.armorPierceLevel,
      ),
    );
    return finalDmg;
  }

  /// Le soin de la rune Vampirique : `p × L` % des dégâts infligés, la demie
  /// vers le haut, au moins `L`, jamais plus que les dégâts — une fois par
  /// carte, après le Vol de vie du statut, sans critique (spec §4.6, A18).
  void _payRuneLifesteal(
    RunController runController,
    EffectiveCard effective,
    int dealt,
  ) {
    if (effective.lifestealLevel <= 0 || dealt < 1) return;
    final share = (effective.lifestealPercent * dealt + 50) ~/ 100;
    runController.heal(min(dealt, max(share, effective.lifestealLevel)));
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
    // La carte `draw` et la rune `quick` (un `addEffect draw`) passent toutes
    // deux ici : la borne est la stat de run (spec P-43 E3, §4.3).
    deckController.drawCards(
      scaledValue,
      maxHandSize: runController.currentState.maxHandSize,
    );
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
        // Le bonus de Puissance de statut est déjà dans [scaledValue] : le
        // résolveur le donne au seul premier statut de la résolution (Q11).
        scaledValue,
        effect.duration ?? 1,
        // L'id de la carte, jamais celui de l'exemplaire : deux exemplaires
        // d'une même carte s'additionnent (spec P-43 E0, A2).
        sourceId: StatusSource.card(card.data.id),
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
