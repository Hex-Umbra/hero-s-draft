import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import '../heros_draft_game.dart';
import '../../services/audio/game_moment.dart';
import '../controllers/run_controller.dart';
import '../controllers/deck_controller.dart';
import '../../models/combat_state.dart';
import '../components/entities/hero_card.dart';
import '../components/entities/enemy_card.dart';
import '../components/card_component.dart';

class StateSyncSystem extends Component with HasGameReference<HerosDraftGame> {
  RunState? currentState;
  RunState? nextState;
  DeckState? nextDeckState;
  CombatState? currentCombatState;
  CombatState? nextCombatState;

  @override
  void update(double dt) {
    super.update(dt);
    if (nextState != null && game.hasLayout) {
      _applyState(nextState!);
      nextState = null;
    }
    if (nextDeckState != null && game.hasLayout) {
      _applyDeckState(nextDeckState!);
      nextDeckState = null;
    }
    if (nextCombatState != null && game.hasLayout) {
      _applyCombatState(nextCombatState!);
      nextCombatState = null;
    }
  }

  void _applyState(RunState state) {
    currentState = state;

    int bonusAtt = state.effectiveAttaque - state.heroStats.attaque;

    if (game.heroCard == null) {
      String imagePath = 'hero_paladin.png';
      if (game.availableHeroes.isNotEmpty) {
        final heroData = game.availableHeroes.firstWhere(
          (h) => h.id == state.heroClassId,
          orElse: () => game.availableHeroes.first,
        );
        imagePath = heroData.iconPath;
      }

      game.heroCard = HeroCard(
        state.heroStats,
        bonusAttack: bonusAtt,
        imagePath: imagePath,
      );
      game.heroCard!.position = Vector2(game.size.x / 2, game.size.y * 0.51);
      game.add(game.heroCard!);
    } else {
      game.heroCard!.updateStats(state.heroStats, bonusAttack: bonusAtt);
    }

    for (var card in game.handCards) {
      card.refreshVisuals();
    }
  }

  void _applyDeckState(DeckState deck) {
    final newHandIds = deck.hand.map((c) => c.uniqueId).toSet();
    final cardsToRemove = game.handCards
        .where((c) => !newHandIds.contains(c.card.uniqueId))
        .toList();

    for (var c in cardsToRemove) {
      c.removeFromParent();
      game.handCards.remove(c);
    }

    final currentHandIds = game.handCards.map((c) => c.card.uniqueId).toSet();
    final cardsToAdd = deck.hand
        .where((c) => !currentHandIds.contains(c.uniqueId))
        .toList();

    for (var c in cardsToAdd) {
      final cardComp = CardComponent(c);
      cardComp.isEnteringHand = true;
      cardComp.position = Vector2(40, game.size.y - 40);
      cardComp.scale = Vector2.zero();
      game.handCards.add(cardComp);
      game.add(cardComp);
    }

    if (cardsToRemove.isNotEmpty || cardsToAdd.isNotEmpty) {
      game.layoutHand();
    }
  }

  void _applyCombatState(CombatState state) {
    game.currentPhase = state.turnPhase;

    // 1. Gérer les disparitions (morts)
    final newEnemiesIds = state.enemies.map((e) => e.id).toSet();
    final cardsToRemove = game.enemyCards
        .where((c) => !newEnemiesIds.contains(c.id))
        .toList();

    bool immediateRemovals = false;
    for (var card in cardsToRemove) {
      if (game.isCardAnimating) {
        card.isPendingDeath = true;
      } else {
        card.isDead = true;
        card.isPendingDeath = true;
        game.audio.onMoment(GameMoment.enemyDeath, source: card.data);
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
        game.enemyCards.remove(card);
        immediateRemovals = true;
      }
    }

    // 2. Gérer les apparitions ou mises à jour
    bool listChanged = immediateRemovals;

    for (var enemyInstance in state.enemies) {
      final existingIndex = game.enemyCards.indexWhere(
        (c) => c.id == enemyInstance.id,
      );
      if (existingIndex != -1) {
        game.enemyCards[existingIndex].updateStats(enemyInstance);
      } else {
        final enemyCard = EnemyCard(
          instance: enemyInstance,
          onTapEnemy: game.handlePlayerTargeting,
        );
        game.enemyCards.add(enemyCard);
        game.add(enemyCard);
        listChanged = true;
      }
    }

    // 3. Repositionner si la liste a changé
    if (listChanged) {
      game.repositionEnemies();
      game.onEnemiesSpawned?.call();
    }

    // 4. Synchroniser la sélection visuelle
    game.selectedEnemy = null;
    for (var card in game.enemyCards) {
      final isSelected = card.id == state.selectedEnemyId;
      card.setSelection(isSelected);
      if (isSelected) {
        game.selectedEnemy = card;
      }
    }

    currentCombatState = state;
  }
}
