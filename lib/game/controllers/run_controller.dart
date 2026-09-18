import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entity_stats.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/relic_data.dart';
import '../../models/data/passive_data.dart';
import '../../models/data/stat_rule.dart';
import '../../models/map_node.dart';
import '../../models/status_effect.dart';
import '../../models/missing_save_item.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../services/map_generator_service.dart';
import '../services/level_up_reward_service.dart';
import '../systems/passives/passive_strategy.dart';
import '../systems/trait_system.dart';
import '../systems/stat_gains.dart';
import 'debug_run_controller.dart';
import 'inventory_controller.dart';
import 'run/player_stats_manager.dart';
import 'run/map_progression_manager.dart';
import 'run/gold_manager.dart';
import 'combat/status_effect_processor.dart';

class RunState {
  final int currentLevel;
  final int act;
  final EntityStats heroStats;
  final String heroClassId;
  final List<MapNode> mapNodes;
  final String? currentNodeId;
  final PassiveData? activePassive; // Passif dynamique du héros
  final List<String> forgeSlots;
  final String? forgeTargetCardId;
  final Map<String, List<String>> forgeTargetSessions;
  final int bonusForgeSlots;
  final int pendingDrafts; // Nombre de drafts de montée de niveau en attente

  /// Cartes piochées au début de chaque tour, et taille de la main d'ouverture.
  /// Règle de run propre au joueur : elle n'a pas sa place sur `EntityStats`,
  /// qui est partagé avec les ennemis.
  final int cardsPerTurn;

  /// Les règles de stat de la classe (spec P-41, §7.1), pour la même raison
  /// que `cardsPerTurn` : un ennemi n'en a jamais.
  ///
  /// **Jamais sérialisées.** Une règle est du contenu : `fromJsonWithReport`
  /// la relit de la classe, comme il relit déjà le passif actif. Les figer
  /// dans une sauvegarde ferait survivre à une modification du `class.json`
  /// une run qui n'en tiendrait pas compte.
  final List<StatRule> statRules;

  bool get isBossLevel => currentLevel > 0 && currentLevel % 10 == 0;
  bool get isDead => heroStats.currentPv <= 0;

