import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/status_effect.dart';
import '../../../models/data/relic_data.dart';
import '../inventory_controller.dart';
import '../run_controller.dart';
import '../checkpoint_controller.dart';

class PlayerStatsManager {
  final RunController controller;
  final Ref ref;

  PlayerStatsManager(this.controller, this.ref);

  /// Applique un modificateur à la carte héro (ex: récompense de draft)
  void applyHeroStatModifier({
    int maxPvAcc = 0,
    int attackAcc = 0,
    int armorAcc = 0,
    int maxManaAcc = 0,
    int luckAcc = 0,
    int critChanceAcc = 0,
    double critDamageAcc = 0.0,
  }) {
    final currentStats = controller.currentState.heroStats;
    final newMaxPv = currentStats.maxPv + maxPvAcc;
    final newCurrentPv =
        (currentStats.currentPv + (maxPvAcc > 0 ? maxPvAcc : 0)).clamp(
          0,
          newMaxPv,
        );

    final newMaxMana = currentStats.maxMana + maxManaAcc;
    // On ajoute aussi le bonus au mana actuel
    final newCurrentMana = (currentStats.currentMana + maxManaAcc).clamp(
      0,
      newMaxMana,
    );

    controller.updateState(
      controller.currentState.copyWith(
        heroStats: currentStats.copyWith(
          maxPv: newMaxPv,
          currentPv: newCurrentPv,
          maxMana: newMaxMana,
          currentMana: newCurrentMana,
          attaque: currentStats.attaque + attackAcc,
          armorMastery: currentStats.armorMastery + armorAcc,
          luck: currentStats.luck + luckAcc,
          critChance: currentStats.critChance + critChanceAcc,
          critMultiplier: currentStats.critMultiplier + critDamageAcc,
        ),
      ),
    );
  }

  /// Applique un modificateur aux règles de run propres au joueur.
  /// Distinct d'`applyHeroStatModifier`, qui opère sur `EntityStats` — lequel
  /// est partagé avec les ennemis et n'a donc pas à porter de notion de deck.
  void applyRunRuleModifier({int cardsPerTurnAcc = 0}) {
    controller.updateState(
      controller.currentState.copyWith(
        cardsPerTurn: controller.currentState.cardsPerTurn + cardsPerTurnAcc,
      ),
    );
  }

  /// Ajoute de l'Expérience au joueur.
  /// Gère les montées de niveaux successives avec conservation de l'XP excédentaire (carry-over).
  /// Retourne [true] si au moins un niveau a été gagné.
  bool gainXp(int amount) {
    if (amount <= 0) return false;

    var currentStats = controller.currentState.heroStats;
    int newXp = currentStats.xp + amount;
    int currentLevel = currentStats.level;
    int currentXpToNext = currentStats.xpToNextLevel;
    bool leveledUp = false;
    int levelsGained = 0;

    while (newXp >= currentXpToNext) {
      newXp -= currentXpToNext;
      currentLevel++;
      // Formule d'XP requise pour le nouveau niveau: 100 * (1.5 ^ (level - 1))
      currentXpToNext = (100 * pow(1.5, currentLevel - 1)).round();
      leveledUp = true;
      levelsGained++;
    }

    controller.updateState(
      controller.currentState.copyWith(
        heroStats: currentStats.copyWith(
          level: currentLevel,
          xp: newXp,
          xpToNextLevel: currentXpToNext,
        ),
        pendingDrafts: controller.currentState.pendingDrafts + levelsGained,
      ),
    );

    return leveledUp;
  }

  void decrementPendingDrafts() {
    if (controller.currentState.pendingDrafts > 0) {
      controller.updateState(
        controller.currentState.copyWith(
          pendingDrafts: controller.currentState.pendingDrafts - 1,
        ),
      );
      ref.read(checkpointProvider.notifier).bump();
    }
  }

  void resetPendingDrafts() {
    controller.updateState(
      controller.currentState.copyWith(pendingDrafts: 0),
    );
  }

