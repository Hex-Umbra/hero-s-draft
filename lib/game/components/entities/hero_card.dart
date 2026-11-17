import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../../models/entity_stats.dart';
import '../effect_icon.dart';
import '../../../models/data/card_data.dart';
import '../../../models/data/charge_data.dart';
import '../../../services/audio/game_moment.dart';
import '../../systems/charge_rules.dart';
import '../visual_effects/fire_wave_effects.dart';
import 'combat_entity.dart';

class HeroCard extends CombatEntity with TapCallbacks {
  EntityStats stats;
  final String imagePath;
  bool suppressArmorChangeAnimation = false;

  @override
  bool get isPlayer => true;

  @override
  late final RectangleComponent borderInfo;
  @override
  late final SpriteComponent sprite;

  HeroCard(this.stats, {required this.imagePath})
    : super(size: Vector2(120, 160));

  @override
  double get entityBaseScale => game.scaleFactor * 1.3;

  @override
  void refreshBorderVisuals() {
    _refreshBorderVisuals();
  }

  bool _isHighlighted = false;
  double _glowOpacity = 1.0;
  double _totalTime = 0;

  void setHighlight(bool highlight) {
    if (_isHighlighted == highlight) return;
    _isHighlighted = highlight;

    if (_isHighlighted) {
      borderInfo.paint.color = Colors.cyanAccent;
      borderInfo.paint.strokeWidth = 4;
    } else {
      borderInfo.paint.color = Colors.white;
      borderInfo.paint.strokeWidth = 2;
    }
  }

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
        ..strokeWidth = 8 + (2 * _glowOpacity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.outer,
          10 + (4 * _glowOpacity),
        );
      canvas.drawRRect(rrect, glowPaint);
    }
    super.render(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // Système Click-to-Play : Ciblage de soi-même
    if (game.focusedCard != null) {
      if (game.focusedCard!.card.data.target == CardTarget.self) {
        final cardToPlay = game.focusedCard!;
        if (!cardToPlay.canAfford) {
          game.audio.onMoment(GameMoment.insufficientMana);
          cardToPlay.shakeAnimation();
          return;
        }
        game.setFocusedCard(null);
        bool played = game.tryPlayCard(cardToPlay, null);
        if (played) {
          return;
        }
      }
    }
  }

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    // Appliquer l'échelle initiale (Agrandie pour le terrain)
    scale = Vector2.all(game.scaleFactor * 1.3);

    // Position par défaut au centre pour le joueur (sera mise à jour par onGameResize du jeu)
    position = Vector2(game.size.x / 2, game.size.y * 0.6);

    // Visuel Sprite
    sprite = SpriteComponent(
      sprite: Sprite(game.images.fromCache(imagePath)),
      size: size,
    );
    add(sprite);

    // Encadré de la carte
    borderInfo = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    add(borderInfo);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Mettre à jour l'échelle lors du redimensionnement (Agrandie pour le terrain)
    scale = Vector2.all(game.scaleFactor * 1.3);
  }

  /// Etat en attente pendant qu'une carte s'anime, sur le modele de
  /// `EnemyCard._pendingVisualInstance`.
  ///
  /// Le heros ne differait rien avant le 2026-08-29 : il appliquait ses
  /// reactions des la frame suivant le changement d'etat, donc environ 16 ms
  /// apres le son de la carte jouee. Une carte de soin ou d'armure produisait
  /// ainsi deux bruitages superposes. La resolution est desormais rendue a la
  /// frappe d'impact de l'animation, comme pour les ennemis.
  EntityStats? _pendingStats;
  bool _pendingSuppressArmorChange = false;

  void updateStats(EntityStats newStats) {
    // Le drapeau est consomme dans les deux branches : le laisser arme
    // jusqu'a la resolution le ferait s'appliquer a une mise a jour ulterieure
    // qui ne l'a pas demande.
    final suppress = suppressArmorChangeAnimation;
    suppressArmorChangeAnimation = false;

    if (game.isCardAnimating) {
      _pendingStats = newStats;
      _pendingSuppressArmorChange = suppress;
      return;
    }

    _applyStats(newStats, suppress);
  }

  /// Applique ce qui attendait la frappe d'impact. Sans rien en attente, ne
  /// fait rien : appelable deux fois sans effet double.
  void resolvePendingVisualStats() {
    final pending = _pendingStats;
    if (pending == null) return;
    _pendingStats = null;
    _applyStats(pending, _pendingSuppressArmorChange);
  }

  void _applyStats(EntityStats newStats, bool suppressArmorChange) {
    final ownFire = _ownFire(stats, newStats);
    triggerHitReactions(
      stats,
      newStats,
      suppressArmorChange: suppressArmorChange,
      fireDamage: ownFire.burst || ownFire.ember,
    );
    // Apres les reactions : le rougeoiement remplace la teinte des degats.
    if (ownFire.burst) {
      game.add(
        FireBurst(
          position: position.clone(),
          radius: 1.5 * size.x * scale.x,
        ),
      );
    }
    if (ownFire.ember) emberFlash();
    refreshChargeVisuals(stats, newStats);
    stats = newStats;
  }

  /// Le Feu du heros resolu dans la transition (spec P-53, §5.2, F-a), lu sur
  /// chaque piste `explode` presente avant et apres : une rupture comptee en
  /// plus appelle l'eclair seul, sans boule de feu ; sinon, des points tombes
  /// a 0 appellent le rougeoiement. Le retrait de debug, qui vide les pistes,
  /// n'appelle rien.
  static ({bool burst, bool ember}) _ownFire(
    EntityStats oldStats,
    EntityStats newStats,
  ) {
    var burst = false;
    var ember = false;
    for (final MapEntry(key: id, value: track) in newStats.charges.entries) {
      if (track.rupture.kind != RuptureKind.explode) continue;
      final before = oldStats.charges[id];
      if (before == null) continue;
      if (track.ruptures > before.ruptures) {
        burst = true;
      } else if (ChargeRules.points(oldStats, id) > 0 &&
          ChargeRules.points(newStats, id) == 0) {
        ember = true;
      }
    }
    return (burst: burst, ember: ember);
  }

  void _refreshBorderVisuals() {
    if (_isHighlighted) {
      borderInfo.paint.color = Colors.cyanAccent;
      borderInfo.paint.strokeWidth = 4;
    } else {
      borderInfo.paint.color = Colors.white;
      borderInfo.paint.strokeWidth = 2;
    }
  }

  void buffAnimation(String iconType) {
    // Faire popper l'icône
    final effectIcon = EffectIcon(
      iconType: iconType,
      position: position + Vector2(0, -size.y * scale.y / 2),
    );
    effectIcon.priority = 200;
    game.add(effectIcon);
  }
}
