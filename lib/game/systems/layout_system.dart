import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' hide Image;
import '../heros_draft_game.dart';
import '../game_constants.dart';
import 'board_scale.dart';
import 'enemy_row.dart';
import 'hand_geometry.dart';

class LayoutSystem extends Component with HasGameReference<HerosDraftGame> {
  void layoutHand() {
    final handCards = game.handCards;
    if (handCards.isEmpty) return;

    final int count = handCards.length;
    final double radius = game.size.y * 1.5;

    final double angleStep = handAngleStep(
      count: count,
      availableWidth: game.size.x - 2 * GameConstants.handSideReserve,
      cardWidth: GameConstants.cardWidth * game.scaleFactor * 0.88,
      radius: radius,
    );

    final double totalAngle = (count - 1) * angleStep;
    final double startAngle = -totalAngle / 2;

    final Vector2 centerPoint = Vector2(
      game.size.x / 2,
      game.size.y + radius - (game.size.y * 0.23),
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

      final Vector2 targetPos;
      final double targetAngle = angle;
      final Vector2 targetScale;

      if (card == game.focusedCard) {
        targetPos = Vector2(x, y) + Vector2(0, -60);
        targetScale = Vector2.all(game.scaleFactor * 0.88 * 1.25);
      } else if (card == game.hoveredCard) {
        targetPos = Vector2(x, y);
        targetScale = Vector2.all(
          game.scaleFactor * 0.88 * GameConstants.cardHoverScale,
        );
      } else {
        targetPos = Vector2(x, y);
        targetScale = Vector2.all(game.scaleFactor * 0.88);
      }

      final double duration = card.isEnteringHand ? 0.7 : 0.35;

      card.removeAll(card.children.whereType<MoveEffect>());
      card.removeAll(card.children.whereType<RotateEffect>());
      card.removeAll(card.children.whereType<ScaleEffect>());

      card.add(
        MoveEffect.to(
          targetPos,
          EffectController(duration: duration, curve: Curves.easeOutCubic),
        ),
      );
      card.add(
        RotateEffect.to(
          targetAngle,
          EffectController(duration: duration, curve: Curves.easeOutCubic),
        ),
      );
      card.add(
        ScaleEffect.to(
          targetScale,
          EffectController(duration: duration, curve: Curves.easeOutCubic),
          onComplete: card.isEnteringHand ? () {
            card.isEnteringHand = false;
            // Arrivée en main, la carte devient survolable : le pointeur
            // immobile au-dessus d'elle doit la désigner sans bouger.
            game.refreshHover();
          } : null,
        ),
      );

      if (card != game.hoveredCard && card != game.focusedCard) {
        card.priority = card.basePriority;
      }
    }

    // Les places au repos viennent de changer sous un pointeur peut-être
    // immobile : l'arbitre du survol relit la main.
    game.refreshHover();
  }

  void repositionEnemies() {
    final enemyCards = game.enemyCards;
    if (enemyCards.isEmpty) {
      // Le dernier ennemi vient de partir : sa carte qui s'efface ne reste pas
      // survolée.
      game.refreshEntityHover();
      return;
    }

    // Le centre de chaque fenêtre, sur le pixel physique (spec P-05, vague 2,
    // §5.6) ; l'ancre de la carte est le centre de sa fenêtre.
    final ratio = game.devicePixelRatio;
    final centers = placeRow(
      slots: [for (final enemy in enemyCards) slotOf(enemy.frame)],
      unit: game.boardScale.frame,
      screenWidth: game.size.x,
      devicePixelRatio: ratio,
    );
    final rowY = enemyRowCenterYFor(
      game.size.y,
      scale: game.boardScale,
      devicePixelRatio: ratio,
    );

    for (int i = 0; i < enemyCards.length; i++) {
      enemyCards[i].place(Vector2(centers[i], rowY));
    }

    // Le plateau vient de changer sous un pointeur peut-être immobile :
    // l'arbitre du survol relit les cartes de combat.
    game.refreshEntityHover();
  }
}
