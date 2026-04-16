import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class FloatingText extends TextComponent {
  final Vector2 movement;

  FloatingText({
    required String text,
    required Color color,
    required Vector2 position,
    Vector2? movement,
  }) : movement = movement ?? Vector2(0, -50),
       super(
         text: text,
         position: position,
         anchor: Anchor.center,
         textRenderer: TextPaint(
           style: TextStyle(
             color: color,
             fontSize: 24,
             fontWeight: FontWeight.bold,
             shadows: const [
               Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
             ],
           ),
         ),
       );

  @override
  Future<void> onLoad() async {
    add(MoveEffect.by(movement, EffectController(duration: 1.0)));
    add(RemoveEffect(delay: 1.0));
  }
}
