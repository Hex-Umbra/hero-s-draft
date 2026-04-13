import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/entities/hero_card.dart';
import 'components/entities/enemy_card.dart';

import 'controllers/run_controller.dart';
import 'systems/encounter_system.dart';

enum TurnPhase { player, enemy }

class HerosDraftGame extends FlameGame {
  HeroCard? heroCard;
  List<EnemyCard> enemyCards = [];
  RunState? _currentState;
  RunState? _nextState;
  
  TurnPhase currentPhase = TurnPhase.player;
  EnemyCard? selectedEnemy;

  final void Function(int) onPlayerTakeDamage;
  final void Function() onEnemiesDead;
  final void Function() onTurnEnded;

  HerosDraftGame({
    required this.onPlayerTakeDamage,
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

    if (heroCard == null) {
      heroCard = HeroCard(state.heroStats);
      heroCard!.position = Vector2(size.x / 2, size.y - 150);
      add(heroCard!);
    } else {
      heroCard!.updateStats(state.heroStats);
    }
  }

  void _spawnEnemies(int level) {
    for (var enemy in enemyCards) {
      enemy.removeFromParent();
    }
    enemyCards.clear();

    final enemyStats = EncounterSystem.generateEnemiesForLevel(level);
    bool isBoss = level > 0 && level % 10 == 0;

    double startX = (size.x / 2) - ((enemyStats.length - 1) * 80);
    
    for (int i = 0; i < enemyStats.length; i++) {
      final enemy = EnemyCard(
        stats: enemyStats[i], 
        isBoss: isBoss,
        onTapEnemy: _handlePlayerTargeting,
      )..position = Vector2(startX + (i * 160), 160);
      
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
    selectedEnemy!.updateStats(selectedEnemy!.stats.takeDamage(playerAttack));

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

    await Future.delayed(const Duration(milliseconds: 600));

    // 2. Riposte des Ennemis (Séquentielle)
    for (var enemy in enemyCards) {
      if (_currentState == null || _currentState!.isDead) break;
      
      enemy.bumpAnimation();
      await Future.delayed(const Duration(milliseconds: 200));
      onPlayerTakeDamage(enemy.stats.attaque);
      await Future.delayed(const Duration(milliseconds: 400));
    }

    await Future.delayed(const Duration(milliseconds: 300));

    // Fin du tour complet
    currentPhase = TurnPhase.player;
    onTurnEnded();
  }

  void resetEnemies() {
    _currentState = null;
  }
}
