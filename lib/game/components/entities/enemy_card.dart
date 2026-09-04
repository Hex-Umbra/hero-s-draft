import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/entity_stats.dart';
import '../../../models/data/enemy_data.dart';
import '../../../models/enemy_intent.dart';
import '../../../models/status_effect.dart';
import '../../../models/enemy_instance.dart';
import '../effect_icon.dart';
import 'stat_badge.dart';
import 'status_indicator.dart';
import 'combat_entity.dart';

class EnemyCard extends CombatEntity
    with TapCallbacks, HasPaint {
  EnemyInstance instance;
  final void Function(EnemyCard) onTapEnemy;

  @override
  bool get isPlayer => false;

  @override
  late final RectangleComponent borderInfo;
  late final StatBadge hpBadge;
  @override
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
  bool isDead = false;
  bool isPendingDeath = false;
  EnemyInstance? _pendingVisualInstance;

  double _scaleMultiplier = 1.0;
  double get scaleMultiplier => _scaleMultiplier;
  set scaleMultiplier(double value) {
    if (_scaleMultiplier == value) return;
    _scaleMultiplier = value;
    scale = Vector2.all(baseScale);
  }

  double get baseScale => game.scaleFactor * 1.45 * (isBoss ? 1.25 : 1.0) * _scaleMultiplier;

  @override
  double get entityBaseScale => baseScale;

  @override
  void refreshBorderVisuals() {
    _refreshBorderVisuals();
  }

  EnemyCard({required this.instance, required this.onTapEnemy})
    : super(size: Vector2(100, 140));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    // Appliquer l'échelle initiale
    scale = Vector2.all(baseScale);

    final spriteName = data.spritePath;

    // Chargement asynchrone robuste (lit le cache si déjà chargé, ou charge depuis les assets sinon)
    final image = await game.images.load(spriteName);

    // Préserver le ratio d'aspect original de l'image (type BoxFit.contain)
    final double imgWidth = image.width.toDouble();
    final double imgHeight = image.height.toDouble();
    final double imgRatio = imgWidth / imgHeight;
    final double cardRatio =
        size.x / size.y; // Ratio de la carte (100 / 140 = 0.714)

    Vector2 spriteSize;
    Vector2 spritePosition;

    if (imgRatio > cardRatio) {
      // L'image est plus large/carrée que le ratio de la carte (ex. le slime 320x320) -> Ajuster sur la largeur
      final double width = size.x;
      final double height = size.x / imgRatio;
      spriteSize = Vector2(width, height);
      spritePosition = Vector2(
        0,
        (size.y - height) / 2,
      ); // Centrer verticalement
    } else {
      // L'image est plus élancée/haute que le ratio de la carte -> Ajuster sur la hauteur
      final double height = size.y;
      final double width = size.y * imgRatio;
      spriteSize = Vector2(width, height);
      spritePosition = Vector2(
        (size.x - width) / 2,
        0,
      ); // Centrer horizontalement
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
    hpBadge.position = Vector2(
      size.x / 2,
      -12,
    ); // Centré légèrement au-dessus de la carte
    add(hpBadge);

    // Positionner les buffs (à gauche) et les debuffs (à droite)
    buffIndicator = StatusIndicator(
      statuses: stats.statuses.where((s) => s.type == StatusType.buff).toList(),
      position: Vector2(-36, 10),
    );
    add(buffIndicator);

    debuffIndicator = StatusIndicator(
      statuses: stats.statuses
          .where((s) => s.type == StatusType.debuff)
          .toList(),
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
    // Mettre à jour l'échelle lors du redimensionnement
    scale = Vector2.all(baseScale);
  }

  String get activeLocale {
    final context = game.buildContext;
    if (context != null) {
      return Localizations.localeOf(context).languageCode;
    }
    return 'fr'; // Langue par défaut en secours
  }

  String getTranslation(
    String Function(AppLocalizations) select, {
    String fallback = '',
  }) {
    final context = game.buildContext;
    if (context != null) {
      final localizations = AppLocalizations.of(context);
      if (localizations != null) {
        return select(localizations);
      }
    }
    return fallback;
  }

  void _refreshBadges() {
    final hpSuffix = getTranslation((l) => l.hpAbbreviation, fallback: 'PV');
    hpBadge.updateHpValues(
      '${stats.currentPv}/${stats.maxPv}',
      stats.maxPv > 0 ? stats.currentPv / stats.maxPv : 0.0,
      stats.effectiveAttaque,
      stats.armure,
      armorPercentage: stats.maxPv > 0 ? stats.armure / stats.maxPv : 0.0,
      tooltipTitle: getTranslation(
        (l) => l.enemyStatsTitle,
        fallback: 'STATS DE L\'ENNEMI',
      ),
      tooltipDescription: getTranslation(
        (l) => l.enemyStatsDesc(
          stats.currentPv,
          stats.maxPv,
          stats.effectiveAttaque,
          stats.armure,
        ),
        fallback:
            'Santé : ${stats.currentPv}/${stats.maxPv} $hpSuffix.\nAttaque : ${stats.effectiveAttaque}.\nArmure : ${stats.armure}.',
      ),
    );
  }

  void updateStats(EnemyInstance newInstance) {
    if (game.isCardAnimating) {
      _pendingVisualInstance = newInstance;
    } else {
      triggerHitReactions(stats, newInstance.stats);
      instance = newInstance;
      _refreshBadges();
      buffIndicator.updateStatuses(
        instance.stats.statuses.where((s) => s.type == StatusType.buff).toList(),
      );
      debuffIndicator.updateStatuses(
        instance.stats.statuses.where((s) => s.type == StatusType.debuff).toList(),
      );
    }
  }

  void resolvePendingVisualStats() {
    if (_pendingVisualInstance != null) {
      triggerHitReactions(stats, _pendingVisualInstance!.stats);
      instance = _pendingVisualInstance!;
      _refreshBadges();
      buffIndicator.updateStatuses(
        instance.stats.statuses.where((s) => s.type == StatusType.buff).toList(),
      );
      debuffIndicator.updateStatuses(
        instance.stats.statuses.where((s) => s.type == StatusType.debuff).toList(),
      );
      _pendingVisualInstance = null;
    }
  }

  void _refreshBorderVisuals() {
    if (isSelected) {
      borderInfo.paint.color = Colors.amber;
      borderInfo.paint.strokeWidth = 4;
    } else if (_isHighlighted) {
      borderInfo.paint.color = Colors.cyanAccent;
      borderInfo.paint.strokeWidth = 3;
    } else {
      borderInfo.paint.color = Colors.white;
      borderInfo.paint.strokeWidth = 2;
    }
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
  dynamic _glowAnimation; // Dynamic to avoid exact type check compile error if Effect is not fully imported

  void setHighlight(bool highlight) {
    if (_isHighlighted == highlight) return;
    _isHighlighted = highlight;
    if (!isLoaded) return;

    if (_isHighlighted) {
      borderInfo.paint.color = Colors.cyanAccent;
      borderInfo.paint.strokeWidth = 3;

      // Glow animation handled dynamically in update/render
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

  @override
  void dashAnimation({bool isDownward = true}) {
    super.dashAnimation(isDownward: isDownward);
  }

  void buffAnimation(IntentType type) {
    final effectIcon = EffectIcon(
      iconType: type == IntentType.defend ? 'defend' : 'buff',
      position: position + Vector2(0, -size.y * scale.y / 2),
    );
    effectIcon.priority = 200;
    game.add(effectIcon);
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapEnemy(this);
  }
}
