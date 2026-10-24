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
import '../../../models/signature_instance.dart';
import '../services/combat_debug_logger.dart';
import '../systems/encounter_system.dart';
import '../systems/passives/passive_strategy.dart';
import '../systems/trait_system.dart';
import '../services/effect_resolver.dart';
import '../services/effects/effect_strategy.dart';
import 'run_controller.dart';
import 'deck_controller.dart';
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
    int playerMight = 0,
    int playerMaxMana = 3,
    int playerRelicsCount = 0,
    int deckFusionRanks = 0,
    String? bossEnemyId,
  }) {
    final enemyDataList = EncounterSystem.generateEnemiesForLevel(
      level,
      availableEnemies,
      nodeType: nodeType,
      playerLevel: playerLevel,
      act: act,
      playerMaxHp: playerMaxHp,
      playerMight: playerMight,
      playerMaxMana: playerMaxMana,
      playerRelicsCount: playerRelicsCount,
      deckFusionRanks: deckFusionRanks,
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
      playerMight: playerMight,
      playerMaxMana: playerMaxMana,
      playerRelicsCount: playerRelicsCount,
      deckFusionRanks: deckFusionRanks,
      isBoss: isBoss,
      isElite: isElite,
    );

    CombatDebugLogger.logCombatInitialization(
      playerLevel: playerLevel,
      act: act,
      nodeType: nodeType,
      playerMaxHp: playerMaxHp,
      playerMight: playerMight,
      playerMaxMana: playerMaxMana,
      playerRelicsCount: playerRelicsCount,
      deckFusionRanks: deckFusionRanks,
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
        might: (data.baseDamage * enemyDamageMultiplier).round(),
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

  /// Applique le jeu d'une carte par le joueur
  void applyPlayerCardPlay(CardInstance card) {
    final runController = ref.read(runProvider.notifier);
    final deckController = ref.read(deckProvider.notifier);

    // 1. Résolution des effets
    final success = EffectResolver.resolveCard(
      card,
      runController,
      deckController,
      this,
      state.selectedEnemyId,
      ref.read(effectRegistryProvider),
    );
    if (!success) return;

    // 2. Transmettre au deck que la carte est jouée
    deckController.playCard(card);

    // 3. La suite commune. `enemyId` n'est renseigné que pour une carte qui
    // vise un seul ennemi (contrat de `PassiveEvent.enemyId`) : une carte à
    // portée de groupe laisserait sinon une sélection résiduelle marquer un
    // seul ennemi.
    _afterCardPlayed(
      card,
      enemyId: card.data.target == CardTarget.singleEnemy
          ? state.selectedEnemyId
          : null,
    );
  }

  /// Joue une signature (spec P-43 E4, §4.3) : résolue comme une carte, par
  /// sa vue de carte, puis mise en recharge ; elle n'entre dans aucune pile.
  ///
  /// Rend `false` sans rien toucher si le tour n'est pas au joueur, si le
  /// combat est fini, si la signature n'est pas de la run, si elle recharge,
  /// si elle vise un seul ennemi sans [enemyId] — jamais la sélection
  /// restante d'une carte précédente —, ou si le mana manque.
  bool playSignature(SignatureInstance signature, {String? enemyId}) {
    final runController = ref.read(runProvider.notifier);
    final runState = runController.currentState;
    final id = signature.data.id;
    final card = signature.asCard;
    final isSingleTarget = card.data.target == CardTarget.singleEnemy;

    // 1. Les refus sans effet. La run se compare par id : une run rechargée
    // reconstruit ses instances (A8).
    if (state.turnPhase != TurnPhase.player || state.isCombatEnded) {
      return false;
    }
    if (!runState.signatures.any((s) => s.data.id == id)) return false;
    if (!state.isSignatureReady(id)) return false;
    if (isSingleTarget && enemyId == null) return false;

    // 2. Mana et cible, avant toute écriture.
    if (!EffectResolver.canPlayCard(card, runState, enemyId)) return false;

    // 3. La cible, comme l'écran la pose avant de jouer une carte, puis la
    // résolution, qui paie le mana. Le contrôle de l'étape 2 porte sur le
    // même état : elle réussit.
    if (isSingleTarget) selectEnemy(enemyId);
    EffectResolver.resolveCard(
      card,
      runController,
      ref.read(deckProvider.notifier),
      this,
      enemyId,
      ref.read(effectRegistryProvider),
    );

    // 4. La recharge : le tour à partir duquel elle se rejoue.
    state = state.copyWith(
      signaturesReadyOn: {
        ...state.signaturesReadyOn,
        id: state.turnCount + signature.cooldown,
      },
    );

    // 5. Aucune pile. 6. La suite commune.
    _afterCardPlayed(card, enemyId: isSingleTarget ? enemyId : null);
    return true;
  }

  /// Ce qui suit le jeu d'une carte comme celui d'une signature : les
  /// passifs (l'événement générique, puis celui du type), les reliques des
  /// mêmes événements, puis le nettoyage des morts. Un seul chemin : tout ce
  /// qui écoute une carte jouée voit une signature jouée (spec P-43 E4,
  /// §4.4 ; Q-P1).
  void _afterCardPlayed(CardInstance card, {required String? enemyId}) {
    final runController = ref.read(runProvider.notifier);

    TraitSystem.dispatch(
      runController,
      PassiveEvent(RelicTrigger.onCardPlayed, card: card, enemyId: enemyId),
    );
    final typedTrigger = switch (card.data.type) {
      CardType.attack => RelicTrigger.onAttackPlayed,
      CardType.skill => RelicTrigger.onSkillPlayed,
      CardType.power => RelicTrigger.onPowerPlayed,
      // Une carte Statut ne se joue pas (`EffectResolver.canPlayCard`).
      CardType.status => null,
    };
    if (typedTrigger != null) {
      TraitSystem.dispatch(
        runController,
        PassiveEvent(typedTrigger, card: card, enemyId: enemyId),
      );
    }

    runController.applyRelics(RelicTrigger.onCardPlayed);
    if (typedTrigger != null) runController.applyRelics(typedTrigger);

    cleanDeadEnemies();
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