  MapNodeType? get currentNodeType {
    if (currentNodeId == null) return null;
    try {
      return mapNodes.firstWhere((n) => n.id == currentNodeId).type;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'RunState.currentNodeType: currentNodeId "$currentNodeId" not found in mapNodes ($e)',
        );
      }
      return null;
    }
  }

  const RunState({
    required this.currentLevel,
    this.act = 1,
    required this.heroStats,
    required this.heroClassId,
    this.mapNodes = const [],
    this.currentNodeId,
    this.activePassive,
    this.forgeSlots = const [],
    this.forgeTargetCardId,
    this.forgeTargetSessions = const {},
    this.bonusForgeSlots = 0,
    this.pendingDrafts = 0,
    this.cardsPerTurn = 5,
    this.statRules = const [],
  });

  RunState copyWith({
    int? currentLevel,
    int? act,
    EntityStats? heroStats,
    String? heroClassId,
    List<MapNode>? mapNodes,
    String? currentNodeId,
    bool resetCurrentNode = false,
    PassiveData? activePassive,
    List<String>? forgeSlots,
    String? forgeTargetCardId,
    bool resetForgeTargetCardId = false,
    Map<String, List<String>>? forgeTargetSessions,
    bool resetForgeTargetSessions = false,
    int? bonusForgeSlots,
    int? pendingDrafts,
    int? cardsPerTurn,
    List<StatRule>? statRules,
  }) {
    return RunState(
      currentLevel: currentLevel ?? this.currentLevel,
      act: act ?? this.act,
      heroStats: heroStats ?? this.heroStats,
      heroClassId: heroClassId ?? this.heroClassId,
      mapNodes: mapNodes ?? this.mapNodes,
      currentNodeId: resetCurrentNode
          ? null
          : (currentNodeId ?? this.currentNodeId),
      activePassive: activePassive ?? this.activePassive,
      forgeSlots: forgeSlots ?? this.forgeSlots,
      forgeTargetCardId: resetForgeTargetCardId
          ? null
          : (forgeTargetCardId ?? this.forgeTargetCardId),
      forgeTargetSessions: resetForgeTargetSessions
          ? const {}
          : (forgeTargetSessions ?? this.forgeTargetSessions),
      bonusForgeSlots: bonusForgeSlots ?? this.bonusForgeSlots,
      pendingDrafts: pendingDrafts ?? this.pendingDrafts,
      cardsPerTurn: cardsPerTurn ?? this.cardsPerTurn,
      statRules: statRules ?? this.statRules,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentLevel': currentLevel,
        'act': act,
        'heroStats': heroStats.toJson(),
        'heroClassId': heroClassId,
        'mapNodes': mapNodes.map((n) => n.toJson()).toList(),
        'currentNodeId': currentNodeId,
        'activePassiveId': activePassive?.id,
        'activePassiveNameFr': activePassive?.nameFr,
        'activePassiveNameEn': activePassive?.nameEn,
        'forgeSlots': forgeSlots,
        'forgeTargetCardId': forgeTargetCardId,
        'forgeTargetSessions': forgeTargetSessions,
        'bonusForgeSlots': bonusForgeSlots,
        'pendingDrafts': pendingDrafts,
        'cardsPerTurn': cardsPerTurn,
      };

  static (RunState, List<MissingSaveItem>) fromJsonWithReport(
    Map<String, dynamic> json,
  ) {
    final missing = <MissingSaveItem>[];

    final (forgeSlots, forgeSlotsMissing) =
        ForgeUpgradeData.filterValidRefs(json['forgeSlots'] as List<dynamic>?);
    missing.addAll(forgeSlotsMissing);

    final rawSessions =
        json['forgeTargetSessions'] as Map<String, dynamic>? ?? const {};
    final forgeTargetSessions = <String, List<String>>{};
    rawSessions.forEach((cardId, refs) {
      final (upgrades, sessionMissing) =
          ForgeUpgradeData.filterValidRefs(refs as List<dynamic>?);
      forgeTargetSessions[cardId] = upgrades;
      missing.addAll(sessionMissing);
    });

    final activePassiveId = json['activePassiveId'] as String?;
    PassiveData? activePassive;
    if (activePassiveId != null) {
      activePassive = PassiveData.getById(activePassiveId);
      if (activePassive == null) {
        missing.add(
          MissingSaveItem(
            id: activePassiveId,
            nameFr: json['activePassiveNameFr'] as String? ?? activePassiveId,
            nameEn: json['activePassiveNameEn'] as String? ?? activePassiveId,
            category: 'passive',
          ),
        );
      }
    }

    final run = RunState(
      currentLevel: json['currentLevel'] as int,
      act: json['act'] as int? ?? 1,
      heroStats: EntityStats.fromJson(json['heroStats'] as Map<String, dynamic>),
      heroClassId: json['heroClassId'] as String,
      mapNodes: (json['mapNodes'] as List<dynamic>? ?? const [])
          .map((n) => MapNode.fromJson(n as Map<String, dynamic>))
          .toList(),
      currentNodeId: json['currentNodeId'] as String?,
      activePassive: activePassive,
      forgeSlots: forgeSlots,
      forgeTargetCardId: json['forgeTargetCardId'] as String?,
      forgeTargetSessions: forgeTargetSessions,
      bonusForgeSlots: json['bonusForgeSlots'] as int? ?? 0,
      pendingDrafts: json['pendingDrafts'] as int? ?? 0,
      cardsPerTurn: json['cardsPerTurn'] as int? ?? 5,
      // Relues de la classe, jamais de la sauvegarde. Registre absent ou
      // classe inconnue : aucune règle — `state_sync_system.dart` traite déjà
      // un `heroClassId` inconnu comme un bug de sauvegarde, pas comme un cas
      // à masquer.
      statRules:
          HeroData.getById(json['heroClassId'] as String)?.statRules ??
              const [],
    );

    return (run, missing);
  }
}

