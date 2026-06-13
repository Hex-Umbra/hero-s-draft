import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entity_stats.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/relic_data.dart';
import '../../models/data/passive_data.dart';
import '../../models/map_node.dart';
import '../../models/status_effect.dart';
import '../../services/map_generator_service.dart';
import '../systems/trait_system.dart';
import 'inventory_controller.dart';
import 'skill_controller.dart';

class RunState {
  final int currentLevel;
  final int act;
  final EntityStats heroStats;
  final String heroClassId;
  final List<MapNode> mapNodes;
  final String? currentNodeId;
  final String? passiveTrait; // Trait passif du héros (ex: regenArmor)
  final PassiveData? activePassive; // Passif dynamique du héros
  final List<String> forgeSlots;
  final String? forgeTargetCardId;
  final Map<String, List<String>> forgeTargetSessions;
  final int bonusForgeSlots;
  final int pendingDrafts; // Nombre de drafts de montée de niveau en attente

  bool get isBossLevel => currentLevel > 0 && currentLevel % 10 == 0;
  bool get isDead => heroStats.currentPv <= 0;

  int get effectiveAttaque => heroStats.effectiveAttaque;

  MapNodeType? get currentNodeType {
    if (currentNodeId == null) return null;
    try {
      return mapNodes.firstWhere((n) => n.id == currentNodeId).type;
    } catch (_) {
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
    );
  }
}

class RunController extends Notifier<RunState> {
  RunState get currentState => state;