  /// Applique un soin en jeu
  void heal(int amount, {bool isCrit = false}) {
    int newPv = (controller.currentState.heroStats.currentPv + amount).clamp(
      0,
      controller.currentState.heroStats.maxPv,
    );
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: controller.currentState.heroStats.copyWith(
          currentPv: newPv,
          lastActionWasCrit: isCrit,
        ),
      ),
    );
  }

  /// Modifie la valeur exacte d'un champ sans affecter les max (pour la récupération d'armure par ex)
  void setHeroStats({
    int? currentPv,
    int? armure,
    int? currentMana,
    int? armorMastery,
    bool? lastActionWasCrit,
  }) {
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: controller.currentState.heroStats.copyWith(
          currentPv: currentPv ?? controller.currentState.heroStats.currentPv,
          armure: armure ?? controller.currentState.heroStats.armure,
          currentMana: currentMana ?? controller.currentState.heroStats.currentMana,
          armorMastery: armorMastery ?? controller.currentState.heroStats.armorMastery,
          lastActionWasCrit: lastActionWasCrit ?? false,
        ),
      ),
    );
  }

  /// Subit des dégâts
  void takeDamage(int amount, {bool isCrit = false}) {
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: controller.currentState.heroStats.takeDamage(amount, isCrit: isCrit),
      ),
    );
  }

  /// Applique un effet de statut
  void addStatus(StatusEffect effect) {
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: controller.currentState.heroStats.addStatus(effect),
      ),
    );
  }

  /// Déclenche les effets des reliques pour un trigger donné
  void applyRelics(RelicTrigger trigger) {
    final relics = ref.read(inventoryProvider).relics;
    final relevantRelics = relics.where((r) => r.trigger == trigger).toList();
    for (var relic in relevantRelics) {
      applyRelicEffect(relic);
    }
  }

  /// Déclenche les reliques d'élimination d'ennemi
  void onEnemyKilled() {
    applyRelics(RelicTrigger.onEnemyKilled);
  }

  void applyRelicEffect(RelicData relic) {
    switch (relic.effectType) {
      case 'gain_mana':
        if (relic.trigger == RelicTrigger.startOfRun) {
          applyHeroStatModifier(maxManaAcc: relic.value);
        } else {
          controller.updateState(
            controller.currentState.copyWith(
              heroStats: controller.currentState.heroStats.copyWith(
                currentMana: controller.currentState.heroStats.currentMana + relic.value,
              ),
            ),
          );
        }
        break;
      case 'gain_armor':
        controller.updateState(
          controller.currentState.copyWith(
            heroStats: controller.currentState.heroStats.copyWith(
              armure: controller.currentState.heroStats.armure + relic.value,
            ),
          ),
        );
        break;
      case 'gain_strength':
        if (relic.trigger == RelicTrigger.startOfRun) {
          applyHeroStatModifier(attackAcc: relic.value);
        } else {
          addStatus(
            StatusEffect(
              id: 'strength',
              name: 'Force (Relique)',
              type: StatusType.buff,
              value: relic.value,
              duration: 99, // 99 tours (durée du combat)
            ),
          );
        }
        break;
      case 'gain_luck':
        if (relic.trigger == RelicTrigger.startOfRun) {
          applyHeroStatModifier(luckAcc: relic.value);
        } else {
          controller.updateState(
            controller.currentState.copyWith(
              heroStats: controller.currentState.heroStats.copyWith(
                luck: controller.currentState.heroStats.luck + relic.value,
              ),
            ),
          );
        }
        break;
      case 'gain_crit':
        if (relic.trigger == RelicTrigger.startOfRun) {
          applyHeroStatModifier(critChanceAcc: relic.value);
        } else {
          addStatus(
            StatusEffect(
              id: 'crit_chance',
              name: 'Critique (Relique)',
              type: StatusType.buff,
              value: relic.value,
              duration: 99, // 99 tours (durée du combat)
            ),
          );
        }
        break;
      case 'heal':
        heal(relic.value);
        break;
      // Cet effectType n'a de sens qu'en `startOfRun` : une variante par combat
      // ou par tour cumulerait indéfiniment. Aucune garde n'est posée ici, le
      // contrat étant porté par la donnée (`relics.json`) et par le `case`
      // symétrique de `removeRelicEffect`.
      case 'increase_cards_per_turn':
        applyRunRuleModifier(cardsPerTurnAcc: relic.value);
        break;
      case 'charge_armor_mastery_combat':
        final existing = controller.currentState.heroStats.statuses.where((s) => s.id == 'kunai_charge');
        final int newVal = (existing.isEmpty ? 0 : existing.first.value) + 1;
        if (newVal >= 3) {
          final updatedStatuses = controller.currentState.heroStats.statuses.where((s) => s.id != 'kunai_charge').toList();
          controller.updateState(
            controller.currentState.copyWith(
              heroStats: controller.currentState.heroStats.copyWith(
                statuses: updatedStatuses,
              ),
            ),
          );
          addStatus(
            StatusEffect(
              id: 'armor_mastery',
              name: 'Maîtrise d\'Armure (Relique)',
              type: StatusType.buff,
              value: relic.value,
              duration: 99,
            ),
          );
        } else {
          addStatus(
            const StatusEffect(
              id: 'kunai_charge',
              name: 'Charge Kunaï',
              type: StatusType.buff,
              value: 1,
              duration: 1,
              isStackable: true,
            ),
          );
        }
        break;
      case 'charge_strength_combat':
        final existing = controller.currentState.heroStats.statuses.where((s) => s.id == 'shuriken_charge');
        final int newVal = (existing.isEmpty ? 0 : existing.first.value) + 1;
        if (newVal >= 3) {
          final updatedStatuses = controller.currentState.heroStats.statuses.where((s) => s.id != 'shuriken_charge').toList();
          controller.updateState(
            controller.currentState.copyWith(
              heroStats: controller.currentState.heroStats.copyWith(
                statuses: updatedStatuses,
              ),
            ),
          );
          addStatus(
            StatusEffect(
              id: 'strength',
              name: 'Force (Relique)',
              type: StatusType.buff,
              value: relic.value,
              duration: 99,
            ),
          );
        } else {
          addStatus(
            const StatusEffect(
              id: 'shuriken_charge',
              name: 'Charge Shuriken',
              type: StatusType.buff,
              value: 1,
              duration: 1,
              isStackable: true,
            ),
          );
        }
        break;
      case 'charge_strength_turn':
        final existing = controller.currentState.heroStats.statuses.where((s) => s.id == 'pen_nib_charge');
        final int newVal = (existing.isEmpty ? 0 : existing.first.value) + 1;
        if (newVal >= 5) {
          final updatedStatuses = controller.currentState.heroStats.statuses.where((s) => s.id != 'pen_nib_charge').toList();
          controller.updateState(
            controller.currentState.copyWith(
              heroStats: controller.currentState.heroStats.copyWith(
                statuses: updatedStatuses,
              ),
            ),
          );
          addStatus(
            StatusEffect(
              id: 'strength',
              name: 'Force (Relique)',
              type: StatusType.buff,
              value: relic.value,
              duration: 1,
            ),
          );
        } else {
          addStatus(
            const StatusEffect(
              id: 'pen_nib_charge',
              name: 'Charge Plume',
              type: StatusType.buff,
              value: 1,
              duration: 99,
              isStackable: true,
            ),
          );
        }
        break;
      case 'charge_armor_turn':
        final existing = controller.currentState.heroStats.statuses.where((s) => s.id == 'incense_charge');
        final int newVal = (existing.isEmpty ? 0 : existing.first.value) + 1;
        if (newVal >= 4) {
          final updatedStatuses = controller.currentState.heroStats.statuses.where((s) => s.id != 'incense_charge').toList();
          controller.updateState(
            controller.currentState.copyWith(
              heroStats: controller.currentState.heroStats.copyWith(
                statuses: updatedStatuses,
              ),
            ),
          );
          setHeroStats(armure: controller.currentState.heroStats.armure + relic.value);
        } else {
          addStatus(
            const StatusEffect(
              id: 'incense_charge',
              name: 'Charge Encensoir',
              type: StatusType.buff,
              value: 1,
              duration: 99,
              isStackable: true,
            ),
          );
        }
        break;
    }
  }

  void removeRelicEffect(RelicData relic) {
    if (relic.trigger == RelicTrigger.startOfRun) {
      switch (relic.effectType) {
        case 'gain_mana':
          applyHeroStatModifier(maxManaAcc: -relic.value);
          break;
        case 'gain_strength':
          applyHeroStatModifier(attackAcc: -relic.value);
          break;
        case 'gain_luck':
          applyHeroStatModifier(luckAcc: -relic.value);
          break;
        case 'gain_crit':
          applyHeroStatModifier(critChanceAcc: -relic.value);
          break;
        case 'increase_cards_per_turn':
          applyRunRuleModifier(cardsPerTurnAcc: -relic.value);
          break;
      }
    }
  }

  void exchangeRelics(List<RelicData> sacrificed, RelicData gained) {
    for (var relic in sacrificed) {
      removeRelicEffect(relic);
    }
    final sacrificedIds = sacrificed.map((r) => r.id).toList();
    ref.read(inventoryProvider.notifier).removeRelics(sacrificedIds);
    ref.read(inventoryProvider.notifier).addRelic(gained);
  }

  /// Consomme les ressources nécessaires. Retourne false si insuffisant.
  bool consumeResource({int mana = 0, int hpPercent = 0}) {
    int hpCost = 0;
    if (hpPercent > 0) {
      hpCost = (controller.currentState.heroStats.currentPv * (hpPercent / 100.0)).round();
      if (hpCost < 1) hpCost = 1;
      if (controller.currentState.heroStats.currentPv <= hpCost) return false;
    }

    if (mana > 0 && controller.currentState.heroStats.currentMana < mana) {
      return false;
    }

    controller.updateState(
      controller.currentState.copyWith(
        heroStats: controller.currentState.heroStats.copyWith(
          currentMana: controller.currentState.heroStats.currentMana - mana,
          currentPv: controller.currentState.heroStats.currentPv - hpCost,
        ),
      ),
    );
    return true;
  }

  /// Applique un buff d'attaque pour une durée donnée
  void applyAttackBuff(int duration) {
    int bonus = (controller.currentState.heroStats.maxPv * 0.15).round();
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: controller.currentState.heroStats.addStatus(
          StatusEffect(
            id: 'strength',
            name: 'Attaque',
            type: StatusType.buff,
            value: bonus,
            duration: duration,
          ),
        ),
      ),
    );
  }

  /// Applique un effet de Vol de vie pour une durée donnée
  void applyLifestealBuff(int duration) {
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: controller.currentState.heroStats.addStatus(
          StatusEffect(
            id: 'lifesteal',
            name: 'Vol de Vie',
            type: StatusType.buff,
            value: 1,
            duration: duration,
          ),
        ),
      ),
    );
  }
}
