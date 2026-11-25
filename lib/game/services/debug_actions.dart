import 'package:flutter/foundation.dart';

import '../../models/card_instance.dart';
import '../../models/combat_state.dart';
import '../../models/data/card_data.dart';
import '../../models/data/charge_data.dart';
import '../../models/data/enemy_data.dart';
import '../../models/data/relic_data.dart';
import '../../models/entity_stats.dart';
import '../../models/signature_instance.dart';
import '../../services/game_data_service.dart';
import '../../services/save_service.dart' show RefReader;
import '../systems/charge_rules.dart';
import '../systems/encounter_system.dart';
import '../systems/signature_evolution_rules.dart';
import '../controllers/combat_controller.dart';
import '../controllers/debug_run_controller.dart';
import '../controllers/deck_controller.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/run_controller.dart';

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

  /// Fait gagner exactement un niveau, par le **vrai** chemin.
  ///
  /// Ecrire `level` a la main ne fait qu'ecraser une statistique : l'XP
  /// accumulee n'est pas consommee et le draft de recompense ne s'ouvre pas.
  /// `gainXp` fait les deux, dont l'incrementation de `pendingDrafts` —
  /// c'est elle qui fait apparaitre l'overlay de montee de niveau sur la
  /// carte. Le palier est celui de l'acte courant, lu sur la courbe (spec
  /// P-43 E3, §4.4).
  static void gainLevel(RefReader read) {
    if (!_allowed(read)) return;
    final run = read(runProvider);
    final threshold = read(xpCurveProvider).thresholdFor(run.act);
    final missing = threshold - run.heroStats.xp;
    read(runProvider.notifier).gainXp(missing > 0 ? missing : 1);
  }

  /// Pose l'evolution [evolutionId] sur la signature [signatureId], par les
  /// regles du jeu : elle doit etre dans le pool de la signature et dans ce
  /// que son prochain palier admet. Refuse sans rien ecrire (retourne `false`, que seuls les tests lisent).
  ///
  /// Seule l'attente n'est pas lue (spec §8) : ni `pendingFor`, ni le niveau
  /// du heros, ni la sauvegarde.
  static bool takeSignatureEvolution(
    RefReader read,
    String signatureId,
    String evolutionId,
  ) {
    if (!_allowed(read)) return false;
    final signature = read(
      runProvider,
    ).signatures.where((s) => s.data.id == signatureId).firstOrNull;
    if (signature == null) return false;
    final taken = SignatureEvolutionRules.take(signature, evolutionId);
    if (taken == null) return false;
    _replaceSignature(read, signature, taken);
    return true;
  }

  /// Rend la signature [signatureId] sans aucune evolution.
  static void clearSignatureEvolutions(RefReader read, String signatureId) {
    final signature = read(
      runProvider,
    ).signatures.where((s) => s.data.id == signatureId).firstOrNull;
    if (signature == null) return;
    _replaceSignature(read, signature, SignatureInstance(signature.data));
  }

  static void _replaceSignature(
    RefReader read,
    SignatureInstance from,
    SignatureInstance to,
  ) {
    updateRun(
      read,
      (s) => s.copyWith(
        signatures: [for (final x in s.signatures) x == from ? to : x],
      ),
    );
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
    ).drawCards(amount, maxHandSize: read(runProvider).maxHandSize);
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
    combat.updateEnemyStats(
      enemyId,
      enemy.stats.copyWith(currentPv: currentPv),
    );
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

  /// La rangee la plus longue que le plateau sait placer (spec P-05, vague 2,
  /// B91). Un combat n'en met jamais plus de cinq a la fois ; le menu de debug
  /// peut aller jusqu'a six pour essayer la rangee pleine.
  static const int maxEnemiesOnBoard = 6;

  /// Fait entrer un ennemi de [data] sur le plateau, aux PV et a la Puissance
  /// d'un combat normal de l'acte et du niveau courants, intention tiree.
  /// Rien hors d'un combat en cours, ni au-dela de [maxEnemiesOnBoard].
  static void spawnEnemy(RefReader read, EnemyData data) {
    if (!_allowed(read)) return;
    final combat = read(combatProvider.notifier);
    final state = combat.currentState;
    if (state.isCombatEnded || state.enemies.length >= maxEnemiesOnBoard) {
      return;
    }
    final run = read(runProvider);
    final enemy = CombatController.scaledEnemy(
      data,
      enemyLevel: EncounterSystem.getEnemyLevel(
        playerLevel: run.heroStats.level,
        isBoss: false,
        isElite: false,
      ),
      act: run.act,
      isBoss: false,
      isElite: false,
    );
    combat.updateState(
      state.copyWith(enemies: [...state.enemies, combat.rollIntent(enemy)]),
    );
  }

  /// Pose un point de la charge [chargeId] par `ChargeRules.pose` : plafond,
  /// refus sur un porteur rompu, rupture au seuil. Sans bonus de Puissance.
  /// [enemyId] nul : le heros ; un id absent du catalogue, ou un ennemi
  /// absent du combat : rien.
  static void poseCharge(RefReader read, String chargeId, {String? enemyId}) {
    if (!_allowed(read)) return;
    final charge = read(chargeCatalogProvider)[chargeId];
    if (charge == null) return;
    if (enemyId == null) {
      read(runProvider.notifier).updateHeroStats(
        (s) => ChargeRules.pose(s, charge, 1, ChargeBearer.hero),
      );
      return;
    }
    final combat = read(combatProvider.notifier);
    final enemy = combat.currentState.enemies
        .where((e) => e.id == enemyId)
        .firstOrNull;
    if (enemy == null) return;
    combat.updateEnemyStats(
      enemyId,
      ChargeRules.pose(enemy.stats, charge, 1, ChargeRules.bearerOf(enemy)),
    );
  }

  /// Vide les charges du heros et de chaque ennemi : les entrees des ids du
  /// catalogue et les pistes. Les autres statuts, Poison compris, restent.
  static void clearCharges(RefReader read) {
    if (!_allowed(read)) return;
    final ids = read(chargeCatalogProvider).ids;
    EntityStats cleared(EntityStats s) => s.copyWith(
      statuses: [
        for (final status in s.statuses)
          if (!ids.contains(status.id)) status,
      ],
      charges: const {},
    );
    read(runProvider.notifier).updateHeroStats(cleared);
    final combat = read(combatProvider.notifier);
    for (final enemy in List.of(combat.currentState.enemies)) {
      combat.updateEnemyStats(enemy.id, cleared(enemy.stats));
    }
  }

  /// Raccourci de debug : ne force que la phase joueur. Elle ne joue ni la
  /// chaine du Feu ni les fermetures de phase des charges — une charge
  /// rompue le reste (decision du plan P-53).
  static void skipEnemyPhase(RefReader read) {
    if (!_allowed(read)) return;
    final combat = read(combatProvider.notifier);
    combat.updateState(
      combat.currentState.copyWith(turnPhase: TurnPhase.player),
    );
  }
}
