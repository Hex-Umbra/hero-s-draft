import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import '../../../models/entity_stats.dart';
import '../../../models/combat_state.dart';
import '../floating_text.dart';
import '../effect_icon.dart';
import '../../heros_draft_game.dart';
import '../../../models/data/card_data.dart';

class HeroCard extends PositionComponent
    with TapCallbacks, HasGameReference<HerosDraftGame> {
  EntityStats stats;
  int bonusAttack;
  final String imagePath;

  late final RectangleComponent borderInfo;
  late final SpriteComponent sprite;

  HeroCard(this.stats, {this.bonusAttack = 0, required this.imagePath})
    : super(size: Vector2(120, 160));

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
        ..maskFilter = MaskFilter.blur(
          BlurStyle.outer,
          10 + (4 * _glowOpacity),
        );
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
    sprite = SpriteComponent(
      sprite: Sprite(game.images.fromCache(imagePath)),
      size: size,
    );
    add(sprite);

    // Encadré de la carte
    borderInfo = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    add(borderInfo);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Mettre à jour l'échelle lors du redimensionnement (Agrandie pour le terrain)
    scale = Vector2.all(game.scaleFactor * 1.3);
  }

  void updateStats(EntityStats newStats, {int bonusAttack = 0}) {
    final oldStats = stats;

    final isPlayerTurnPhase = game.currentPhase == TurnPhase.player;
    final hadPoison = oldStats.statuses.any((s) => s.id == 'poison');
    final isPoisonDamage = isPlayerTurnPhase && hadPoison;

    if (newStats.armure < oldStats.armure) {
      final lostArmor = oldStats.armure - newStats.armure;
      _spawnFloatingText(
        '-$lostArmor',
        const Color(0xFF3B82F6), // Technical premium blue
        position + Vector2(0, (size.y / 2 - 20) * scale.y),
        isShield: true,
      );
      shieldHitAnimation();
    } else if (newStats.armure > oldStats.armure) {
      final gainedArmor = newStats.armure - oldStats.armure;
      _spawnFloatingText(
        '+$gainedArmor',
        Colors.lightBlueAccent,
        position + Vector2(0, -size.y * scale.y / 2),
      );
    }

    if (newStats.currentPv < oldStats.currentPv) {
      final lostHp = oldStats.currentPv - newStats.currentPv;
      final isCritical = lostHp >= 15;
      final damageColor = isPoisonDamage
          ? const Color(0xFF10B981) // Poison neon green
          : (isCritical
                ? const Color(0xFFEF4444)
                : const Color(0xFFF87171)); // Red spectrum

      _spawnFloatingText(
        '-$lostHp',
        damageColor,
        position + Vector2(0, -(size.y / 4) * scale.y),
        isCritical: isCritical,
        isPoison: isPoisonDamage,
      );

      // Visual animations feedback
      shakeAndFlashAnimation(isPoison: isPoisonDamage);

      // Spawn particles
      spawnDamageParticles(
        color: damageColor,
        count: isCritical ? 25 : (isPoisonDamage ? 12 : 15),
      );
    }

    stats = newStats;
    this.bonusAttack = bonusAttack;
  }

  void shieldHitAnimation() {
    removeAll(children.whereType<ScaleEffect>());
    final double baseScale = game.scaleFactor * 1.3;

    // Bump d'échelle pour l'armure
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(baseScale * 1.08),
          EffectController(duration: 0.06, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(baseScale),
          EffectController(duration: 0.2, curve: Curves.easeIn),
          onComplete: () {
            _refreshBorderVisuals();
          },
        ),
      ]),
    );

    // Bordure bleu cyan temporaire
    borderInfo.paint.color = Colors.cyanAccent;
    borderInfo.paint.strokeWidth = _isHighlighted ? 6 : 4;
  }

  void _refreshBorderVisuals() {
    if (_isHighlighted) {
      borderInfo.paint.color = Colors.cyanAccent;
      borderInfo.paint.strokeWidth = 4;
    } else {
      borderInfo.paint.color = Colors.white;
      borderInfo.paint.strokeWidth = 2;
    }
  }

  void shakeAndFlashAnimation({bool isPoison = false}) {
    final double baseScale = game.scaleFactor * 1.3;

    removeAll(children.whereType<ScaleEffect>());
    sprite.removeAll(sprite.children.whereType<ColorEffect>());

    // 1. Sleek Scale Bump (Elastic Out)
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(baseScale * (isPoison ? 1.12 : 1.22)),
          EffectController(duration: 0.08, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(baseScale),
          EffectController(duration: 0.35, curve: Curves.elasticOut),
        ),
      ]),
    );

    // 2. High-frequency Shake
    final rand = Random();
    final shakeIntensity = isPoison ? 8.0 : 18.0;
    for (int i = 0; i < 5; i++) {
      add(
        MoveEffect.by(
          Vector2(
            (rand.nextDouble() - 0.5) * shakeIntensity,
            (rand.nextDouble() - 0.5) * shakeIntensity,
          ),
          EffectController(duration: 0.025, alternate: true),
        ),
      );
    }

    // 3. Decoupled Color Tint on sprite
    final flashColor = isPoison ? const Color(0xFF10B981) : Colors.redAccent;
    sprite.add(
      SequenceEffect([
        ColorEffect(
          flashColor,
          EffectController(duration: 0.1),
          opacityTo: 0.75,
        ),
        ColorEffect(
          flashColor,
          EffectController(duration: 0.25, curve: Curves.easeIn),
          opacityTo: 0.0,
        ),
      ]),
    );
  }

  void spawnDamageParticles({required Color color, required int count}) {
    final rand = Random();
    final centerPos = position.clone();

    game.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: count,
          lifespan: 0.6,
          generator: (i) {
            final angle = rand.nextDouble() * 2 * pi;
            final targetOffset =
                Vector2(cos(angle), sin(angle)) * (40 + rand.nextDouble() * 60);

            return MovingParticle(
              curve: Curves.easeOutCubic,
              from: centerPos,
              to: centerPos + targetOffset,
              child: ScaledParticle(
                child: CircleParticle(
                  radius: 1.5 + rand.nextDouble() * 2.0,
                  paint: Paint()
                    ..color = color.withValues(alpha: 0.95)
                    ..style = PaintingStyle.fill,
                ),
              ),
            );
          },
        ),
      )..priority = priority + 10,
    );
  }

  void _spawnFloatingText(
    String text,
    Color color,
    Vector2 globalPos, {
    bool isCritical = false,
    bool isPoison = false,
    bool isShield = false,
  }) {
    final ft = FloatingText(
      text: text,
      color: color,
      position: globalPos,
      isUpward: true,
      isCritical: isCritical,
      isPoison: isPoison,
      isShield: isShield,
    );
    ft.priority = 200;
    game.add(ft);
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
      position: position + Vector2(0, -size.y * scale.y / 2),
    );
    effectIcon.priority = 200;
    game.add(effectIcon);
  }
}
