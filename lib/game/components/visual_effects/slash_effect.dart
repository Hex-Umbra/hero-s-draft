import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class SlashEffect extends PositionComponent with HasPaint {
  final Color color;
  final double thickness;

  SlashEffect({
    required Vector2 position,
    required Vector2 size,
    this.color = Colors.red,
    this.thickness = 8.0,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // On commence invisible et petit
    scale = Vector2(0, 1);
    opacity = 0;

    add(
      SequenceEffect([
        // 1. Apparition rapide et étirement
        CombinedEffect([
          ScaleEffect.to(
            Vector2(1.2, 1),
            EffectController(duration: 0.1, curve: Curves.easeOut),
          ),
          OpacityEffect.to(1.0, EffectController(duration: 0.05)),
        ]),
        // 2. Disparition
        CombinedEffect([
          ScaleEffect.to(
            Vector2(1.5, 0),
            EffectController(duration: 0.2, curve: Curves.easeIn),
          ),
          OpacityEffect.to(0.0, EffectController(duration: 0.2)),
        ]),
        RemoveEffect(),
      ]),
    );
  }

  @override
  void render(Canvas canvas) {
    final mainPaint = Paint()
      ..color = color.withAlpha((opacity * 255).toInt())
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withAlpha((opacity * 100).toInt())
      ..strokeWidth = thickness * 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 1. Dessiner le Glow
    canvas.drawLine(Offset(0, 0), Offset(size.x, size.y), glowPaint);

    // 2. Dessiner le trait principal
    canvas.drawLine(Offset(0, 0), Offset(size.x, size.y), mainPaint);

    // 3. Ajouter un trait blanc central pour l'effet de tranchant (plus fin)
    final sharpPaint = Paint()
      ..color = Colors.white.withAlpha((opacity * 200).toInt())
      ..strokeWidth = thickness * 0.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.x * 0.1, size.y * 0.1),
      Offset(size.x * 0.9, size.y * 0.9),
      sharpPaint,
    );
  }
}
