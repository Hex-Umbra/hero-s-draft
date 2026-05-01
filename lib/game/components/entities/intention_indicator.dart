import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../models/enemy_intent.dart';

class IntentionIndicator extends PositionComponent {
  EnemyIntent? _intent;
  late final RectangleComponent _bg;
  late final TextComponent _iconText;
  late final TextComponent _valueText;

  IntentionIndicator() : super(size: Vector2(60, 40));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    _bg = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.black.withAlpha(150),
    );
    add(_bg);

    _iconText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 20),
      ),
      anchor: Anchor.center,
      position: Vector2(15, size.y / 2),
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
      anchor: Anchor.center,
      position: Vector2(45, size.y / 2),
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
      _iconText.text = '';
      _valueText.text = '';
      _bg.opacity = 0;
      return;
    }

    _bg.opacity = 1;
    switch (_intent!.type) {
      case IntentType.attack:
        _iconText.text = '⚔️';
        _valueText.text = '${_intent!.value}';
        _valueText.textRenderer = TextPaint(style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold));
        break;
      case IntentType.defend:
        _iconText.text = '🛡️';
        _valueText.text = '${_intent!.value}';
        _valueText.textRenderer = TextPaint(style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold));
        break;
      case IntentType.buff:
        _iconText.text = '✨';
        _valueText.text = '+${_intent!.value}';
        _valueText.textRenderer = TextPaint(style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold));
        break;
    }
  }
}
