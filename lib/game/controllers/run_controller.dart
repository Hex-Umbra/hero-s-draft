import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/entity_stats.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/relic_data.dart';
import '../../models/map_node.dart';
import '../../models/status_effect.dart';
import '../../services/map_generator_service.dart';

class RunState {
  final int currentLevel;
  final EntityStats heroStats;
  final String heroClassId;
  final List<RelicData> relics;
  final List<MapNode> mapNodes;
  final String? currentNodeId;
  final int gold;
  
  // Variables pour gérer l'état du cooldown des sorts
  final int skill1Cooldown;
  final int skill2Cooldown;

  bool get isBossLevel => currentLevel > 0 && currentLevel % 10 == 0;
  bool get isDead => heroStats.currentPv <= 0;

  int get effectiveAttaque => heroStats.effectiveAttaque;

  const RunState({
    required this.currentLevel,
    required this.heroStats,
    required this.heroClassId,
    this.relics = const [],
    this.mapNodes = const [],
    this.currentNodeId,
    this.gold = 0,
    this.skill1Cooldown = 0,
    this.skill2Cooldown = 0,
  });

  RunState copyWith({
    int? currentLevel,
    EntityStats? heroStats,
    String? heroClassId,
    List<RelicData>? relics,
    List<MapNode>? mapNodes,
    String? currentNodeId,
    int? gold,
    int? skill1Cooldown,
    int? skill2Cooldown,
  }) {
    return RunState(
      currentLevel: currentLevel ?? this.currentLevel,
      heroStats: heroStats ?? this.heroStats,
      heroClassId: heroClassId ?? this.heroClassId,
      relics: relics ?? this.relics,
      mapNodes: mapNodes ?? this.mapNodes,
      currentNodeId: currentNodeId ?? this.currentNodeId,
      gold: gold ?? this.gold,
      skill1Cooldown: skill1Cooldown ?? this.skill1Cooldown,
      skill2Cooldown: skill2Cooldown ?? this.skill2Cooldown,
    );
  }
}

class RunController extends StateNotifier<RunState> {
  RunState get currentState => state;

  RunController()
      : super(RunState(
          currentLevel: 1,
          heroClassId: 'paladin',
          heroStats: EntityStats(
            maxPv: 100,
            currentPv: 100,
            maxMana: 10,
            currentMana: 10,
            armure: 20,
            attaque: 0, // Force de base à 0
          ),
        ));

  /// Démarre une nouvelle partie avec la classe choisie
  void startNewRun(HeroData chosenClass) {
    final generatedMap = MapGeneratorService.generateMap();
    state = RunState(
      currentLevel: 1,
      heroClassId: chosenClass.id,
      heroStats: EntityStats(
        maxPv: chosenClass.maxHp,
        currentPv: chosenClass.maxHp,
        maxMana: chosenClass.maxMana,
        currentMana: chosenClass.maxMana,
        armure: chosenClass.baseArmor,
        attaque: 0, // Force de base à 0
      ),
      mapNodes: generatedMap,
      currentNodeId: null,
      gold: 50,
    );
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

    state = state.copyWith(mapNodes: updatedNodes);

    if (completedNode != null && completedNode!.type == MapNodeType.boss) {
      advanceToNextWorld();
    }
  }

