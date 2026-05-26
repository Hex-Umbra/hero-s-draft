import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../heros_draft_game.dart';
import '../widgets/circle_progress.dart';
import '../widgets/flame_shield_icon.dart';
import '../widgets/flame_sword_icon.dart';
import '../widgets/linear_progress_bar.dart';

enum StatType { hp, armor, attack, mana }

class StatBadge extends PositionComponent
    with TapCallbacks, HasGameReference<HerosDraftGame> {
  final StatType type;
  final bool isCircle;
  String _value;
  int? _baseValue;
  int? _bonusValue;
  double _fillPercentage;
  int _attackValue;
  int _armorValue;
  double _armorPercentage;
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
    int attackValue = 0,
    int armorValue = 0,
    double armorPercentage = 0.0,
    String? tooltipTitle,
    String? tooltipDescription,
  }) : _value = value,
       _baseValue = baseValue,
       _bonusValue = bonusValue,
       _fillPercentage = fillPercentage,
       _attackValue = attackValue,
       _armorValue = armorValue,
       _armorPercentage = armorPercentage,
       _customTooltipTitle = tooltipTitle,
       _customTooltipDescription = tooltipDescription,
       super(size: isCircle ? Vector2.all(36) : (type == StatType.hp ? Vector2(130, 16) : Vector2(48, 22)));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    _updateVisuals();
  }

  void _updateVisuals() {
    removeAll(children);

    if (type == StatType.hp && !isCircle) {
      size = Vector2(130, 16);

      // 1. Dessine l'Attaque : Épée custom dessinée en rouge + Valeur
      add(
        FlameSwordIcon(
          position: Vector2(0, size.y / 2),
          size: Vector2(10, 10),
          color: const Color(0xFFFF3B30),
          anchor: Anchor.centerLeft,
        ),
      );
      add(
        TextComponent(
          text: '$_attackValue',
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFFFF5252),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 2.0, offset: Offset(1, 1)),
              ],
            ),
          ),
          anchor: Anchor.centerLeft,
          position: Vector2(11, size.y / 2),
        ),
      );

      // 2. Dessine l'Armure : Bouclier vectoriel premium dessiné en bleu/cyan + Valeur
      add(
        FlameShieldIcon(
          position: Vector2(28, size.y / 2),
          size: Vector2(10, 10),
          color: const Color(0xFF2196F3),
          anchor: Anchor.centerLeft,
        ),
      );
      add(
        TextComponent(
          text: '$_armorValue',
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 2.0, offset: Offset(1, 1)),
              ],
            ),
          ),
          anchor: Anchor.centerLeft,
          position: Vector2(39, size.y / 2),
        ),
      );

      // 3. Dessine la Barre de vie progressive avec l'armure superposée
      final pb = LinearProgressBarComponent(
        size: Vector2(66, 13),
        percentage: _fillPercentage,
        armorPercentage: _armorPercentage,
        borderRadius: 4.0,
      );
      pb.position = Vector2(64, 1.5);
      add(pb);

      textComponent = TextComponent(
        text: _value,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black54,
                offset: Offset(0.5, 0.5),
                blurRadius: 1.0,
              ),
            ],
          ),
        ),
        anchor: Anchor.center,
        position: Vector2(97, size.y / 2),
      );
      add(textComponent);
      return;
    }

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
      add(
        CircleComponent(
          radius: size.x / 2,
          paint: Paint()..color = Colors.black.withAlpha(220),
        ),
      );

      add(
        CircleProgressComponent(
          radius: size.x / 2,
          percentage: _fillPercentage,
          color: color,
        ),
      );

      add(
        CircleComponent(
          radius: size.x / 2,
          paint: Paint()
            ..color = Colors.white.withAlpha(100)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        ),
      );

      textComponent = TextComponent(
        text: _value.split('/').first,
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
      // Ajuste la largeur si bonus présent
      final bool hasBonus = _bonusValue != null && _bonusValue! > 0;
      if (hasBonus) {
        size.x = 90; // Élargit pour le format "Total (Base + Bonus)"
      } else {
        size.x = 48;
      }

      add(
        RectangleComponent(
          size: size,
          paint: Paint()..color = Colors.black.withAlpha(200),
        ),
      );

      add(
        RectangleComponent(
          size: Vector2(3, size.y),
          paint: Paint()..color = color,
        ),
      );

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

      if (hasBonus) {
        // Affichage complexe : Total (Base + Bonus) avec mesure dynamique pour un alignement parfait
        final totalStyle = const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        );
        final normalStyle = const TextStyle(color: Colors.white70, fontSize: 8);
        final bonusStyle = const TextStyle(
          color: Colors.orangeAccent,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        );

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

        // On commence après l'icône (environ x=20) et on centre dans l'espace restant
        double currentX = 20 + (size.x - 20 - fullW) / 2;

        add(
          TextComponent(
            text: _value,
            textRenderer: TextPaint(style: totalStyle),
            anchor: Anchor.centerLeft,
            position: Vector2(currentX, size.y / 2),
          ),
        );
        currentX += totalW;

        add(
          TextComponent(
            text: part1,
            textRenderer: TextPaint(style: normalStyle),
            anchor: Anchor.centerLeft,
            position: Vector2(currentX, size.y / 2),
          ),
        );
        currentX += p1W;

        add(
          TextComponent(
            text: part2,
            textRenderer: TextPaint(style: bonusStyle),
            anchor: Anchor.centerLeft,
            position: Vector2(currentX, size.y / 2),
          ),
        );
        currentX += p2W;

        add(
          TextComponent(
            text: part3,
            textRenderer: TextPaint(style: normalStyle),
            anchor: Anchor.centerLeft,
            position: Vector2(currentX, size.y / 2),
          ),
        );
      } else {
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
  }

  void updateValue(
    String newValue, {
    int? baseValue,
    int? bonusValue,
    double? fillPercentage,
    Color? textColor,
    String? tooltipTitle,
    String? tooltipDescription,
  }) {
    _value = newValue;
    _baseValue = baseValue;
    _bonusValue = bonusValue;
    if (fillPercentage != null) _fillPercentage = fillPercentage;
    if (tooltipTitle != null) _customTooltipTitle = tooltipTitle;
    if (tooltipDescription != null) {
      _customTooltipDescription = tooltipDescription;
    }

    if (isLoaded) {
      _updateVisuals(); // On reconstruit car le layout peut changer (largeur)
    }
  }

  void updateHpValues(
    String hpValue,
    double fillPercentage,
    int attackValue,
    int armorValue, {
    double? armorPercentage,
    String? tooltipTitle,
    String? tooltipDescription,
  }) {
    _value = hpValue;
    _fillPercentage = fillPercentage;
    _attackValue = attackValue;
    _armorValue = armorValue;
    if (armorPercentage != null) _armorPercentage = armorPercentage;
    if (tooltipTitle != null) _customTooltipTitle = tooltipTitle;
    if (tooltipDescription != null) {
      _customTooltipDescription = tooltipDescription;
    }

    if (isLoaded) {
      _updateVisuals();
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
        return (
          'POINTS DE VIE',
          'Santé actuelle de l\'entité. Si elle tombe à zéro, l\'entité est vaincue.',
        );
      case StatType.armor:
        return (
          'ARMURE',
          'Réduit les prochains dégâts reçus. L\'armure est consommée avant les PV.',
        );
      case StatType.attack:
        return (
          'ATTAQUE',
          'Dégâts de base de l\'entité. Affecte la puissance des attaques.',
        );
      case StatType.mana:
        return (
          'MANA',
          'Énergie utilisée pour lancer des capacités spéciales.',
        );
    }
  }
}
