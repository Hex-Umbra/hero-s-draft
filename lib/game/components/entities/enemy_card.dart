import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import '../../../data/models/entity_stats.dart';
import '../../../models/data/enemy_data.dart';
import '../floating_text.dart';
import 'stat_badge.dart';
import '../../heros_draft_game.dart';

class EnemyCard extends PositionComponent with TapCallbacks, HasGameReference<HerosDraftGame> {
  EntityStats stats;
  final EnemyData? data;
  final bool isBoss;
  final void Function(EnemyCard) onTapEnemy;

  late final RectangleComponent borderInfo;
  late final TextComponent titleText;
  
  late final StatBadge hpBadge;
  late final StatBadge armorBadge;
  late final StatBadge attackBadge;
  late final StatBadge manaBadge;

  bool isSelected = false;

  EnemyCard({
    required this.stats,
    this.data,
    this.isBoss = false,
    required this.onTapEnemy,
  }) : super(size: Vector2(140, 200));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    String spriteName = isBoss ? 'enemy_boss.png' : 'enemy_goblin.png';
    add(
      SpriteComponent(
        sprite: Sprite(game.images.fromCache(spriteName)),
        size: size,
      ),
    );

    borderInfo = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    add(borderInfo);

    String title = data?.name ?? (isBoss ? 'BOSS' : 'ENNEMI');
    titleText = TextComponent(
      text: title,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 10),
    );
    add(titleText);

    hpBadge = StatBadge(type: StatType.hp, value: '${stats.currentPv}/${stats.maxPv}');
    hpBadge.position = Vector2(0, 0);
    add(hpBadge);

    armorBadge = StatBadge(type: StatType.armor, value: '${stats.armure}');
    armorBadge.position = Vector2(size.x, 0);
    add(armorBadge);

    attackBadge = StatBadge(type: StatType.attack, value: '${stats.attaque}');
    attackBadge.position = Vector2(0, size.y);
    add(attackBadge);

    manaBadge = StatBadge(type: StatType.mana, value: '${stats.currentMana}/${stats.maxMana}');
    manaBadge.position = Vector2(size.x / 2, size.y - 25);
    add(manaBadge);
  }

  void _refreshBadges() {
    hpBadge.updateValue('${stats.currentPv}/${stats.maxPv}');
    armorBadge.updateValue('${stats.armure}');
    attackBadge.updateValue(stats.attaque.toString());
    manaBadge.updateValue('${stats.currentMana}/${stats.maxMana}');
  }

  void updateStats(EntityStats newStats) {
    if (newStats.armure < stats.armure) {
      _spawnFloatingText(
        '-${stats.armure - newStats.armure}',
        Colors.blue,
        Vector2(size.x / 2, size.y - 20),
      );
    }
    if (newStats.currentPv < stats.currentPv) {
      _spawnFloatingText(
        '-${stats.currentPv - newStats.currentPv}',
        Colors.red,
        Vector2(size.x / 2, size.y),
      );
    }

    stats = newStats;
    _refreshBadges();
  }

  void _spawnFloatingText(String text, Color color, Vector2 pos) {
    final ft = FloatingText(
      text: text,
      color: color,
      position: pos,
      movement: Vector2(0, 50),
    );
    add(ft);
  }

  void setSelection(bool selected) {
    isSelected = selected;
    if (isSelected) {
      borderInfo.paint.color = Colors.amber;
      borderInfo.paint.strokeWidth = 4;
    } else {
      borderInfo.paint.color = Colors.white;
      borderInfo.paint.strokeWidth = 2;
    }
  }

  void bumpAnimation() {
    add(
      MoveEffect.by(
        Vector2(0, 30),
        EffectController(duration: 0.1, alternate: true),
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapEnemy(this);
  }
}
