import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../card_component.dart';
import '../entities/enemy_card.dart';
import '../../../models/data/card_data.dart';
import '../../../services/audio/game_moment.dart';
import '../visual_effects/ribbon_trail.dart';

class CardInteractionHandler {
  final CardComponent cardComponent;

  CardInteractionHandler(this.cardComponent);

  void onHoverEnter() {
    if (cardComponent.isEnteringHand || cardComponent.isPlayed) return;
    if (cardComponent.isDragging) return;
    cardComponent.game.setHoveredCard(cardComponent);
  }

  void onHoverExit() {
    if (cardComponent.isEnteringHand || cardComponent.isPlayed) return;
    if (cardComponent.isDragging) return;
    if (cardComponent.game.hoveredCard == cardComponent) {
      cardComponent.game.setHoveredCard(null);
    }
  }

  void onTapDown(TapDownEvent event) {
    if (cardComponent.isEnteringHand || cardComponent.isPlayed) return;
    if (cardComponent.game.focusedCard == cardComponent) {
      cardComponent.game.setFocusedCard(null);
    } else {
      // La carte devient la carte focalisee : c'est le geste de "pick up"
      // du parcours clic-pour-jouer, l'equivalent au clic du debut d'un
      // glisser (voir onDragStart). Ne pas emettre dans la branche
      // inverse : defocaliser n'est pas reprendre la carte en main.
      cardComponent.game.audio.onMoment(GameMoment.cardPickup);
      cardComponent.game.setFocusedCard(cardComponent);
    }
    cardComponent.refreshVisuals();
    event.continuePropagation = false;
  }

  void onDragStart(DragStartEvent event) {
    if (cardComponent.isEnteringHand || cardComponent.isPlayed) return;

    cardComponent.isDragging = true;
    cardComponent.targetTilt = 0;

    cardComponent.activeTrail = RibbonTrail(
      priority: cardComponent.priority - 1,
      glowColor: cardComponent.getElementalColor(),
      coreColor: Colors.white,
    );
    cardComponent.game.add(cardComponent.activeTrail!);

    if (cardComponent.game.focusedCard == cardComponent) {
      // Vrai signifie qu'onTapDown, qui s'execute toujours en premier sur ce
      // meme geste, vient de focaliser cette carte dans sa propre branche
      // else (elle partait donc non focalisee) et a deja emis cardPickup
      // a ce moment-la. Ce glisser ne fait qu'acter la fin du focus, ce
      // n'est pas une seconde prise en main : ne pas re-emettre.
      cardComponent.game.setFocusedCard(null);
    } else {
      // Faux signifie que la carte partait deja focalisee : onTapDown vient
      // de la defocaliser sans emettre (voir son propre commentaire). C'est
      // donc ici, et seulement ici, l'unique emission de ce geste.
      cardComponent.game.audio.onMoment(GameMoment.cardPickup);
    }
    if (cardComponent.game.hoveredCard == cardComponent) {
      cardComponent.game.setHoveredCard(null);
    }

    cardComponent.clearEffects();
    cardComponent.priority = 200;

    cardComponent.angle = 0;
    cardComponent.scale = Vector2.all(cardComponent.game.scaleFactor * 0.88 * 1.25);
    cardComponent.refreshVisuals();
  }

  void onDragUpdate(DragUpdateEvent event) {
    if (cardComponent.isEnteringHand || cardComponent.isPlayed) return;
    if (!cardComponent.isDragging) return;

    cardComponent.position += event.canvasDelta;
    cardComponent.targetTilt = (event.canvasDelta.x * 0.08).clamp(-0.4, 0.4);

    bool isInCancelZone = cardComponent.position.y > cardComponent.game.size.y * 0.68;
    if (isInCancelZone != cardComponent.isHoveringCancelZone) {
      cardComponent.isHoveringCancelZone = isInCancelZone;
      applyCancelZoneFeedback(cardComponent.isHoveringCancelZone);
    }

    if (cardComponent.card.data.target == CardTarget.singleEnemy) {
      EnemyCard? hoveredEnemy = cardComponent.isHoveringCancelZone
          ? null
          : findHoveredEnemy(cardComponent.position);
      cardComponent.game.highlightEnemy(hoveredEnemy);
    }
  }

  void applyCancelZoneFeedback(bool cancelling) {
    cardComponent.clearEffects();
    cardComponent.isCancelling = cancelling;

    if (cancelling) {
      cardComponent.add(ScaleEffect.to(Vector2.all(0.9), EffectController(duration: 0.1)));
    } else {
      cardComponent.add(ScaleEffect.to(Vector2.all(1.25), EffectController(duration: 0.1)));
    }
    cardComponent.refreshVisuals();
  }

  void onDragEnd(DragEndEvent event) {
    if (cardComponent.isPlayed) return;
    if (!cardComponent.isDragging) return;

    cardComponent.isDragging = false;
    cardComponent.targetTilt = 0;
    cardComponent.game.setFocusedCard(null);

    cardComponent.activeTrail?.stop();
    cardComponent.activeTrail = null;

    if (cardComponent.isHoveringCancelZone) {
      cardComponent.animator.returnToHand();
      cardComponent.game.highlightEnemy(null);
      return;
    }

    if (!cardComponent.canAfford) {
      cardComponent.game.audio.onMoment(GameMoment.insufficientMana);
      cardComponent.animator.shakeAnimation();
      cardComponent.animator.returnToHand();
      cardComponent.game.highlightEnemy(null);
      return;
    }

    EnemyCard? targetedEnemy;
    if (cardComponent.card.data.target == CardTarget.singleEnemy) {
      targetedEnemy = cardComponent.game.highlightedEnemy;
    }

    bool played = cardComponent.game.tryPlayCard(cardComponent, targetedEnemy);

    if (!played) {
      cardComponent.animator.returnToHand();
    }

    cardComponent.game.highlightEnemy(null);
  }

  void onDragCancel(DragCancelEvent event) {
    if (cardComponent.isPlayed) return;
    if (!cardComponent.isDragging) return;

    cardComponent.isDragging = false;
    cardComponent.targetTilt = 0;
    cardComponent.game.setFocusedCard(null);

    cardComponent.activeTrail?.stop();
    cardComponent.activeTrail = null;

    cardComponent.animator.returnToHand();
    cardComponent.game.highlightEnemy(null);
  }

  EnemyCard? findHoveredEnemy(Vector2 canvasPos) {
    for (var enemy in cardComponent.game.enemyCards) {
      if (enemy.containsPoint(canvasPos)) {
        return enemy;
      }
    }
    return null;
  }
}
