import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LinearProgressBarComponent extends PositionComponent {
  double percentage;
  double armorPercentage;
  final double borderRadius;

  LinearProgressBarComponent({
    required Vector2 size,
    required this.percentage,
    this.armorPercentage = 0.0,
    this.borderRadius = 4.0,
  }) : super(size: size);

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1. Dessine l'arrière-plan sombre
    final bgPaint = Paint()..color = Colors.black.withAlpha(200);
    canvas.drawRRect(rrect, bgPaint);

    if (percentage > 0) {
      canvas.save();
      canvas.clipRRect(rrect);

      // 2. Dessine le remplissage de PV avec gradient (Rouge) doté d'un padding pour loger à l'intérieur
      final double pvVertPad = 2.0;
      final double pvHorizPad = 1.5;
      final fillRect = Rect.fromLTWH(
        pvHorizPad,
        pvVertPad,
        (size.x * percentage.clamp(0.0, 1.0)) - (pvHorizPad * 2),
        size.y - (pvVertPad * 2),
      );
      final pvRRect = RRect.fromRectAndRadius(
        fillRect,
        const Radius.circular(2.0),
      );

      final fillPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF8B0000), // Rouge foncé
            Color(0xFFE74C3C), // Rouge vif
            Color(0xFFFF7675), // Rouge clair / corail
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(fillRect);

      canvas.drawRRect(pvRRect, fillPaint);
      canvas.restore();
    }

    if (armorPercentage > 0) {
      canvas.save();
      canvas.clipRRect(rrect);

      // 3. Dessine l'armure superposée qui englobe la barre de vie (presque pleine hauteur)
      final double vertPad = 0.5;
      final double horizPad = 0.5;
      final double drawWidth =
          (size.x * armorPercentage.clamp(0.0, 1.0)) - (horizPad * 2);

      if (drawWidth > 0) {
        final armorRect = Rect.fromLTWH(
          horizPad,
          vertPad,
          drawWidth,
          size.y - (vertPad * 2),
        );
        final armorRRect = RRect.fromRectAndRadius(
          armorRect,
          const Radius.circular(3.5),
        );

        final armorPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.blueAccent.withValues(alpha: 0.45),
              Colors.lightBlueAccent.withValues(alpha: 0.65),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(armorRect);

        canvas.drawRRect(armorRRect, armorPaint);

        // Petite bordure bleu clair brillante sur la capsule d'armure qui englobe
        final armorBorderPaint = Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawRRect(armorRRect, armorBorderPaint);
      }
      canvas.restore();
    }

    // 4. Dessine la bordure blanche translucide
    final borderPaint = Paint()
      ..color = Colors.white.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);
  }
}
