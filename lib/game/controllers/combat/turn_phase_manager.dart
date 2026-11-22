import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/combat_state.dart';
import '../../../models/enemy_instance.dart';
import '../../../models/enemy_intent.dart';
import '../../../models/status_effect.dart';
import '../run_controller.dart';
import '../combat_controller.dart';
import '../deck_controller.dart';
import 'status_effect_processor.dart';
import '../../systems/charge_rules.dart';
import '../../systems/stat_gains.dart';
import '../../services/damage_pipeline.dart';
import '../../../services/audio/audio_providers.dart';
import '../../../services/game_data_service.dart';
import '../../../services/audio/game_moment.dart';

class TurnPhaseManager {
  final CombatController controller;
  final Ref ref;

  TurnPhaseManager(this.controller, this.ref);

  /// Vrai dès qu'un camp a perdu : le dernier ennemi est mort, ou le héros.
  /// La phase ennemie peut finir le combat des deux façons — par les statuts
  /// des ennemis, par leurs attaques — et l'écran enchaîne quand même sa fin
  /// de phase : plus aucun tour ne doit alors s'ouvrir.
  bool get _isCombatOver =>
      controller.currentState.isCombatEnded || ref.read(runProvider).isDead;

  /// Ouvre le combat côté joueur : nettoyage des statuts, mana au max,
  /// reliques `startOfCombat`, puis main d'ouverture.
  ///
  /// L'ordre est celui d'avant P-02 et doit le rester : `startCombat()`
  /// déclenche les reliques, la pioche vient après.
  void startPlayerCombat() {
    final runController = ref.read(runProvider.notifier);
    final deckController = ref.read(deckProvider.notifier);

    if (kDebugMode && ref.read(deckProvider).masterDeck.isEmpty) {
      debugPrint('startPlayerCombat: masterDeck vide — '
          'StarterDeckDraftScreen a-t-il été court-circuité ?');
    }

    runController.startCombat();
    deckController.startCombat(
      handSize: runController.currentState.cardsPerTurn,
      maxHandSize: runController.currentState.maxHandSize,
    );
  }

  /// Ouvre un tour joueur : mana, armure, reliques `startOfTurn`, statuts,
  /// cooldowns et passifs, puis pioche.
  ///
  /// L'ordre est celui d'avant P-02 et doit le rester : inverser les deux
  /// appels décalerait toute relique `startOfTurn` d'un tour.
  ///
  /// Sans effet sur un combat fini.
  void startPlayerTurn() {
    if (_isCombatOver) return;
    ref.read(audioDirectorProvider).onMoment(GameMoment.turnStart);
    final runController = ref.read(runProvider.notifier);

    runController.startTurn();
    ref.read(deckProvider.notifier).drawCards(
          runController.currentState.cardsPerTurn,
          maxHandSize: runController.currentState.maxHandSize,
        );
  }

  /// Une fermeture de phase chez tous les porteurs, héros et ennemis (spec
  /// P-53, A9).
  void _closePhase({required bool endsPlayerTurn}) {
    ref.read(runProvider.notifier).updateHeroStats(
          (s) => ChargeRules.closePhase(s, endsPlayerTurn: endsPlayerTurn),
        );
    controller.updateState(
      controller.currentState.copyWith(
        enemies: [
          for (final enemy in controller.currentState.enemies)
            enemy.copyWith(
              stats: ChargeRules.closePhase(
                enemy.stats,
                endsPlayerTurn: endsPlayerTurn,
              ),
            ),
        ],
      ),
    );
  }

  /// Écrit une vague du Feu dans l'état, ou efface le compte rendu s'il n'y
  /// en a pas eu ; rend vrai si la vague s'est jouée.
  bool _playFireWave({required Set<String>? bearerIds, required int wave}) {
    final (row, report) = ChargeRules.fireWave(
      controller.currentState.enemies,
      bearerIds: bearerIds,
      wave: wave,
      charges: ref.read(chargeCatalogProvider),
    );
    controller.updateState(
      controller.currentState.copyWith(
        enemies: row,
        fireWaveReport: report,
        clearFireWaveReport: report == null,
      ),
    );
    return report != null;
  }

