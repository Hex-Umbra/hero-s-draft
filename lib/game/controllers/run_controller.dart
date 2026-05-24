import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/entity_stats.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/relic_data.dart';
import '../../models/data/passive_data.dart';
import '../../models/map_node.dart';
import '../../models/status_effect.dart';
import '../../services/map_generator_service.dart';
import '../systems/trait_system.dart';

class RunState {
  final int currentLevel;
  final int act;
  final EntityStats heroStats;
  final String heroClassId;
  final List<RelicData> relics;
  final List<MapNode> mapNodes;
  final String? currentNodeId;
  final int gold;
  final String? passiveTrait; // Trait passif du héros (ex: regenArmor)
  final PassiveData? activePassive; // Passif dynamique du héros
  final int bonusShopCards; // Nombre additionnel de cartes dans le shop

  // Variables pour gérer l'état du cooldown des sorts
  final int skill1Cooldown;
  final int skill2Cooldown;

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
    this.relics = const [],
    this.mapNodes = const [],
    this.currentNodeId,
    this.gold = 0,
    this.passiveTrait,
    this.activePassive,
    this.skill1Cooldown = 0,
    this.skill2Cooldown = 0,
    this.bonusShopCards = 0,
  });

  RunState copyWith({
    int? currentLevel,
    int? act,
    EntityStats? heroStats,
    String? heroClassId,
    List<RelicData>? relics,
    List<MapNode>? mapNodes,
    String? currentNodeId,
    bool resetCurrentNode = false,
    int? gold,
    String? passiveTrait,
    PassiveData? activePassive,
    int? skill1Cooldown,
    int? skill2Cooldown,
    int? bonusShopCards,
  }) {
    return RunState(
      currentLevel: currentLevel ?? this.currentLevel,
      act: act ?? this.act,
      heroStats: heroStats ?? this.heroStats,
      heroClassId: heroClassId ?? this.heroClassId,
      relics: relics ?? this.relics,
      mapNodes: mapNodes ?? this.mapNodes,
      currentNodeId: resetCurrentNode
          ? null
          : (currentNodeId ?? this.currentNodeId),
      gold: gold ?? this.gold,
      passiveTrait: passiveTrait ?? this.passiveTrait,
      activePassive: activePassive ?? this.activePassive,
      skill1Cooldown: skill1Cooldown ?? this.skill1Cooldown,
      skill2Cooldown: skill2Cooldown ?? this.skill2Cooldown,
      bonusShopCards: bonusShopCards ?? this.bonusShopCards,
    );
  }
}

class RunController extends StateNotifier<RunState> {
  RunState get currentState => state;

  RunController()
    : super(
        RunState(
          currentLevel: 1,
          act: 1,
          heroClassId: 'paladin',
          passiveTrait: 'regenArmor',
          activePassive: PassiveData.fallback('regenArmor'),
          heroStats: EntityStats(
            maxPv: 100,
            currentPv: 100,
            maxMana: 3,
            currentMana: 3,
            armure: 0,
            attaque: 0, // Force de base à 0
            luck: 0,
          ),
          bonusShopCards: 0,
        ),
      );

  /// Démarre une nouvelle partie avec la classe choisie
  void startNewRun(HeroData chosenClass, [PassiveData? activePassive]) {
    final generatedMap = MapGeneratorService.generateMap();
    state = RunState(
      currentLevel: 1,
      act: 1,
      heroClassId: chosenClass.id,
      passiveTrait: chosenClass.passiveTrait,
      activePassive: activePassive ?? PassiveData.fallback(chosenClass.passiveTrait ?? ''),
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
      gold: 50,
      bonusShopCards: 0,
    );
  }

  /// Augmente définitivement le nombre de cartes affichées dans la boutique
  void buyShopExpansion() {
    state = state.copyWith(bonusShopCards: state.bonusShopCards + 1);
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
      heroStats: state.heroStats.copyWith(
        armure: 0,
        statuses: [],
      ),
    );

