import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/entity_stats.dart';
import '../../../models/card_instance.dart';
import '../../../models/combat_state.dart';
import '../../../models/enemy_instance.dart';
import '../../../models/enemy_intent.dart';
import '../../../models/data/card_data.dart';
import '../../../models/data/enemy_data.dart';
import '../../../models/data/relic_data.dart';
import '../../../models/map_node.dart';
import '../services/combat_debug_logger.dart';
import '../systems/encounter_system.dart';
import '../systems/trait_system.dart';
import '../services/effect_resolver.dart';
import '../services/effects/effect_strategy.dart';
import '../../../models/data/skill_data.dart';
import 'run_controller.dart';
import 'deck_controller.dart';
import '../services/damage_pipeline.dart';
import 'combat/turn_phase_manager.dart';

class CombatController extends Notifier<CombatState> {
  late final TurnPhaseManager _turnPhaseManager;

  @override
  CombatState build() {
    _turnPhaseManager = TurnPhaseManager(this, ref);
    return CombatState();
  }

  CombatState get currentState => state;

  /// Permet aux managers de mettre à jour l'état du combat
  void updateState(CombatState newState) {
    state = newState;
  }

  /// Génère les ennemis via EncounterSystem et initialise l'état du combat
  void initializeCombat(
    int level,
    MapNodeType? nodeType,
    List<EnemyData> availableEnemies, {
    int playerLevel = 1,
    int act = 1,
    int playerMaxHp = 100,
    int playerAttaque = 0,
    int playerMaxMana = 3,
    int playerRelicsCount = 0,
    int playerCardsCount = 0,
    String? bossEnemyId,
  }) {
    final enemyDataList = EncounterSystem.generateEnemiesForLevel(
      level,
      availableEnemies,
      nodeType: nodeType,
      playerLevel: playerLevel,
      act: act,
      playerMaxHp: playerMaxHp,
      playerAttaque: playerAttaque,
      playerMaxMana: playerMaxMana,
      playerRelicsCount: playerRelicsCount,
      playerCardsCount: playerCardsCount,
      bossEnemyId: bossEnemyId,
    );

    final bool isBoss = nodeType == MapNodeType.boss || (nodeType == null && level > 0 && level % 10 == 0);
    final bool isElite = nodeType == MapNodeType.elite;

    final int enemyLevel = EncounterSystem.getEnemyLevel(
      playerLevel: playerLevel,
      isBoss: isBoss,
      isElite: isElite,
    );

    final double hpMultiplier = EncounterSystem.getHpMultiplier(
      enemyLevel: enemyLevel,
      act: act,
      isBoss: isBoss,
      isElite: isElite,
    );

    final double damageMultiplier = EncounterSystem.getDamageMultiplier(
      enemyLevel: enemyLevel,
      act: act,
      isBoss: isBoss,
      isElite: isElite,
    );

    final int maxEnemies = isBoss
        ? EncounterSystem.getMaxEnemiesForBoss(act)
        : (isElite ? EncounterSystem.getMaxEnemiesForElite(act) : EncounterSystem.getMaxEnemiesForNormalCombat(act));

    // Detailed debug prints with mathematical calculations and formulas.
    // Delegates to EncounterSystem.calculateBudget so the displayed values
    // can never drift from the ones actually used to generate enemyDataList.
    final budget = EncounterSystem.calculateBudget(
      playerLevel: playerLevel,
      act: act,
      playerMaxHp: playerMaxHp,
      playerAttaque: playerAttaque,
      playerMaxMana: playerMaxMana,
      playerRelicsCount: playerRelicsCount,
      playerCardsCount: playerCardsCount,
      isBoss: isBoss,
      isElite: isElite,
    );

    CombatDebugLogger.logCombatInitialization(
      playerLevel: playerLevel,
      act: act,
      nodeType: nodeType,
      playerMaxHp: playerMaxHp,
      playerAttaque: playerAttaque,
      playerMaxMana: playerMaxMana,
      playerRelicsCount: playerRelicsCount,
      playerCardsCount: playerCardsCount,
      playerPower: budget.playerPower,
      expectedPower: budget.expectedPower,
      baseBudget: budget.baseBudget,
      powerRatio: budget.powerRatio,
      powerModifier: budget.powerModifier,
      nodeMultiplier: budget.nodeMultiplier,
      finalBudget: budget.finalBudget,
      enemyLevel: enemyLevel,
      hpMultiplier: hpMultiplier,
      damageMultiplier: damageMultiplier,
      maxEnemies: maxEnemies,
      enemyDataList: enemyDataList,
      isBoss: isBoss,
      isElite: isElite,
    );

    final List<EnemyInstance> allEnemyInstances = [];
    for (var data in enemyDataList) {
      final bool isCustomBoss = data.id.startsWith('boss_');
      final double enemyHpMultiplier = EncounterSystem.getHpMultiplier(
        enemyLevel: enemyLevel,
        act: act,
        isBoss: isBoss,
        isElite: isElite,
        isCustomBoss: isCustomBoss,
      );
      final double enemyDamageMultiplier = EncounterSystem.getDamageMultiplier(
        enemyLevel: enemyLevel,
        act: act,
        isBoss: isBoss,
        isElite: isElite,
        isCustomBoss: isCustomBoss,
      );

      final stats = EntityStats(
        maxPv: (data.maxHp * enemyHpMultiplier).round(),
        currentPv: (data.maxHp * enemyHpMultiplier).round(),
        armure: 0,
        attaque: (data.baseDamage * enemyDamageMultiplier).round(),
        level: enemyLevel,
        critChance: data.critChance,
      );

      var enemy = EnemyInstance(data: data, stats: stats, isBoss: isBoss);
      allEnemyInstances.add(enemy);
    }

    final List<EnemyInstance> activeEnemies = [];
    final List<EnemyInstance> pendingEnemies = [];

    for (int i = 0; i < allEnemyInstances.length; i++) {
      var enemy = allEnemyInstances[i];
      if (i < 5) {
        enemy = rollIntent(enemy);
        activeEnemies.add(enemy);
      } else {
        pendingEnemies.add(enemy);
      }
    }

    state = CombatState(
      enemies: activeEnemies,
      pendingEnemies: pendingEnemies,
      defeatedEnemies: const [],
      turnPhase: TurnPhase.player,
      turnCount: 1,
      selectedEnemyId: null,
      isCombatEnded: false,
      isVictory: false,
    );
  }

