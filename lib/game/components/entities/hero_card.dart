import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import '../../../data/models/entity_stats.dart';
import '../floating_text.dart';
import 'stat_badge.dart';

class HeroCard extends PositionComponent with TapCallbacks {
  EntityStats stats;
  int bonusAttack;
  String className;
  Color classColor;
  
  late final TextComponent titleText;
  late final StatBadge hpBadge;
  late final StatBadge armorBadge;
  late final StatBadge attackBadge;
  late final StatBadge defenseBadge;
  late final StatBadge manaBadge;

  HeroCard(this.stats, {this.bonusAttack = 0, required this.className, required this.classColor}) : super(size: Vector2(160, 220));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    // Position par défaut au centre en bas pour le joueur
    position = Vector2(250, 500);

    // Visuel Placeholder : Fond Bleu/Gris
    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFF2C3E50),
      ),
    );

    // Encadré de la carte
    add(
      RectangleComponent(
        size: size,
        paint: Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      ),
    );

    titleText = TextComponent(
      text: className.toUpperCase(),
      textRenderer: TextPaint(
        style: TextStyle(color: classColor, fontSize: 16, fontWeight: FontWeight.bold),
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

    defenseBadge = StatBadge(type: StatType.defense, value: '${(stats.defense * 100).toInt()}%');
    defenseBadge.position = Vector2(size.x, size.y);
    add(defenseBadge);

    manaBadge = StatBadge(type: StatType.mana, value: '${stats.currentMana}/${stats.maxMana}');
    manaBadge.position = Vector2(size.x / 2, size.y - 25);
    add(manaBadge);

    _refreshBadges();
  }

  void _refreshBadges() {
    hpBadge.updateValue('${stats.currentPv}/${stats.maxPv}');
    armorBadge.updateValue('${stats.armure}');
    
    if (bonusAttack > 0) {
      attackBadge.updateValue('${stats.attaque + bonusAttack}', textColor: Colors.amber);
    } else {
      attackBadge.updateValue('${stats.attaque}', textColor: Colors.white);
    }

    defenseBadge.updateValue('${(stats.defense * 100).toInt()}%');
    manaBadge.updateValue('${stats.currentMana}/${stats.maxMana}');
  }

  void updateStats(EntityStats newStats, {int bonusAttack = 0}) {
    if (newStats.armure < stats.armure) {
      _spawnFloatingText(
        '-${stats.armure - newStats.armure}',
        Colors.blue,
        Vector2(size.x / 2, 0),
      );
    } else if (newStats.armure > stats.armure) {
      _spawnFloatingText(
        '+${newStats.armure - stats.armure}',
        Colors.lightBlueAccent,
        Vector2(size.x / 2, 0),
      );
    }

    if (newStats.currentPv < stats.currentPv) {
      _spawnFloatingText(
        '-${stats.currentPv - newStats.currentPv}',
        Colors.red,
        Vector2(size.x / 2, 20),
      );
    }

    stats = newStats;
    this.bonusAttack = bonusAttack;
    _refreshBadges();
  }

  void _spawnFloatingText(String text, Color color, Vector2 pos) {
    final ft = FloatingText(text: text, color: color, position: pos);
    add(ft);
  }

  void bumpAnimation() {
    add(
      MoveEffect.by(
        Vector2(0, -30),
        EffectController(duration: 0.1, alternate: true),
      ),
    );
  }
}
