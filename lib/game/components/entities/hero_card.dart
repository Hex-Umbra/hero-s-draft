import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import 'package:flame/effects.dart';
import '../../../data/models/entity_stats.dart';
import '../floating_text.dart';

class StatsTextComponent extends PositionComponent {
  EntityStats stats;
  int bonusAttack;

  StatsTextComponent(this.stats, this.bonusAttack) : super(position: Vector2(10, 10));

  @override
  void render(Canvas canvas) {
    final textSpan = TextSpan(
      children: [
        TextSpan(text: 'HÉROS\n\nPV: ${stats.currentPv}/${stats.maxPv}\nArmure: ${stats.armure}\n', style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        if (bonusAttack > 0) ...[
          TextSpan(text: 'Attaque: ${stats.attaque + bonusAttack}(${stats.attaque} + ', style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
          TextSpan(text: '$bonusAttack', style: const TextStyle(color: Colors.amber, fontSize: 16, height: 1.5, fontWeight: FontWeight.bold)),
          TextSpan(text: ')\n', style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        ] else ...[
          TextSpan(text: 'Attaque: ${stats.attaque}\n', style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        ],
        TextSpan(text: 'Défense: ${(stats.defense * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
      ],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
  }
}

class HeroCard extends PositionComponent with TapCallbacks {
  EntityStats stats;
  int bonusAttack;
  late StatsTextComponent statsText;

  HeroCard(this.stats, {this.bonusAttack = 0}) : super(size: Vector2(160, 220));

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

    // Texte des stats dynamiques (incluant la coloration des bonus d'attaque)
    statsText = StatsTextComponent(stats, bonusAttack);
    add(statsText);
  }

  void updateStats(EntityStats newStats, {int bonusAttack = 0}) {
    if (newStats.armure < stats.armure) {
      _spawnFloatingText('-${stats.armure - newStats.armure}', Colors.blue, Vector2(size.x / 2, 0));
    } else if (newStats.armure > stats.armure) {
      _spawnFloatingText('+${newStats.armure - stats.armure}', Colors.lightBlueAccent, Vector2(size.x / 2, 0));
    }

    if (newStats.currentPv < stats.currentPv) {
      _spawnFloatingText('-${stats.currentPv - newStats.currentPv}', Colors.red, Vector2(size.x / 2, 20));
    }

    stats = newStats;
    this.bonusAttack = bonusAttack;
    statsText.stats = newStats;
    statsText.bonusAttack = bonusAttack;
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
