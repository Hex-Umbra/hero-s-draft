import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../card_component.dart';

class CardRenderer {
  final CardComponent cardComponent;

  CardRenderer(this.cardComponent);

  void render(Canvas canvas) {
    final bool useSaveLayer = cardComponent.opacity < 1.0;
    if (useSaveLayer) {
      canvas.saveLayer(
        cardComponent.size.toRect(),
        Paint()..color = Colors.white.withValues(alpha: cardComponent.opacity),
      );
    }

    final rect = cardComponent.size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    final bgColor = cardComponent.getBackgroundColor();
    final rarityColor = cardComponent.getRarityColor();

    // Fond plein (non transparent)
    final Paint bgPaint = Paint();
    if (cardComponent.isFlashing) {
      bgPaint.color = Colors.white;
    } else {
      bgPaint.color = bgColor;
    }
    canvas.drawRRect(rrect, bgPaint);

    // Bordure fine
    final Paint bPaint = Paint()..style = PaintingStyle.stroke;

    final bool isHovered = cardComponent.game.hoveredCard == cardComponent;
    if (isHovered && !cardComponent.isFlashing) {
      bPaint.strokeWidth = 3.5;
      final colors = cardComponent.getRarityShineColors();
      final angle = cardComponent.foilTime;
      final cosVal = math.cos(angle);
      final sinVal = math.sin(angle);
      bPaint.shader = LinearGradient(
        begin: Alignment(cosVal, sinVal),
        end: Alignment(-cosVal, -sinVal),
        colors: colors,
      ).createShader(rect);
    } else {
      bPaint.strokeWidth = cardComponent.isSelected ? 2.5 : 1.5;
      if (cardComponent.isFlashing) {
        bPaint.color = Colors.white;
      } else {
        bPaint.color = cardComponent.isSelected
            ? Colors.white.withValues(alpha: 0.8)
            : rarityColor.withValues(alpha: 0.5);
      }
    }

    canvas.drawRRect(rrect, bPaint);

    // Halo de sélection (Glow)
    if (cardComponent.isSelected && !cardComponent.isFlashing) {
      final Paint glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = rarityColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
      canvas.drawRRect(rrect, glowPaint);
    }

    // Dessin manuel des textes délégué
    if (!cardComponent.isFlashing) {
      cardComponent.textRenderer.render(canvas, cardComponent.size);
    }

    cardComponent.superRender(canvas);

    if (useSaveLayer) {
      canvas.restore();
    }
  }
}
