import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../card_component.dart';
import '../../game_constants.dart';
import '../entities/enemy_card.dart';
import '../entities/hero_card.dart';
import 'slash_effect.dart';
import 'base_visual_effect.dart';
import '../../../models/data/card_data.dart';

class CardAnimator {
  final CardComponent card;
  final Random rand = Random();

  CardAnimator(this.card);

  void spawnTrailParticles() {
    final elementalColor = card.getElementalColor();
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
                    paint: Paint()..color = elementalColor.withAlpha(150),
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
        card.game.focusedCard == card
            ? Vector2.all(card.game.scaleFactor * 0.88 * 1.25)
            : Vector2.all(card.game.scaleFactor * 0.88),
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
        _playStatusAnimation(
          target,
          const Color(0xFF10B981),
          wrappedOnComplete,
        );
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
    final isAoe =
        target == null || card.card.data.target == CardTarget.allEnemies;
    final castingPos = Vector2(card.game.size.x / 2, card.game.size.y * 0.45);
    final targetPos = target?.position ?? castingPos;

    card.borderPaint.color = Colors.white;

    final effects = <Effect>[];

    if (isAoe) {
      effects.add(
        MoveEffect.to(
          castingPos,
          EffectController(duration: 0.3, curve: Curves.easeOutQuad),
        ),
      );
    }

    effects.addAll([
      CombinedEffect([
        MoveEffect.by(
          Vector2(0, -50),
          EffectController(duration: 0.4, curve: Curves.easeOut),
        ),
        RotateEffect.by(0.2, EffectController(duration: 0.4, alternate: true)),
      ]),
      MoveEffect.to(
        targetPos,
        EffectController(duration: 0.2, curve: Curves.easeIn),
      ),
      ScaleEffect.to(
        Vector2.all(0.0),
        EffectController(duration: 0.1),
        onComplete: () {
          onComplete();
        },
      ),
    ]);

    card.add(SequenceEffect(effects));
  }

  void _playMeleeAnimation(EnemyCard? target, VoidCallback onComplete) {
    final isAoe =
        target == null || card.card.data.target == CardTarget.allEnemies;
    final castingPos = Vector2(card.game.size.x / 2, card.game.size.y * 0.45);
    final targetPos =
        target?.position ??
        Vector2(card.game.size.x / 2, card.game.size.y * 0.25);
    final startPos = isAoe ? castingPos : card.position;
    final anticipationDir = (startPos - targetPos).normalized();

    card.applyFlashVisual();

    final effects = <Effect>[];

    if (isAoe) {
      effects.add(
        MoveEffect.to(
          castingPos,
          EffectController(duration: 0.25, curve: Curves.easeOutQuad),
        ),
      );
    }

    effects.addAll([
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
          } else {
            for (final enemy in card.game.enemyCards) {
              card.game.add(
                SlashEffect(
                  position: enemy.position.clone(),
                  size: enemy.size * 1.5,
                  color: Colors.redAccent,
                ),
              );
            }
          }
          onComplete();
        },
      ),
    ]);

    card.add(SequenceEffect(effects));
  }

  void _playMagicAnimation(EnemyCard? target, VoidCallback onComplete) {
    final isAoe =
        target == null || card.card.data.target == CardTarget.allEnemies;
    final castingPos = Vector2(card.game.size.x / 2, card.game.size.y * 0.45);

    card.borderPaint.color = Colors.cyanAccent;

    final effects = <Effect>[];

    if (isAoe) {
      effects.add(
        MoveEffect.to(
          castingPos,
          EffectController(duration: 0.3, curve: Curves.easeOutQuad),
        ),
      );
    }

    effects.addAll([
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
          onComplete();
        },
      ),
    ]);

    card.add(SequenceEffect(effects));
  }

  void _playBuffAnimation(VoidCallback onComplete) {
    card.borderPaint.color = Colors.white;

    final hasHeal = card.card.data.effects.any((e) => e.type == 'heal');
    final hasArmor = card.card.data.effects.any((e) => e.type == 'armor');
    final hero = card.game.heroCard;

    if (hero != null) {
      if (hasHeal) {
        _spawnHealParticles(hero.position);
      } else if (hasArmor) {
        _spawnShieldDome(hero);
      }
    }

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

  void _spawnHealParticles(Vector2 heroPos) {
    card.game.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 20,
          lifespan: 1.2,
          generator: (i) {
            final startX = heroPos.x + (rand.nextDouble() - 0.5) * 80;
            final startY = heroPos.y + 40;
            final endY = startY - 120 - rand.nextDouble() * 60;
            final endX = startX + (rand.nextDouble() - 0.5) * 30;

            final isGold = rand.nextBool();
            final color = isGold
                ? const Color(0xFFFFD700)
                : const Color(0xFF10B981);

            return MovingParticle(
              from: Vector2(startX, startY),
              to: Vector2(endX, endY),
              child: CrossParticle(
                color: color,
                size: 8.0 + rand.nextDouble() * 8.0,
                lifespan: 1.2,
              ),
            );
          },
        ),
      )..priority = 100,
    );
  }

  void _spawnShieldDome(HeroCard hero) {
    card.game.add(ShieldDome(hero: hero, duration: 0.8));
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
                paint: Paint()
                  ..color = rand.nextBool() ? Colors.orange : Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CrossParticle extends Particle {
  final Color color;
  final double size;

  CrossParticle({
    required this.color,
    required this.size,
    required double lifespan,
  }) : super(lifespan: lifespan);

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0))
      ..strokeWidth = size * 0.25
      ..style = PaintingStyle.stroke;

    final half = size / 2;
    canvas.drawLine(Offset(0, -half), Offset(0, half), paint);
    canvas.drawLine(Offset(-half, 0), Offset(half, 0), paint);
  }
}

class ShieldDome extends BaseVisualEffect {
  final HeroCard hero;
  double _time = 0;

  ShieldDome({required this.hero, required super.duration})
    : super(
        priority: hero.priority + 5,
      );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    position = hero.position;
  }

  @override
  void render(Canvas canvas) {
    final double pulse = 1.0 + 0.05 * sin(_time * 15);
    final double radius = 70.0 * pulse;

    final currentProgress = (_time / duration).clamp(0.0, 1.0);
    final double opacity = 1.0 - currentProgress;

    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);

    // Draw glowing dome arc
    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.4 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(rect, pi, pi, false, paint);

    // Draw soft inner fill dome
    final innerPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.15 * opacity)
      ..style = PaintingStyle.fill;

    canvas.drawArc(rect, pi, pi, true, innerPaint);
  }
}
