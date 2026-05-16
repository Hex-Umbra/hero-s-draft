import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../heros_draft_game.dart';
import 'entities/enemy_card.dart';
import 'visual_effects/ribbon_trail.dart';
import 'visual_effects/slash_effect.dart';

class CardComponent extends PositionComponent
    with
        DragCallbacks,
        TapCallbacks,
        HoverCallbacks,
        HasGameReference<HerosDraftGame>
    implements OpacityProvider {
  final CardInstance card;

  double _opacity = 1.0;

  @override
  double get opacity => _opacity;

  // TextPainters pour le rendu manuel
  late TextPainter _namePainter;
  late TextPainter _costPainter;
  late TextPainter _descPainter;
  late TextPainter _usagePainter;

  // État visuel actuel (pour savoir si on doit repeindre en blanc, etc.)
  bool _isFlashing = false;
  bool _isCancelling = false;

  @override
  set opacity(double value) {
    if (_opacity == value) return;
    _opacity = value;
    _updateTextPainters();
  }

  bool get _canAfford {
    if (!isLoaded || !isMounted) return true;
    final currentMana = game.currentRunState?.heroStats.currentMana ?? 0;
    return currentMana >= card.currentCost;
  }

  void _updateTextPainters() {
    final int alpha = (_opacity * 255).toInt();
    
    // Configurer le style de base selon l'état
    Color nameColor = _isFlashing ? Colors.transparent : Colors.white.withAlpha(alpha);
    Color costColor = _isFlashing ? Colors.transparent : Colors.lightBlueAccent.withAlpha(alpha);
    Color descColor = _isFlashing ? Colors.transparent : Colors.white70.withAlpha(alpha);
    Color usageColor = _isFlashing ? Colors.transparent : Colors.redAccent.withAlpha(alpha);

    if (_isCancelling) {
      nameColor = Colors.white.withAlpha((alpha * 0.6).toInt());
      costColor = Colors.lightBlueAccent.withAlpha((alpha * 0.6).toInt());
      descColor = Colors.white70.withAlpha((alpha * 0.6).toInt());
    }
    
    if (!_canAfford && !_isFlashing) {
      costColor = Colors.redAccent.withAlpha(alpha);
    }

    _namePainter = TextPainter(
      text: TextSpan(
        text: card.data.name,
        style: TextStyle(
          color: nameColor,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.x - 24);

    _costPainter = TextPainter(
      text: TextSpan(
        text: '${card.currentCost}',
        style: TextStyle(
          color: costColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _descPainter = TextPainter(
      text: TextSpan(
        text: _buildDescription(),
        style: TextStyle(
          color: descColor,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.x - 20);

    _usagePainter = TextPainter(
      text: TextSpan(
        text: (card.data.type == CardType.power || card.data.isExhaust) ? '1/1' : '',
        style: TextStyle(
          color: usageColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    game.onShowTooltip(card.data.name, _buildDetailedDescription());
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.onHideTooltip();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    game.onHideTooltip();
  }

  String _buildDetailedDescription() {
    String desc = '${card.data.description}\n\n';
    if (card.data.type == CardType.power || card.data.isExhaust) {
      desc += '⚠️ USAGE UNIQUE (Épuisement)\n\n';
    }
    for (var effect in card.data.effects) {
      final scaledValue = (effect.value * (1 + (card.level - 1) * 0.5)).round();
      if (effect.type == 'damage') desc += '• Dégâts: $scaledValue\n';
      if (effect.type == 'heal') desc += '• Soin: $scaledValue\n';
      if (effect.type == 'armor') desc += '• Armure: $scaledValue\n';
      if (effect.type == 'draw') desc += '• Pioche: $scaledValue cartes\n';
    }
    return desc.trim();
  }

  Vector2 originalPosition = Vector2.zero();
  double originalAngle = 0;
  int basePriority = 10;

  bool isDragging = false;
  double _targetTilt = 0;
  bool _isHoveringCancelZone = false;
  RibbonTrail? _activeTrail;

  @override
  bool isHovered = false;

  // Paramètres visuels
  static const double cardWidth = 140;
  static const double cardHeight = 196;

  final Paint backgroundPaint = Paint()..color = const Color(0xFF2A2A3D);
  final Paint borderPaint = Paint()
    ..color = Colors.blueAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  CardComponent(this.card) : super(size: Vector2(cardWidth, cardHeight)) {
    anchor = Anchor.center;
  }

  @override
  void onHoverEnter() {
    if (isDragging) return;
    game.setHoveredCard(this);
  }

  @override
  void onHoverExit() {
    if (isDragging) return;
    if (game.hoveredCard == this) {
      game.setHoveredCard(null);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDragging) {
      // Interpolation fluide pour l'effet de tilt (inclinaison)
      angle += (_targetTilt - angle) * 15 * dt;
      // Amortissement du tilt cible pour qu'il revienne à 0 quand le mouvement s'arrête
      _targetTilt += (0 - _targetTilt) * 5 * dt;

      // Génération de la queue de particules améliorée (Blanche + Arc-en-ciel)
      _spawnTrailParticles();
      // Mise à jour du ruban
      _activeTrail?.addPoint(position);
    }
  }

  double _particleHue = 0;

  void _spawnTrailParticles() {
    _particleHue = (_particleHue + 15) % 360;
    final rainbowColor =
        HSVColor.fromAHSV(1.0, _particleHue, 0.8, 1.0).toColor();

    final gravity = Vector2(0, 150);

    game.add(
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
                position: position.clone(),
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
                position: position.clone(),
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
      )..priority = priority - 1,
    );
  }

  final rand = Random();

  @override
  Future<void> onLoad() async {
    scale = Vector2.all(game.scaleFactor * 0.75);
    _updateTextPainters();
  }

  Vector2 _lastSize = Vector2.zero();

  @override
  void onGameResize(Vector2 size) {
    if (_lastSize == size) return;
    _lastSize = size.clone();
    super.onGameResize(size);

    if (!isDragging && game.focusedCard != this) {
      scale = Vector2.all(game.scaleFactor * 0.75);
    }
  }

  String _buildDescription() {
    String desc = '';
    final heroAttack = game.heroCard?.stats.effectiveAttaque ?? 0;

    for (var effect in card.data.effects) {
      final scaledValue = (effect.value * (1 + (card.level - 1) * 0.5)).round();
      if (effect.type == 'damage') {
        final totalDmg = scaledValue + heroAttack;
        desc += 'Inflige $totalDmg dégâts.\n';
      }
      if (effect.type == 'heal') desc += 'Soigne $scaledValue PV.\n';
      if (effect.type == 'armor') desc += 'Donne $scaledValue Armure.\n';
    }
    if (desc.isEmpty) {
      desc = card.data.description;
    }
    return desc.trim();
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    // Fond
    if (!_canAfford && !_isFlashing) {
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFF4A1A1A)); // Rouge sombre
    } else {
      canvas.drawRRect(rrect, backgroundPaint);
    }
    
    // Bordure
    if (!_canAfford && !_isFlashing) {
      canvas.drawRRect(rrect, Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeWidth = 3);
    } else {
      canvas.drawRRect(rrect, borderPaint);
    }

    // Dessin manuel des textes
    if (!_isFlashing) {
      // Nom
      _namePainter.paint(
        canvas,
        Offset(size.x / 2 - _namePainter.width / 2 + 10, 10),
      );
      // Coût
      _costPainter.paint(canvas, const Offset(8, 6));
      // Description (centrée verticalement et horizontalement)
      _descPainter.paint(
        canvas,
        Offset(
          size.x / 2 - _descPainter.width / 2,
          size.y / 2 + 15 - _descPainter.height / 2,
        ),
      );
      // Usage
      if (card.data.type == CardType.power) {
        _usagePainter.paint(
          canvas,
          Offset(size.x - _usagePainter.width - 8, size.y - _usagePainter.height - 8),
        );
      }
    }

    super.render(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    game.setFocusedCard(this);
    event.continuePropagation = false;
  }

  void _clearEffects() {
    final effects = children.whereType<Effect>().toList();
    if (effects.isNotEmpty) {
      removeAll(effects);
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    
    if (!_canAfford) {
      // Effet de tremblement si le joueur n'a pas assez de mana
      _shakeAnimation();
      return;
    }

    isDragging = true;
    _targetTilt = 0;

    _activeTrail = RibbonTrail(
      priority: priority - 1,
      glowColor: Colors.amber,
      coreColor: Colors.white,
    );
    game.add(_activeTrail!);

    if (game.focusedCard == this) {
      game.setFocusedCard(null);
    }
    if (game.hoveredCard == this) {
      game.setHoveredCard(null);
    }

    _clearEffects();
    priority = 200;

    angle = 0;
    scale = Vector2.all(game.scaleFactor * 0.75 * 1.25);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!isDragging) return;
    
    position += event.canvasDelta;
    _targetTilt = (event.canvasDelta.x * 0.08).clamp(-0.4, 0.4);

    bool isInCancelZone = position.y > game.size.y * 0.8;
    if (isInCancelZone != _isHoveringCancelZone) {
      _isHoveringCancelZone = isInCancelZone;
      _applyCancelZoneFeedback(_isHoveringCancelZone);
    }

    if (card.data.target == CardTarget.singleEnemy) {
      EnemyCard? hoveredEnemy = _isHoveringCancelZone
          ? null
          : _findHoveredEnemy(position);
      game.highlightEnemy(hoveredEnemy);
    }
  }

  void _applyCancelZoneFeedback(bool isCancelling) {
    _clearEffects();
    _isCancelling = isCancelling;
    
    if (isCancelling) {
      add(ScaleEffect.to(Vector2.all(0.9), EffectController(duration: 0.1)));
      backgroundPaint.color = const Color(0xFF2A2A3D).withAlpha(150);
      borderPaint.color = Colors.grey;
    } else {
      add(ScaleEffect.to(Vector2.all(1.25), EffectController(duration: 0.1)));
      backgroundPaint.color = const Color(0xFF2A2A3D);
      borderPaint.color = Colors.blueAccent;
    }
    _updateTextPainters();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!isDragging) return;
    
    isDragging = false;
    _targetTilt = 0;
    game.setFocusedCard(null);
    
    _activeTrail?.stop();
    _activeTrail = null;

    if (_isHoveringCancelZone) {
      _returnToHand();
      game.highlightEnemy(null);
      return;
    }

    EnemyCard? targetedEnemy;
    if (card.data.target == CardTarget.singleEnemy) {
      targetedEnemy = game.highlightedEnemy;
    }

    bool played = game.tryPlayCard(this, targetedEnemy);

    if (!played) {
      _returnToHand();
    }

    game.highlightEnemy(null);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (!isDragging) return;
    
    isDragging = false;
    _targetTilt = 0;
    game.setFocusedCard(null);
    
    _activeTrail?.stop();
    _activeTrail = null;

    _returnToHand();
    game.highlightEnemy(null);
  }

  EnemyCard? _findHoveredEnemy(Vector2 canvasPos) {
    for (var enemy in game.enemyCards) {
      if (enemy.containsPoint(canvasPos)) {
        return enemy;
      }
    }
    return null;
  }

  void _returnToHand() {
    _isHoveringCancelZone = false;
    _isCancelling = false;
    _isFlashing = false;

    backgroundPaint.color = const Color(0xFF2A2A3D);
    borderPaint.color = Colors.blueAccent;
    
    _updateTextPainters();
    _clearEffects();

    add(
      MoveEffect.to(
        originalPosition,
        EffectController(duration: 0.4, curve: Curves.elasticOut),
      ),
    );
    add(
      RotateEffect.to(
        originalAngle,
        EffectController(duration: 0.4, curve: Curves.elasticOut),
      ),
    );
    add(
      ScaleEffect.to(
        Vector2.all(game.scaleFactor * 0.75),
        EffectController(duration: 0.4, curve: Curves.elasticOut),
      ),
    );

    priority = basePriority;
  }

  void _shakeAnimation() {
    add(
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
    isDragging = false;
    priority = 500;

    final animType = card.data.animation ?? 'melee';

    switch (animType) {
      case 'magic':
        _playMagicAnimation(target, onComplete);
        break;
      case 'buff':
        _playBuffAnimation(onComplete);
        break;
      case 'poison':
        _playStatusAnimation(target, Colors.greenAccent, onComplete);
        break;
      case 'fire':
        _playStatusAnimation(target, Colors.orangeAccent, onComplete);
        break;
      case 'ice':
        _playStatusAnimation(target, Colors.lightBlueAccent, onComplete);
        break;
      case 'lightning':
        _playStatusAnimation(target, Colors.yellowAccent, onComplete);
        break;
      case 'melee':
      default:
        _playMeleeAnimation(target, onComplete);
        break;
    }
  }

  void _playStatusAnimation(
    EnemyCard? target,
    Color color,
    VoidCallback onComplete,
  ) {
    final targetPos = target?.position ?? position + Vector2(0, -size.y * 2);

    backgroundPaint.color = color.withAlpha(204);
    borderPaint.color = Colors.white;

    add(
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
              _spawnImpactParticles(
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
    final targetPos = target?.position ?? position + Vector2(0, -size.y * 2);
    final anticipationDir = (position - targetPos).normalized();

    _applyFlashVisual();

    add(
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
              game.add(
                SlashEffect(
                  position: target.position.clone(),
                  size: target.size * 1.5,
                  color: Colors.redAccent,
                ),
              );
              target.shakeAndFlashAnimation();
            }

            _spawnImpactParticles(targetPos, color: Colors.redAccent);
            onComplete();
          },
        ),
      ]),
    );
  }

  void _playMagicAnimation(EnemyCard? target, VoidCallback onComplete) {
    final targetPos = target?.position ?? position + Vector2(0, -size.y * 2);

    backgroundPaint.color = Colors.deepPurpleAccent;
    borderPaint.color = Colors.cyanAccent;

    add(
      SequenceEffect([
        MoveEffect.by(
          Vector2(0, -30),
          EffectController(duration: 0.3, curve: Curves.easeInOut),
        ),
        ScaleEffect.to(
          Vector2.all(game.scaleFactor * 1.1),
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
            _spawnImpactParticles(
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
    backgroundPaint.color = Colors.amber.withAlpha(200);
    borderPaint.color = Colors.white;

    add(
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

  void _applyFlashVisual() {
    _isFlashing = true;
    backgroundPaint.color = Colors.white;
    borderPaint.color = Colors.white;
    _updateTextPainters();
  }

  void _spawnImpactParticles(
    Vector2 impactPos, {
    Color color = Colors.blueAccent,
    int count = 15,
  }) {
    game.add(
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
}

