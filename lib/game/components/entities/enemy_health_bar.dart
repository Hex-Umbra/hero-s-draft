import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../game_constants.dart';
import '../widgets/flame_shield_icon.dart';
import '../widgets/linear_progress_bar.dart';

/// La barre de PV d'un ennemi, posee au-dessus de sa carte et large comme elle,
/// avec le voile d'armure qui la recouvre. Elle ne decide rien : elle montre ce
/// que la carte lui donne (spec P-05, §5.2). Sa zone d'appui descend jusqu'au
/// haut de la carte et renvoie l'appui a celle-ci.
class EnemyHealthBar extends PositionComponent with TapCallbacks {
  final void Function(TapDownEvent event) onTap;

  late final LinearProgressBarComponent _bar;
  late final TextComponent _hpText;
  late final PositionComponent _armorGroup;
  late final TextComponent _armorText;

  bool _hasArmor = false;

  EnemyHealthBar({required double width, required this.onTap})
    : super(
        position: Vector2(0, GameConstants.enemyHealthBarTop),
        size: Vector2(width, -GameConstants.enemyHealthBarTop),
      ) {
    final centerY = GameConstants.enemyHealthBarHeight / 2;
    _bar = LinearProgressBarComponent(
      size: Vector2(width, GameConstants.enemyHealthBarHeight),
      percentage: 1.0,
      borderRadius: GameConstants.enemyHealthBarRadius,
    );
    _hpText = TextComponent(
      anchor: Anchor.centerLeft,
      textRenderer: _renderer(Colors.white),
    );
    _armorText = TextComponent(
      anchor: Anchor.centerLeft,
      position: Vector2(
        GameConstants.enemyHealthBarShieldSize +
            GameConstants.enemyHealthBarArmorGap,
        centerY,
      ),
      textRenderer: _renderer(const Color(0xFF00E5FF)),
    );
    _armorGroup = PositionComponent(
      children: [
        FlameShieldIcon(
          position: Vector2(0, centerY),
          size: Vector2.all(GameConstants.enemyHealthBarShieldSize),
          color: const Color(0xFF2196F3),
          anchor: Anchor.centerLeft,
        ),
        _armorText,
      ],
    );
    _hpText.position.y = centerY;
  }

  static TextPaint _renderer(Color color) => TextPaint(
    style: TextStyle(
      color: color,
      fontSize: GameConstants.enemyHealthBarFontSize,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(color: Colors.black, blurRadius: 2.0, offset: Offset(1, 1)),
      ],
    ),
  );

  @override
  Future<void> onLoad() async {
    addAll([_bar, _hpText, _armorGroup]);
    _layout();
  }

  /// [veil] est la part de la barre que couvre l'armure, deja calculee par
  /// `ArmorVeil` : la barre la dessine, elle ne la calcule pas.
  void setValues({
    required int currentPv,
    required int maxPv,
    required int armor,
    required double veil,
  }) {
    _bar.percentage = maxPv > 0 ? currentPv / maxPv : 0.0;
    _bar.armorPercentage = veil;
    _hpText.text = '$currentPv/$maxPv';
    _armorText.text = '$armor';
    _hasArmor = armor > 0;
    _layout();
  }

  /// Centre le groupe « PV, bouclier, armure » sur la barre ; sans armure, le
  /// groupe se reduit au texte des PV et le bouclier n'est plus dessine.
  void _layout() {
    _armorGroup.scale = _hasArmor ? Vector2.all(1) : Vector2.zero();
    final armorWidth = GameConstants.enemyHealthBarShieldSize +
        GameConstants.enemyHealthBarArmorGap +
        _armorText.size.x;
    final total = _hasArmor
        ? _hpText.size.x + GameConstants.enemyHealthBarShieldGap + armorWidth
        : _hpText.size.x;
    final start = (size.x - total) / 2;
    _hpText.position.x = start;
    _armorGroup.position.x =
        start + _hpText.size.x + GameConstants.enemyHealthBarShieldGap;
  }

  @override
  void onTapDown(TapDownEvent event) => onTap(event);
}
