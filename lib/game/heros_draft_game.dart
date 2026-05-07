import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'components/card_component.dart';
import 'components/entities/hero_card.dart';
import 'components/entities/enemy_card.dart';
import '../models/card_instance.dart';
import '../models/data/enemy_data.dart';
import '../models/data/hero_data.dart';
import '../models/data/skill_data.dart';
import '../data/models/entity_stats.dart';

import 'controllers/run_controller.dart';
import 'controllers/deck_controller.dart';
import '../models/enemy_intent.dart';
import 'systems/encounter_system.dart';

enum TurnPhase { player, enemy }

class HerosDraftGame extends FlameGame with TapCallbacks {
  List<EnemyData> availableEnemies = [];
  List<HeroData> availableHeroes = [];
  HeroCard? heroCard;
  List<EnemyCard> enemyCards = [];
  List<CardComponent> handCards = [];
  CardComponent? hoveredCard;
  CardComponent? focusedCard;
  
  // Facteur d'échelle basé sur une résolution de référence (800p pour agrandir les éléments)
  double get scaleFactor => (size.y / 800).clamp(0.85, 2.5);
  
  RunState? _currentState;
  RunState? _nextState;
  DeckState? _nextDeckState;
  
  TurnPhase currentPhase = TurnPhase.player;
  EnemyCard? selectedEnemy;
  EnemyCard? highlightedEnemy;

  final void Function(int) onPlayerTakeDamage;
  final void Function(int) onPlayerHeal;
  final void Function(int) onPlayerGainArmor;
  final void Function() onEnemiesDead;
  final void Function(int) onEnemyDebuffDeck;
  final void Function() onTurnEnded;
  final void Function(TurnPhase) onPhaseChanged;
  final void Function(String title, String description) onShowTooltip;
  final void Function() onHideTooltip;
  final bool Function(CardInstance, EnemyCard?) onPlayCard;

  HerosDraftGame({
    required this.onPlayerTakeDamage,
    required this.onPlayerHeal,
    required this.onPlayerGainArmor,
    required this.onEnemiesDead,
    required this.onEnemyDebuffDeck,
    required this.onTurnEnded,
    required this.onPhaseChanged,
    required this.onShowTooltip,
    required this.onHideTooltip,
    required this.onPlayCard,
  });

  void setHoveredCard(CardComponent? card) {
    if (hoveredCard == card) return;

    // Reset previous card if it exists
    if (hoveredCard != null && hoveredCard != focusedCard) {
      hoveredCard!.isHovered = false;
      hoveredCard!.priority = hoveredCard!.basePriority;
      hoveredCard!.removeAll(hoveredCard!.children.whereType<Effect>());
      if (!hoveredCard!.isDragging) {
        hoveredCard!.add(
          ScaleEffect.to(
            Vector2.all(scaleFactor * 0.75),
            EffectController(duration: 0.1, curve: Curves.easeIn),
          ),
        );
      }
    }

    hoveredCard = card;

    // Set new hovered card
    if (hoveredCard != null && hoveredCard != focusedCard) {
      hoveredCard!.isHovered = true;
      hoveredCard!.priority = 100;
      hoveredCard!.removeAll(hoveredCard!.children.whereType<Effect>());
      if (!hoveredCard!.isDragging) {
        hoveredCard!.add(
          ScaleEffect.to(
            Vector2.all(scaleFactor * 0.75 * 1.2),
            EffectController(duration: 0.1, curve: Curves.easeOut),
          ),
        );
      }
    }
  }

