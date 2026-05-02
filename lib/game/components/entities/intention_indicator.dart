import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../models/enemy_intent.dart';

class IntentionIndicator extends PositionComponent with HasPaint {
  EnemyIntent? _intent;
  late final RectangleComponent _bg;
  late final TextComponent _iconText;
  late final TextComponent _valueText;

  IntentionIndicator() : super(size: Vector2(70, 30));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    _bg = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.black.withAlpha(200),
    );
    add(_bg);

    // Bordure pour l'indicateur
    _bg.add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.amber.withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    ));

    _iconText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 18),
      ),
      anchor: Anchor.centerLeft,
      position: Vector2(5, size.y / 2),
    );
    add(_iconText);

    _valueText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.centerRight,
      position: Vector2(size.x - 5, size.y / 2),
    );
    add(_valueText);
    
    _updateVisual();
  }

  void updateIntent(EnemyIntent? intent) {
    _intent = intent;
    if (isLoaded) {
      _updateVisual();
    }
  }

  void _updateVisual() {
    if (_intent == null) {
      isVisible = false;
      return;
    }

    isVisible = true;
    switch (_intent!.type) {
      case IntentType.attack:
        _iconText.text = 'ATK'; // Texte plus fiable que l'emoji
        _valueText.text = '${_intent!.value}';
        _valueText.textRenderer = TextPaint(style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14));
        _iconText.textRenderer = TextPaint(style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12));
        break;
      case IntentType.defend:
        _iconText.text = 'DEF';
        _valueText.text = '${_intent!.value}';
        _valueText.textRenderer = TextPaint(style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14));
        _iconText.textRenderer = TextPaint(style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12));
        break;
      case IntentType.buff:
        _iconText.text = 'BUF';
        _valueText.text = '+${_intent!.value}';
        _valueText.textRenderer = TextPaint(style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 14));
        _iconText.textRenderer = TextPaint(style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12));
        break;
    }
  }
}
