import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../heros_draft_game.dart';

enum StatType { hp, armor, attack, mana }

class StatBadge extends PositionComponent with TapCallbacks, HasGameReference<HerosDraftGame> {
  final StatType type;
  String _value;
  String? _customTooltipTitle;
  String? _customTooltipDescription;
  
  late final RectangleComponent bg;
  late final TextComponent iconComponent;
  late final TextComponent textComponent;
  final double radius;

  StatBadge({
    required this.type,
    required String value,
    this.radius = 24.0,
    String? tooltipTitle,
    String? tooltipDescription,
  }) : _value = value, 
       _customTooltipTitle = tooltipTitle,
       _customTooltipDescription = tooltipDescription,
       super(size: Vector2(55, 30));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    
    Color bgColor;
    String iconText;
    switch (type) {
      case StatType.hp:
        bgColor = const Color(0xFFE74C3C);
        iconText = 'HP';
        break;
      case StatType.armor:
        bgColor = const Color(0xFF3498DB);
        iconText = 'ARM';
        break;
      case StatType.attack:
        bgColor = const Color(0xFFF39C12);
        iconText = 'ATK';
        break;
      case StatType.mana:
        bgColor = const Color(0xFF9B59B6);
        iconText = 'MP';
        break;
    }

    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.black.withAlpha(180),
    ));

    // Barre colorée sur le côté
    add(RectangleComponent(
      size: Vector2(4, size.y),
      paint: Paint()..color = bgColor,
      position: Vector2(0, 0),
    ));

    iconComponent = TextComponent(
      text: iconText,
      textRenderer: TextPaint(
        style: TextStyle(
          color: bgColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.centerLeft,
      position: Vector2(8, size.y / 2),
    );
    add(iconComponent);

    textComponent = TextComponent(
      text: _value,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.centerRight,
      position: Vector2(size.x - 6, size.y / 2),
    );
    add(textComponent);
  }

  void updateValue(String newValue, {Color? textColor, String? tooltipTitle, String? tooltipDescription}) {
    _value = newValue;
    if (isLoaded) {
      textComponent.text = newValue;
      if (textColor != null) {
        textComponent.textRenderer = TextPaint(
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }
    if (tooltipTitle != null) _customTooltipTitle = tooltipTitle;
    if (tooltipDescription != null) _customTooltipDescription = tooltipDescription;
  }

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
    if (_customTooltipTitle != null && _customTooltipDescription != null) {
      return (_customTooltipTitle!, _customTooltipDescription!);
    }

    switch (type) {
      case StatType.hp:
        return ('POINTS DE VIE', 'Santé actuelle de l\'entité. Si elle tombe à zéro, l\'entité est vaincue.');
      case StatType.armor:
        return ('ARMURE', 'Réduit les prochains dégâts reçus. L\'armure est consommée avant les PV.');
      case StatType.attack:
        return ('FORCE', 'Dégâts de base de l\'entité. Affecte la puissance des attaques.');
      case StatType.mana:
        return ('MANA', 'Énergie utilisée pour lancer des capacités spéciales.');
    }
  }
}
