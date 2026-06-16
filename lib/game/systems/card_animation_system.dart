import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' hide Image;
import '../heros_draft_game.dart';
import '../game_constants.dart';
import '../components/card_component.dart';
import '../../models/data/card_data.dart';

class CardAnimationSystem extends Component with HasGameReference<HerosDraftGame> {
  void setHoveredCard(CardComponent? card) {
    final hoveredCard = game.hoveredCard;
    final focusedCard = game.focusedCard;
    if (hoveredCard == card) return;

    if (hoveredCard != null && hoveredCard != focusedCard) {
      hoveredCard.isHovered = false;
      hoveredCard.priority = hoveredCard.basePriority;
      hoveredCard.removeAll(hoveredCard.children.whereType<Effect>());
      hoveredCard.refreshVisuals();
      if (!hoveredCard.isDragging) {
        hoveredCard.add(
          ScaleEffect.to(
            Vector2.all(game.scaleFactor * 0.88),
            EffectController(duration: 0.1, curve: Curves.easeIn),
          ),
        );
      }
    }

    game.hoveredCard = card;

    if (card != null && card != focusedCard) {
      card.isHovered = true;
      card.priority = GameConstants.priorityCardHovered;
      card.removeAll(card.children.whereType<Effect>());
      card.refreshVisuals();
      if (!card.isDragging) {
        card.add(
          ScaleEffect.to(
            Vector2.all(game.scaleFactor * 0.88 * 1.2),
            EffectController(duration: 0.1, curve: Curves.easeOut),
          ),
        );
      }
    }
  }

  void setFocusedCard(CardComponent? card) {
    final focusedCard = game.focusedCard;
    if (focusedCard == card) return;

    if (focusedCard != null) {
      final oldFocused = focusedCard;
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
            Vector2.all(game.scaleFactor * 0.88),
            EffectController(duration: 0.15, curve: Curves.easeIn),
          ),
        );
      }
      game.targetingLine.hide();
      clearTargetHighlights();
      game.onHideTooltip();
    }

    game.focusedCard = card;

    if (card != null) {
      card.isHovered = true;
      card.priority = GameConstants.priorityCardFocused;
      card.removeAll(card.children.whereType<Effect>());
      card.refreshVisuals();
      if (!card.isDragging) {
        card.add(
          MoveEffect.to(
            card.originalPosition + Vector2(0, -60),
            EffectController(duration: 0.2, curve: Curves.easeOut),
          ),
        );
        card.add(
          ScaleEffect.to(
            Vector2.all(game.scaleFactor * 0.88 * 1.25),
            EffectController(duration: 0.2, curve: Curves.easeOut),
          ),
        );
      }
      game.targetingLine.color = card.getElementalColor();
      applyTargetHighlights(card.card.data.target);
      game.onShowTooltip(
        card.card.data.getName(card.activeLocale),
        card.buildDetailedDescription(),
        card.card.data.type,
      );
    }
  }

  void clearTargetHighlights() {
    for (var enemy in game.enemyCards) {
      enemy.setHighlight(false);
    }
    game.heroCard?.setHighlight(false);
  }

  void applyTargetHighlights(CardTarget target) {
    if (target == CardTarget.singleEnemy || target == CardTarget.allEnemies) {
      for (var enemy in game.enemyCards) {
        enemy.setHighlight(true);
      }
    } else if (target == CardTarget.self) {
      game.heroCard?.setHighlight(true);
    }
  }
}
