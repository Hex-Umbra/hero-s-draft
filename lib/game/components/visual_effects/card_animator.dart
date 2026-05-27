import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../card_component.dart';
import '../../game_constants.dart';
import '../entities/enemy_card.dart';
import 'slash_effect.dart';

class CardAnimator {
  final CardComponent card;
  final Random rand = Random();
  double particleHue = 0;

  CardAnimator(this.card);

  void spawnTrailParticles() {
    particleHue = (particleHue + 15) % 360;
    final rainbowColor = HSVColor.fromAHSV(1.0, particleHue, 0.8, 1.0).toColor();
    final gravity = Vector2(0, 150);

    card.game.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 3,
          lifespan: 0.6,
          generator: (i) {
            final initialVelocity = Vector2(
              (rand.nextDouble() - 0.5) * 50,
              (rand.nextDouble() - 0.5) * 50,
            );

            if (i == 0) {
              return AcceleratedParticle(
                position: card.position.clone(),
                speed: initialVelocity,
                acceleration: gravity,
                child: ScaledParticle(
                  child: CircleParticle(
                    radius: 2.0,
                    paint: Paint()..color = Colors.white.withAlpha(100),
                  ),
                ),
              );
            } else {
              return AcceleratedParticle(
                position: card.position.clone(),
                speed: initialVelocity * 1.5,
                acceleration: gravity,
                child: ScaledParticle(
                  child: CircleParticle(
                    radius: 2.0 + rand.nextDouble() * 2.0,
                    paint: Paint()..color = rainbowColor.withAlpha(150),
                  ),
                ),
              );
            }
          },
        ),
      )..priority = card.priority - 1,
    );
  }

  void returnToHand() {
    card.isHoveringCancelZone = false;
    card.isCancelling = false;
    card.isFlashing = false;

    card.borderPaint.color = Colors.blueAccent;
    
    card.refreshVisuals();
    card.clearEffects();

    card.add(
      MoveEffect.to(
        card.originalPosition,
        EffectController(duration: 0.4, curve: Curves.elasticOut),
      ),
    );
    card.add(
      RotateEffect.to(
        card.originalAngle,
        EffectController(duration: 0.4, curve: Curves.elasticOut),
      ),
    );
    card.add(
      ScaleEffect.to(
        Vector2.all(card.game.scaleFactor * 0.88),
        EffectController(duration: 0.4, curve: Curves.elasticOut),
      ),
    );

    card.priority = card.basePriority;
  }

  void shakeAnimation() {
    // Évite les décalages cumulés si l'animation est déclenchée à répétition rapidement
    if (!card.isDragging) {
      final basePos = card.game.focusedCard == card 
          ? card.originalPosition + Vector2(0, -60)
          : card.originalPosition;
      card.position = basePos;
    }

    final existingShakes = card.children.whereType<SequenceEffect>().toList();
    if (existingShakes.isNotEmpty) {
      card.removeAll(existingShakes);
      if (!card.isDragging) {
        final basePos = card.game.focusedCard == card 
            ? card.originalPosition + Vector2(0, -60)
            : card.originalPosition;
        card.position = basePos;
      }
    }

    card.add(
      SequenceEffect([
        MoveEffect.by(Vector2(5, 0), EffectController(duration: 0.05)),
        MoveEffect.by(Vector2(-10, 0), EffectController(duration: 0.05)),
        MoveEffect.by(Vector2(10, 0), EffectController(duration: 0.05)),
        MoveEffect.by(Vector2(-10, 0), EffectController(duration: 0.05)),
        MoveEffect.by(Vector2(5, 0), EffectController(duration: 0.05)),
      ]),
    );
  }

  void playAnimation(EnemyCard? target, {required VoidCallback onComplete}) {
    card.isPlayed = true;
    card.isDragging = false;
    card.priority = GameConstants.priorityCardDraggingMax;

    card.clearEffects();

    final animType = card.card.data.animation ?? 'melee';

    void wrappedOnComplete() {
      if (card.card.data.isExhaust) {
        spawnExhaustParticles(card.position);
      }
      onComplete();
    }

    switch (animType) {
      case 'magic':
        _playMagicAnimation(target, wrappedOnComplete);
        break;
      case 'buff':
        _playBuffAnimation(wrappedOnComplete);
        break;
      case 'poison':
        _playStatusAnimation(target, Colors.greenAccent, wrappedOnComplete);
        break;
      case 'fire':
        _playStatusAnimation(target, Colors.orangeAccent, wrappedOnComplete);
        break;
      case 'ice':
        _playStatusAnimation(target, Colors.lightBlueAccent, wrappedOnComplete);
        break;
      case 'lightning':
        _playStatusAnimation(target, Colors.yellowAccent, wrappedOnComplete);
        break;
      case 'melee':
      default:
        _playMeleeAnimation(target, wrappedOnComplete);
        break;
    }
  }

  void _playStatusAnimation(
    EnemyCard? target,
    Color color,
    VoidCallback onComplete,
  ) {
    final targetPos = target?.position ?? card.position + Vector2(0, -card.size.y * 2);

    card.borderPaint.color = Colors.white;

    card.add(
      SequenceEffect([
        CombinedEffect([
          MoveEffect.by(
            Vector2(0, -50),
            EffectController(duration: 0.4, curve: Curves.easeOut),
          ),
          RotateEffect.by(
            0.2,
            EffectController(duration: 0.4, alternate: true),
          ),
        ]),
        MoveEffect.to(
          targetPos,
          EffectController(duration: 0.2, curve: Curves.easeIn),
        ),
        ScaleEffect.to(
          Vector2.all(0.0),
          EffectController(duration: 0.1),
          onComplete: () {
            if (target != null) {
              spawnImpactParticles(
                targetPos,
                color: color,
                count: 30,
              );
              target.shakeAndFlashAnimation();
            }
            onComplete();
          },
        ),
      ]),
    );
  }

  void _playMeleeAnimation(EnemyCard? target, VoidCallback onComplete) {
    final targetPos = target?.position ?? card.position + Vector2(0, -card.size.y * 2);
    final anticipationDir = (card.position - targetPos).normalized();

    card.applyFlashVisual();

    card.add(
      SequenceEffect([
        MoveEffect.by(
          anticipationDir * 40,
          EffectController(duration: 0.1, curve: Curves.easeOut),
        ),
        MoveEffect.to(
          targetPos,
          EffectController(duration: 0.15, curve: Curves.easeIn),
        ),
        ScaleEffect.to(
          Vector2.all(0.0),
          EffectController(duration: 0.05),
          onComplete: () {
            if (target != null) {
              card.game.add(
                SlashEffect(
                  position: target.position.clone(),
                  size: target.size * 1.5,
                  color: Colors.redAccent,
                ),
              );
              target.shakeAndFlashAnimation();
            }

            spawnImpactParticles(targetPos, color: Colors.redAccent);
            onComplete();
          },
        ),
      ]),
    );
  }

  void _playMagicAnimation(EnemyCard? target, VoidCallback onComplete) {
    final targetPos = target?.position ?? card.position + Vector2(0, -card.size.y * 2);

    card.borderPaint.color = Colors.cyanAccent;

    card.add(
      SequenceEffect([
        MoveEffect.by(
          Vector2(0, -30),
          EffectController(duration: 0.3, curve: Curves.easeInOut),
        ),
        ScaleEffect.to(
          Vector2.all(card.game.scaleFactor * 1.1),
          EffectController(
            duration: 0.4,
            alternate: true,
            curve: Curves.elasticIn,
          ),
        ),
        ScaleEffect.to(
          Vector2.all(0.0),
          EffectController(duration: 0.2, curve: Curves.easeIn),
          onComplete: () {
            spawnImpactParticles(
              targetPos,
              color: Colors.purpleAccent,
              count: 25,
            );
            onComplete();
          },
        ),
      ]),
    );
  }

  void _playBuffAnimation(VoidCallback onComplete) {
    card.borderPaint.color = Colors.white;

    card.add(
      SequenceEffect([
        MoveEffect.by(
          Vector2(0, -100),
          EffectController(duration: 0.6, curve: Curves.easeOut),
        ),
        OpacityEffect.to(
          0.0,
          EffectController(duration: 0.3),
          onComplete: () {
            onComplete();
          },
        ),
      ]),
    );
  }

  void spawnImpactParticles(
    Vector2 impactPos, {
    Color color = Colors.blueAccent,
    int count = 15,
  }) {
    card.game.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: count,
          lifespan: 0.5,
          generator: (i) => MovingParticle(
            curve: Curves.easeOut,
            from: impactPos,
            to:
                impactPos +
                Vector2(
                  (rand.nextDouble() - 0.5) * 200,
                  (rand.nextDouble() - 0.5) * 200,
                ),
            child: ScaledParticle(
              scale: 1.5,
              child: CircleParticle(radius: 2, paint: Paint()..color = color),
            ),
          ),
        ),
      ),
    );
  }

  void spawnExhaustParticles(Vector2 exhaustPos) {
    card.game.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 40,
          lifespan: 0.8,
          generator: (i) => MovingParticle(
            curve: Curves.easeOutQuad,
            from: exhaustPos,
            to:
                exhaustPos +
                Vector2(
                  (rand.nextDouble() - 0.5) * 150,
                  (rand.nextDouble() - 1.0) * 200, // Move upwards
                ),
            child: ScaledParticle(
              scale: 2.0,
              child: CircleParticle(
                radius: 3, 
                paint: Paint()..color = rand.nextBool() ? Colors.orange : Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
