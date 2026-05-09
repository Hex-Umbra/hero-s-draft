import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../heros_draft_game.dart';

enum StatType { hp, armor, attack, mana }

class StatBadge extends PositionComponent with TapCallbacks, HasGameReference<HerosDraftGame> {
  final StatType type;
  final bool isCircle;
  String _value;
  int? _baseValue;
  int? _bonusValue;
  double _fillPercentage;
  String? _customTooltipTitle;
  String? _customTooltipDescription;
  
  late TextComponent iconComponent;
  late TextComponent textComponent;

  StatBadge({
    required this.type,
    required String value,
    int? baseValue,
    int? bonusValue,
    this.isCircle = false,
    double fillPercentage = 1.0,
    String? tooltipTitle,
    String? tooltipDescription,
  }) : _value = value, 
       _baseValue = baseValue,
       _bonusValue = bonusValue,
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
      // ... (Circle logic remains same, but we could use it for Hero HP too if requested)
      add(CircleComponent(
        radius: size.x / 2,
        paint: Paint()..color = Colors.black.withAlpha(220),
      ));

      add(CircleProgressComponent(
        radius: size.x / 2,
        percentage: _fillPercentage,
        color: color,
      ));

      add(CircleComponent(
        radius: size.x / 2,
        paint: Paint()
          ..color = Colors.white.withAlpha(100)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      ));

      textComponent = TextComponent(
        text: _value.split('/').first,
        textRenderer: TextPaint(
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        anchor: Anchor.center,
        position: size / 2,
      );
      add(textComponent);
    } else {
      // Ajuste la largeur si bonus présent
      final bool hasBonus = _bonusValue != null && _bonusValue! > 0;
      if (hasBonus) {
        size.x = 90; // Élargit pour le format "Total (Base + Bonus)"
      } else {
        size.x = 48;
      }

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
          style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        anchor: Anchor.centerLeft,
        position: Vector2(6, size.y / 2),
      );
      add(iconComponent);

      if (hasBonus) {
        // Affichage complexe : Total (Base + Bonus) avec mesure dynamique pour un alignement parfait
        final totalStyle = const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold);
        final normalStyle = const TextStyle(color: Colors.white70, fontSize: 8);
        final bonusStyle = const TextStyle(color: Colors.orangeAccent, fontSize: 8, fontWeight: FontWeight.bold);
        
        final String part1 = ' ($_baseValue+';
        final String part2 = '$_bonusValue';
        final String part3 = ')';

        double measure(String text, TextStyle style) {
          final tp = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.ltr,
          )..layout();
          return tp.width;
        }

        final double totalW = measure(_value, totalStyle);
        final double p1W = measure(part1, normalStyle);
        final double p2W = measure(part2, bonusStyle);
        final double p3W = measure(part3, normalStyle);
        
        final double fullW = totalW + p1W + p2W + p3W;
        
        // On commence aprÃ¨s l'icÃ´ne (environ x=20) et on centre dans l'espace restant
        double currentX = 20 + (size.x - 20 - fullW) / 2;
        
        add(TextComponent(
          text: _value,
          textRenderer: TextPaint(style: totalStyle),
          anchor: Anchor.centerLeft,
          position: Vector2(currentX, size.y / 2),
        ));
        currentX += totalW;

        add(TextComponent(
          text: part1,
          textRenderer: TextPaint(style: normalStyle),
          anchor: Anchor.centerLeft,
          position: Vector2(currentX, size.y / 2),
        ));
        currentX += p1W;

        add(TextComponent(
          text: part2,
          textRenderer: TextPaint(style: bonusStyle),
          anchor: Anchor.centerLeft,
          position: Vector2(currentX, size.y / 2),
        ));
        currentX += p2W;

        add(TextComponent(
          text: part3,
          textRenderer: TextPaint(style: normalStyle),
          anchor: Anchor.centerLeft,
          position: Vector2(currentX, size.y / 2),
        ));
      } else {
        textComponent = TextComponent(
          text: _value,
          textRenderer: TextPaint(
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          anchor: Anchor.centerRight,
          position: Vector2(size.x - 4, size.y / 2),
        );
        add(textComponent);
      }
    }
  }

  void updateValue(String newValue, {int? baseValue, int? bonusValue, double? fillPercentage, Color? textColor, String? tooltipTitle, String? tooltipDescription}) {
    _value = newValue;
    _baseValue = baseValue;
    _bonusValue = bonusValue;
    if (fillPercentage != null) _fillPercentage = fillPercentage;
    if (tooltipTitle != null) _customTooltipTitle = tooltipTitle;
    if (tooltipDescription != null) _customTooltipDescription = tooltipDescription;

    if (isLoaded) {
      _updateVisuals(); // On reconstruit car le layout peut changer (largeur)
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