  @override
  RunState build() {
    return RunState(
      currentLevel: 1,
      act: 1,
      heroClassId: 'paladin',
      passiveTrait: 'regenArmor',
      activePassive: PassiveData.fallback('regenArmor'),
      heroStats: const EntityStats(
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

  /// Démarre une nouvelle partie avec la classe choisie
  void startNewRun(HeroData chosenClass, [PassiveData? activePassive]) {
    final generatedMap = MapGeneratorService.generateMap(act: 1);
    state = RunState(
      currentLevel: 1,
      act: 1,
      heroClassId: chosenClass.id,
      passiveTrait: chosenClass.passiveTrait,
      activePassive:
          activePassive ?? PassiveData.fallback(chosenClass.passiveTrait ?? ''),
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

    // Réinitialise les cooldowns de sorts
    ref.read(skillProvider.notifier).resetCooldowns();
  }

  /// Sélectionne un nœud sur la carte et déplace le joueur
  void travelToNode(String nodeId) {
    state = state.copyWith(currentNodeId: nodeId);
  }

  /// Marque le nœud actuel comme complété
  void completeCurrentNode() {
    if (state.currentNodeId == null) return;

    MapNode? completedNode;
    final updatedNodes = state.mapNodes.map((node) {
      if (node.id == state.currentNodeId) {
        node.isCompleted = true;
        completedNode = node;
      }
      return node;
    }).toList();

    // Reset de l'armure et nettoyage des statuts à la fin du combat pour préserver les passifs
    state = state.copyWith(
      mapNodes: updatedNodes,
      heroStats: state.heroStats.copyWith(armure: 0, statuses: []),
    );

    if (completedNode != null && completedNode!.type == MapNodeType.boss) {
      advanceToNextWorld();
    }
  }

  void advanceToNextWorld() {
    final nextAct = state.act + 1;
    final newMap = MapGeneratorService.generateMap(act: nextAct);
    state = state.copyWith(
      mapNodes: newMap,
      act: nextAct,
      resetCurrentNode: true, // Reset la position pour le nouveau monde
    );
  }

  /// Avance d'un niveau (après avoir drafté)
  void nextLevel() {
    final currentStats = state.heroStats;
    state = state.copyWith(
      currentLevel: state.currentLevel + 1,
      heroStats: currentStats.copyWith(currentMana: currentStats.maxMana),
    );
    // Réinitialise les cooldowns à chaque nouveau niveau
    ref.read(skillProvider.notifier).resetCooldowns();
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
    final currentStats = state.heroStats;
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

    state = state.copyWith(
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
    );
  }

  /// Ajoute de l'Expérience au joueur.
  /// Gère les montées de niveaux successives avec conservation de l'XP excédentaire (carry-over).
  /// Retourne [true] si au moins un niveau a été gagné.
  bool gainXp(int amount) {
    if (amount <= 0) return false;

    var currentStats = state.heroStats;
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

    state = state.copyWith(
      heroStats: currentStats.copyWith(
        level: currentLevel,
        xp: newXp,
        xpToNextLevel: currentXpToNext,
      ),
      pendingDrafts: state.pendingDrafts + levelsGained,
    );

    return leveledUp;
  }

  void decrementPendingDrafts() {
    if (state.pendingDrafts > 0) {
      state = state.copyWith(pendingDrafts: state.pendingDrafts - 1);
    }
  }

  void resetPendingDrafts() {
    state = state.copyWith(pendingDrafts: 0);
  }

  /// Applique un soin en jeu
  void heal(int amount, {bool isCrit = false}) {
    int newPv = (state.heroStats.currentPv + amount).clamp(
      0,
      state.heroStats.maxPv,
    );
    state = state.copyWith(
      heroStats: state.heroStats.copyWith(
        currentPv: newPv,
        lastActionWasCrit: isCrit,
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
    state = state.copyWith(
      heroStats: state.heroStats.copyWith(
        currentPv: currentPv ?? state.heroStats.currentPv,
        armure: armure ?? state.heroStats.armure,
        currentMana: currentMana ?? state.heroStats.currentMana,
        armorMastery: armorMastery ?? state.heroStats.armorMastery,
        lastActionWasCrit: lastActionWasCrit ?? false,
      ),
    );
  }

  /// Subit des dégâts
  void takeDamage(int amount, {bool isCrit = false}) {
    state = state.copyWith(heroStats: state.heroStats.takeDamage(amount, isCrit: isCrit));
  }

  /// Applique un effet de statut
  void addStatus(StatusEffect effect) {
    state = state.copyWith(heroStats: state.heroStats.addStatus(effect));
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
          state = state.copyWith(
            heroStats: state.heroStats.copyWith(
              currentMana: state.heroStats.currentMana + relic.value,
            ),
          );
        }
        break;
      case 'gain_armor':
        state = state.copyWith(
          heroStats: state.heroStats.copyWith(
            armure: state.heroStats.armure + relic.value,
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
          state = state.copyWith(
            heroStats: state.heroStats.copyWith(
              luck: state.heroStats.luck + relic.value,
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
      case 'charge_armor_mastery_combat':
        final existing = state.heroStats.statuses.where((s) => s.id == 'kunai_charge');
        final int newVal = (existing.isEmpty ? 0 : existing.first.value) + 1;
        if (newVal >= 3) {
          final updatedStatuses = state.heroStats.statuses.where((s) => s.id != 'kunai_charge').toList();
          state = state.copyWith(
            heroStats: state.heroStats.copyWith(
              statuses: updatedStatuses,
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
        final existing = state.heroStats.statuses.where((s) => s.id == 'shuriken_charge');
        final int newVal = (existing.isEmpty ? 0 : existing.first.value) + 1;
        if (newVal >= 3) {
          final updatedStatuses = state.heroStats.statuses.where((s) => s.id != 'shuriken_charge').toList();
          state = state.copyWith(
            heroStats: state.heroStats.copyWith(
              statuses: updatedStatuses,
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
        final existing = state.heroStats.statuses.where((s) => s.id == 'pen_nib_charge');
        final int newVal = (existing.isEmpty ? 0 : existing.first.value) + 1;
        if (newVal >= 5) {
          final updatedStatuses = state.heroStats.statuses.where((s) => s.id != 'pen_nib_charge').toList();
          state = state.copyWith(
            heroStats: state.heroStats.copyWith(
              statuses: updatedStatuses,
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
        final existing = state.heroStats.statuses.where((s) => s.id == 'incense_charge');
        final int newVal = (existing.isEmpty ? 0 : existing.first.value) + 1;
        if (newVal >= 4) {
          final updatedStatuses = state.heroStats.statuses.where((s) => s.id != 'incense_charge').toList();
          state = state.copyWith(
            heroStats: state.heroStats.copyWith(
              statuses: updatedStatuses,
            ),
          );
          setHeroStats(armure: state.heroStats.armure + relic.value);
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
    // 1. Restaurer le Mana à sa valeur maximale (ne se cumule pas d'un tour à l'autre)
    state = state.copyWith(
      heroStats: state.heroStats.copyWith(currentMana: state.heroStats.maxMana),
    );

    // 2. Déclencher les reliques de début de tour (qui peuvent maintenant rajouter du mana par-dessus)
    applyRelics(RelicTrigger.startOfTurn);

    // 3. Appliquer les effets de début de tour (ex: Poison, Regen)
    int poisonDamage = 0;
    int strengthGain = 0;
    int armorGain = 0;

    for (var status in state.heroStats.statuses) {
      if (status.id == 'poison') {
        poisonDamage += status.value;
      } else if (status.id == 'strength_regen') {
        strengthGain += status.value;
      } else if (status.id == 'armor_regen') {
        armorGain += status.value;
      }
    }

    EntityStats updatedStats = state.heroStats;
    if (poisonDamage > 0) {
      updatedStats = updatedStats.takeDamage(poisonDamage);
    }
    if (strengthGain > 0) {
      updatedStats = updatedStats.addStatus(
        StatusEffect(
          id: 'strength',
          name: 'Attaque',
          type: StatusType.buff,
          value: strengthGain,
          duration: 3, // 3 tours maximum au lieu d'un buff permanent
        ),
      );
    }
    if (armorGain > 0) {
      updatedStats = updatedStats.copyWith(
        armure: updatedStats.armure + armorGain,
      );
    }

    // 4. Décrémenter les statuts
    state = state.copyWith(heroStats: updatedStats.tickStatuses());
    // Décrémenter les cooldowns via le skill provider
    ref.read(skillProvider.notifier).tickCooldowns();

    // 5. Déclencher les traits passifs
    TraitSystem.onTurnStart(this);
  }

  /// Gardé pour la compatibilité avec l'ancien code s'il est appelé ailleurs
  void tickCooldown() {
    startTurn();
  }

  /// Consomme les ressources nécessaires. Retourne false si insuffisant.
  bool consumeResource({int mana = 0, int hpPercent = 0}) {
    int hpCost = 0;
    if (hpPercent > 0) {
      hpCost = (state.heroStats.currentPv * (hpPercent / 100.0)).round();
      if (hpCost < 1) hpCost = 1;
      if (state.heroStats.currentPv <= hpCost) return false;
    }

    if (mana > 0 && state.heroStats.currentMana < mana) {
      return false;
    }

    state = state.copyWith(
      heroStats: state.heroStats.copyWith(
        currentMana: state.heroStats.currentMana - mana,
        currentPv: state.heroStats.currentPv - hpCost,
      ),
    );
    return true;
  }

  /// Applique un buff d'attaque pour une durée donnée
  void applyAttackBuff(int duration) {
    int bonus = (state.heroStats.maxPv * 0.15).round();
    state = state.copyWith(
      heroStats: state.heroStats.addStatus(
        StatusEffect(
          id: 'strength',
          name: 'Attaque',
          type: StatusType.buff,
          value: bonus,
          duration: duration,
        ),
      ),
    );
  }

  /// Applique un effet de Vol de vie pour une durée donnée
  void applyLifestealBuff(int duration) {
    state = state.copyWith(
      heroStats: state.heroStats.addStatus(
        StatusEffect(
          id: 'lifesteal',
          name: 'Vol de Vie',
          type: StatusType.buff,
          value: 1,
          duration: duration,
        ),
      ),
    );
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
    if (state.bonusForgeSlots >= 4) return false;
    final costs = [50, 80, 120, 175];
    final cost = costs[state.bonusForgeSlots];
    final success = ref.read(inventoryProvider.notifier).spendGold(cost);
    if (!success) return false;

    state = state.copyWith(
      bonusForgeSlots: state.bonusForgeSlots + 1,
    );
    return true;
  }
}

final runProvider = NotifierProvider<RunController, RunState>(RunController.new);
