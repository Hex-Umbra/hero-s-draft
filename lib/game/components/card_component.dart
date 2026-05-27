import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../heros_draft_game.dart';
import '../game_constants.dart';
import 'entities/enemy_card.dart';
import 'visual_effects/ribbon_trail.dart';
import 'widgets/card_text_renderer.dart';
import 'visual_effects/card_animator.dart';

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

  late final CardTextRenderer textRenderer;
  late final CardAnimator animator;

  // État visuel actuel (exposé aux classes d'accompagnement)
  bool isFlashing = false;
  bool isCancelling = false;
  bool isHoveringCancelZone = false;
  bool isPlayed = false;

  bool get _isSelected => game.focusedCard == this;

  @override
  set opacity(double value) {
    if (_opacity == value) return;
    _opacity = value;
    refreshVisuals();
  }

  bool get canAfford {
    if (!isLoaded || !isMounted) return true;
    final currentMana = game.currentRunState?.heroStats.currentMana ?? 0;
    return currentMana >= card.currentCost;
  }

  Color getTypeColor() {
    if (!canAfford && !isFlashing) return Colors.redAccent;
    if (isCancelling) return Colors.grey;
    
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

  Color getBackgroundColor() {
    return isCancelling ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A3D);
  }

  IconData getTypeIconData() {
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

  String get activeLocale {
    final context = game.buildContext;
    if (context != null) {
      return Localizations.localeOf(context).languageCode;
    }
    return 'fr'; // Langue par défaut en secours
  }

  String getTranslation(String Function(AppLocalizations) select, {String fallback = ''}) {
    final context = game.buildContext;
    if (context != null) {
      final localizations = AppLocalizations.of(context);
      if (localizations != null) {
        return select(localizations);
      }
    }
    return fallback;
  }

  String getTypeLabel() {
    switch (card.data.type) {
      case CardType.attack:
        return getTranslation((l) => l.cardTypeAttack, fallback: 'Attaque');
      case CardType.skill:
        return getTranslation((l) => l.cardTypeSkill, fallback: 'Compétence');
      case CardType.power:
        return getTranslation((l) => l.cardTypePower, fallback: 'Pouvoir');
      case CardType.status:
        return getTranslation((l) => l.cardTypeStatus, fallback: 'Statut');
    }
  }

  Color getRarityColor() {
    final r = card.data.rarity.name.toLowerCase();
    if (r.contains('legendary')) return Colors.orangeAccent;
    if (r.contains('epic')) return Colors.purpleAccent;
    if (r.contains('rare')) return Colors.blueAccent;
    if (r.contains('uncommon')) return Colors.greenAccent;
    return Colors.white70;
  }

  void refreshVisuals() {
    textRenderer.refreshVisuals(opacity, isFlashing, isCancelling);
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    if (isPlayed) return;
    game.onShowTooltip(card.data.getName(activeLocale), _buildDetailedDescription());
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
    String desc = '${card.data.getDescription(activeLocale)}\n\n';
    if (card.data.type == CardType.power || card.data.isExhaust) {
      desc += '${getTranslation((l) => l.exhaustWarning, fallback: '⚠️ USAGE UNIQUE (Épuisement)')}\n\n';
    }
    for (var effect in card.data.effects) {
      final scaledValue = (effect.value * (1 + (card.level - 1) * 0.5)).round();
      if (effect.type == 'damage') {
        desc += '• ${getTranslation((l) => l.cardDescDamage(scaledValue), fallback: 'Dégâts: $scaledValue')}\n';
      }
      if (effect.type == 'heal') {
        desc += '• ${getTranslation((l) => l.cardDescHeal(scaledValue), fallback: 'Soin: $scaledValue')}\n';
      }
      if (effect.type == 'armor') {
        desc += '• ${getTranslation((l) => l.cardDescArmor(scaledValue), fallback: 'Armure: $scaledValue')}\n';
      }
      if (effect.type == 'draw') {
        desc += '• ${getTranslation((l) => l.cardDescDraw(scaledValue), fallback: 'Pioche: $scaledValue cartes')}\n';
      }
    }
    return desc.trim();
  }

  Vector2 originalPosition = Vector2.zero();
  double originalAngle = 0;
  int basePriority = 10;

  bool isDragging = false;
  double _targetTilt = 0;
  RibbonTrail? _activeTrail;

  @override
  bool isHovered = false;

  // Paramètres visuels
  static const double cardWidth = GameConstants.cardWidth;
  static const double cardHeight = GameConstants.cardHeight;

  final Paint borderPaint = Paint()
    ..color = Colors.blueAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  CardComponent(this.card) : super(size: Vector2(cardWidth, cardHeight)) {
    anchor = Anchor.center;
    textRenderer = CardTextRenderer(this);
    animator = CardAnimator(this);
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
      angle += (_targetTilt - angle) * 15 * dt;
      _targetTilt += (0 - _targetTilt) * 5 * dt;

      animator.spawnTrailParticles();
      _activeTrail?.addPoint(position);
    }
  }

  @override
  Future<void> onLoad() async {
    scale = Vector2.all(game.scaleFactor * 0.88);
    refreshVisuals();
  }

  Vector2 _lastSize = Vector2.zero();

  @override
  void onGameResize(Vector2 size) {
    if (_lastSize == size) return;
    _lastSize = size.clone();
    super.onGameResize(size);

    if (!isDragging && game.focusedCard != this) {
      scale = Vector2.all(game.scaleFactor * 0.88);
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    final typeColor = getTypeColor();
    final bgColor = getBackgroundColor();

    // Fond avec Gradient
    final Paint bgPaint = Paint();
    if (isFlashing) {
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

    // Bordure
    final Paint bPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isSelected ? 3.0 : 2.0
      ..color = _isSelected ? Colors.white : typeColor;

    if (isFlashing) bPaint.color = Colors.white;
    canvas.drawRRect(rrect, bPaint);

    // Halo de sélection (Glow)
    if (_isSelected && !isFlashing) {
      final Paint glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..color = typeColor.withAlpha(150)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
      canvas.drawRRect(rrect, glowPaint);
    }

    // Dessin manuel des textes délégué
    if (!isFlashing) {
      textRenderer.render(canvas, size);
    }

    super.render(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isPlayed) return;
    super.onTapDown(event);
    if (game.focusedCard == this) {
      game.setFocusedCard(null);
    } else {
      game.setFocusedCard(this);
    }
    refreshVisuals();
    event.continuePropagation = false;
  }

  void clearEffects() {
    final effects = children.whereType<Effect>().toList();
    if (effects.isNotEmpty) {
      removeAll(effects);
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (isPlayed) return;
    super.onDragStart(event);

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

    clearEffects();
    priority = 200;

    angle = 0;
    scale = Vector2.all(game.scaleFactor * 0.88 * 1.25);
    refreshVisuals();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isPlayed) return;
    if (!isDragging) return;
    
    position += event.canvasDelta;
    _targetTilt = (event.canvasDelta.x * 0.08).clamp(-0.4, 0.4);

    bool isInCancelZone = position.y > game.size.y * 0.68;
    if (isInCancelZone != isHoveringCancelZone) {
      isHoveringCancelZone = isInCancelZone;
      _applyCancelZoneFeedback(isHoveringCancelZone);
    }

    if (card.data.target == CardTarget.singleEnemy) {
      EnemyCard? hoveredEnemy = isHoveringCancelZone
          ? null
          : _findHoveredEnemy(position);
      game.highlightEnemy(hoveredEnemy);
    }
  }

  void _applyCancelZoneFeedback(bool cancelling) {
    clearEffects();
    isCancelling = cancelling;
    
    if (cancelling) {
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

    if (isHoveringCancelZone) {
      animator.returnToHand();
      game.highlightEnemy(null);
      return;
    }

    if (!canAfford) {
      animator.shakeAnimation();
      animator.returnToHand();
      game.highlightEnemy(null);
      return;
    }

    EnemyCard? targetedEnemy;
    if (card.data.target == CardTarget.singleEnemy) {
      targetedEnemy = game.highlightedEnemy;
    }

    bool played = game.tryPlayCard(this, targetedEnemy);

    if (!played) {
      animator.returnToHand();
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

    animator.returnToHand();
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

  void shakeAnimation() {
    animator.shakeAnimation();
  }

  void playAnimation(EnemyCard? target, {required VoidCallback onComplete}) {
    animator.playAnimation(target, onComplete: onComplete);
  }

  void applyFlashVisual() {
    isFlashing = true;
    borderPaint.color = Colors.white;
    refreshVisuals();
  }
}
