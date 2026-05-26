import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import '../../../data/models/entity_stats.dart';
import '../../../models/data/enemy_data.dart';
import '../../../models/enemy_intent.dart';
import '../../../models/status_effect.dart';
import '../../../models/enemy_instance.dart';
import '../floating_text.dart';
import '../effect_icon.dart';
import 'stat_badge.dart';
import 'status_indicator.dart';
import '../../heros_draft_game.dart';

class EnemyCard extends PositionComponent
    with TapCallbacks, HasGameReference<HerosDraftGame>, HasPaint {
  EnemyInstance instance;
  final void Function(EnemyCard) onTapEnemy;

  late final RectangleComponent borderInfo;
  late final StatBadge hpBadge;
  late final SpriteComponent sprite;
  late final StatusIndicator buffIndicator;
  late final StatusIndicator debuffIndicator;

  String get id => instance.id;
  EnemyData get data => instance.data;
  EntityStats get stats => instance.stats;
  EnemyIntent? get currentIntent => instance.currentIntent;
  EnemyIntent? get effectiveIntent => instance.effectiveIntent;
  bool get isBoss => instance.isBoss;

  bool isSelected = false;

  EnemyCard({
    required this.instance,
    required this.onTapEnemy,
  }) : super(size: Vector2(100, 140));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    // Appliquer l'échelle initiale (Agrandie pour le terrain et Boss proportionnel)
    scale = Vector2.all(game.scaleFactor * 1.45 * (isBoss ? 1.25 : 1.0));

    String spriteName = data.spritePath;
    if (spriteName.isEmpty) spriteName = 'enemy_goblin.png';

    // Chargement asynchrone robuste (lit le cache si déjà chargé, ou charge depuis les assets sinon)
    final image = await game.images.load(spriteName);

    // Préserver le ratio d'aspect original de l'image (type BoxFit.contain)
    final double imgWidth = image.width.toDouble();
    final double imgHeight = image.height.toDouble();
    final double imgRatio = imgWidth / imgHeight;
    final double cardRatio = size.x / size.y; // Ratio de la carte (100 / 140 = 0.714)

    Vector2 spriteSize;
    Vector2 spritePosition;

    if (imgRatio > cardRatio) {
      // L'image est plus large/carrée que le ratio de la carte (ex. le slime 320x320) -> Ajuster sur la largeur
      final double width = size.x;
      final double height = size.x / imgRatio;
      spriteSize = Vector2(width, height);
      spritePosition = Vector2(0, (size.y - height) / 2); // Centrer verticalement
    } else {
      // L'image est plus élancée/haute que le ratio de la carte -> Ajuster sur la hauteur
      final double height = size.y;
      final double width = size.y * imgRatio;
      spriteSize = Vector2(width, height);
      spritePosition = Vector2((size.x - width) / 2, 0); // Centrer horizontalement
    }

    sprite = SpriteComponent(
      sprite: Sprite(image),
      size: spriteSize,
      position: spritePosition,
    );
    add(sprite);

    borderInfo = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    add(borderInfo);

    hpBadge = StatBadge(
      type: StatType.hp,
      value: '${stats.currentPv}/${stats.maxPv}',
      isCircle: false,
      fillPercentage: stats.maxPv > 0 ? stats.currentPv / stats.maxPv : 1.0,
      attackValue: stats.effectiveAttaque,
      armorValue: stats.armure,
      armorPercentage: stats.maxPv > 0 ? stats.armure / stats.maxPv : 0.0,
    );
    hpBadge.position = Vector2(size.x / 2, -12); // Centré légèrement au-dessus de la carte
    add(hpBadge);

    // Positionner les buffs (à gauche) et les debuffs (à droite)
    buffIndicator = StatusIndicator(
      statuses: stats.statuses.where((s) => s.type == StatusType.buff).toList(),
      position: Vector2(-36, 10),
    );
    add(buffIndicator);

    debuffIndicator = StatusIndicator(
      statuses: stats.statuses.where((s) => s.type == StatusType.debuff).toList(),
      position: Vector2(size.x + 4, 10),
    );
    add(debuffIndicator);

    _refreshBadges();

    // Apply visual states now that borderInfo is initialized
    setSelection(isSelected);
    if (_isHighlighted) {
      _isHighlighted = false;
      setHighlight(true);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Mettre à jour l'échelle lors du redimensionnement (Agrandie pour le terrain et Boss proportionnel)
    scale = Vector2.all(game.scaleFactor * 1.45 * (isBoss ? 1.25 : 1.0));
  }

  void _refreshBadges() {
    hpBadge.updateHpValues(
      '${stats.currentPv}/${stats.maxPv}',
      stats.maxPv > 0 ? stats.currentPv / stats.maxPv : 0.0,
      stats.effectiveAttaque,
      stats.armure,
      armorPercentage: stats.maxPv > 0 ? stats.armure / stats.maxPv : 0.0,
      tooltipTitle: 'STATS DE L\'ENNEMI',
      tooltipDescription: 'Santé : ${stats.currentPv}/${stats.maxPv} PV.\nAttaque : ${stats.effectiveAttaque}.\nArmure : ${stats.armure}.',
    );
  }

  void updateStats(EnemyInstance newInstance) {
    final oldStats = stats;
    final newStats = newInstance.stats;

    if (newStats.armure < oldStats.armure) {
      _spawnFloatingText(
        '-${oldStats.armure - newStats.armure}',
        Colors.blue,
        Vector2(size.x / 2, size.y - 20),
      );
    }
    if (newStats.currentPv < oldStats.currentPv) {
      _spawnFloatingText(
        '-${oldStats.currentPv - newStats.currentPv}',
        Colors.red,
        Vector2(size.x / 2, size.y),
      );
      // Feedback visuel d'impact
      shakeAndFlashAnimation();
    }

    instance = newInstance;
    _refreshBadges();
    buffIndicator.updateStatuses(newStats.statuses.where((s) => s.type == StatusType.buff).toList());
    debuffIndicator.updateStatuses(newStats.statuses.where((s) => s.type == StatusType.debuff).toList());
  }

  void shakeAndFlashAnimation() {
    // 1. Tremblement (Shake)
    final rand = Random();
    for (int i = 0; i < 4; i++) {
      add(
        MoveEffect.by(
          Vector2(
            (rand.nextDouble() - 0.5) * 20,
            (rand.nextDouble() - 0.5) * 20,
          ),
          EffectController(duration: 0.025, alternate: true),
        ),
      );
    }

    // 2. Flash Blanc
    add(
      ColorEffect(
        Colors.white,
        EffectController(duration: 0.1, alternate: true),
        opacityTo: 0.8,
      ),
    );
  }

  void _spawnFloatingText(String text, Color color, Vector2 pos) {
    final ft = FloatingText(
      text: text,
      color: color,
      position: pos,
      isUpward: false,
    );
    add(ft);
  }

  void setSelection(bool selected) {
    isSelected = selected;
    if (!isLoaded) return;
    if (isSelected) {
      borderInfo.paint.color = Colors.amber;
      borderInfo.paint.strokeWidth = 4;
    } else {
      borderInfo.paint.color = Colors.white;
      borderInfo.paint.strokeWidth = 2;
    }
  }

  bool _isHighlighted = false;
  double _glowOpacity = 1.0;
  Effect? _glowAnimation;

  void setHighlight(bool highlight) {
    if (_isHighlighted == highlight) return;
    _isHighlighted = highlight;
    if (!isLoaded) return;

    if (_isHighlighted) {
      borderInfo.paint.color = Colors.cyanAccent;
      borderInfo.paint.strokeWidth = 3;
      
      _glowAnimation = SequenceEffect([
        OpacityEffect.to(0.3, EffectController(duration: 0.8, curve: Curves.easeInOut)),
        OpacityEffect.to(1.0, EffectController(duration: 0.8, curve: Curves.easeInOut)),
      ], onComplete: () {}, infinite: true);
    } else {
      borderInfo.paint.color = isSelected ? Colors.amber : Colors.white;
      borderInfo.paint.strokeWidth = isSelected ? 4 : 2;
      
      _glowAnimation?.removeFromParent();
      _glowAnimation = null;
    }
  }

  double _totalTime = 0;
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
        ..strokeWidth = 6 + (2 * _glowOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, 8 + (4 * _glowOpacity));
      canvas.drawRRect(rrect, glowPaint);
    }
    super.render(canvas);
  }

  void dashAnimation() {
    add(
      SequenceEffect([
        MoveEffect.by(
          Vector2(0, 50),
          EffectController(duration: 0.1, curve: Curves.easeOut),
        ),
        MoveEffect.by(
          Vector2(0, -50),
          EffectController(duration: 0.15, curve: Curves.bounceOut),
        ),
      ]),
    );
  }

  void buffAnimation(IntentType type) {
    final effectIcon = EffectIcon(
      iconType: type == IntentType.defend ? 'defend' : 'buff',
      position: Vector2(size.x / 2, 0),
    );
    add(effectIcon);
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapEnemy(this);
  }
}