class RunController extends Notifier<RunState> {
  RunState get currentState => state;

  late final PlayerStatsManager _playerStatsManager;
  late final MapProgressionManager _mapProgressionManager;
  late final GoldManager _goldManager;

  @override
  RunState build() {
    _playerStatsManager = PlayerStatsManager(this, ref);
    _mapProgressionManager = MapProgressionManager(this, ref);
    _goldManager = GoldManager(this, ref);

    return RunState(
      currentLevel: 1,
      act: 1,
      heroClassId: 'paladin',
      activePassive: null,
      heroStats: EntityStats(
        maxPv: 100,
        currentPv: 100,
        maxMana: 3,
        currentMana: 3,
        armure: 0,
        might: 0, // Puissance de base à 0
        luck: 0,
      ),
      pendingDrafts: 0,
    );
  }

  // Permet aux managers internes de mettre à jour l'état
  void updateState(RunState newState) {
    state = newState;
  }

  /// Remplace intégralement l'état par une sauvegarde chargée
  void hydrate(RunState savedState) {
    state = savedState;
  }

  /// Démarre une nouvelle partie avec la classe choisie
  void startNewRun(HeroData chosenClass, [PassiveData? activePassive]) {
    final generatedMap = MapGeneratorService.generateMap(act: 1);
    state = RunState(
      currentLevel: 1,
      act: 1,
      heroClassId: chosenClass.id,
      activePassive: activePassive,
      heroStats: EntityStats(
        maxPv: chosenClass.maxHp,
        currentPv: chosenClass.maxHp,
        maxMana: chosenClass.maxMana,
        currentMana: chosenClass.maxMana,
        armure: 0,
        mastery: chosenClass.mastery,
        might: 0, // Puissance de base à 0
        mightTargets: chosenClass.mightTargets,
        critChance: chosenClass.critChance,
        luck: chosenClass.luck,
      ),
      mapNodes: generatedMap,
      currentNodeId: null,
      pendingDrafts: 0,
      statRules: chosenClass.statRules,
    );

    // Réinitialise l'inventaire avec 50 d'or de départ
    ref
        .read(inventoryProvider.notifier)
        .reset(
          initialGold: 50,
          initialRelics: const [],
          initialBonusShopCards: 0,
        );

    // La run nait ici, deux écrans après le bouton qui a déclaré son mode :
    // c'est le moment où l'intention posée à l'accueil devient effective.
    // `kDebugMode` étant une constante de compilation, cette ligne disparaît
    // du build release, où toute run est donc normale.
    if (kDebugMode) {
      ref.read(debugRunProvider.notifier).applyRequestedMode();
    }
  }

  /// Sélectionne un nœud sur la carte et déplace le joueur
  void travelToNode(String nodeId) {
    _mapProgressionManager.travelToNode(nodeId);
  }

  /// Marque le nœud actuel comme complété
  void completeCurrentNode() {
    _mapProgressionManager.completeCurrentNode();
  }

  void advanceToNextWorld() {
    _mapProgressionManager.advanceToNextWorld();
  }

  /// Avance d'un niveau (après avoir drafté)
  void nextLevel() {
    _mapProgressionManager.nextLevel();
  }

  /// Applique un modificateur à la carte héro (ex: récompense de draft)
  void applyHeroStatModifier({
    int maxPvAcc = 0,
    int mightAcc = 0,
    int masteryAcc = 0,
    int maxManaAcc = 0,
    int luckAcc = 0,
    int critChanceAcc = 0,
    double critDamageAcc = 0.0,
  }) {
    _playerStatsManager.applyHeroStatModifier(
      maxPvAcc: maxPvAcc,
      mightAcc: mightAcc,
      masteryAcc: masteryAcc,
      maxManaAcc: maxManaAcc,
      luckAcc: luckAcc,
      critChanceAcc: critChanceAcc,
      critDamageAcc: critDamageAcc,
    );
  }

