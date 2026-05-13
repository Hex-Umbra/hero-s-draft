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

class CardComponent extends PositionComponent
    with
        DragCallbacks,
        TapCallbacks,
        HoverCallbacks,
        HasGameReference<HerosDraftGame> {
  final CardInstance card;

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
    for (var effect in card.data.effects) {
      if (effect.type == 'damage') desc += '• Dégâts: ${effect.value}\n';
      if (effect.type == 'heal') desc += '• Soin: ${effect.value}\n';
      if (effect.type == 'armor') desc += '• Armure: ${effect.value}\n';
      if (effect.type == 'draw') desc += '• Pioche: ${effect.value} cartes\n';
    }
    return desc.trim();
  }

  Vector2 originalPosition = Vector2.zero();
  double originalAngle = 0;
  int basePriority = 10;

  bool isDragging = false;
  double _targetTilt = 0;
  bool _isHoveringCancelZone = false;

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

      // Génération de la queue de particules arc-en-ciel
      _spawnRainbowParticle();
    }
  }

  double _particleHue = 0;

  void _spawnRainbowParticle() {
    // On fait défiler la teinte (0-360) pour l'effet arc-en-ciel
    _particleHue = (_particleHue + 10) % 360;
    final color = HSVColor.fromAHSV(1.0, _particleHue, 0.8, 1.0).toColor();

    // Création d'une particule qui bouge légèrement et rétrécit
    game.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 2,
          lifespan: 0.4,
          generator: (i) => MovingParticle(
            curve: Curves.easeOut,
            // Vitesse aléatoire pour l'éparpillement
            from: position.clone(),
            to:
                position +
                Vector2(
                  (rand.nextDouble() - 0.5) * 40,
                  (rand.nextDouble() - 0.5) * 40,
                ),
            child: ScaledParticle(
              scale: 1.0,
              // Une petite étincelle (cercle de rayon 2)
              // Le cercle reçoit directement le Paint avec la couleur arc-en-ciel
              child: CircleParticle(radius: 2, paint: Paint()..color = color),
            ),
          ),
        ),
      )..priority = priority - 1, // Juste derrière la carte
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
    for (var effect in card.data.effects) {
      if (effect.type == 'damage') desc += 'Inflige ${effect.value} dégâts.\n';
      if (effect.type == 'heal') desc += 'Soigne ${effect.value} PV.\n';
      if (effect.type == 'armor') desc += 'Donne ${effect.value} Armure.\n';
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

    // Direction de l'attaque
    final targetPos = target?.position ?? position + Vector2(0, -size.y * 2);
    final anticipationDir = (position - targetPos).normalized();

    // Flash blanc (on change les paints)
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
            _spawnImpactParticles(targetPos);
            onComplete();
          },
        ),
      ]),
    );
  }

  void _spawnImpactParticles(Vector2 impactPos) {
    // Éclat de particules de la couleur de la bordure (bleu par défaut)
    final color = Colors.blueAccent;

    game.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 15,
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
