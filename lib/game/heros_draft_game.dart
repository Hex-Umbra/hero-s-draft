import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Image, PointerMoveEvent;
import 'components/card_component.dart';
import 'components/entities/hero_card.dart';
import 'components/entities/enemy_card.dart';
import 'components/visual_effects/targeting_line.dart';
import '../models/card_instance.dart';
import '../models/data/enemy_data.dart';
import '../models/data/hero_data.dart';
import '../models/data/skill_data.dart';
import '../models/data/card_data.dart';
import '../models/entity_stats.dart';
import 'game_constants.dart';

import 'controllers/run_controller.dart';
import 'controllers/deck_controller.dart';
import '../models/enemy_intent.dart';
import '../models/combat_state.dart';

class HerosDraftGame extends FlameGame with TapCallbacks, PointerMoveCallbacks {
  List<EnemyData> availableEnemies = [];
  List<HeroData> availableHeroes = [];
  HeroCard? heroCard;
  List<EnemyCard> enemyCards = [];
  List<CardComponent> handCards = [];
  CardComponent? hoveredCard;
  CardComponent? focusedCard;

  late final TargetingLine targetingLine;
  Vector2 _lastPointerPos = Vector2.zero();

  double get scaleFactor => (size.y / 800).clamp(0.85, 2.5);

  RunState? _currentState;
  RunState? get currentRunState => _currentState;
  RunState? _nextState;
  DeckState? _nextDeckState;

  CombatState? _currentCombatState;
  CombatState? get currentCombatState => _currentCombatState;
  CombatState? _nextCombatState;

  TurnPhase currentPhase = TurnPhase.player;
  EnemyCard? selectedEnemy;
  EnemyCard? highlightedEnemy;
  bool isCardAnimating = false;

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
  final VoidCallback? onEnemiesSpawned;
  final void Function() onEnemyKilled;

