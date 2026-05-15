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

  @override
  set opacity(double value) {
    _opacity = value;
    backgroundPaint.color = backgroundPaint.color.withValues(alpha: value);
    borderPaint.color = borderPaint.color.withValues(alpha: value);

    // Appliquer aux textes (si initialisés)
    try {
      final nameStyle = (nameText.textRenderer as TextPaint).style;
      nameText.textRenderer =
          TextPaint(style: nameStyle.copyWith(color: nameStyle.color?.withValues(alpha: value)));
          
      final costStyle = (costText.textRenderer as TextPaint).style;
      costText.textRenderer =
          TextPaint(style: costStyle.copyWith(color: costStyle.color?.withValues(alpha: value)));
          
      final descStyle = (descriptionText.textRenderer as TextPaint).style;
      descriptionText.textRenderer =
          TextPaint(style: descStyle.copyWith(color: descStyle.color?.withValues(alpha: value)));
          
      final usageStyle = (usageText.textRenderer as TextPaint).style;
      usageText.textRenderer =
          TextPaint(style: usageStyle.copyWith(color: usageStyle.color?.withValues(alpha: value)));
    } catch (_) {
      // Ignorer si les textes ne sont pas encore chargés
    }
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
    if (card.data.type == CardType.power) {
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

  late TextComponent nameText;
  late TextComponent costText;
  late TextComponent descriptionText;
  late TextComponent usageText;

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

      // TODO: Audio Hook - sfx_card_slide (Jouer un son de glissement si la vitesse est élevée)

      // Génération de la queue de particules améliorée (Blanche + Arc-en-ciel)
      _spawnTrailParticles();
      // Mise à jour du ruban
      _activeTrail?.addPoint(position);
    }
  }

  double _particleHue = 0;

  void _spawnTrailParticles() {
    // On fait défiler la teinte (0-360) pour l'effet arc-en-ciel
    _particleHue = (_particleHue + 15) % 360;
    final rainbowColor =
        HSVColor.fromAHSV(1.0, _particleHue, 0.8, 1.0).toColor();

    // Vecteur de gravité (vers le bas)
    final gravity = Vector2(0, 150);

    // Création d'un mélange de particules avec gravité (AcceleratedParticle)
    game.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 3,
          lifespan: 0.6, // Un peu plus long pour voir l'effet de chute
          generator: (i) {
            // Vitesse initiale aléatoire pour que les particules "sortent" de la carte
            final initialVelocity = Vector2(
              (rand.nextDouble() - 0.5) * 50,
              (rand.nextDouble() - 0.5) * 50,
            );

            if (i == 0) {
              // Particule blanche
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
              // Particules arc-en-ciel
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
    // Appliquer l'échelle initiale (Réduite pour la main)
    scale = Vector2.all(game.scaleFactor * 0.75);

    // Nom de la carte
    nameText = TextComponent(
      text: card.data.name,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(
        size.x / 2 + 12,
        12,
      ), // Décalé vers la droite pour éviter le mana
      anchor: Anchor.topCenter,
    );
    add(nameText);

    // Coût en mana
    costText = TextComponent(
      text: '${card.currentCost}',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.lightBlueAccent,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(16, 16),
      anchor: Anchor.center,
    );
    add(costText);

    // Description (simplifiée pour l'instant)
    descriptionText = TextComponent(
      text: _buildDescription(),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
      position: Vector2(size.x / 2, size.y / 2 + 15),
      anchor: Anchor.center,
      size: Vector2(size.x - 24, size.y / 2),
    );
    add(descriptionText);

    // Nombre d'utilisations (Usage Unique pour les Pouvoirs)
    final isPower = card.data.type == CardType.power;
    usageText = TextComponent(
      text: isPower ? '1/1' : '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.redAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(size.x - 12, size.y - 12),
      anchor: Anchor.bottomRight,
    );
    add(usageText);
  }

  Vector2 _lastSize = Vector2.zero();

  @override
  void onGameResize(Vector2 size) {
    if (_lastSize == size) return;
    _lastSize = size.clone();
    super.onGameResize(size);

    // Mise à jour de l'échelle si on n'est pas en train de drag ou focus
    if (!isDragging && game.focusedCard != this) {
      scale = Vector2.all(game.scaleFactor * 0.75);
    }
  }

  String _buildDescription() {
    String desc = '';
    // Récupérer l'attaque du héros via le jeu pour l'affichage dynamique
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
      // Ajout basique de retour à la ligne pour les descriptions longues sans effets
      if (desc.length > 20) {
        int spaceIdx = desc.indexOf(' ', 15);
        if (spaceIdx != -1 && spaceIdx < desc.length - 1) {
          desc =
              '${desc.substring(0, spaceIdx)}\n${desc.substring(spaceIdx + 1)}';
        }
      }
    }
    return desc;
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    // Fond
    canvas.drawRRect(rrect, backgroundPaint);
    // Bordure
    canvas.drawRRect(rrect, borderPaint);

    super.render(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    game.setFocusedCard(this);
    event.continuePropagation =
        false; // Empêche l'événement de se propager au jeu (qui annulerait le focus)
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
    isDragging = true;
    _targetTilt = 0;

    // Initialisation du ruban
    _activeTrail = RibbonTrail(
      priority: priority - 1,
      glowColor: Colors.amber,
      coreColor: Colors.white,
    );
    game.add(_activeTrail!);

    // Nettoie proprement le focus/hover au niveau du jeu,
    // (le flag isDragging = true empêchera setFocusedCard d'ajouter une animation de retour)
    if (game.focusedCard == this) {
      game.setFocusedCard(null);
    }
    if (game.hoveredCard == this) {
      game.setHoveredCard(null);
    }

    _clearEffects();
    priority = 200;

    // La carte se remet droite et s'agrandit pour le drag
    angle = 0;
    scale = Vector2.all(game.scaleFactor * 0.75 * 1.25);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // Utiliser canvasDelta évite les distorsions si l'échelle (scale) est modifiée
    position += event.canvasDelta;

    // Calcul du tilt dynamique basé sur la vitesse horizontale
    // On limite l'inclinaison pour ne pas faire de tours complets
    _targetTilt = (event.canvasDelta.x * 0.08).clamp(-0.4, 0.4);

    // Feedback visuel de zone de sécurité (annulation)
    // On utilise désormais 80% de la hauteur de l'écran comme seuil
    bool isInCancelZone = position.y > game.size.y * 0.8;
    if (isInCancelZone != _isHoveringCancelZone) {
      _isHoveringCancelZone = isInCancelZone;
      _applyCancelZoneFeedback(_isHoveringCancelZone);
    }

    // Gestion du ciblage (Arrow) - Uniquement si on n'est pas en zone d'annulation
    if (card.data.target == CardTarget.singleEnemy) {
      EnemyCard? hoveredEnemy = _isHoveringCancelZone
          ? null
          : _findHoveredEnemy(position);
      game.highlightEnemy(hoveredEnemy);
    }
  }

  void _applyCancelZoneFeedback(bool isCancelling) {
    _clearEffects();
    if (isCancelling) {
      // Effet d'annulation : plus petit, transparent, bordure grise
      add(ScaleEffect.to(Vector2.all(0.9), EffectController(duration: 0.1)));
      backgroundPaint.color = const Color(0xFF2A2A3D).withAlpha(150);
      borderPaint.color = Colors.grey;

      final nameStyle = (nameText.textRenderer as TextPaint).style;
      final costStyle = (costText.textRenderer as TextPaint).style;
      final descStyle = (descriptionText.textRenderer as TextPaint).style;

      nameText.textRenderer = TextPaint(
        style: nameStyle.copyWith(color: Colors.white.withAlpha(150)),
      );
      costText.textRenderer = TextPaint(
        style: costStyle.copyWith(color: Colors.lightBlueAccent.withAlpha(150)),
      );
      descriptionText.textRenderer = TextPaint(
        style: descStyle.copyWith(color: Colors.white70.withAlpha(150)),
      );
    } else {
      // Effet actif : grand, opaque, bordure bleue
      add(ScaleEffect.to(Vector2.all(1.25), EffectController(duration: 0.1)));
      backgroundPaint.color = const Color(0xFF2A2A3D);
      borderPaint.color = Colors.blueAccent;

      final nameStyle = (nameText.textRenderer as TextPaint).style;
      final costStyle = (costText.textRenderer as TextPaint).style;
      final descStyle = (descriptionText.textRenderer as TextPaint).style;

      nameText.textRenderer = TextPaint(
        style: nameStyle.copyWith(color: Colors.white),
      );
      costText.textRenderer = TextPaint(
        style: costStyle.copyWith(color: Colors.lightBlueAccent),
      );
      descriptionText.textRenderer = TextPaint(
        style: descStyle.copyWith(color: Colors.white70),
      );
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    _targetTilt = 0;
    game.setFocusedCard(null); // On enlève le focus systématiquement
    
    // Arrêt du ruban
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
    isDragging = false;
    _targetTilt = 0;
    game.setFocusedCard(null);
    
    // Arrêt du ruban
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

    // Reset visual state
    backgroundPaint.color = const Color(0xFF2A2A3D);
    borderPaint.color = Colors.blueAccent;
    nameText.textRenderer = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    costText.textRenderer = TextPaint(
      style: const TextStyle(
        color: Colors.lightBlueAccent,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
    descriptionText.textRenderer = TextPaint(
      style: const TextStyle(color: Colors.white70, fontSize: 14),
    );

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

  void playAnimation(EnemyCard? target, {required VoidCallback onComplete}) {
    isDragging = false;
    priority = 500; // Au-dessus de tout le monde

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

    // Effet visuel thématique
    backgroundPaint.color = color.withValues(alpha: 0.8);
    borderPaint.color = Colors.white;

    add(
      SequenceEffect([
        // 1. Ascension et rotation (Chargement magique)
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
        // 2. Dash rapide vers la cible
        MoveEffect.to(
          targetPos,
          EffectController(duration: 0.2, curve: Curves.easeIn),
        ),
        // 3. Explosion thématique et disparition
        ScaleEffect.to(
          Vector2.all(0.0),
          EffectController(duration: 0.1),
          onComplete: () {
            if (target != null) {
              // Particules thématiques denses
              _spawnImpactParticles(
                targetPos,
                color: color,
                count: 30,
              );
              // Réaction de l'ennemi
              target.shakeAndFlashAnimation();
            }
            onComplete();
          },
        ),
      ]),
    );
  }

  void _playMeleeAnimation(EnemyCard? target, VoidCallback onComplete) {
    // Direction de l'attaque
    final targetPos = target?.position ?? position + Vector2(0, -size.y * 2);
    final anticipationDir = (position - targetPos).normalized();

    // Flash blanc
    _applyFlashVisual();

    add(
      SequenceEffect([
        // 1. Anticipation (Recule légèrement)
        MoveEffect.by(
          anticipationDir * 40,
          EffectController(duration: 0.1, curve: Curves.easeOut),
        ),
        // 2. Dash vers la cible
        MoveEffect.to(
          targetPos,
          EffectController(duration: 0.15, curve: Curves.easeIn),
        ),
        // 3. Impact et disparition
        ScaleEffect.to(
          Vector2.all(0.0),
          EffectController(duration: 0.05),
          onComplete: () {
            // Effet de Slash sur l'ennemi
            if (target != null) {
              game.add(
                SlashEffect(
                  position: target.position.clone(),
                  size: target.size * 1.5, // Plus grand que l'ennemi pour le style
                  color: Colors.redAccent,
                ),
              );
              // Faire trembler l'ennemi
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

    // Effet visuel : Teinte violette/magique
    backgroundPaint.color = Colors.deepPurpleAccent;
    borderPaint.color = Colors.cyanAccent;

    add(
      SequenceEffect([
        // 1. Lévitation et vibration
        MoveEffect.by(
          Vector2(0, -30),
          EffectController(duration: 0.3, curve: Curves.easeInOut),
        ),
        // 2. Pulsation (Chargement)
        ScaleEffect.to(
          Vector2.all(game.scaleFactor * 1.1),
          EffectController(
            duration: 0.4,
            alternate: true,
            curve: Curves.elasticIn,
          ),
        ),
        // 3. Explosion magique et disparition
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
    // Effet visuel : Teinte dorée
    backgroundPaint.color = Colors.amber.withAlpha(200);
    borderPaint.color = Colors.white;

    add(
      SequenceEffect([
        // 1. Montée douce (Élévation spirituelle)
        MoveEffect.by(
          Vector2(0, -100),
          EffectController(duration: 0.6, curve: Curves.easeOut),
        ),
        // 2. Fondu et disparition
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
    backgroundPaint.color = Colors.white;
    borderPaint.color = Colors.white;
    nameText.textRenderer = TextPaint(
      style: const TextStyle(color: Colors.transparent),
    );
    costText.textRenderer = TextPaint(
      style: const TextStyle(color: Colors.transparent),
    );
    descriptionText.textRenderer = TextPaint(
      style: const TextStyle(color: Colors.transparent),
    );
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
