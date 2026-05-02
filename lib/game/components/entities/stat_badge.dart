import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../heros_draft_game.dart';

enum StatType { hp, armor, attack, mana }

class StatBadge extends PositionComponent with TapCallbacks, HasGameReference<HerosDraftGame> {
  final StatType type;
  // ...
  @override
  void onLongTapDown(TapDownEvent event) {
    final tooltipData = _getTooltipData();
    game.onShowTooltip(tooltipData.$1, tooltipData.$2);
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.onHideTooltip();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    game.onHideTooltip();
  }

  (String, String) _getTooltipData() {
    switch (type) {
      case StatType.hp:
        return ('POINTS DE VIE', 'Votre santé actuelle. Si elle tombe à zéro, la partie est terminée.');
      case StatType.armor:
        return ('ARMURE', 'Réduit les prochains dégâts reçus. L\'armure est consommée avant les PV.');
      case StatType.attack:
        return ('FORCE', 'Augmente les dégâts infligés par vos cartes d\'attaque.');
      case StatType.mana:
        return ('MANA', 'Énergie utilisée pour jouer des cartes. Se régénère à chaque tour.');
    }
  }
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