  /// Début de la phase ennemie (spec P-53, A12) : la fermeture du tour du
  /// joueur, puis la première vague du Feu. Rend vrai si elle s'est jouée ;
  /// les suivantes passent par [resolveNextFireWave], le reste des statuts
  /// par [resolveEnemyStatuses].
  bool startEnemyTurn() {
    controller.updateState(
      controller.currentState.copyWith(turnPhase: TurnPhase.enemy),
    );
    _closePhase(endsPlayerTurn: true);
    return _playFireWave(bearerIds: null, wave: 1);
  }

  /// La vague suivante de la chaîne du Feu, sur les porteurs que la précédente
  /// a nommés ; faux, compte rendu effacé, quand la chaîne est finie.
  bool resolveNextFireWave() {
    final report = controller.currentState.fireWaveReport;
    if (report == null || report.nextBearerIds.isEmpty) {
      controller.updateState(
        controller.currentState.copyWith(clearFireWaveReport: true),
      );
      return false;
    }
    return _playFireWave(
      bearerIds: report.nextBearerIds,
      wave: report.wave + 1,
    );
  }

  /// Les autres statuts de chaque ennemi, après la chaîne du Feu, puis le
  /// nettoyage des morts, une seule fois — ceux de la chaîne compris (spec
  /// P-53, A10).
  void resolveEnemyStatuses() {
    final charges = ref.read(chargeCatalogProvider);
    controller.updateState(
      controller.currentState.copyWith(
        enemies: [
          for (final enemy in controller.currentState.enemies)
            enemy.copyWith(
              stats: StatusEffectProcessor.processEnemyStatuses(
                enemy.stats,
                charges,
              ),
            ),
        ],
        clearFireWaveReport: true,
      ),
    );

    controller.cleanDeadEnemies();
  }

  /// Fin de la phase ennemie : sa fermeture (spec P-53, A9), puis roll
  /// intents et retour au joueur. Sans effet sur un combat fini.
  void endEnemyTurn() {
    if (_isCombatOver) return;
    _closePhase(endsPlayerTurn: false);
    final List<EnemyInstance> rolledEnemies = controller.currentState.enemies
        .map((enemy) => controller.rollIntent(enemy))
        .toList();

    controller.updateState(
      controller.currentState.copyWith(
        enemies: rolledEnemies,
        turnPhase: TurnPhase.player,
        turnCount: controller.currentState.turnCount + 1,
      ),
    );
  }

  /// Applique l'effet de l'intention d'un ennemi ; un ennemi gelé ne résout
  /// rien et dépense son gel, qu'il ait une intention ou non (spec P-53, A13).
  void resolveEnemyIntent(String enemyId) {
    final runController = ref.read(runProvider.notifier);
    final index = controller.currentState.enemies.indexWhere((e) => e.id == enemyId);
    if (index == -1) return;
    final enemy = controller.currentState.enemies[index];

    if (enemy.skipsAction) {
      controller.updateEnemy(
        enemy.copyWith(stats: ChargeRules.consumeSkip(enemy.stats)),
      );
      return;
    }

    final intent = enemy.effectiveIntent;
    if (intent == null) return;

    switch (intent.type) {
      case IntentType.attack:
        final charges = ref.read(chargeCatalogProvider);
        final (dmg, isCrit) = DamagePipeline.calculate(
          initialDamage: intent.value,
          attackerStats: enemy.stats,
          defenderStats: runController.currentState.heroStats,
          charges: charges,
        );

        runController.updateHeroStats((s) => ChargeRules.noteHit(s, charges));
        runController.takeDamage(dmg, isCrit: isCrit);
        break;
      case IntentType.defend:
        final updatedEnemy = enemy.copyWith(
          stats: StatGains.apply(
            enemy.stats,
            StatGain(GainResource.armor, intent.value, GainSource.enemyIntent),
            const [],
          ),
        );
        controller.updateEnemy(updatedEnemy);
        break;
      case IntentType.buff:
        final updatedEnemy = enemy.copyWith(
          stats: enemy.stats.addStatus(
            StatusEffect(
              id: 'might',
              name: 'Puissance',
              type: StatusType.buff,
              value: intent.value,
              duration: 99,
              // L'id de la donnée, jamais l'uuid de l'instance (spec P-43
              // E0, A2).
              sourceId: StatusSource.enemy(enemy.data.id),
            ),
          ),
        );
        controller.updateEnemy(updatedEnemy);
        break;
    }
  }
}