    if (completedNode != null && completedNode!.type == MapNodeType.boss) {
      advanceToNextWorld();
    }
  }

  /// Avance au monde suivant (boucle de jeu)
  void advanceToNextWorld() {
    final newMap = MapGeneratorService.generateMap();
    state = state.copyWith(
      mapNodes: newMap,
      act: state.act + 1,
      resetCurrentNode: true, // Reset la position pour le nouveau monde
    );
  }

  /// Ajoute de l'or au trésor du joueur
  void gainGold(int amount) {
    state = state.copyWith(gold: state.gold + amount);
  }

  /// Dépense de l'or. Retourne false si fonds insuffisants.
  bool spendGold(int amount) {
    if (state.gold < amount) return false;
    state = state.copyWith(gold: state.gold - amount);
    return true;
  }

  /// Avance d'un niveau (après avoir drafté)
  void nextLevel() {
    final currentStats = state.heroStats;
    state = state.copyWith(
      currentLevel: state.currentLevel + 1,
      heroStats: currentStats.copyWith(currentMana: currentStats.maxMana),
      skill1Cooldown: 0,
      skill2Cooldown: 0,
    );
  }

  /// Applique un modificateur à la carte héro (ex: récompense de draft)
  void applyHeroStatModifier({
    int maxPvAcc = 0,
    int attackAcc = 0,
    int armorAcc = 0,
    int maxManaAcc = 0,
    int luckAcc = 0,
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
      ),
    );
  }

  /// Applique un soin en jeu
  void heal(int amount) {
    int newPv = (state.heroStats.currentPv + amount).clamp(
      0,
      state.heroStats.maxPv,
    );
    state = state.copyWith(
      heroStats: state.heroStats.copyWith(currentPv: newPv),
    );
  }

  /// Modifie la valeur exacte d'un champ sans affecter les max (pour la récupération d'armure par ex)
  void setHeroStats({int? currentPv, int? armure, int? currentMana}) {
    state = state.copyWith(
      heroStats: state.heroStats.copyWith(
        currentPv: currentPv ?? state.heroStats.currentPv,
        armure: armure ?? state.heroStats.armure,
        currentMana: currentMana ?? state.heroStats.currentMana,
      ),
    );
  }

  /// Subit des dégâts
  void takeDamage(int amount) {
    state = state.copyWith(heroStats: state.heroStats.takeDamage(amount));
  }

  /// Applique un effet de statut
  void addStatus(StatusEffect effect) {
    state = state.copyWith(heroStats: state.heroStats.addStatus(effect));
  }

  /// Ajoute une relique à la collection
  void addRelic(RelicData relic) {
    state = state.copyWith(relics: [...state.relics, relic]);
    if (relic.trigger == RelicTrigger.startOfRun) {
      _applyRelicEffect(relic);
    }
  }

  /// Déclenche les effets des reliques pour un trigger donné
  void applyRelics(RelicTrigger trigger) {
    final relevantRelics = state.relics
        .where((r) => r.trigger == trigger)
        .toList();
    for (var relic in relevantRelics) {
      _applyRelicEffect(relic);
    }
  }

  /// Déclenche les reliques d'élimination d'ennemi
  void onEnemyKilled() {
    applyRelics(RelicTrigger.onEnemyKilled);
  }

  void _applyRelicEffect(RelicData relic) {
    switch (relic.effectType) {
      case 'gain_mana':
        state = state.copyWith(
          heroStats: state.heroStats.copyWith(
            currentMana: state.heroStats.currentMana + relic.value,
          ),
        );
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
      case 'heal':
        heal(relic.value);
        break;
    }
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

    // 4. Décrémenter les statuts et les cooldowns
    state = state.copyWith(
      heroStats: updatedStats.tickStatuses(),
      skill1Cooldown: state.skill1Cooldown > 0 ? state.skill1Cooldown - 1 : 0,
      skill2Cooldown: state.skill2Cooldown > 0 ? state.skill2Cooldown - 1 : 0,
    );

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

  /// Tente de lancer le premier sort générique (pour méthodes externes)
  bool triggerGenericSkill1({
    required int cd,
    int mana = 0,
    int hpPercent = 0,
  }) {
    if (state.skill1Cooldown > 0) return false;
    if (!consumeResource(mana: mana, hpPercent: hpPercent)) return false;
    state = state.copyWith(skill1Cooldown: cd);
    return true;
  }

  /// Tente de lancer le second sort générique (pour méthodes externes)
  bool triggerGenericSkill2({
    required int cd,
    int mana = 0,
    int hpPercent = 0,
  }) {
    if (state.skill2Cooldown > 0) return false;
    if (!consumeResource(mana: mana, hpPercent: hpPercent)) return false;
    state = state.copyWith(skill2Cooldown: cd);
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
}

final runProvider = StateNotifierProvider<RunController, RunState>((ref) {
  return RunController();
});
