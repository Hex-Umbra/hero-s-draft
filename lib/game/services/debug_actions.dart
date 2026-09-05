import 'package:flutter/foundation.dart';

import '../../models/card_instance.dart';
import '../../models/combat_state.dart';
import '../../models/data/card_data.dart';
import '../../models/data/relic_data.dart';
import '../../models/entity_stats.dart';
import '../../services/save_service.dart' show RefReader;
import '../controllers/combat_controller.dart';
import '../controllers/debug_run_controller.dart';
import '../controllers/deck_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/run_controller.dart';
import '../game_constants.dart';

/// Mutations d'etat reservees au menu de debug.
///
/// Calquee sur `SaveService` : une classe statique qui recoit un `RefReader` et
/// compose les controleurs, sans detenir d'etat. Elle n'appelle que des
/// methodes deja publiques — celles que le systeme de sauvegarde avait deja
/// rendues necessaires.
class DebugActions {
  const DebugActions._();

  /// Deux conditions, verifiees a chaque action.
  ///
  /// Le menu n'est deja affiche qu'en mode debug et dans une run debug ; cette
  /// garde tient la meme promesse au niveau de la logique. Une run normale
  /// n'est alors pas seulement *difficile* a modifier faute de bouton : elle
  /// est intouchable, y compris par un appel egare.
  static bool _allowed(RefReader read) =>
      kDebugMode && read(debugRunProvider).isDebugRun;

  /// Point de mutation unique de `RunState`. L'appelant decrit le changement
  /// avec `copyWith` ; la garde est traitee ici, une seule fois.
  static void updateRun(RefReader read, RunState Function(RunState) mutate) {
    if (!_allowed(read)) return;
    final controller = read(runProvider.notifier);
    controller.updateState(mutate(controller.currentState));
  }

  /// Raccourci pour les champs d'`EntityStats`, imbriques dans `RunState`.
  static void updateHeroStats(
    RefReader read,
    EntityStats Function(EntityStats) mutate,
  ) {
    updateRun(read, (s) => s.copyWith(heroStats: mutate(s.heroStats)));
  }

  /// L'or vit sur `InventoryState`, pas sur `RunState`.
  static void setGold(RefReader read, int gold) {
    if (!_allowed(read)) return;
    read(
      inventoryProvider.notifier,
    ).hydrate(read(inventoryProvider).copyWith(gold: gold));
  }

  /// Acte suivant **avec** regeneration de la carte et perte de la position.
  /// A ne proposer que hors combat.
  static void advanceToNextAct(RefReader read) {
    if (!_allowed(read)) return;
    read(runProvider.notifier).advanceToNextWorld();
  }

  static void addCard(RefReader read, CardData card) {
    if (!_allowed(read)) return;
    read(deckProvider.notifier).addCardToMasterDeck(CardInstance(data: card));
  }

  static void removeCard(RefReader read, String uniqueId) {
    if (!_allowed(read)) return;
    read(deckProvider.notifier).removeCardById(uniqueId);
  }

  static void drawCards(RefReader read, int amount) {
    if (!_allowed(read)) return;
    read(
      deckProvider.notifier,
    ).drawCards(amount, maxHandSize: GameConstants.maxHandSize);
  }

  static void discardHand(RefReader read) {
    if (!_allowed(read)) return;
    read(deckProvider.notifier).discardHand();
  }

  /// `addRelic` declenche deja l'effet des reliques `startOfRun` : le
  /// comportement obtenu est celui du vrai jeu.
  ///
  /// Attention, dissymetrie heritee du jeu et non de ce menu :
  /// `removeRelic` ne defait pas cet effet.
  static void addRelic(RefReader read, RelicData relic) {
    if (!_allowed(read)) return;
    read(inventoryProvider.notifier).addRelic(relic);
  }

  static void removeRelic(RefReader read, String relicId) {
    if (!_allowed(read)) return;
    read(inventoryProvider.notifier).removeRelics([relicId]);
  }

  /// Fixe les PV d'un ennemi, puis resout les morts par le **vrai** chemin :
  /// `cleanDeadEnemies` distribue l'XP, declenche les reliques et fait
  /// apparaitre la vague suivante s'il en reste une.
  ///
  /// A ne pas confondre avec [winCombat], qui court-circuite tout.
  static void setEnemyHp(RefReader read, String enemyId, int currentPv) {
    if (!_allowed(read)) return;
    final combat = read(combatProvider.notifier);
    final index = combat.currentState.enemies.indexWhere(
      (e) => e.id == enemyId,
    );
    if (index == -1) return;
    final enemy = combat.currentState.enemies[index];
    combat.updateEnemyStats(enemyId, enemy.stats.copyWith(currentPv: currentPv));
    combat.cleanDeadEnemies();
  }

  static void killAllEnemies(RefReader read) {
    if (!_allowed(read)) return;
    final combat = read(combatProvider.notifier);
    // Copie explicite : `updateEnemyStats` remplace la liste a chaque appel.
    for (final enemy in List.of(combat.currentState.enemies)) {
      combat.updateEnemyStats(enemy.id, enemy.stats.copyWith(currentPv: 0));
    }
    combat.cleanDeadEnemies();
  }

  /// Termine le combat sans passer par la mort des ennemis : va directement a
  /// l'ecran de recompense.
  static void winCombat(RefReader read) {
    if (!_allowed(read)) return;
    final combat = read(combatProvider.notifier);
    combat.updateState(
      combat.currentState.copyWith(
        enemies: const [],
        pendingEnemies: const [],
        isCombatEnded: true,
        isVictory: true,
      ),
    );
  }

  static void loseCombat(RefReader read) {
    if (!_allowed(read)) return;
    updateHeroStats(read, (s) => s.copyWith(currentPv: 0));
  }

  static void skipEnemyPhase(RefReader read) {
    if (!_allowed(read)) return;
    final combat = read(combatProvider.notifier);
    combat.updateState(
      combat.currentState.copyWith(turnPhase: TurnPhase.player),
    );
  }
}
