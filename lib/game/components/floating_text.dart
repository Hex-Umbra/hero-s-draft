import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class FloatingText extends TextComponent with HasPaint {
  final bool isCritical;
  final bool isUpward;
  final bool isPoison;
  final bool isShield;

  FloatingText({
    required String text,
    required Color color,
    required Vector2 position,
    this.isCritical = false,
    this.isUpward = true,
    this.isPoison = false,
    this.isShield = false,
  }) : super(
         text: text,
         position: position,
         anchor: Anchor.center,
         textRenderer: TextPaint(
           style: TextStyle(
             color: color,
             fontSize: isCritical ? 36 : (isPoison ? 22 : 26),
             fontWeight: FontWeight.bold,
             shadows: [
               Shadow(
                 color: Colors.black.withValues(alpha: 0.8),
                 offset: const Offset(2, 2),
                 blurRadius: 4,
               ),
               if (isCritical)
                 const Shadow(
                   color: Colors.orangeAccent,
                   offset: Offset.zero,
                   blurRadius: 8,
                 ),
               if (isPoison)
                 const Shadow(
                   color: Colors.greenAccent,
                   offset: Offset.zero,
                   blurRadius: 6,
                 ),
               if (isShield)
                 const Shadow(
                   color: Colors.cyanAccent,
                   offset: Offset.zero,
                   blurRadius: 6,
                 ),
             ],
           ),
         ),
       );

  @override
  void render(Canvas canvas) {
    // TextComponent ne supporte pas l'opacité nativement via OpacityEffect
    // sans utiliser un saveLayer ou modifier le textRenderer.
    // L'utilisation de saveLayer ici permet à l'OpacityEffect de fonctionner.
    if (opacity < 1) {
      canvas.saveLayer(size.toRect(), paint);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  @override
  Future<void> onLoad() async {
    final random = Random();

    // TODO: Audio Hook - sfx_ui_pop (Jouer un son de 'pop' lors de l'apparition du texte)

    // Initialisation de l'échelle pour l'effet "pop"
    scale = Vector2.all(0.1);

    // Trajectoire aléatoire en arc de cercle
    final double driftX = (random.nextDouble() - 0.5) * 80; // Entre -40 et 40
    double driftY =
        60 + random.nextDouble() * 40; // Base positive (vers le bas)

    if (isUpward) {
      driftY = -driftY; // Inverser pour aller vers le haut
    }

    // 1. Effet de Pop (Agrandissement rapide)
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.15, curve: Curves.bounceOut),
      ),
    );

    // 2. Mouvement (Drift)
    if (isPoison) {
      add(
        MoveEffect.by(
          Vector2(0, -90 - random.nextDouble() * 30),
          EffectController(duration: 1.2, curve: Curves.easeOutQuad),
        ),
      );
    } else if (isShield) {
      add(
        MoveEffect.by(
          Vector2(driftX * 0.5, -40 - random.nextDouble() * 20),
          EffectController(duration: 1.0, curve: Curves.easeOutQuad),
        ),
      );
    } else {
      add(
        MoveEffect.by(
          Vector2(driftX, driftY),
          EffectController(duration: 1.0, curve: Curves.easeOutCubic),
        ),
      );
    }

    // 3. Fondu (Fade out)
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 1.2, curve: Curves.easeIn),
      ),
    );

    if (isCritical) {
      add(
        ScaleEffect.by(
          Vector2.all(1.25),
          EffectController(duration: 0.2, alternate: true),
        ),
      );
    }

    add(RemoveEffect(delay: 1.2));
  }

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (isPoison) {
      _time += dt;
      // Add slight horizontal sin wave
      position.x += sin(_time * 10) * 0.8;
    }
  }
}
