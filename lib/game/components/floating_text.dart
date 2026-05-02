import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class FloatingText extends TextComponent {
  final bool isCritical;

  FloatingText({
    required String text,
    required Color color,
    required Vector2 position,
    this.isCritical = false,
  }) : super(
         text: text,
         position: position,
         anchor: Anchor.center,
         textRenderer: TextPaint(
           style: TextStyle(
             color: color,
             fontSize: isCritical ? 32 : 24,
             fontWeight: FontWeight.bold,
             shadows: const [
               Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
             ],
           ),
         ),
       );

  @override
  Future<void> onLoad() async {
    final random = Random();
    
    // Trajectoire aléatoire en arc de cercle
    final double driftX = (random.nextDouble() - 0.5) * 80; // Entre -40 et 40
    final double driftY = -60 - random.nextDouble() * 40;   // Entre -60 et -100

    add(
      MoveEffect.by(
        Vector2(driftX, driftY),
        EffectController(duration: 1.0, curve: Curves.easeOut),
      ),
    );

    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 1.0, curve: Curves.easeIn),
      ),
    );

    if (isCritical) {
      add(
        ScaleEffect.by(
          Vector2.all(1.2),
          EffectController(duration: 0.2, alternate: true),
        ),
      );
    }

    add(RemoveEffect(delay: 1.0));
  }
}
