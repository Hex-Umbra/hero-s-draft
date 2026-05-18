import 'dart:math';
import 'dart:ui' as ui;
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
  late TextPainter _descPainter;
  late TextPainter _usagePainter;
  late TextPainter _typePainter;
  late TextPainter _bgIconPainter;
  late TextPainter _rarityPainter;
  TextPainter? _manaPainter;

  // État visuel actuel
  bool _isFlashing = false;
  bool _isCancelling = false;
  bool isPlayed = false;

  bool get _isSelected => game.focusedCard == this;

  @override
  set opacity(double value) {
    if (_opacity == value) return;
    _opacity = value;
    refreshVisuals();
  }

  bool get _canAfford {
    if (!isLoaded || !isMounted) return true;
    final currentMana = game.currentRunState?.heroStats.currentMana ?? 0;
    return currentMana >= card.currentCost;
  }

  Color _getTypeColor() {
    if (!_canAfford && !_isFlashing) return Colors.redAccent;
    if (_isCancelling) return Colors.grey;
    
    switch (card.data.type) {
      case CardType.attack:
        return Colors.redAccent;
      case CardType.skill:
        return Colors.blueAccent;
      case CardType.power:
        return Colors.amber;
      case CardType.status:
        return Colors.blueGrey;
    }
  }

  Color _getBackgroundColor() {
    return _isCancelling ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A3D);
  }

  IconData _getTypeIconData() {
    switch (card.data.type) {
      case CardType.attack:
        return Icons.hardware_rounded;
      case CardType.skill:
        return Icons.shield_rounded;
      case CardType.power:
        return Icons.auto_fix_high_rounded;
      case CardType.status:
        return Icons.warning_rounded;
    }
  }

  String _getTypeLabel() {
    switch (card.data.type) {
      case CardType.attack:
        return 'Attaque';
      case CardType.skill:
        return 'Compétence';
      case CardType.power:
        return 'Pouvoir';
      case CardType.status:
        return 'Statut';
    }
  }

  Color _getRarityColor() {
    final r = card.data.rarity.name.toLowerCase();
    if (r.contains('legendary')) return Colors.orangeAccent;
    if (r.contains('epic')) return Colors.purpleAccent;
    if (r.contains('rare')) return Colors.blueAccent;
    if (r.contains('uncommon')) return Colors.greenAccent;
    return Colors.white70;
  }

  void refreshVisuals() {
    final int alpha = (_opacity * 255).toInt();
    final typeColor = _getTypeColor();
    
    // Configurer le style de base selon l'état
    Color nameColor = _isFlashing ? Colors.transparent : Colors.white.withAlpha(alpha);
    Color descColor = _isFlashing ? Colors.transparent : Colors.white.withAlpha(alpha);
    Color usageColor = _isFlashing ? Colors.transparent : Colors.white.withAlpha(alpha);
    Color typeLabelColor = _isFlashing ? Colors.transparent : typeColor.withAlpha((alpha * 0.7).toInt());
    Color rarityColor = _isFlashing ? Colors.transparent : _getRarityColor().withAlpha(alpha);
    Color manaColor = _isFlashing ? Colors.transparent : Colors.cyanAccent.withAlpha(alpha);

    if (_isCancelling) {
      final cancelAlpha = (alpha * 0.6).toInt();
      nameColor = nameColor.withAlpha(cancelAlpha);
      descColor = descColor.withAlpha(cancelAlpha);
      typeLabelColor = typeLabelColor.withAlpha(cancelAlpha);
      rarityColor = rarityColor.withAlpha(cancelAlpha);
      manaColor = manaColor.withAlpha(cancelAlpha);
    }

    _namePainter = TextPainter(
      text: TextSpan(
        text: card.data.name.toUpperCase(),
        style: TextStyle(
          color: nameColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.x - 24);

    if (card.currentCost > 0) {
      final manaString = String.fromCharCode(Icons.diamond_rounded.codePoint);
      String fullManaString = '';
      for (int i = 0; i < card.currentCost; i++) {
        fullManaString += manaString;
      }
      
      _manaPainter = TextPainter(
        text: TextSpan(
          text: fullManaString,
          style: TextStyle(
            color: manaColor,
            fontSize: 16,
            fontFamily: Icons.diamond_rounded.fontFamily,
            package: Icons.diamond_rounded.fontPackage,
            letterSpacing: 2.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    } else {
      _manaPainter = null;
    }

    _descPainter = TextPainter(
      text: TextSpan(
        text: _buildDescription(),
        style: TextStyle(
          color: descColor,
          fontSize: 10,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.x - 20);

    _usagePainter = TextPainter(
      text: TextSpan(
        text: 'USAGE UNIQUE',
        style: TextStyle(
          color: usageColor,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _typePainter = TextPainter(
      text: TextSpan(
        text: _getTypeLabel().toUpperCase(),
        style: TextStyle(
          color: typeLabelColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    _rarityPainter = TextPainter(
      text: TextSpan(
        text: card.data.rarity.name.toUpperCase(),
        style: TextStyle(
          color: rarityColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final iconData = _getTypeIconData();
    _bgIconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          color: Colors.white.withAlpha((alpha * 0.05).toInt()),
          fontSize: 80,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    if (isPlayed) return;
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

  final Paint borderPaint = Paint()
    ..color = Colors.blueAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  CardComponent(this.card) : super(size: Vector2(cardWidth, cardHeight)) {
    anchor = Anchor.center;
  }

  @override
  void onHoverEnter() {
    if (isPlayed) return;
    if (isDragging) return;
    game.setHoveredCard(this);
  }

  @override
  void onHoverExit() {
    if (isPlayed) return;
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
    refreshVisuals();
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
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    final typeColor = _getTypeColor();
    final bgColor = _getBackgroundColor();

    // Fond avec Gradient
    final Paint bgPaint = Paint();
    if (_isFlashing) {
      bgPaint.color = Colors.white;
    } else {
      bgPaint.shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.y),
        [
          bgColor,
          bgColor.withAlpha(200),
        ],
      );
    }
    canvas.drawRRect(rrect, bgPaint);

    // Icône de fond subtile
    if (!_isFlashing) {
      _bgIconPainter.paint(
        canvas,
        Offset(size.x / 2 - _bgIconPainter.width / 2, size.y / 2 - _bgIconPainter.height / 2),
      );
    }

    // Bordure
    final Paint bPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isSelected ? 3.0 : 2.0
      ..color = _isSelected ? Colors.white : typeColor;

    if (_isFlashing) bPaint.color = Colors.white;
    canvas.drawRRect(rrect, bPaint);

    // Halo de sélection (Glow)
    if (_isSelected && !_isFlashing) {
      final Paint glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = typeColor.withAlpha(150)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
      canvas.drawRRect(rrect, glowPaint);
    }

    // Dessin manuel des textes (Coordonnées Fixes)
    if (!_isFlashing) {
      // Titre (centré, fixe en haut)
      _namePainter.paint(
        canvas,
        Offset(size.x / 2 - _namePainter.width / 2, 14),
      );

      // Ligne séparatrice (fixe)
      final linePaint = Paint()
        ..color = typeColor.withAlpha(100)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(size.x / 2 - 20, 32),
        Offset(size.x / 2 + 20, 32),
        linePaint,
      );

      // Rareté (fixe sous la ligne)
      _rarityPainter.paint(
        canvas,
        Offset(size.x / 2 - _rarityPainter.width / 2, 42),
      );

      // Badge Usage Unique (fixe)
      if (card.data.isExhaust || card.data.type == CardType.power) {
        final badgeWidth = _usagePainter.width + 12;
        final badgeRect = Rect.fromCenter(
          center: Offset(size.x / 2, 62),
          width: badgeWidth,
          height: 14,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
          Paint()..color = Colors.redAccent.withAlpha(200),
        );
        _usagePainter.paint(
          canvas,
          Offset(size.x / 2 - _usagePainter.width / 2, 62 - _usagePainter.height / 2),
        );
      }

      // Description (centrée parfaitement sur la carte)
      _descPainter.paint(
        canvas,
        Offset(
          size.x / 2 - _descPainter.width / 2,
          (size.y / 2) - _descPainter.height / 2 + 5, // Légèrement décalée vers le bas pour l'équilibre
        ),
      );

      // Cristaux de Mana (En bas au centre)
      if (_manaPainter != null) {
        _manaPainter!.paint(
          canvas,
          Offset(size.x / 2 - _manaPainter!.width / 2, 150),
        );
      }

      // Type Label (tout en bas)
      _typePainter.paint(
        canvas,
        Offset(size.x / 2 - _typePainter.width / 2, 175),
      );
    }

    super.render(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isPlayed) return;
    super.onTapDown(event);
    game.setFocusedCard(this);
    refreshVisuals(); // Refresh painters for selection
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
    if (isPlayed) return;
    super.onDragStart(event);
    
    if (!_canAfford) {
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
    refreshVisuals();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isPlayed) return;
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
    } else {
      add(ScaleEffect.to(Vector2.all(1.25), EffectController(duration: 0.1)));
    }
    refreshVisuals();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    if (isPlayed) return;
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
    if (isPlayed) return;
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

    borderPaint.color = Colors.blueAccent;
    
    refreshVisuals();
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
    isPlayed = true;
    isDragging = false;
    priority = 500;

    _clearEffects();

    final animType = card.data.animation ?? 'melee';

    void wrappedOnComplete() {
      if (card.data.isExhaust) {
        _spawnExhaustParticles(position);
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
    final targetPos = target?.position ?? position + Vector2(0, -size.y * 2);

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
    borderPaint.color = Colors.white;
    refreshVisuals();
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

  void _spawnExhaustParticles(Vector2 exhaustPos) {
    game.add(
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

