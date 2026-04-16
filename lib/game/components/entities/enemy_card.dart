import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import '../../../data/models/entity_stats.dart';
import '../floating_text.dart';

class EnemyCard extends PositionComponent with TapCallbacks {
  EntityStats stats;
  late TextComponent statsText;
  final bool isBoss;
  final void Function(EnemyCard) onTapEnemy;

  bool isSelected = false;
  late final RectangleComponent borderInfo;

  EnemyCard({
    required this.stats,
    this.isBoss = false,
    required this.onTapEnemy,
  }) : super(size: Vector2(140, 200));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    add(
      RectangleComponent(
        size: size,
        paint: Paint()
          ..color = isBoss ? const Color(0xFF8E44AD) : const Color(0xFFC0392B),
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

    statsText = TextComponent(
      text: _buildStatsString(),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
      ),
      position: Vector2(10, 10),
    );
    add(statsText);
  }

  String _buildStatsString() {
    String title = isBoss ? 'BOSS' : 'ENNEMI';
    return '$title\n\nPV: ${stats.currentPv}/${stats.maxPv}\nArmure: ${stats.armure}\nAttaque: ${stats.attaque}';
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
    statsText.text = _buildStatsString();
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