  /// Sélectionne l'ennemi ciblé par le joueur
  void selectEnemy(String? enemyId) {
    state = state.copyWith(
      selectedEnemyId: enemyId,
      clearSelectedEnemy: enemyId == null,
    );
  }

  /// Met à jour les statistiques d'un ennemi spécifique
  void updateEnemyStats(String enemyId, EntityStats newStats) {
    state = state.copyWith(
      enemies: state.enemies.map((enemy) {
        if (enemy.id != enemyId) return enemy;
        return enemy.copyWith(stats: newStats);
      }).toList(),
    );
  }

  /// Résout les calculs et l'application d'un Skill (compétence héroïque)
  void executeSkill(SkillData skill, {String? targetEnemyId}) {
    final runController = ref.read(runProvider.notifier);
    final heroStats = runController.currentState.heroStats;
    final effectiveAttaque = runController.currentState.effectiveAttaque;

    if (skill.effectType == 'damage_aoe') {
      state = state.copyWith(
        enemies: state.enemies.map((enemy) {
          final (dmg, isCrit) = DamagePipeline.calculate(
            initialDamage: (effectiveAttaque * (skill.effectValue / 100.0)).round(),
            attackerStats: heroStats,
            defenderStats: enemy.stats,
          );
          return enemy.copyWith(stats: enemy.stats.takeDamage(dmg, isCrit: isCrit));
        }).toList(),
      );
      cleanDeadEnemies();
    } else if (skill.effectType == 'damage_targeted' && targetEnemyId != null) {
      state = state.copyWith(
        enemies: state.enemies.map((enemy) {
          if (enemy.id != targetEnemyId) return enemy;
          final (dmg, isCrit) = DamagePipeline.calculate(
            initialDamage: (effectiveAttaque * (skill.effectValue / 100.0)).round(),
            attackerStats: heroStats,
            defenderStats: enemy.stats,
          );
          return enemy.copyWith(stats: enemy.stats.takeDamage(dmg, isCrit: isCrit));
        }).toList(),
      );
      cleanDeadEnemies();
    } else if (skill.effectType == 'damage_pierce' && targetEnemyId != null) {
      final enemyIndex = state.enemies.indexWhere((e) => e.id == targetEnemyId);
      if (enemyIndex != -1) {
        final enemy = state.enemies[enemyIndex];
        final (dmg, isCrit) = DamagePipeline.calculate(
          initialDamage: effectiveAttaque,
          attackerStats: heroStats,
          defenderStats: enemy.stats,
        );
        int stolenArmor = (enemy.stats.armure * (skill.effectValue / 100.0)).round();
        int newPv = enemy.stats.currentPv - dmg;
        int newArm = enemy.stats.armure - stolenArmor;
        if (newPv < 0) newPv = 0;
        if (newArm < 0) newArm = 0;

        state = state.copyWith(
          enemies: state.enemies.map((e) {
            if (e.id != targetEnemyId) return e;
            return e.copyWith(
              stats: e.stats.copyWith(
                currentPv: newPv,
                armure: newArm,
                lastActionWasCrit: isCrit,
              ),
            );
          }).toList(),
        );
        if (stolenArmor > 0) {
          runController.setHeroStats(armure: heroStats.armure + stolenArmor);
        }
        cleanDeadEnemies();
      }
    } else if (skill.effectType == 'armor_buff') {
      runController.setHeroStats(armure: heroStats.armure + skill.effectValue);
    }
  }