  /// Avance au monde suivant (boucle de jeu)
  void advanceToNextWorld() {
    final newMap = MapGeneratorService.generateMap();
    state = state.copyWith(
      mapNodes: newMap,
      currentNodeId: null, // Réinitialise la position pour le nouveau monde
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

  /// Avance d'un niveau (après avoir drafté) et restaure 50% du mana
  void nextLevel() {
    final currentStats = state.heroStats;
    int manaToRestore = (currentStats.maxMana * 0.50).round();
    int newMana = (currentStats.currentMana + manaToRestore).clamp(0, currentStats.maxMana);

    state = state.copyWith(
      currentLevel: state.currentLevel + 1,
      heroStats: currentStats.copyWith(currentMana: newMana),
      skill1Cooldown: 0,
      skill2Cooldown: 0,
    );
  }

  /// Applique un modificateur à la carte héro (ex: récompense de draft)
  void applyHeroStatModifier({int maxPvAcc = 0, int attackAcc = 0, int armorAcc = 0, int maxManaAcc = 0}) {
    final currentStats = state.heroStats;
    final newMaxPv = currentStats.maxPv + maxPvAcc;
    final newCurrentPv = (currentStats.currentPv + (maxPvAcc > 0 ? maxPvAcc : 0)).clamp(0, newMaxPv);
    
    final newMaxMana = currentStats.maxMana + maxManaAcc;
    // On ajoute aussi le bonus au mana actuel
    final newCurrentMana = (currentStats.currentMana + maxManaAcc).clamp(0, newMaxMana);

    state = state.copyWith(
      heroStats: currentStats.copyWith(
        maxPv: newMaxPv,
        currentPv: newCurrentPv,
        maxMana: newMaxMana,
        currentMana: newCurrentMana,
        attaque: currentStats.attaque + attackAcc,
        armure: currentStats.armure + armorAcc,
      ),
    );
  }

  /// Applique un soin en jeu
  void heal(int amount) {
    int newPv = (state.heroStats.currentPv + amount).clamp(0, state.heroStats.maxPv);
    state = state.copyWith(heroStats: state.heroStats.copyWith(currentPv: newPv));
  }

  /// Modifie la valeur exacte d'un champ sans affecter les max (pour la récupération d'armure par ex)
  void setHeroStats({int? currentPv, int? armure}) {
    state = state.copyWith(
      heroStats: state.heroStats.copyWith(
        currentPv: currentPv ?? state.heroStats.currentPv,
        armure: armure ?? state.heroStats.armure,
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
    final relevantRelics = state.relics.where((r) => r.trigger == trigger).toList();
    for (var relic in relevantRelics) {
      _applyRelicEffect(relic);
    }
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
        addStatus(StatusEffect(
          id: 'strength',
          name: 'Force (Relique)',
          type: StatusType.buff,
          value: relic.value,
          duration: 3, // Limité à 3 tours au lieu de 99
        ));
        break;
      case 'heal':
        heal(relic.value);
        break;
    }
  }

  /// Prépare l'état pour un nouveau combat
  void startCombat() {
    // 1. Nettoyage des buffs/debuffs du combat précédent
    state = state.copyWith(
      heroStats: state.heroStats.copyWith(
        statuses: [],
      ),
    );
    // 2. Déclenchement des reliques
    applyRelics(RelicTrigger.startOfCombat);
  }

  /// Nouveau Tour : Applique les effets de début de tour, baisse le cooldown, les buffs, et restaure le mana
  void startTurn() {
    // 0. Déclencher les reliques de début de tour
    applyRelics(RelicTrigger.startOfTurn);

    // 1. Appliquer les effets de début de tour (ex: Poison, Regen)
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
      updatedStats = updatedStats.addStatus(StatusEffect(
        id: 'strength',
        name: 'Force',
        type: StatusType.buff,
        value: strengthGain,
        duration: 3, // 3 tours maximum au lieu d'un buff permanent
      ));
    }
    if (armorGain > 0) {
      updatedStats = updatedStats.copyWith(armure: updatedStats.armure + armorGain);
    }

    // 2. Restaurer Mana et décrémenter les statuts
    state = state.copyWith(
      heroStats: updatedStats.copyWith(
        currentMana: updatedStats.maxMana,
      ).tickStatuses(),
      skill1Cooldown: state.skill1Cooldown > 0 ? state.skill1Cooldown - 1 : 0,
      skill2Cooldown: state.skill2Cooldown > 0 ? state.skill2Cooldown - 1 : 0,
    );
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
  bool triggerGenericSkill1({required int cd, int mana = 0, int hpPercent = 0}) {
    if (state.skill1Cooldown > 0) return false;
    if (!consumeResource(mana: mana, hpPercent: hpPercent)) return false;
    state = state.copyWith(skill1Cooldown: cd);
    return true;
  }

  /// Tente de lancer le second sort générique (pour méthodes externes)
  bool triggerGenericSkill2({required int cd, int mana = 0, int hpPercent = 0}) {
    if (state.skill2Cooldown > 0) return false;
    if (!consumeResource(mana: mana, hpPercent: hpPercent)) return false;
    state = state.copyWith(skill2Cooldown: cd);
    return true;
  }

  /// Applique un buff d'attaque pour une durée donnée
  void applyAttackBuff(int duration) {
    int bonus = (state.heroStats.maxPv * 0.15).round();
    state = state.copyWith(
      heroStats: state.heroStats.addStatus(StatusEffect(
        id: 'strength',
        name: 'Force',
        type: StatusType.buff,
        value: bonus,
        duration: duration,
      )),
    );
  }

  /// Applique un effet de Vol de vie pour une durée donnée
  void applyLifestealBuff(int duration) {
    state = state.copyWith(
      heroStats: state.heroStats.addStatus(StatusEffect(
        id: 'lifesteal',
        name: 'Vol de Vie',
        type: StatusType.buff,
        value: 1, 
        duration: duration,
      )),
    );
  }
}

final runProvider = StateNotifierProvider<RunController, RunState>((ref) {
  return RunController();
});
