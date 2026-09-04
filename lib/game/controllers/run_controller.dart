import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entity_stats.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/relic_data.dart';
import '../../models/data/passive_data.dart';
import '../../models/map_node.dart';
import '../../models/status_effect.dart';
import '../../models/missing_save_item.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../services/map_generator_service.dart';
import '../systems/trait_system.dart';
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
  final String? passiveTrait; // Trait passif du héros (ex: regen_armor)
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

  bool get isBossLevel => currentLevel > 0 && currentLevel % 10 == 0;
  bool get isDead => heroStats.currentPv <= 0;

  int get effectiveAttaque => heroStats.effectiveAttaque;

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
    this.passiveTrait,
    this.activePassive,
    this.forgeSlots = const [],
    this.forgeTargetCardId,
    this.forgeTargetSessions = const {},
    this.bonusForgeSlots = 0,
    this.pendingDrafts = 0,
    this.cardsPerTurn = 5,
  });

  RunState copyWith({
    int? currentLevel,
    int? act,
    EntityStats? heroStats,
    String? heroClassId,
    List<MapNode>? mapNodes,
    String? currentNodeId,
    bool resetCurrentNode = false,
    String? passiveTrait,
    PassiveData? activePassive,
    List<String>? forgeSlots,
    String? forgeTargetCardId,
    bool resetForgeTargetCardId = false,
    Map<String, List<String>>? forgeTargetSessions,
    bool resetForgeTargetSessions = false,
    int? bonusForgeSlots,
    int? pendingDrafts,
    int? cardsPerTurn,
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
      passiveTrait: passiveTrait ?? this.passiveTrait,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'currentLevel': currentLevel,
        'act': act,
        'heroStats': heroStats.toJson(),
        'heroClassId': heroClassId,
        'mapNodes': mapNodes.map((n) => n.toJson()).toList(),
        'currentNodeId': currentNodeId,
        'passiveTrait': passiveTrait,
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
      passiveTrait: json['passiveTrait'] as String?,
      activePassive: activePassive,
      forgeSlots: forgeSlots,
      forgeTargetCardId: json['forgeTargetCardId'] as String?,
      forgeTargetSessions: forgeTargetSessions,
      bonusForgeSlots: json['bonusForgeSlots'] as int? ?? 0,
      pendingDrafts: json['pendingDrafts'] as int? ?? 0,
      cardsPerTurn: json['cardsPerTurn'] as int? ?? 5,
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
      passiveTrait: 'regen_armor',
      activePassive: null,
      heroStats: EntityStats(
        maxPv: 100,
        currentPv: 100,
        maxMana: 3,
        currentMana: 3,
        armure: 0,
        attaque: 0, // Force de base à 0
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
      passiveTrait: chosenClass.passiveTrait,
      activePassive: activePassive,
      heroStats: EntityStats(
        maxPv: chosenClass.maxHp,
        currentPv: chosenClass.maxHp,
        maxMana: chosenClass.maxMana,
        currentMana: chosenClass.maxMana,
        armure: 0,
        armorMastery: chosenClass.armorMastery,
        attaque: 0, // Force de base à 0
        luck: chosenClass.luck,
      ),
      mapNodes: generatedMap,
      currentNodeId: null,
      pendingDrafts: 0,
    );

    // Réinitialise l'inventaire avec 50 d'or de départ
    ref
        .read(inventoryProvider.notifier)
        .reset(
          initialGold: 50,
          initialRelics: const [],
          initialBonusShopCards: 0,
        );

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
    int attackAcc = 0,
    int armorAcc = 0,
    int maxManaAcc = 0,
    int luckAcc = 0,
    int critChanceAcc = 0,
    double critDamageAcc = 0.0,
  }) {
    _playerStatsManager.applyHeroStatModifier(
      maxPvAcc: maxPvAcc,
      attackAcc: attackAcc,
      armorAcc: armorAcc,
      maxManaAcc: maxManaAcc,
      luckAcc: luckAcc,
      critChanceAcc: critChanceAcc,
      critDamageAcc: critDamageAcc,
    );
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

  /// Modifie la valeur exacte d'un champ sans affecter les max (pour la récupération d'armure par ex)
  void setHeroStats({
    int? currentPv,
    int? armure,
    int? currentMana,
    int? armorMastery,
    bool? lastActionWasCrit,
  }) {
    _playerStatsManager.setHeroStats(
      currentPv: currentPv,
      armure: armure,
      currentMana: currentMana,
      armorMastery: armorMastery,
      lastActionWasCrit: lastActionWasCrit,
    );
  }

  /// Subit des dégâts
  void takeDamage(int amount, {bool isCrit = false}) {
    _playerStatsManager.takeDamage(amount, isCrit: isCrit);
  }

  /// Applique un effet de statut
  void addStatus(StatusEffect effect) {
    _playerStatsManager.addStatus(effect);
  }

  /// Déclenche les effets des reliques pour un trigger donné
  void applyRelics(RelicTrigger trigger) {
    _playerStatsManager.applyRelics(trigger);
  }

  /// Déclenche les reliques d'élimination d'ennemi
  void onEnemyKilled() {
    _playerStatsManager.onEnemyKilled();
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
    TraitSystem.onTurnStart(this);
  }

  void startTurn() {
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
    final updatedStats = StatusEffectProcessor.processPlayerStatuses(state.heroStats);
    state = state.copyWith(heroStats: updatedStats);


    // 4. Déclencher les traits passifs
    TraitSystem.onTurnStart(this);
  }

  /// Gardé pour la compatibilité avec l'ancien code s'il est appelé ailleurs
  void tickCooldown() {
    startTurn();
  }

  /// Consomme les ressources nécessaires. Retourne false si insuffisant.
  bool consumeResource({int mana = 0, int hpPercent = 0}) {
    return _playerStatsManager.consumeResource(mana: mana, hpPercent: hpPercent);
  }

  /// Applique un buff d'attaque pour une durée donnée
  void applyAttackBuff(int duration) {
    _playerStatsManager.applyAttackBuff(duration);
  }

  /// Applique un effet de Vol de vie pour une durée donnée
  void applyLifestealBuff(int duration) {
    _playerStatsManager.applyLifestealBuff(duration);
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