  /// Applique le jeu d'une carte par le joueur
  void applyPlayerCardPlay(CardInstance card) {
    final runController = ref.read(runProvider.notifier);
    final deckController = ref.read(deckProvider.notifier);
    final registry = ref.read(effectRegistryProvider);

    // 1. Résolution des effets
    final success = EffectResolver.resolveCard(
      card,
      runController,
      deckController,
      this,
      state.selectedEnemyId,
      registry,
    );

    if (success) {
      // 2. Transmettre au deck que la carte est jouée
      deckController.playCard(card);

      // 3. Déclencher les traits passifs
      TraitSystem.onCardPlayed(runController, card);

      // 4. Déclencher les reliques liées aux cartes jouées
      runController.applyRelics(RelicTrigger.onCardPlayed);
      if (card.data.type == CardType.attack) {
        runController.applyRelics(RelicTrigger.onAttackPlayed);
      } else if (card.data.type == CardType.skill) {
        runController.applyRelics(RelicTrigger.onSkillPlayed);
      } else if (card.data.type == CardType.power) {
        runController.applyRelics(RelicTrigger.onPowerPlayed);
      }

      // 5. Nettoyer les morts
      cleanDeadEnemies();
    }
  }

  /// Applique l'effet de l'intention d'un ennemi
  void resolveEnemyIntent(String enemyId) {
    _turnPhaseManager.resolveEnemyIntent(enemyId);
  }

  /// Ouvre le combat côté joueur (statuts, mana, reliques, main d'ouverture)
  void startPlayerCombat() {
    _turnPhaseManager.startPlayerCombat();
  }

  /// Ouvre un tour joueur (mana, reliques, statuts, pioche)
  void startPlayerTurn() {
    _turnPhaseManager.startPlayerTurn();
  }

  /// Début du tour de l'ennemi (application des statuts autonomes)
  void startEnemyTurn() {
    _turnPhaseManager.startEnemyTurn();
  }