  /// Applique une récompense de niveau tirée (spec P-41, §8.1).
  void applyLevelUpReward(DraftChoice choice) {
    _playerStatsManager.applyLevelUpReward(choice);
  }

  /// Applique un modificateur aux règles de run propres au joueur
  void applyRunRuleModifier({int cardsPerTurnAcc = 0}) {
    _playerStatsManager.applyRunRuleModifier(cardsPerTurnAcc: cardsPerTurnAcc);
  }

  /// Ajoute de l'Expérience au joueur.
  /// Gère les montées de niveaux successives avec conservation de l'XP excédentaire (carry-over).
  /// Retourne [true] si au moins un niveau a été gagné.
  bool gainXp(int amount) {
    return _playerStatsManager.gainXp(amount);
  }

  void decrementPendingDrafts() {
    _playerStatsManager.decrementPendingDrafts();
  }

  void resetPendingDrafts() {
    _playerStatsManager.resetPendingDrafts();
  }

  /// Applique un soin en jeu
  void heal(int amount, {bool isCrit = false}) {
    _playerStatsManager.heal(amount, isCrit: isCrit);
  }

  /// Accorde au héros un gain d'armure, de mana ou de puissance, par le point
  /// de passage unique `StatGains` (spec P-41, §4.1).
  void grant(StatGain gain) {
    _playerStatsManager.grant(gain);
  }

  /// Subit des dégâts
  void takeDamage(int amount, {bool isCrit = false}) {
    final armorBefore = state.heroStats.armure;
    _playerStatsManager.takeDamage(amount, isCrit: isCrit);

    // Ce que l'armure a réellement absorbé : de quoi nourrir *Ferveur*, chez
    // qui encaisser devient une ressource offensive (spec §6.3). Les dégâts
    // de poison n'arrivent pas ici — ils sont appliqués par
    // `StatusEffectProcessor`, fonction pure sans controller — et ne
    // déclenchent donc pas le passif.
    final absorbed = amount <= 0
        ? 0
        : (amount < armorBefore ? amount : armorBefore);
    if (absorbed > 0) {
      TraitSystem.dispatch(
        this,
        PassiveEvent(RelicTrigger.onDamageTaken, absorbedDamage: absorbed),
      );
    }
  }

  /// Applique un effet de statut
  void addStatus(StatusEffect effect) {
    _playerStatsManager.addStatus(effect);
  }

  /// Retire tout statut portant [id]
  void removeStatus(String id) {
    _playerStatsManager.removeStatus(id);
  }

  /// Déclenche les effets des reliques pour un trigger donné
  void applyRelics(RelicTrigger trigger) {
    _playerStatsManager.applyRelics(trigger);
  }

  /// Déclenche les reliques et le passif d'élimination d'ennemi. Appelé une
  /// fois par ennemi abattu (`CombatController.cleanDeadEnemies`), ce qui fait
  /// de *Frénésie* une boule de neige (spec §6.3).
  void onEnemyKilled() {
    _playerStatsManager.onEnemyKilled();
    TraitSystem.dispatch(this, const PassiveEvent(RelicTrigger.onEnemyKilled));
  }

  void applyRelicEffect(RelicData relic) {
    _playerStatsManager.applyRelicEffect(relic);
  }

  void removeRelicEffect(RelicData relic) {
    _playerStatsManager.removeRelicEffect(relic);
  }

  void exchangeRelics(List<RelicData> sacrificed, RelicData gained) {
    _playerStatsManager.exchangeRelics(sacrificed, gained);
  }

