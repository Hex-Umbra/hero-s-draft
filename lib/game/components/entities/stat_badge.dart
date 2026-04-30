import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum StatType { hp, armor, attack, mana }

class StatBadge extends PositionComponent {
  final StatType type;
  String _value;
  late final CircleComponent bg;
  late final TextComponent textComponent;
  final double radius;

  StatBadge({
    required this.type,
    required String value,
    this.radius = 22.0,
  }) : _value = value, super(size: Vector2.all(radius * 2));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    
    Color bgColor;
    Color strokeColor = Colors.white;
    switch (type) {
      case StatType.hp:
        bgColor = const Color(0xFFC0392B); // Dark Red
        break;
      case StatType.armor:
        bgColor = const Color(0xFF2980B9); // Blue
        break;
      case StatType.attack:
        bgColor = const Color(0xFFD35400); // Orange
        break;
      case StatType.mana:
        bgColor = const Color(0xFF8E44AD); // Purple
        break;
    }

    add(CircleComponent(
      radius: radius,
      paint: Paint()..color = bgColor,
    ));

    add(CircleComponent(
      radius: radius,
      paint: Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));

    textComponent = TextComponent(
      text: _value,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2.all(radius),
    );
    add(textComponent);
  }

  void updateValue(String newValue, {Color? textColor}) {
    _value = newValue;
    textComponent.text = newValue;
    if (textColor != null) {
      textComponent.textRenderer = TextPaint(
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      textComponent.textRenderer = TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }
}
