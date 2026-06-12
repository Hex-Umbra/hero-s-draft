import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../heros_draft_game.dart';
import '../../game_constants.dart';
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

  // Cached Flame sub-components for incremental in-place updates
  TextComponent? iconComponent;
  TextComponent? textComponent;
  TextComponent? _attackTextComponent;
  TextComponent? _armorTextComponent;
  LinearProgressBarComponent? _progressBarComponent;
  CircleProgressComponent? _circleProgressComponent;

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
       super(
         size: isCircle
             ? GameConstants.badgeCircleSize
             : (type == StatType.hp
                   ? GameConstants.badgeHpSize
                   : GameConstants.badgeStandardSize),
       );

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    _initVisuals();
  }

  /// Initialise l'ensemble des composants une seule fois lors du chargement
  void _initVisuals() {
    removeAll(children);

    if (type == StatType.hp && !isCircle) {
      size = GameConstants.badgeHpSize;

      // 1. Dessine l'Attaque : Épée + Valeur
      add(
        FlameSwordIcon(
          position: Vector2(0, size.y / 2),
          size: Vector2(10, 10),
          color: const Color(0xFFFF3B30),
          anchor: Anchor.centerLeft,
        ),
      );
      _attackTextComponent = TextComponent(
        text: '$_attackValue',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFFFF5252),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 2.0,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        anchor: Anchor.centerLeft,
        position: Vector2(11, size.y / 2),
      );
      add(_attackTextComponent!);

      // 2. Dessine l'Armure : Bouclier + Valeur
      add(
        FlameShieldIcon(
          position: Vector2(28, size.y / 2),
          size: Vector2(10, 10),
          color: const Color(0xFF2196F3),
          anchor: Anchor.centerLeft,
        ),
      );
      _armorTextComponent = TextComponent(
        text: '$_armorValue',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 2.0,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
        anchor: Anchor.centerLeft,
        position: Vector2(39, size.y / 2),
      );
      add(_armorTextComponent!);

      // 3. Dessine la Barre de vie progressive avec l'armure superposée
      _progressBarComponent = LinearProgressBarComponent(
        size: Vector2(66, 13),
        percentage: _fillPercentage,
        armorPercentage: _armorPercentage,
        borderRadius: 4.0,
      );
      _progressBarComponent!.position = Vector2(64, 1.5);
      add(_progressBarComponent!);

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
      add(textComponent!);
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

      _circleProgressComponent = CircleProgressComponent(
        radius: size.x / 2,
        percentage: _fillPercentage,
        color: color,
      );
      add(_circleProgressComponent!);

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
      add(textComponent!);
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
      add(iconComponent!);

      _rebuildStaticBadgeContent(hasBonus, color);
    }
  }

  /// Reconstruit la section de texte dynamique (utilisée pour les badges rectangulaires simples/bonus)
  void _rebuildStaticBadgeContent(bool hasBonus, Color color) {
    // Nettoie les TextComponents de valeur précédents pour éviter les doublons
    children
        .whereType<TextComponent>()
        .where((tc) => tc != iconComponent)
        .toList()
        .forEach(remove);

    if (hasBonus) {
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
      add(textComponent!);
    }
  }

  /// Met à jour la valeur et la progression de manière incrémentale en place
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
      if (isCircle) {
        if (_circleProgressComponent != null) {
          _circleProgressComponent!.percentage = _fillPercentage;
        }
        if (textComponent != null) {
          textComponent!.text = _value.split('/').first;
        }
      } else if (type != StatType.hp) {
        final bool hasBonus = _bonusValue != null && _bonusValue! > 0;
        final double targetWidth = hasBonus ? 90.0 : 48.0;

        // Si le layout ou la largeur change (ex: bonus apparu/disparu), on réinitialise
        if (size.x != targetWidth) {
          _initVisuals();
        } else {
          // Sinon, on effectue une simple mise à jour en place des TextComponents de valeur
          Color color;
          switch (type) {
            case StatType.hp:
              color = const Color(0xFFE74C3C);
              break;
            case StatType.armor:
              color = const Color(0xFF3498DB);
              break;
            case StatType.attack:
              color = const Color(0xFFF39C12);
              break;
            case StatType.mana:
              color = const Color(0xFF9B59B6);
              break;
          }
          _rebuildStaticBadgeContent(hasBonus, color);
        }
      } else {
        // Fallback HP horizontal
        _initVisuals();
      }
    }
  }

  /// Met à jour les valeurs complexes d'HP de manière 100% incrémentale (en place)
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
      // Optimisation absolue : mise à jour des valeurs existantes sans remove ni reconstruction !
      if (_attackTextComponent != null) {
        _attackTextComponent!.text = '$_attackValue';
      }
      if (_armorTextComponent != null) {
        _armorTextComponent!.text = '$_armorValue';
      }
      if (_progressBarComponent != null) {
        _progressBarComponent!.percentage = _fillPercentage;
        _progressBarComponent!.armorPercentage = _armorPercentage;
      }
      if (textComponent != null) {
        textComponent!.text = _value;
      }
    }
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    final tooltipData = _getTooltipData();
    game.onShowTooltip(tooltipData.$1, tooltipData.$2, null);
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.onHideTooltip();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    game.onHideTooltip();
  }

  String get activeLocale {
    final context = game.buildContext;
    if (context != null) {
      return Localizations.localeOf(context).languageCode;
    }
    return 'fr'; // Langue par défaut en secours
  }

  String getTranslation(String Function(AppLocalizations) select) {
    final context = game.buildContext;
    if (context != null) {
      final localizations = AppLocalizations.of(context);
      if (localizations != null) {
        return select(localizations);
      }
    }
    return ''; // Chute si non monté
  }

  (String, String) _getTooltipData() {
    if (_customTooltipTitle != null && _customTooltipDescription != null) {
      return (_customTooltipTitle!, _customTooltipDescription!);
    }

    switch (type) {
      case StatType.hp:
        return (
          getTranslation((l) => l.tooltipHpTitle),
          getTranslation((l) => l.tooltipHpDesc),
        );
      case StatType.armor:
        return (
          getTranslation((l) => l.tooltipArmorTitle),
          getTranslation((l) => l.tooltipArmorDesc),
        );
      case StatType.attack:
        return (
          getTranslation((l) => l.tooltipAttackTitle),
          getTranslation((l) => l.tooltipAttackDesc),
        );
      case StatType.mana:
        return (
          getTranslation((l) => l.tooltipManaTitle),
          getTranslation((l) => l.tooltipManaDesc),
        );
    }
  }
}
