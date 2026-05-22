import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../models/enemy_intent.dart';
import '../../../l10n/app_localizations.dart';
import '../../heros_draft_game.dart';

class IntentionIndicator extends PositionComponent
    with HasPaint, HasGameReference<HerosDraftGame> {
  EnemyIntent? _intent;
  late final RectangleComponent _bg;
  late final TextComponent _label;
  late final TextComponent _iconText;
  late final TextComponent _valueText;

  IntentionIndicator({EnemyIntent? initialIntent})
    : _intent = initialIntent,
      super(size: Vector2(74, 34));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    _bg = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.black.withAlpha(220),
    );
    add(_bg);

    // Bordure plus fine et discrète
    _bg.add(
      RectangleComponent(
        size: size,
        paint: Paint()
          ..color = Colors.amber.withAlpha(180)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      ),
    );

    // Label "Next action" plus petit
    final l10n = AppLocalizations.of(game.buildContext!)!;
    _label = TextComponent(
      text: '${l10n.nextAction} :',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.amberAccent,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 2),
    );
    add(_label);

    _iconText = TextComponent(
      text: '',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 10)),
      anchor: Anchor.centerLeft,
      position: Vector2(8, size.y / 2 + 6),
    );
    add(_iconText);

    _valueText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.centerRight,
      position: Vector2(size.x - 8, size.y / 2 + 6),
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

  @override
  void renderTree(Canvas canvas) {
    // Ne plus dessiner l'ancien rectangle par-dessus la carte en combat
    // Tout est maintenant géré par le panneau HUD réactif en bas à droite
  }

  void _updateVisual() {
    if (_intent == null) {
      return;
    }

    switch (_intent!.type) {
      case IntentType.attack:
        _iconText.text = 'ATK';
        _valueText.text = '${_intent!.value}';
        _valueText.textRenderer = TextPaint(
          style: const TextStyle(
            color: Color(0xFFFF5252),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        );
        _iconText.textRenderer = TextPaint(
          style: const TextStyle(
            color: Color(0xFFFF5252),
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        );
        break;
      case IntentType.defend:
        _iconText.text = 'DEF';
        _valueText.text = '${_intent!.value}';
        _valueText.textRenderer = TextPaint(
          style: const TextStyle(
            color: Color(0xFF448AFF),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        );
        _iconText.textRenderer = TextPaint(
          style: const TextStyle(
            color: Color(0xFF448AFF),
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        );
        break;
      case IntentType.buff:
        _iconText.text = 'BUF';
        _valueText.text = '+${_intent!.value}';
        _valueText.textRenderer = TextPaint(
          style: const TextStyle(
            color: Color(0xFFE040FB),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        );
        _iconText.textRenderer = TextPaint(
          style: const TextStyle(
            color: Color(0xFFE040FB),
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        );
        break;
      case IntentType.debuffDeck:
        _iconText.text = 'CUR';
        _valueText.text = '${_intent!.value}';
        _valueText.textRenderer = TextPaint(
          style: const TextStyle(
            color: Color(0xFF69F0AE),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        );
        _iconText.textRenderer = TextPaint(
          style: const TextStyle(
            color: Color(0xFF69F0AE),
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        );
        break;
    }
  }
}