  void startCombat() {
    // 1. Nettoyage des buffs/debuffs du combat précédent,
    // et restauration du mana au max (l'armure est remise à 0 en fin de combat dans completeCurrentNode)
    state = state.copyWith(
      heroStats: state.heroStats.copyWith(
        statuses: [],
        currentMana: state.heroStats.maxMana,
      ),
    );
    // 2. Déclenchement des reliques
    applyRelics(RelicTrigger.startOfCombat);
    // 3. Déclenchement des passifs de début de combat/tour pour le tour 1 (ex: Berserker)
    TraitSystem.dispatch(this, const PassiveEvent(RelicTrigger.startOfTurn));
  }

  void startTurn() {
    // L'armure que le tour précédent a laissée, avant sa remise à zéro : c'est
    // la seule valeur que *Bénédiction* peut convertir, et elle n'existe plus
    // une ligne plus bas (spec §1.1, §6.3).
    //
    // Capturée ici plutôt que le dispatch déplacé avant la remise à zéro :
    // là, tout passif `startOfTurn` qui donne de l'armure la verrait effacée
    // en silence — et cela vaudrait pour le prochain écrit comme pour
    // `berserker_armor` hier.
    final survivingArmor = state.heroStats.armure;

    // 1. Restaurer le Mana à sa valeur maximale (ne se cumule pas d'un tour à l'autre) et reset l'armure
    state = state.copyWith(
      heroStats: state.heroStats.copyWith(
        armure: 0,
        currentMana: state.heroStats.maxMana,
      ),
    );

    // 2. Déclencher les reliques de début de tour (qui peuvent maintenant rajouter du mana par-dessus)
    applyRelics(RelicTrigger.startOfTurn);

    // 3. Appliquer les effets de début de tour (ex: Poison, Regen) et décrémenter les statuts via le StatusEffectProcessor
    final updatedStats = StatusEffectProcessor.processPlayerStatuses(
      state.heroStats,
      state.statRules,
    );
    state = state.copyWith(heroStats: updatedStats);


    // 4. Déclencher les traits passifs
    TraitSystem.dispatch(
      this,
      PassiveEvent(RelicTrigger.startOfTurn, survivingArmor: survivingArmor),
    );
  }

  /// Fin du tour du joueur : le passif, puis les reliques de fin de tour, dans
  /// l'ordre que suivait `game_screen.dart` (spec P-49, §5.4). La défausse et
  /// le tour ennemi restent à l'écran : ils ne relèvent pas de ce controller.
  void endTurn() {
    TraitSystem.dispatch(this, const PassiveEvent(RelicTrigger.endOfTurn));
    applyRelics(RelicTrigger.endOfTurn);
  }

  /// Gardé pour la compatibilité avec l'ancien code s'il est appelé ailleurs
  void tickCooldown() {
    startTurn();
  }

  /// Consomme les ressources nécessaires. Retourne false si insuffisant.
  bool consumeResource({int mana = 0, int hpPercent = 0}) {
    return _playerStatsManager.consumeResource(mana: mana, hpPercent: hpPercent);
  }

  /// Arme le Vol de vie pour une valeur et une durée données
  void applyLifestealBuff({required int value, required int duration}) {
    _playerStatsManager.applyLifestealBuff(value: value, duration: duration);
  }

  void setForgeSession(String cardId, List<String> slots) {
    final updated = Map<String, List<String>>.from(state.forgeTargetSessions);
    updated[cardId] = slots;
    state = state.copyWith(
      forgeTargetSessions: updated,
      forgeTargetCardId: cardId,
      forgeSlots: slots,
    );
  }

  void clearForgeSession() {
    state = state.copyWith(
      resetForgeTargetCardId: true,
      forgeSlots: const [],
      resetForgeTargetSessions: true,
    );
  }

  bool buyBonusForgeSlot() {
    return _goldManager.buyBonusForgeSlot();
  }
}

final runProvider = NotifierProvider<RunController, RunState>(RunController.new);
