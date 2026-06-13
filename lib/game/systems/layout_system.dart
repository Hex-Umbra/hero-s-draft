import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' hide Image;
import '../heros_draft_game.dart';

class LayoutSystem extends Component with HasGameReference<HerosDraftGame> {
  void layoutHand() {
    final handCards = game.handCards;
    if (handCards.isEmpty) return;

    final int count = handCards.length;
    final double radius = game.size.y * 1.5;

    double angleStep = 0.08;
    if (count > 4) {
      angleStep = (0.4 / count).clamp(0.04, 0.08);
    }

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
        targetScale = Vector2.all(game.scaleFactor * 0.88 * 1.2);
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
          } : null,
        ),
      );

      if (card != game.hoveredCard && card != game.focusedCard) {
        card.priority = card.basePriority;
      }
    }
  }

  void repositionEnemies() {
    final enemyCards = game.enemyCards;
    if (enemyCards.isEmpty) return;

    final int count = enemyCards.length;
    double scaleMultiplier = 1.0;

    final double visualWidthPerEnemy = (100.0 + 70.0) * game.scaleFactor * 1.45;

    double totalEstimatedWidth = count * visualWidthPerEnemy;
    final double maxAvailableWidth = game.size.x * 0.95;

    if (totalEstimatedWidth > maxAvailableWidth) {
      scaleMultiplier = (maxAvailableWidth / totalEstimatedWidth).clamp(0.4, 1.0);
    }

    for (var enemy in enemyCards) {
      enemy.scaleMultiplier = scaleMultiplier;
    }

    final double minSpacing = 165.0 * game.scaleFactor * 1.45 * scaleMultiplier;
    final double maxSpacing = 280.0 * game.scaleFactor * 1.45 * scaleMultiplier;

    double spacing = (game.size.x * 0.85) / (count + 1);
    spacing = spacing.clamp(minSpacing, maxSpacing);

    double startX = (game.size.x / 2) - ((count - 1) * (spacing / 2));
    double posY = game.size.y * 0.21;

    for (int i = 0; i < count; i++) {
      enemyCards[i].position = Vector2(startX + (i * spacing), posY);
    }
  }
}