  void setFocusedCard(CardComponent? card) {
    if (focusedCard == card) return;

    // Reset previous focus
    if (focusedCard != null) {
      focusedCard!.isHovered = false;
      focusedCard!.priority = focusedCard!.basePriority;
      focusedCard!.removeAll(focusedCard!.children.whereType<Effect>());
      if (!focusedCard!.isDragging) {
        focusedCard!.add(
          MoveEffect.to(
            focusedCard!.originalPosition,
            EffectController(duration: 0.15, curve: Curves.easeIn),
          ),
        );
        focusedCard!.add(
          ScaleEffect.to(
            Vector2.all(scaleFactor * 0.75),
            EffectController(duration: 0.15, curve: Curves.easeIn),
          ),
        );
      }
    }

    focusedCard = card;

    // Apply new focus
    if (focusedCard != null) {
      focusedCard!.isHovered = true;
      focusedCard!.priority = 150; // Plus haut que le hover simple
      focusedCard!.removeAll(focusedCard!.children.whereType<Effect>());
      if (!focusedCard!.isDragging) {
        focusedCard!.add(
          MoveEffect.to(
            focusedCard!.originalPosition + Vector2(0, -60), // Monte plus haut
            EffectController(duration: 0.2, curve: Curves.easeOut),
          ),
        );
        focusedCard!.add(
          ScaleEffect.to(
            Vector2.all(scaleFactor * 0.75 * 1.25), // Légèrement plus grand que le hover
            EffectController(duration: 0.2, curve: Curves.easeOut),
          ),
        );
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    // Si on clique sur le fond (pas sur une carte), on enlève le focus
    setFocusedCard(null);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // On retire le FixedResolutionViewport pour utiliser tout l'espace disponible (MaxViewport par défaut)
    // La caméra s'adaptera dynamiquement à la taille de l'écran.

    // 1. Précharger les images
    await images.loadAll([
      'bg_dungeon.png',
      'hero_paladin.png',
      'hero_berserker.png',
      'hero_mage.png',
      'enemy_goblin.png',
    ]);

    // 2. Ajouter l'arrière-plan
    final bgSprite = Sprite(images.fromCache('bg_dungeon.png'));
    add(SpriteComponent(
      sprite: bgSprite,
      size: size,
    )..priority = -100);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Recalculer le layout si le jeu est déjà initialisé
    if (heroCard != null) {
      heroCard!.position = Vector2(size.x / 2, size.y * 0.6);
    }
    if (enemyCards.isNotEmpty) {
      _repositionEnemies();
    }
    _layoutHand();
    
    // Ajuster l'arrière-plan
    children.whereType<SpriteComponent>().forEach((bg) {
      if (bg.priority == -100) bg.size = size;
    });
  }

  void highlightEnemy(EnemyCard? enemy) {
    if (highlightedEnemy != enemy) {
      highlightedEnemy?.setSelection(false);
      highlightedEnemy = enemy;
      highlightedEnemy?.setSelection(true);
    }
  }

  bool tryPlayCard(dynamic cardComp, EnemyCard? target) {
    if (cardComp is CardComponent && onPlayCard(cardComp.card, target)) {
      // Si la carte est jouée, on la retire immédiatement visuellement 
      // en attendant que syncDeck la supprime officiellement
      cardComp.removeFromParent();
      handCards.remove(cardComp);
      _layoutHand();
      return true;
    }
    return false;
  }

  @override
  Color backgroundColor() => const Color(0xFF1E1E2C);

  void syncState(RunState state) {
    _nextState = state;
  }
  
  void syncDeck(DeckState deckState) {
    _nextDeckState = deckState;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_nextState != null && hasLayout) {
      _applyState(_nextState!);
      _nextState = null;
    }
    if (_nextDeckState != null && hasLayout) {
      _applyDeckState(_nextDeckState!);
      _nextDeckState = null;
    }
  }

  void _applyDeckState(DeckState deck) {
    // 1. Trouver les cartes à retirer (qui ne sont plus dans la main du DeckState)
    final newHandIds = deck.hand.map((c) => c.uniqueId).toSet();
    final cardsToRemove = handCards.where((c) => !newHandIds.contains(c.card.uniqueId)).toList();
    
    for (var c in cardsToRemove) {
      c.removeFromParent();
      handCards.remove(c);
    }

    // 2. Trouver les cartes à ajouter
    final currentHandIds = handCards.map((c) => c.card.uniqueId).toSet();
    final cardsToAdd = deck.hand.where((c) => !currentHandIds.contains(c.uniqueId)).toList();
    
    for (var c in cardsToAdd) {
      final cardComp = CardComponent(c);
      handCards.add(cardComp);
      add(cardComp);
    }

    // 3. Mettre à jour le layout si la main a changé
    if (cardsToRemove.isNotEmpty || cardsToAdd.isNotEmpty) {
      _layoutHand();
    }
  }

  void _layoutHand() {
    if (handCards.isEmpty) return;

    final int count = handCards.length;
    // On veut un arc de cercle proportionnel à la taille de l'écran
    final double radius = size.y * 1.5;
    
    // Calcul dynamique de l'angle entre chaque carte (réduit pour plus de compacité)
    double angleStep = 0.08;
    if (count > 4) {
      angleStep = (0.4 / count).clamp(0.04, 0.08);
    }
    
    final double totalAngle = (count - 1) * angleStep;
    final double startAngle = -totalAngle / 2;

    // Le centre de l'arc de cercle est situé plus bas pour descendre les cartes
    // On ajuste l'offset pour redescendre la main car les cartes sont plus petites
    final Vector2 centerPoint = Vector2(size.x / 2, size.y + radius - (size.y * 0.15));

    for (int i = 0; i < count; i++) {
      final card = handCards[i];
      card.basePriority = 10 + i; // Assigne une priorité basée sur l'index
      
      final double angle = startAngle + (i * angleStep);
      
      // Position sur le cercle
      final double x = centerPoint.x + radius * sin(angle);
      final double y = centerPoint.y - radius * cos(angle);

      // On sauvegarde TOUJOURS la position théorique dans la main
      card.originalPosition = Vector2(x, y);
      card.originalAngle = angle;

      if (card.isDragging) continue;

      // On n'oriente physiquement la carte que si elle n'est pas drag
      if (card == focusedCard) {
        // La carte est focus, elle monte dans l'axe vertical mais garde son angle
        card.position = Vector2(x, y) + Vector2(0, -60);
        card.angle = angle;
      } else {
        card.position = Vector2(x, y);
        card.angle = angle;
      }
      
      // Si la carte n'est pas mise en avant (hover/focus), on applique sa basePriority
      if (card != hoveredCard && card != focusedCard) {
        card.priority = card.basePriority;
      }
    }
  }

  void _applyState(RunState state) {
    if (_currentState == null || _currentState!.currentLevel < state.currentLevel) {
       _spawnEnemies(state.currentLevel);
    }
    _currentState = state;

    int bonusAtt = state.effectiveAttaque - state.heroStats.attaque;

    if (heroCard == null) {
      String imagePath = 'hero_paladin.png';
      if (availableHeroes.isNotEmpty) {
        final heroData = availableHeroes.firstWhere((h) => h.id == state.heroClassId, orElse: () => availableHeroes.first);
        imagePath = heroData.iconPath;
      }
      
      heroCard = HeroCard(state.heroStats, bonusAttack: bonusAtt, imagePath: imagePath);
      heroCard!.position = Vector2(size.x / 2, size.y * 0.6);
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
    
    for (int i = 0; i < enemyDataList.length; i++) {
      final data = enemyDataList[i];
      // On initialise les stats réelles en se basant sur data
      final stats = EntityStats(
        maxPv: data.maxHp,
        currentPv: data.maxHp,
        armure: 0,
        attaque: data.baseDamage,
      );

      final enemy = EnemyCard(
        stats: stats, 
        data: data,
        isBoss: isBoss,
        onTapEnemy: _handlePlayerTargeting,
      );
      
      enemyCards.add(enemy);
      add(enemy);
    }
    _repositionEnemies();
  }

  void _repositionEnemies() {
    if (enemyCards.isEmpty) return;
    
    // Espacement dynamique basé sur la largeur de l'écran
    double spacing = (size.x * 0.8) / (enemyCards.length + 1);
    spacing = spacing.clamp(120, 250); // Garder des limites raisonnables
    
    double startX = (size.x / 2) - ((enemyCards.length - 1) * (spacing / 2));
    double posY = size.y * 0.25; // 25% du haut

    for (int i = 0; i < enemyCards.length; i++) {
      enemyCards[i].position = Vector2(startX + (i * spacing), posY);
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
    if (currentPhase != TurnPhase.player || _currentState == null || _currentState!.isDead) return;

    currentPhase = TurnPhase.enemy; // Empêcher d'autres sélections

    // Fin du tour du joueur, on passe directement à la phase de l'ennemi.
    // L'attaque automatique a été retirée car les dégâts sont maintenant infligés via les cartes.
    if (enemyCards.isEmpty) {
      onEnemiesDead();
      currentPhase = TurnPhase.player;
      return;
    }

    await _enemyRipostePhase();
  }

  Future<void> executeSkill(SkillData skill, {required void Function() onTriggerAttackBuff, required void Function() onTriggerLifesteal}) async {
    if (currentPhase != TurnPhase.player || _currentState == null || _currentState!.isDead) return;

    if ((skill.effectType == 'damage_targeted' || skill.effectType == 'damage_pierce') && selectedEnemy == null) {
      return;
    }

    if (skill.effectType.startsWith('damage')) {
      if (enemyCards.isEmpty) return;
      currentPhase = TurnPhase.enemy;

      heroCard?.dashAnimation();
      await Future.delayed(const Duration(milliseconds: 200));

      if (skill.effectType == 'damage_aoe') {
        int dmg = (_currentState!.effectiveAttaque * (skill.effectValue / 100.0)).round();
        if (dmg < 1) dmg = 1;
        for (var enemy in enemyCards.toList()) {
          enemy.updateStats(enemy.stats.takeDamage(dmg));
          if (enemy.stats.currentPv <= 0) {
            enemy.removeFromParent();
            enemyCards.remove(enemy);
            if (selectedEnemy == enemy) selectedEnemy = null;
          }
        }
      } else if (skill.effectType == 'damage_targeted') {
        int dmg = (_currentState!.effectiveAttaque * (skill.effectValue / 100.0)).round();
        selectedEnemy!.updateStats(selectedEnemy!.stats.takeDamage(dmg));
        if (selectedEnemy!.stats.currentPv <= 0) {
          selectedEnemy!.removeFromParent();
          enemyCards.remove(selectedEnemy);
          selectedEnemy = null;
        }
      } else if (skill.effectType == 'damage_pierce') {
        int dmg = _currentState!.effectiveAttaque;
        int stolenArmor = (selectedEnemy!.stats.armure * (skill.effectValue / 100.0)).round();
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
      }

      if (enemyCards.isEmpty) {
        onEnemiesDead();
        currentPhase = TurnPhase.player;
        return;
      }

      await _enemyRipostePhase();
    } else {
      // Pour les buffs, on ne change pas la phase et on applique l'effet
      if (skill.effectType == 'armor_buff') {
        onPlayerGainArmor(skill.effectValue);
      } else if (skill.effectType == 'attack_buff') {
        onTriggerAttackBuff();
      } else if (skill.effectType == 'lifesteal_buff') {
        onTriggerLifesteal();
      }
    }
  }

  Future<void> _enemyRipostePhase() async {
    onPhaseChanged(TurnPhase.enemy);
    await Future.delayed(const Duration(milliseconds: 600));

    // Début de tour des ennemis (Poison, Tick de buffs, etc.)
    for (var enemy in enemyCards) {
      enemy.startTurn();
    }
    
    // Nettoyage des ennemis morts (ex: par poison)
    for (var enemy in enemyCards.toList()) {
      if (enemy.stats.currentPv <= 0) {
        enemy.removeFromParent();
        enemyCards.remove(enemy);
        if (selectedEnemy == enemy) selectedEnemy = null;
      }
    }

    if (enemyCards.isEmpty) {
      onEnemiesDead();
      currentPhase = TurnPhase.player;
      onPhaseChanged(TurnPhase.player);
      onTurnEnded();
      return;
    }

    // Riposte des Ennemis (Séquentielle)
    for (var enemy in enemyCards) {
      if (_currentState == null || _currentState!.isDead) break;
      
      final intent = enemy.currentIntent;
      if (intent == null) continue;

      if (intent.type == IntentType.attack) {
        enemy.dashAnimation();
      } else {
        enemy.buffAnimation(intent.type);
      }
      
      await Future.delayed(const Duration(milliseconds: 200));

      switch (intent.type) {
        case IntentType.attack:
          onPlayerTakeDamage(intent.value);
          break;
        case IntentType.defend:
          enemy.updateStats(enemy.stats.copyWith(armure: enemy.stats.armure + intent.value));
          break;
        case IntentType.buff:
          // Buff simple : augmente l'attaque de base
          enemy.updateStats(enemy.stats.copyWith(attaque: enemy.stats.attaque + intent.value));
          break;
        case IntentType.debuffDeck:
          // Ajoute une blessure dans la défausse
          onEnemyDebuffDeck(intent.value);
          break;
      }
      
      await Future.delayed(const Duration(milliseconds: 400));
    }

    // Préparer les prochaines intentions
    for (var enemy in enemyCards) {
      enemy.rollIntent();
    }

    await Future.delayed(const Duration(milliseconds: 300));

    currentPhase = TurnPhase.player;
    onPhaseChanged(TurnPhase.player);
    onTurnEnded();
  }


  void resetEnemies() {
    _currentState = null;
  }
}
