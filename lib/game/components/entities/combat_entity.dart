import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../../heros_draft_game.dart';
import '../../../models/entity_stats.dart';
import '../../../models/combat_state.dart';
import '../floating_text.dart';

abstract class CombatEntity extends PositionComponent
    with HasGameReference<HerosDraftGame> {
  CombatEntity({super.position, super.size, super.scale, super.angle, super.anchor, super.children, super.priority});

  SpriteComponent get sprite;
  RectangleComponent get borderInfo;
  double get entityBaseScale;
  bool get isPlayer;

  void refreshBorderVisuals();

  void shieldHitAnimation() {
    removeAll(children.whereType<ScaleEffect>());
    final double bScale = entityBaseScale;

    // Bump d'échelle pour l'armure
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(bScale * 1.08),
          EffectController(duration: 0.06, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(bScale),
          EffectController(duration: 0.2, curve: Curves.easeIn),
          onComplete: () {
            refreshBorderVisuals();
          },
        ),
      ]),
    );

    // Bordure bleu cyan temporaire
    borderInfo.paint.color = Colors.cyanAccent;
    borderInfo.paint.strokeWidth = 4;
  }

  void shakeAndFlashAnimation({bool isPoison = false, bool isCritical = false}) {
    final double bScale = entityBaseScale;

    removeAll(children.whereType<ScaleEffect>());
    sprite.removeAll(sprite.children.whereType<ColorEffect>());

    // 1. Sleek Scale Bump (Elastic Out)
    final double bumpMultiplier = isCritical ? 1.45 : (isPoison ? 1.12 : 1.22);
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(bScale * bumpMultiplier),
          EffectController(duration: 0.08, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(bScale),
          EffectController(duration: 0.35, curve: Curves.elasticOut),
        ),
      ]),
    );

    // 2. High-frequency Shake
    final rand = Random();
    final shakeIntensity = isCritical ? 28.0 : (isPoison ? 8.0 : 18.0);
    final shakeCount = isCritical ? 8 : 5;
    for (int i = 0; i < shakeCount; i++) {
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
    final flashColor = isCritical
        ? const Color(0xFFF59E0B)
        : (isPoison ? const Color(0xFF10B981) : Colors.redAccent);
    sprite.add(
      SequenceEffect([
        ColorEffect(
          flashColor,
          EffectController(duration: 0.1),
          opacityTo: isCritical ? 0.85 : 0.75,
        ),
        ColorEffect(
          flashColor,
          EffectController(duration: isCritical ? 0.35 : 0.25, curve: Curves.easeIn),
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

  void dashAnimation({bool isDownward = false}) {
    final double direction = isDownward ? 1.0 : -1.0;
    add(
      SequenceEffect([
        MoveEffect.by(
          Vector2(0, 50 * direction),
          EffectController(duration: 0.1, curve: Curves.easeOut),
        ),
        MoveEffect.by(
          Vector2(0, -50 * direction),
          EffectController(duration: 0.15, curve: Curves.bounceOut),
        ),
      ]),
    );
  }

  void spawnFloatingText(
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
      isUpward: isPlayer,
      isCritical: isCritical,
      isPoison: isPoison,
      isShield: isShield,
    );
    ft.priority = 200;
    game.add(ft);
  }

  void triggerHitReactions(
    EntityStats oldStats,
    EntityStats newStats, {
    bool suppressArmorChange = false,
  }) {
    final isTurnPhaseForPoison = isPlayer
        ? game.currentPhase == TurnPhase.player
        : game.currentPhase == TurnPhase.enemy;
    final hadPoison = oldStats.statuses.any((s) => s.id == 'poison');
    final isPoisonDamage = isTurnPhaseForPoison && hadPoison;

    if (!suppressArmorChange) {
      if (newStats.armure < oldStats.armure) {
        final lostArmor = oldStats.armure - newStats.armure;
        spawnFloatingText(
          '-$lostArmor',
          const Color(0xFF3B82F6), // Technical premium blue
          position + Vector2(0, (size.y / 2 - 20) * scale.y),
          isShield: true,
        );
        shieldHitAnimation();
      } else if (newStats.armure > oldStats.armure) {
        final gainedArmor = newStats.armure - oldStats.armure;
        spawnFloatingText(
          '+$gainedArmor',
          Colors.lightBlueAccent,
          position + Vector2(0, -size.y * scale.y / 2),
        );
      }
    }

    if (newStats.currentPv < oldStats.currentPv) {
      final lostHp = oldStats.currentPv - newStats.currentPv;
      final isCritical = newStats.lastActionWasCrit;
      final damageColor = isPoisonDamage
          ? const Color(0xFF10B981) // Poison neon green
          : (isCritical
              ? const Color(0xFFF59E0B)
              : const Color(0xFFF87171)); // Red spectrum

      final double verticalOffset = isPlayer ? -size.y / 4 : size.y / 2;

      spawnFloatingText(
        '-$lostHp',
        damageColor,
        position + Vector2(0, verticalOffset * scale.y),
        isCritical: isCritical,
        isPoison: isPoisonDamage,
      );

      // Visual animations feedback
      shakeAndFlashAnimation(isPoison: isPoisonDamage, isCritical: isCritical);

      // Spawn particles
      spawnDamageParticles(
        color: damageColor,
        count: isCritical ? 35 : (isPoisonDamage ? 12 : 15),
      );
    }
  }
}