  // Nouveaux callbacks de découplage Riverpod combat - Étape 4
  final void Function(String enemyId) onResolveEnemyIntent;
  final void Function() onStartEnemyTurn;
  final void Function() onEndEnemyTurn;
  final void Function(String? enemyId) onSelectEnemy;
  final void Function(String enemyId, EntityStats stats) onUpdateEnemyStats;

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
    required this.onEnemyKilled,
    required this.onResolveEnemyIntent,
    required this.onStartEnemyTurn,
    required this.onEndEnemyTurn,
    required this.onSelectEnemy,
    required this.onUpdateEnemyStats,
    this.onEnemiesSpawned,
  });

  void setHoveredCard(CardComponent? card) {
    if (hoveredCard == card) return;

    if (hoveredCard != null && hoveredCard != focusedCard) {
      hoveredCard!.isHovered = false;
      hoveredCard!.priority = hoveredCard!.basePriority;
      hoveredCard!.removeAll(hoveredCard!.children.whereType<Effect>());
      hoveredCard!.refreshVisuals();
      if (!hoveredCard!.isDragging) {
        hoveredCard!.add(
          ScaleEffect.to(
            Vector2.all(scaleFactor * 0.88),
            EffectController(duration: 0.1, curve: Curves.easeIn),
          ),
        );
      }
    }

    hoveredCard = card;

    if (hoveredCard != null && hoveredCard != focusedCard) {
      hoveredCard!.isHovered = true;
      hoveredCard!.priority = GameConstants.priorityCardHovered;
      hoveredCard!.removeAll(hoveredCard!.children.whereType<Effect>());
      hoveredCard!.refreshVisuals();
      if (!hoveredCard!.isDragging) {
        hoveredCard!.add(
          ScaleEffect.to(
            Vector2.all(scaleFactor * 0.88 * 1.2),
            EffectController(duration: 0.1, curve: Curves.easeOut),
          ),
        );
      }
    }
  }

  void setFocusedCard(CardComponent? card) {
    if (focusedCard == card) return;

    if (focusedCard != null) {
      final oldFocused = focusedCard!;
      oldFocused.isHovered = false;
      oldFocused.priority = oldFocused.basePriority;
      oldFocused.removeAll(oldFocused.children.whereType<Effect>());
      oldFocused.refreshVisuals();
      if (!oldFocused.isDragging) {
        oldFocused.add(
          MoveEffect.to(
            oldFocused.originalPosition,
            EffectController(duration: 0.15, curve: Curves.easeIn),
          ),
        );
        oldFocused.add(
          ScaleEffect.to(
            Vector2.all(scaleFactor * 0.88),
            EffectController(duration: 0.15, curve: Curves.easeIn),
          ),
        );
      }
      targetingLine.hide();
      _clearTargetHighlights();
    }

    focusedCard = card;

    if (focusedCard != null) {
      focusedCard!.isHovered = true;
      focusedCard!.priority = GameConstants.priorityCardFocused;
      focusedCard!.removeAll(focusedCard!.children.whereType<Effect>());
      focusedCard!.refreshVisuals();
      if (!focusedCard!.isDragging) {
        focusedCard!.add(
          MoveEffect.to(
            focusedCard!.originalPosition + Vector2(0, -60),
            EffectController(duration: 0.2, curve: Curves.easeOut),
          ),
        );
        focusedCard!.add(
          ScaleEffect.to(
            Vector2.all(scaleFactor * 0.88 * 1.25),
            EffectController(duration: 0.2, curve: Curves.easeOut),
          ),
        );
      }
      targetingLine.color = focusedCard!.getElementalColor();
      _applyTargetHighlights(focusedCard!.card.data.target);
    }
  }

  void _clearTargetHighlights() {
    for (var enemy in enemyCards) {
      enemy.setHighlight(false);
    }
    heroCard?.setHighlight(false);
  }

  void _applyTargetHighlights(CardTarget target) {
    if (target == CardTarget.singleEnemy || target == CardTarget.allEnemies) {
      for (var enemy in enemyCards) {
        enemy.setHighlight(true);
      }
    } else if (target == CardTarget.self) {
      heroCard?.setHighlight(true);
    }
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _lastPointerPos = event.localPosition;

    if (focusedCard != null && !focusedCard!.isDragging) {
      targetingLine.updatePoints(
        focusedCard!.position + Vector2(0, -40),
        _lastPointerPos,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    setFocusedCard(null);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    targetingLine = TargetingLine();
    add(targetingLine..priority = GameConstants.priorityTargetingLine);

    final List<String> imagesToPreload = ['bg_dungeon.png'];

    try {
      final String enemiesRaw = await rootBundle.loadString(
        'assets/data/enemies.json',
      );
      final List<dynamic> enemiesJson = jsonDecode(enemiesRaw);
      for (final enemy in enemiesJson) {
        final spritePath = enemy['spritePath'] as String?;
        if (spritePath != null && spritePath.isNotEmpty) {
          imagesToPreload.add(spritePath);
        }
      }

      final String heroesRaw = await rootBundle.loadString(
        'assets/data/heroes.json',
      );
      final List<dynamic> heroesJson = jsonDecode(heroesRaw);
      for (final hero in heroesJson) {
        final iconPath = hero['iconPath'] as String?;
        if (iconPath != null && iconPath.isNotEmpty) {
          imagesToPreload.add(iconPath);
        }
      }
    } catch (e) {
      imagesToPreload.addAll([
        'hero_paladin.png',
        'hero_berserker.png',
        'hero_mage.png',
        'enemy_goblin.png',
        'enemy_slime.png',
        'enemy_skeleton.png',
        'enemy_orc.png',
      ]);
    }

    final uniqueImages = imagesToPreload.toSet().toList();
    await images.loadAll(uniqueImages);

    final bgSprite = Sprite(images.fromCache('bg_dungeon.png'));
    add(
      SpriteComponent(sprite: bgSprite, size: size)
        ..priority = GameConstants.priorityBackground,
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (heroCard != null) {
      heroCard!.position = Vector2(size.x / 2, size.y * 0.51);
    }
    if (enemyCards.isNotEmpty) {
      _repositionEnemies();
    }
    _layoutHand();

    children.whereType<SpriteComponent>().forEach((bg) {
      if (bg.priority == GameConstants.priorityBackground) bg.size = size;
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
      handCards.remove(cardComp);
      _layoutHand();

      isCardAnimating = true;

      cardComp.playAnimation(
        target,
        onComplete: () {
          cardComp.removeFromParent();
          isCardAnimating = false;
          resolvePendingDeaths();
        },
      );

      return true;
    }
    return false;
  }

  void resolvePendingDeaths() {
    // 1. Resolve pending visual updates for all enemies
    for (var card in enemyCards) {
      card.resolvePendingVisualStats();
    }

    // 2. Resolve pending deaths
    final deadCards = enemyCards.where((c) => c.isPendingDeath).toList();
    if (deadCards.isEmpty) return;

    for (var card in deadCards) {
      card.isDead = true;
      card.add(OpacityEffect.to(0.0, EffectController(duration: 0.4)));
      card.add(
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.4),
          onComplete: () {
            card.removeFromParent();
          },
        ),
      );
      enemyCards.remove(card);
    }
    _repositionEnemies();
    onEnemiesSpawned?.call();
  }

  @override
  Color backgroundColor() => const Color(0xFF1E1E2C);

  void syncState(RunState state) {
    _nextState = state;
  }

  void syncDeck(DeckState deckState) {
    _nextDeckState = deckState;
  }

  void syncCombat(CombatState combatState) {
    _nextCombatState = combatState;
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
    if (_nextCombatState != null && hasLayout) {
      _applyCombatState(_nextCombatState!);
      _nextCombatState = null;
    }
  }

  void _applyDeckState(DeckState deck) {
    final newHandIds = deck.hand.map((c) => c.uniqueId).toSet();
    final cardsToRemove = handCards
        .where((c) => !newHandIds.contains(c.card.uniqueId))
        .toList();

    for (var c in cardsToRemove) {
      c.removeFromParent();
      handCards.remove(c);
    }

    final currentHandIds = handCards.map((c) => c.card.uniqueId).toSet();
    final cardsToAdd = deck.hand
        .where((c) => !currentHandIds.contains(c.uniqueId))
        .toList();

    for (var c in cardsToAdd) {
      final cardComp = CardComponent(c);
      handCards.add(cardComp);
      add(cardComp);
    }

    if (cardsToRemove.isNotEmpty || cardsToAdd.isNotEmpty) {
      _layoutHand();
    }
  }

  void _layoutHand() {
    if (handCards.isEmpty) return;

    final int count = handCards.length;
    final double radius = size.y * 1.5;

    double angleStep = 0.08;
    if (count > 4) {
      angleStep = (0.4 / count).clamp(0.04, 0.08);
    }

    final double totalAngle = (count - 1) * angleStep;
    final double startAngle = -totalAngle / 2;

    final Vector2 centerPoint = Vector2(
      size.x / 2,
      size.y + radius - (size.y * 0.23),
    );

    for (int i = 0; i < count; i++) {
      final card = handCards[i];
      card.basePriority = 10 + i;

      final double angle = startAngle + (i * angleStep);

      final double x = centerPoint.x + radius * sin(angle);
      final double y = centerPoint.y - radius * cos(angle);

      card.originalPosition = Vector2(x, y);
      card.originalAngle = angle;

      if (card.isDragging) continue;

      if (card == focusedCard) {
        card.position = Vector2(x, y) + Vector2(0, -60);
        card.angle = angle;
      } else {
        card.position = Vector2(x, y);
        card.angle = angle;
      }

      if (card != hoveredCard && card != focusedCard) {
        card.priority = card.basePriority;
      }
    }
  }

  void _applyState(RunState state) {
    _currentState = state;

    int bonusAtt = state.effectiveAttaque - state.heroStats.attaque;

    if (heroCard == null) {
      String imagePath = 'hero_paladin.png';
      if (availableHeroes.isNotEmpty) {
        final heroData = availableHeroes.firstWhere(
          (h) => h.id == state.heroClassId,
          orElse: () => availableHeroes.first,
        );
        imagePath = heroData.iconPath;
      }

      heroCard = HeroCard(
        state.heroStats,
        bonusAttack: bonusAtt,
        imagePath: imagePath,
      );
      heroCard!.position = Vector2(size.x / 2, size.y * 0.51);
      add(heroCard!);
    } else {
      heroCard!.updateStats(state.heroStats, bonusAttack: bonusAtt);
    }

    for (var card in handCards) {
      card.refreshVisuals();
    }
  }

  void _applyCombatState(CombatState state) {
    currentPhase = state.turnPhase;

    // 1. Gérer les disparitions (morts)
    final newEnemiesIds = state.enemies.map((e) => e.id).toSet();
    final cardsToRemove = enemyCards
        .where((c) => !newEnemiesIds.contains(c.id))
        .toList();

    bool immediateRemovals = false;
    for (var card in cardsToRemove) {
      if (isCardAnimating) {
        card.isPendingDeath = true;
      } else {
        card.isDead = true;
        card.isPendingDeath = true;
        card.add(OpacityEffect.to(0.0, EffectController(duration: 0.4)));
        card.add(
          ScaleEffect.to(
            Vector2.zero(),
            EffectController(duration: 0.4),
            onComplete: () {
              card.removeFromParent();
            },
          ),
        );
        enemyCards.remove(card);
        immediateRemovals = true;
      }
    }

    // 2. Gérer les apparitions ou mises à jour
    bool listChanged = immediateRemovals;

    for (var enemyInstance in state.enemies) {
      final existingIndex = enemyCards.indexWhere(
        (c) => c.id == enemyInstance.id,
      );
      if (existingIndex != -1) {
        enemyCards[existingIndex].updateStats(enemyInstance);
      } else {
        final enemyCard = EnemyCard(
          instance: enemyInstance,
          onTapEnemy: _handlePlayerTargeting,
        );
        enemyCards.add(enemyCard);
        add(enemyCard);
        listChanged = true;
      }
    }

    // 3. Repositionner si la liste a changé
    if (listChanged) {
      _repositionEnemies();
      onEnemiesSpawned?.call();
    }

    // 4. Synchroniser la sélection visuelle
    selectedEnemy = null;
    for (var card in enemyCards) {
      final isSelected = card.id == state.selectedEnemyId;
      card.setSelection(isSelected);
      if (isSelected) {
        selectedEnemy = card;
      }
    }

    _currentCombatState = state;
  }

  void _repositionEnemies() {
    if (enemyCards.isEmpty) return;

    double spacing = (size.x * 0.8) / (enemyCards.length + 1);
    spacing = spacing.clamp(120, 250);

    double startX = (size.x / 2) - ((enemyCards.length - 1) * (spacing / 2));
    double posY = size.y * 0.21;

    for (int i = 0; i < enemyCards.length; i++) {
      enemyCards[i].position = Vector2(startX + (i * spacing), posY);
    }
  }

  void _handlePlayerTargeting(EnemyCard target) {
    if (_currentState == null ||
        _currentState!.isDead ||
        currentPhase != TurnPhase.player) {
      return;
    }

    if (focusedCard != null) {
      if (focusedCard!.card.data.target == CardTarget.singleEnemy ||
          focusedCard!.card.data.target == CardTarget.allEnemies) {
        final cardToPlay = focusedCard!;
        if (!cardToPlay.canAfford) {
          cardToPlay.shakeAnimation();
          return;
        }
        setFocusedCard(null);
        bool played = tryPlayCard(cardToPlay, target);
        if (played) {
          return;
        }
      }
    }
  }

  Future<void> executeTurn() async {
    if (currentPhase != TurnPhase.player ||
        _currentState == null ||
        _currentState!.isDead) {
      return;
    }

    currentPhase = TurnPhase.enemy;

    if (enemyCards.isEmpty) {
      onEnemiesDead();
      currentPhase = TurnPhase.player;
      return;
    }

    await _enemyRipostePhase();
  }

  Future<void> executeSkill(
    SkillData skill, {
    required void Function() onTriggerAttackBuff,
    required void Function() onTriggerLifesteal,
  }) async {
    if (currentPhase != TurnPhase.player ||
        _currentState == null ||
        _currentState!.isDead) {
      return;
    }

    if ((skill.effectType == 'damage_targeted' ||
            skill.effectType == 'damage_pierce') &&
        selectedEnemy == null) {
      return;
    }

    if (skill.effectType.startsWith('damage')) {
      if (enemyCards.isEmpty) return;
      currentPhase = TurnPhase.enemy;

      heroCard?.dashAnimation();
      await Future.delayed(const Duration(milliseconds: 200));

      if (skill.effectType == 'damage_aoe') {
        int dmg =
            (_currentState!.effectiveAttaque * (skill.effectValue / 100.0))
                .round();
        if (dmg < 1) dmg = 1;
        for (var enemy in enemyCards.toList()) {
          onUpdateEnemyStats(enemy.id, enemy.stats.takeDamage(dmg));
        }
      } else if (skill.effectType == 'damage_targeted') {
        int dmg =
            (_currentState!.effectiveAttaque * (skill.effectValue / 100.0))
                .round();
        onUpdateEnemyStats(
          selectedEnemy!.id,
          selectedEnemy!.stats.takeDamage(dmg),
        );
      } else if (skill.effectType == 'damage_pierce') {
        int dmg = _currentState!.effectiveAttaque;
        int stolenArmor =
            (selectedEnemy!.stats.armure * (skill.effectValue / 100.0)).round();
        int newPv = selectedEnemy!.stats.currentPv - dmg;
        int newArm = selectedEnemy!.stats.armure - stolenArmor;
        if (newPv < 0) newPv = 0;
        if (newArm < 0) newArm = 0;

        onUpdateEnemyStats(
          selectedEnemy!.id,
          selectedEnemy!.stats.copyWith(currentPv: newPv, armure: newArm),
        );
        if (stolenArmor > 0) {
          onPlayerGainArmor(stolenArmor);
        }
      }

      // La riposte est déclenchée après l'effet visuel et la mise à jour Riverpod
      await Future.delayed(const Duration(milliseconds: 400));
      if (enemyCards.isEmpty) {
        onEnemiesDead();
        currentPhase = TurnPhase.player;
        return;
      }

      await _enemyRipostePhase();
    } else {
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

    // 1. Début de tour des ennemis (Poison, Tick de buffs, etc. résolu dans Riverpod)
    onStartEnemyTurn();

    // Laisser le temps aux animations de ticks (ex: poison) avant les attaques
    await Future.delayed(const Duration(milliseconds: 400));

    // Riposte des Ennemis (Séquentielle)
    final activeEnemies = List<EnemyCard>.from(enemyCards);
    for (var enemy in activeEnemies) {
      if (_currentState == null || _currentState!.isDead) break;

      final intent = enemy.effectiveIntent;
      if (intent == null) continue;

      if (intent.type == IntentType.attack) {
        enemy.dashAnimation();
      } else {
        enemy.buffAnimation(intent.type);
      }

      await Future.delayed(const Duration(milliseconds: 200));

      // Résoudre l'intention dans Riverpod
      onResolveEnemyIntent(enemy.id);

      await Future.delayed(const Duration(milliseconds: 400));
    }

    await Future.delayed(const Duration(milliseconds: 300));

    // 2. Fin de tour ennemi dans Riverpod (roll intents, repasse le tour au joueur)
    onEndEnemyTurn();
  }

  void resetEnemies() {
    _currentState = null;
    _currentCombatState = null;
  }
}
