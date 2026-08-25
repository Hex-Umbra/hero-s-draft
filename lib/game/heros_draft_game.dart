import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
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
import '../services/audio/audio_director.dart';
import '../services/audio/game_moment.dart';

import 'systems/state_sync_system.dart';
import 'systems/card_animation_system.dart';
import 'systems/combat_visual_system.dart';
import 'systems/layout_system.dart';

class HerosDraftGame extends FlameGame with TapCallbacks, PointerMoveCallbacks {
  List<EnemyData> availableEnemies = [];
  List<HeroData> availableHeroes = [];
  HeroCard? heroCard;
  List<EnemyCard> enemyCards = [];
  List<CardComponent> handCards = [];
  CardComponent? hoveredCard;
  CardComponent? focusedCard;

  StateSyncSystem? stateSyncSystem;
  CardAnimationSystem? cardAnimationSystem;
  CombatVisualSystem? combatVisualSystem;
  LayoutSystem? layoutSystem;

  TargetingLine get targetingLine => combatVisualSystem!.targetingLine;
  Vector2 _lastPointerPos = Vector2.zero();

  double get scaleFactor => (size.y / 800).clamp(0.85, 2.5);

  RunState? get currentRunState => stateSyncSystem?.currentState;
  CombatState? get currentCombatState => stateSyncSystem?.currentCombatState;

  TurnPhase currentPhase = TurnPhase.player;
  EnemyCard? selectedEnemy;
  EnemyCard? highlightedEnemy;
  bool isCardAnimating = false;

  /// Injecte depuis `GameScreen` : la couche Flame ne lit jamais un provider.
  final AudioDirector audio;

  final void Function() onEnemiesDead;
  final void Function(TurnPhase) onPhaseChanged;
  final void Function(String title, String description, CardType? cardType) onShowTooltip;
  final void Function() onHideTooltip;
  final bool Function(CardInstance, EnemyCard?) onPlayCard;
  final VoidCallback? onEnemiesSpawned;
  final void Function() onEnemyKilled;

  final void Function(String enemyId) onResolveEnemyIntent;
  final void Function() onStartEnemyTurn;
  final void Function() onEndEnemyTurn;
  final void Function(String? enemyId) onSelectEnemy;
  final void Function(String enemyId, EntityStats stats) onUpdateEnemyStats;
  final void Function(SkillData skill, String? targetEnemyId) onExecuteSkill;
  final VoidCallback? onAnimationStateChanged;

  HerosDraftGame({
    required this.audio,
    required this.onEnemiesDead,
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
    required this.onExecuteSkill,
    this.onEnemiesSpawned,
    this.onAnimationStateChanged,
  });

  void setHoveredCard(CardComponent? card) {
    if (card != null && card != hoveredCard) {
      audio.onMoment(GameMoment.cardHover);
    }
    cardAnimationSystem?.setHoveredCard(card);
  }

  void setFocusedCard(CardComponent? card) {
    cardAnimationSystem?.setFocusedCard(card);
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    _lastPointerPos = event.localPosition;
    combatVisualSystem?.updatePointer(_lastPointerPos);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    setFocusedCard(null);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final system = StateSyncSystem();
    stateSyncSystem = system;
    final animSys = CardAnimationSystem();
    cardAnimationSystem = animSys;
    final visualSys = CombatVisualSystem();
    combatVisualSystem = visualSys;
    final laySys = LayoutSystem();
    layoutSystem = laySys;

    await add(system);
    await add(animSys);
    await add(visualSys);
    await add(laySys);

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
      repositionEnemies();
    }
    layoutHand();

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
      layoutHand();

      isCardAnimating = true;
      onAnimationStateChanged?.call();

      cardComp.playAnimation(
        target,
        onComplete: () {
          cardComp.removeFromParent();
          isCardAnimating = false;
          onAnimationStateChanged?.call();
          resolvePendingDeaths();
        },
      );

      return true;
    }
    return false;
  }

  void resolvePendingDeaths() {
    for (var card in enemyCards) {
      card.resolvePendingVisualStats();
    }

    final deadCards = enemyCards.where((c) => c.isPendingDeath).toList();
    if (deadCards.isEmpty) return;

    for (var card in deadCards) {
      audio.onMoment(GameMoment.enemyDeath);
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
    repositionEnemies();
    onEnemiesSpawned?.call();
  }

  @override
  Color backgroundColor() => const Color(0xFF1E1E2C);

  void syncState(RunState state) {
    stateSyncSystem?.nextState = state;
  }

  void syncDeck(DeckState deckState) {
    stateSyncSystem?.nextDeckState = deckState;
  }

  void syncCombat(CombatState combatState) {
    stateSyncSystem?.nextCombatState = combatState;
  }

  void layoutHand() {
    layoutSystem?.layoutHand();
  }

  void repositionEnemies() {
    layoutSystem?.repositionEnemies();
  }

  void handlePlayerTargeting(EnemyCard target) {
    _handlePlayerTargeting(target);
  }

  void _handlePlayerTargeting(EnemyCard target) {
    if (currentRunState == null ||
        currentRunState!.isDead ||
        currentPhase != TurnPhase.player) {
      return;
    }

    if (focusedCard != null) {
      if (focusedCard!.card.data.target == CardTarget.singleEnemy ||
          focusedCard!.card.data.target == CardTarget.allEnemies) {
        final cardToPlay = focusedCard!;
        if (!cardToPlay.canAfford) {
          audio.onMoment(GameMoment.insufficientMana);
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
        currentRunState == null ||
        currentRunState!.isDead) {
      return;
    }
    audio.onMoment(GameMoment.turnEnd);

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
        currentRunState == null ||
        currentRunState!.isDead) {
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
      await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayHeroDashMs));

      onExecuteSkill(skill, selectedEnemy?.id);

      await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayAfterSkillMs));
      if (enemyCards.isEmpty) {
        onEnemiesDead();
        currentPhase = TurnPhase.player;
        return;
      }

      await _enemyRipostePhase();
    } else {
      if (skill.effectType == 'armor_buff') {
        onExecuteSkill(skill, null);
      } else if (skill.effectType == 'attack_buff') {
        onTriggerAttackBuff();
      } else if (skill.effectType == 'lifesteal_buff') {
        onTriggerLifesteal();
      }
    }
  }

  Future<void> _enemyRipostePhase() async {
    onPhaseChanged(TurnPhase.enemy);
    await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayEnemyTurnStartMs));

    onStartEnemyTurn();

    await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayAfterTicksMs));

    final activeEnemies = List<EnemyCard>.from(enemyCards);
    for (var enemy in activeEnemies) {
      if (currentRunState == null || currentRunState!.isDead) break;

      final intent = enemy.effectiveIntent;
      if (intent == null) continue;

      if (intent.type == IntentType.attack) {
        audio.onMoment(GameMoment.enemyAttack);
        enemy.dashAnimation();
      } else {
        enemy.buffAnimation(intent.type);
      }

      await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayEnemyDashMs));

      onResolveEnemyIntent(enemy.id);

      await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayAfterIntentResolveMs));
    }

    await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayEnemyTurnEndMs));

    onEndEnemyTurn();
  }

  void resetEnemies() {
    stateSyncSystem?.currentState = null;
    stateSyncSystem?.currentCombatState = null;
  }

  @override
  void onRemove() {
    stateSyncSystem?.currentState = null;
    stateSyncSystem?.currentCombatState = null;
    super.onRemove();
  }
}
