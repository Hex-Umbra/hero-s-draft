import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../heros_draft_game.dart';

enum StatType { hp, armor, attack, mana }

class StatBadge extends PositionComponent with TapCallbacks, HasGameReference<HerosDraftGame> {
  final StatType type;
  final bool isCircle;
  String _value;
  double _fillPercentage;
  String? _customTooltipTitle;
  String? _customTooltipDescription;
  
  late TextComponent iconComponent;
  late TextComponent textComponent;

  StatBadge({
    required this.type,
    required String value,
    this.isCircle = false,
    double fillPercentage = 1.0,
    String? tooltipTitle,
    String? tooltipDescription,
  }) : _value = value, 
       _fillPercentage = fillPercentage,
       _customTooltipTitle = tooltipTitle,
       _customTooltipDescription = tooltipDescription,
       super(size: isCircle ? Vector2.all(36) : Vector2(48, 22));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    _updateVisuals();
  }

  void _updateVisuals() {
    removeAll(children);

    Color color;
    String iconText;
    switch (type) {
      case StatType.hp:
        color = const Color(0xFFE74C3C);
        iconText = 'HP';
        break;
      case StatType.armor:
        color = const Color(0xFF3498DB);
        iconText = 'ARM';
        break;
      case StatType.attack:
        color = const Color(0xFFF39C12);
        iconText = 'ATK';
        break;
      case StatType.mana:
        color = const Color(0xFF9B59B6);
        iconText = 'MP';
        break;
    }

    if (isCircle) {
      // Background noir
      add(CircleComponent(
        radius: size.x / 2,
        paint: Paint()..color = Colors.black.withAlpha(220),
      ));

      // Arc de cercle pour les HP (décrémente)
      add(CircleProgressComponent(
        radius: size.x / 2,
        percentage: _fillPercentage,
        color: color,
      ));

      // Bordure
      add(CircleComponent(
        radius: size.x / 2,
        paint: Paint()
          ..color = Colors.white.withAlpha(100)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      ));

      textComponent = TextComponent(
        text: _value.split('/').first, // Pour le cercle on ne garde que le PV actuel
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        anchor: Anchor.center,
        position: size / 2,
      );
      add(textComponent);
    } else {
      // Layout rectangulaire pour les autres badges
      add(RectangleComponent(
        size: size,
        paint: Paint()..color = Colors.black.withAlpha(200),
      ));

      add(RectangleComponent(
        size: Vector2(3, size.y),
        paint: Paint()..color = color,
      ));

      iconComponent = TextComponent(
        text: iconText,
        textRenderer: TextPaint(
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        anchor: Anchor.centerLeft,
        position: Vector2(6, size.y / 2),
      );
      add(iconComponent);

      textComponent = TextComponent(
        text: _value,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        anchor: Anchor.centerRight,
        position: Vector2(size.x - 4, size.y / 2),
      );
      add(textComponent);
    }
  }

  void updateValue(String newValue, {double? fillPercentage, Color? textColor, String? tooltipTitle, String? tooltipDescription}) {
    _value = newValue;
    if (fillPercentage != null) _fillPercentage = fillPercentage;
    if (tooltipTitle != null) _customTooltipTitle = tooltipTitle;
    if (tooltipDescription != null) _customTooltipDescription = tooltipDescription;

    if (isLoaded) {
      if (isCircle) {
        _updateVisuals(); // On reconstruit pour mettre à jour l'arc
      } else {
        textComponent.text = newValue;
        if (textColor != null) {
          textComponent.textRenderer = TextPaint(
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          );
        }
      }
    }
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

class CircleProgressComponent extends PositionComponent {
  final double radius;
  final double percentage;
  final Color color;

  CircleProgressComponent({
    required this.radius,
    required this.percentage,
    required this.color,
  }) : super(size: Vector2.all(radius * 2));

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Dessine un arc de cercle à partir du haut (-pi/2)
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.x, size.y),
      -1.5708, // -90 degrés
      6.28319 * percentage, // 360 degrés * pourcentage
      true,
      paint,
    );
  }
}
