import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import 'package:flame/effects.dart';
import '../../../data/models/entity_stats.dart';
import '../floating_text.dart';

class HeroCard extends PositionComponent with TapCallbacks {
  EntityStats stats;
  late TextComponent statsText;

  HeroCard(this.stats) : super(size: Vector2(160, 220));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    
    // Position par défaut au centre en bas pour le joueur
    position = Vector2(250, 500); 

    // Visuel Placeholder : Fond Bleu/Gris
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF2C3E50),
    ));
    
    // Encadré de la carte
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));

    // Texte des stats
    statsText = TextComponent(
      text: _buildStatsString(),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
      ),
      position: Vector2(10, 10),
    );
    add(statsText);
  }

  String _buildStatsString() {
    return 'HÉROS\n\nPV: ${stats.currentPv}/${stats.maxPv}\nArmure: ${stats.armure}\nAttaque: ${stats.attaque}\nDéfense: ${(stats.defense * 100).toInt()}%';
  }

  void updateStats(EntityStats newStats) {
    if (newStats.armure < stats.armure) {
      _spawnFloatingText('-${stats.armure - newStats.armure}', Colors.blue, Vector2(size.x / 2, 0));
    } else if (newStats.armure > stats.armure) {
      _spawnFloatingText('+${newStats.armure - stats.armure}', Colors.lightBlueAccent, Vector2(size.x / 2, 0));
    }

    if (newStats.currentPv < stats.currentPv) {
      _spawnFloatingText('-${stats.currentPv - newStats.currentPv}', Colors.red, Vector2(size.x / 2, 20));
    }

    stats = newStats;
    statsText.text = _buildStatsString();
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
