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

    // Seule une carte encore en main reprend sa taille : une carte jouée garde
    // son animation, une carte défaussée n'est plus dessinée.
    if (hoveredCard != null &&
        hoveredCard != focusedCard &&
        game.handCards.contains(hoveredCard)) {
      hoveredCard.priority = hoveredCard.basePriority;
      hoveredCard.refreshVisuals();
      if (!hoveredCard.isDragging) {
        _scaleForHover(hoveredCard, 1.0, Curves.easeIn);
      }
    }

    game.hoveredCard = card;

    if (card != null && card != focusedCard) {
      card.priority = GameConstants.priorityCardHovered;
      card.refreshVisuals();
      if (!card.isDragging) {
        _scaleForHover(card, GameConstants.cardHoverScale, Curves.easeOut);
      }
    }
  }

  /// Le survol ne touche que la taille : le déplacement et la rotation d'une
  /// remise en page en cours vont à leur terme.
  void _scaleForHover(CardComponent card, double factor, Curve curve) {
    card.removeAll(card.children.whereType<ScaleEffect>());
    card.add(
      ScaleEffect.to(
        Vector2.all(game.scaleFactor * 0.88 * factor),
        EffectController(duration: 0.1, curve: curve),
      ),
    );
  }

  void setFocusedCard(CardComponent? card) {
    final focusedCard = game.focusedCard;
    if (focusedCard == card) return;

    if (focusedCard != null) {
      final oldFocused = focusedCard;
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
