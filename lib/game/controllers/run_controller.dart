import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/entity_stats.dart';
import '../../data/models/player_class.dart';

class RunState {
  final int currentLevel;
  final EntityStats heroStats;
  final PlayerClassType heroClass;
  
  // Variables pour gérer l'état du cooldown du sort
  final int specialCooldown;
  final int specialMaxCooldown;
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
    required this.heroClass,
    this.specialCooldown = 0,
    this.specialMaxCooldown = 3,
    this.attackBuffDuration = 0,
    this.lifestealDuration = 0,
  });

  RunState copyWith({
    int? currentLevel,
    EntityStats? heroStats,
    PlayerClassType? heroClass,
    int? specialCooldown,
    int? specialMaxCooldown,
    int? attackBuffDuration,
    int? lifestealDuration,
  }) {
    return RunState(
      currentLevel: currentLevel ?? this.currentLevel,
      heroStats: heroStats ?? this.heroStats,
      heroClass: heroClass ?? this.heroClass,
      specialCooldown: specialCooldown ?? this.specialCooldown,
      specialMaxCooldown: specialMaxCooldown ?? this.specialMaxCooldown,
      attackBuffDuration: attackBuffDuration ?? this.attackBuffDuration,
      lifestealDuration: lifestealDuration ?? this.lifestealDuration,
    );
  }
}

class RunController extends StateNotifier<RunState> {
  RunController()
      : super(RunState(
          currentLevel: 1,
          heroClass: PlayerClassType.paladin,
          heroStats: PlayerClass.paladin.startingStats,
        ));

  /// Démarre une nouvelle partie avec la classe choisie
  void startNewRun(PlayerClass chosenClass) {
    state = RunState(
      currentLevel: 1,
      heroClass: chosenClass.type,
      heroStats: chosenClass.startingStats,
    );
  }

  /// Avance d'un niveau (après avoir drafté)
  void nextLevel() {
    state = state.copyWith(currentLevel: state.currentLevel + 1);
  }

  /// Applique un modificateur à la carte héro (ex: récompense de draft)
  void applyHeroStatModifier({int maxPvAcc = 0, int attackAcc = 0, int armorAcc = 0}) {
    final currentStats = state.heroStats;
    final newMaxPv = currentStats.maxPv + maxPvAcc;
    final newCurrentPv = (currentStats.currentPv + (maxPvAcc > 0 ? maxPvAcc : 0)).clamp(0, newMaxPv);
    
    state = state.copyWith(
      heroStats: currentStats.copyWith(
        maxPv: newMaxPv,
        currentPv: newCurrentPv,
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

  /// Baisse le cooldown et la durée des buffs à chaque nouveau tour
  void tickCooldown() {
    state = state.copyWith(
      specialCooldown: state.specialCooldown > 0 ? state.specialCooldown - 1 : 0,
      attackBuffDuration: state.attackBuffDuration > 0 ? state.attackBuffDuration - 1 : 0,
      lifestealDuration: state.lifestealDuration > 0 ? state.lifestealDuration - 1 : 0,
    );
  }

  /// Réinitialise le cooldown après son utilisation (obsolète mais gardé pour interface par défaut)
  void resetCooldown() {
    state = state.copyWith(specialCooldown: state.specialMaxCooldown);
  }

  /// Restaure 15 points d'armure de façon instantanée
  void useArmorRestoreSpecial() {
    if (state.specialCooldown > 0) return;
    
    final newArmor = state.heroStats.armure + 15;
    state = state.copyWith(
      heroStats: state.heroStats.copyWith(armure: newArmor),
      specialCooldown: state.specialMaxCooldown,
    );
  }

  /// Augmente l'attaque de 25% pendant 2 tours
  void useAttackBuffSpecial() {
    if (state.specialCooldown > 0) return;

    state = state.copyWith(
      attackBuffDuration: 2,
      specialCooldown: state.specialMaxCooldown,
    );
  }

  /// Applique un effet de Vol de vie pour 3 tours (Berserker)
  void useBerserkerLifesteal() {
    if (state.specialCooldown > 0) return;
    state = state.copyWith(
      lifestealDuration: 3,
      specialCooldown: state.specialMaxCooldown,
    );
  }

  /// Réduit manuellement le cooldown sans effet (ex: pour les autres capacités déclenchées côté jeu)
  void triggerGenericSpecial() {
    if (state.specialCooldown > 0) return;
    state = state.copyWith(specialCooldown: state.specialMaxCooldown);
  }
}

final runProvider = StateNotifierProvider<RunController, RunState>((ref) {
  return RunController();
});
