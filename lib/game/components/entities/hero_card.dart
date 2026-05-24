import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import '../../../data/models/entity_stats.dart';
import '../floating_text.dart';
import '../effect_icon.dart';
import 'status_indicator.dart';
import '../../heros_draft_game.dart';
import '../../../models/data/card_data.dart';

class HeroCard extends PositionComponent
    with TapCallbacks, HasGameReference<HerosDraftGame> {
  EntityStats stats;
  int bonusAttack;
  final String imagePath;

  late final RectangleComponent borderInfo;
  late final StatusIndicator statusIndicator;

  HeroCard(
    this.stats, {
    this.bonusAttack = 0,
    required this.imagePath,
  }) : super(size: Vector2(120, 160));

  bool _isHighlighted = false;
  double _glowOpacity = 1.0;
  double _totalTime = 0;

  void setHighlight(bool highlight) {
    if (_isHighlighted == highlight) return;
    _isHighlighted = highlight;

    if (_isHighlighted) {
      borderInfo.paint.color = Colors.cyanAccent;
      borderInfo.paint.strokeWidth = 4;
    } else {
      borderInfo.paint.color = Colors.white;
      borderInfo.paint.strokeWidth = 2;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isHighlighted) {
      _totalTime += dt;
      _glowOpacity = 0.5 + 0.3 * sin(_totalTime * 4);
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isHighlighted) {
      final rect = size.toRect();
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(0));
      final glowPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: _glowOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 + (2 * _glowOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, 10 + (4 * _glowOpacity));
      canvas.drawRRect(rrect, glowPaint);
    }
    super.render(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // Système Click-to-Play : Ciblage de soi-même
    if (game.focusedCard != null) {
      if (game.focusedCard!.card.data.target == CardTarget.self) {
        final cardToPlay = game.focusedCard!;
        if (!cardToPlay.canAfford) {
          cardToPlay.shakeAnimation();
          return;
        }
        game.setFocusedCard(null);
        bool played = game.tryPlayCard(cardToPlay, null);
        if (played) {
          return;
        }
      }
    }
  }

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    // Appliquer l'échelle initiale (Agrandie pour le terrain)
    scale = Vector2.all(game.scaleFactor * 1.3);

    // Position par défaut au centre pour le joueur (sera mise à jour par onGameResize du jeu)
    position = Vector2(game.size.x / 2, game.size.y * 0.6);

    // Visuel Sprite
    add(
      SpriteComponent(
        sprite: Sprite(game.images.fromCache(imagePath)),
        size: size,
      ),
    );

    // Encadré de la carte
    borderInfo = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    add(borderInfo);

    // Positionner les debuffs/buffs sur le côté droit de la carte
    statusIndicator = StatusIndicator(
      statuses: stats.statuses,
      position: Vector2(size.x + 4, 10),
    );
    add(statusIndicator);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Mettre à jour l'échelle lors du redimensionnement (Agrandie pour le terrain)
    scale = Vector2.all(game.scaleFactor * 1.3);
  }

  void updateStats(
    EntityStats newStats, {
    int bonusAttack = 0,
  }) {
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
    statusIndicator.updateStatuses(newStats.statuses);
  }

  void _spawnFloatingText(String text, Color color, Vector2 pos) {
    final ft = FloatingText(text: text, color: color, position: pos);
    add(ft);
  }

  void dashAnimation() {
    add(
      SequenceEffect([
        MoveEffect.by(
          Vector2(0, -50),
          EffectController(duration: 0.1, curve: Curves.easeOut),
        ),
        MoveEffect.by(
          Vector2(0, 50),
          EffectController(duration: 0.15, curve: Curves.bounceOut),
        ),
      ]),
    );
  }

  void buffAnimation(String iconType) {
    // Faire popper l'icône
    final effectIcon = EffectIcon(
      iconType: iconType,
      position: Vector2(size.x / 2, 0), // Milieu haut
    );
    add(effectIcon);
  }
}
