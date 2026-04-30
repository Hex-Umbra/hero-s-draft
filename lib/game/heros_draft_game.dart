import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/entities/hero_card.dart';
import 'components/entities/enemy_card.dart';
import '../models/data/enemy_data.dart';

import 'controllers/run_controller.dart';
import 'systems/encounter_system.dart';

enum TurnPhase { player, enemy }

class HerosDraftGame extends FlameGame {
  List<EnemyData> availableEnemies = [];
  HeroCard? heroCard;
  List<EnemyCard> enemyCards = [];
  RunState? _currentState;
  RunState? _nextState;
  
  TurnPhase currentPhase = TurnPhase.player;
  EnemyCard? selectedEnemy;

  final void Function(int) onPlayerTakeDamage;
  final void Function(int) onPlayerHeal;
  final void Function(int) onPlayerGainArmor;
  final void Function() onEnemiesDead;
  final void Function() onTurnEnded;

  HerosDraftGame({
    required this.onPlayerTakeDamage,
    required this.onPlayerHeal,
    required this.onPlayerGainArmor,
    required this.onEnemiesDead,
    required this.onTurnEnded,
  });

  @override
  Color backgroundColor() => const Color(0xFF1E1E2C);

  void syncState(RunState state) {
    _nextState = state;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_nextState != null && hasLayout) {
      _applyState(_nextState!);
      _nextState = null;
    }
  }

  void _applyState(RunState state) {
    if (_currentState == null || _currentState!.currentLevel < state.currentLevel) {
       _spawnEnemies(state.currentLevel);
    }
    _currentState = state;

    int bonusAtt = state.effectiveAttaque - state.heroStats.attaque;

    if (heroCard == null) {
      Color cColor = Colors.blue;
      String cName = 'Paladin';
      if (state.heroClassId == 'berserker') {
        cColor = Colors.red;
        cName = 'Berserker';
      }
      if (state.heroClassId == 'mage') {
        cColor = Colors.purple;
        cName = 'Mage';
      }

      heroCard = HeroCard(state.heroStats, bonusAttack: bonusAtt, className: cName, classColor: cColor);
      heroCard!.position = Vector2(size.x / 2, size.y - 150);
      add(heroCard!);
    } else {
      heroCard!.updateStats(state.heroStats, bonusAttack: bonusAtt);
    }
  }

  void _spawnEnemies(int level) {
    for (var enemy in enemyCards) {
      enemy.removeFromParent();
    }
    enemyCards.clear();

    final enemyDataList = EncounterSystem.generateEnemiesForLevel(level, availableEnemies);
    bool isBoss = level > 0 && level % 10 == 0;

    double spacing = 195.0; // 140 width + 44 (2*radius) + 11 (half radius margin)
    double startX = (size.x / 2) - ((enemyDataList.length - 1) * (spacing / 2));
    
    for (int i = 0; i < enemyDataList.length; i++) {
      final data = enemyDataList[i];
      // On initialise les stats réelles en se basant sur data
      final stats = EntityStats(
        maxPv: data.maxHp,
        currentPv: data.maxHp,
        armure: 0,
        attaque: data.baseDamage,
        defense: 0,
      );

      final enemy = EnemyCard(
        stats: stats, 
        data: data,
        isBoss: isBoss,
        onTapEnemy: _handlePlayerTargeting,
      )..position = Vector2(startX + (i * spacing), 160);
      
      enemyCards.add(enemy);
      add(enemy);
    }
  }

  void _handlePlayerTargeting(EnemyCard target) {
    if (_currentState == null || _currentState!.isDead || currentPhase != TurnPhase.player) return;
    
    for (var e in enemyCards) {
      e.setSelection(false);
    }
    target.setSelection(true);
    selectedEnemy = target;
  }

  Future<void> executeTurn() async {
    if (currentPhase != TurnPhase.player || selectedEnemy == null || _currentState == null || _currentState!.isDead) return;

    currentPhase = TurnPhase.enemy; // Empêcher d'autres sélections

    // 1. Attaque du Joueur
    heroCard?.bumpAnimation();
    await Future.delayed(const Duration(milliseconds: 200));

    int playerAttack = _currentState!.effectiveAttaque;
    int dmgDealt = playerAttack; // Pour le lifesteal
    selectedEnemy!.updateStats(selectedEnemy!.stats.takeDamage(playerAttack));

    // Lifesteal du Berserker
    if (_currentState!.lifestealDuration > 0) {
      int heal = (dmgDealt * 0.25).round();
      if (heal > 0) onPlayerHeal(heal);
    }

    // Si l'ennemi ciblé meurt, on le retire
    if (selectedEnemy!.stats.currentPv <= 0) {
      selectedEnemy!.removeFromParent();
      enemyCards.remove(selectedEnemy);
      selectedEnemy = null;
    }

    // Victoire totale
    if (enemyCards.isEmpty) {
      onEnemiesDead();
      currentPhase = TurnPhase.player;
      return;
    }

    await _enemyRipostePhase();
  }

  Future<void> executeMageAoe() async {
    if (currentPhase != TurnPhase.player || _currentState == null || _currentState!.isDead || enemyCards.isEmpty) return;
    currentPhase = TurnPhase.enemy;

    heroCard?.bumpAnimation();
    await Future.delayed(const Duration(milliseconds: 200));

    int dmg = (_currentState!.effectiveAttaque * 0.20).round();
    if (dmg < 1) dmg = 1;

    for (var enemy in enemyCards.toList()) {
      enemy.updateStats(enemy.stats.takeDamage(dmg));
      if (enemy.stats.currentPv <= 0) {
        enemy.removeFromParent();
        enemyCards.remove(enemy);
        if (selectedEnemy == enemy) selectedEnemy = null;
      }
    }

    if (enemyCards.isEmpty) {
      onEnemiesDead();
      currentPhase = TurnPhase.player;
      return;
    }

    await _enemyRipostePhase();
  }

  Future<void> executeMageTargeted() async {
    if (currentPhase != TurnPhase.player || selectedEnemy == null || _currentState == null || _currentState!.isDead) return;
    currentPhase = TurnPhase.enemy;

    heroCard?.bumpAnimation();
    await Future.delayed(const Duration(milliseconds: 200));

    int dmg = (_currentState!.effectiveAttaque * 1.50).round();
    selectedEnemy!.updateStats(selectedEnemy!.stats.takeDamage(dmg));

    if (selectedEnemy!.stats.currentPv <= 0) {
      selectedEnemy!.removeFromParent();
      enemyCards.remove(selectedEnemy);
      selectedEnemy = null;
    }

    if (enemyCards.isEmpty) {
      onEnemiesDead();
      currentPhase = TurnPhase.player;
      return;
    }

    await _enemyRipostePhase();
  }

  Future<void> executeBerserkerTargeted() async {
    if (currentPhase != TurnPhase.player || selectedEnemy == null || _currentState == null || _currentState!.isDead) return;
    currentPhase = TurnPhase.enemy;

    heroCard?.bumpAnimation();
    await Future.delayed(const Duration(milliseconds: 200));

    int dmg = _currentState!.effectiveAttaque;
    int stolenArmor = (selectedEnemy!.stats.armure * 0.15).round();
    
    // Ignore armure = on réduit direct les PV
    int newPv = selectedEnemy!.stats.currentPv - dmg;
    int newArm = selectedEnemy!.stats.armure - stolenArmor;
    if (newPv < 0) newPv = 0;
    if (newArm < 0) newArm = 0;

    selectedEnemy!.updateStats(selectedEnemy!.stats.copyWith(currentPv: newPv, armure: newArm));

    if (stolenArmor > 0) {
      onPlayerGainArmor(stolenArmor);
    }

    if (selectedEnemy!.stats.currentPv <= 0) {
      selectedEnemy!.removeFromParent();
      enemyCards.remove(selectedEnemy);
      selectedEnemy = null;
    }

    if (enemyCards.isEmpty) {
      onEnemiesDead();
      currentPhase = TurnPhase.player;
      return;
    }

    await _enemyRipostePhase();
  }

  Future<void> _enemyRipostePhase() async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Riposte des Ennemis (Séquentielle)
    for (var enemy in enemyCards) {
      if (_currentState == null || _currentState!.isDead) break;
      
      enemy.bumpAnimation();
      await Future.delayed(const Duration(milliseconds: 200));
      onPlayerTakeDamage(enemy.stats.attaque);
      await Future.delayed(const Duration(milliseconds: 400));
    }

    await Future.delayed(const Duration(milliseconds: 300));

    currentPhase = TurnPhase.player;
    onTurnEnded();
  }


  void resetEnemies() {
    _currentState = null;
  }
}
