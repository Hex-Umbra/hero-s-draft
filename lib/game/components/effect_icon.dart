import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class EffectIcon extends TextComponent with HasPaint {
  final String iconType;

  EffectIcon({required this.iconType, required Vector2 position})
    : super(
        text: _getEmojiForType(iconType),
        position: position,
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 32,
            shadows: [
              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
      );

  static String _getEmojiForType(String type) {
    if (type == 'defend') return '🛡️';
    if (type == 'buff' ||
        type == 'armor_buff' ||
        type == 'attack_buff' ||
        type == 'lifesteal_buff') {
      return '✨';
    }
    return '';
  }

  @override
  Future<void> onLoad() async {
    // Animation combinée : Flotte vers le haut, gonfle puis disparaît en fondu
    add(
      MoveEffect.by(
        Vector2(0, -60),
        EffectController(duration: 1.0, curve: Curves.easeOut),
      ),
    );

    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 1.0, curve: Curves.easeIn),
      ),
    );

    add(
      ScaleEffect.by(
        Vector2.all(1.5),
        EffectController(duration: 0.2, alternate: true),
      ),
    );

    add(RemoveEffect(delay: 1.0));
  }

  @override
  void render(Canvas canvas) {
    if (opacity < 1) {
      canvas.saveLayer(size.toRect(), paint);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }
}
