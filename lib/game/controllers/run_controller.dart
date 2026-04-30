import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/entity_stats.dart';
import '../../models/data/hero_data.dart';

class RunState {
  final int currentLevel;
  final EntityStats heroStats;
  final String heroClassId;
  
  // Variables pour gérer l'état du cooldown des sorts
  final int skill1Cooldown;
  final int skill2Cooldown;
  // Durée du buff d'attaque
  final int attackBuffDuration;
  // Durée du vol de vie (Berserker)
  final int lifestealDuration;

  bool get isBossLevel => currentLevel > 0 && currentLevel % 10 == 0;
  bool get isDead => heroStats.currentPv <= 0;

  int get effectiveAttaque {
    if (attackBuffDuration > 0) {
      int bonus = (heroStats.maxPv * 0.15).round();
      return heroStats.attaque + bonus;
    }
    return heroStats.attaque;
  }

  const RunState({
    required this.currentLevel,
    required this.heroStats,
    required this.heroClassId,
    this.skill1Cooldown = 0,
    this.skill2Cooldown = 0,
    this.attackBuffDuration = 0,
    this.lifestealDuration = 0,
  });

  RunState copyWith({
    int? currentLevel,
    EntityStats? heroStats,
    String? heroClassId,
    int? skill1Cooldown,
    int? skill2Cooldown,
    int? attackBuffDuration,
    int? lifestealDuration,
  }) {
    return RunState(
      currentLevel: currentLevel ?? this.currentLevel,
      heroStats: heroStats ?? this.heroStats,
      heroClassId: heroClassId ?? this.heroClassId,
      skill1Cooldown: skill1Cooldown ?? this.skill1Cooldown,
      skill2Cooldown: skill2Cooldown ?? this.skill2Cooldown,
      attackBuffDuration: attackBuffDuration ?? this.attackBuffDuration,
      lifestealDuration: lifestealDuration ?? this.lifestealDuration,
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
    );
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

  /// Nouveau Tour : Baisse le cooldown, les buffs, et restaure le mana
  void startTurn() {
    state = state.copyWith(
      heroStats: state.heroStats.copyWith(
        currentMana: state.heroStats.maxMana,
      ),
      skill1Cooldown: state.skill1Cooldown > 0 ? state.skill1Cooldown - 1 : 0,
      skill2Cooldown: state.skill2Cooldown > 0 ? state.skill2Cooldown - 1 : 0,
      attackBuffDuration: state.attackBuffDuration > 0 ? state.attackBuffDuration - 1 : 0,
      lifestealDuration: state.lifestealDuration > 0 ? state.lifestealDuration - 1 : 0,
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
    state = state.copyWith(attackBuffDuration: duration);
  }

  /// Applique un effet de Vol de vie pour une durée donnée
  void applyLifestealBuff(int duration) {
    state = state.copyWith(lifestealDuration: duration);
  }
}

final runProvider = StateNotifierProvider<RunController, RunState>((ref) {
  return RunController();
});