  /// Fin de la phase ennemie : roll intents et retour au joueur
  void endEnemyTurn() {
    _turnPhaseManager.endEnemyTurn();
  }

  /// Décrémente la durée des statuts de l'ennemi
  void tickEnemyStatuses(String enemyId) {
    state = state.copyWith(
      enemies: state.enemies.map((enemy) {
        if (enemy.id != enemyId) return enemy;
        return enemy.copyWith(stats: enemy.stats.tickStatuses());
      }).toList(),
    );
  }

  /// Calcule et attribue la prochaine intention de l'ennemi
  void rollIntentForEnemy(String enemyId) {
    state = state.copyWith(
      enemies: state.enemies.map((enemy) {
        if (enemy.id != enemyId) return enemy;
        return rollIntent(enemy);
      }).toList(),
    );
  }

  /// Nettoie les ennemis décédés et met à jour les indicateurs de fin de combat
  void cleanDeadEnemies() {
    final runController = ref.read(runProvider.notifier);
    final List<EnemyInstance> remainingEnemies = [];
    final List<EnemyInstance> newlyKilledEnemies = [];
    int killedCount = 0;

    for (var enemy in state.enemies) {
      if (enemy.stats.currentPv <= 0) {
        killedCount++;
        newlyKilledEnemies.add(enemy);
        runController.onEnemyKilled();
      } else {
        remainingEnemies.add(enemy);
      }
    }

    if (killedCount > 0) {
      final List<EnemyInstance> nextPending = List.from(state.pendingEnemies);
      for (int i = 0; i < killedCount; i++) {
        if (remainingEnemies.length < 5 && nextPending.isNotEmpty) {
          var incoming = nextPending.removeAt(0);
          incoming = rollIntent(incoming);
          remainingEnemies.add(incoming);
        }
      }

      String? nextSelected = state.selectedEnemyId;
      if (nextSelected != null &&
          !remainingEnemies.any((e) => e.id == nextSelected)) {
        nextSelected = null;
      }

      final bool isCombatEnded = remainingEnemies.isEmpty && nextPending.isEmpty;
      final bool isVictory = isCombatEnded;

      state = state.copyWith(
        enemies: remainingEnemies,
        pendingEnemies: nextPending,
        defeatedEnemies: [...state.defeatedEnemies, ...newlyKilledEnemies],
        selectedEnemyId: nextSelected,
        clearSelectedEnemy: nextSelected == null,
        isCombatEnded: isCombatEnded,
        isVictory: isVictory,
      );
    }
  }

  /// Met à jour l'instance interne d'un ennemi
  void updateEnemy(EnemyInstance updatedEnemy) {
    state = state.copyWith(
      enemies: state.enemies
          .map((e) => e.id == updatedEnemy.id ? updatedEnemy : e)
          .toList(),
    );
  }

  /// Calcule l'intention suivante d'un ennemi
  EnemyInstance rollIntent(EnemyInstance enemy) {
    final data = enemy.data;
    EnemyIntent nextIntent;
    int nextStep = enemy.intentStep;

    if (data.intents != null && data.intents!.isNotEmpty) {
      nextIntent = data.intents![enemy.intentStep];
      nextStep = (enemy.intentStep + 1) % data.intents!.length;
    } else {
      final random = Random();
      final roll = random.nextInt(100);

      if (roll < 60) {
        nextIntent = EnemyIntent(
          type: IntentType.attack,
          value: data.baseDamage,
        );
      } else if (roll < 85) {
        nextIntent = EnemyIntent(
          type: IntentType.defend,
          value: 5 + random.nextInt(6),
        );
      } else {
        nextIntent = EnemyIntent(type: IntentType.buff, value: 2);
      }
    }
    return enemy.copyWith(currentIntent: nextIntent, intentStep: nextStep);
  }
}

final combatProvider = NotifierProvider<CombatController, CombatState>(CombatController.new);
