import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import '../../../data/models/entity_stats.dart';
import '../floating_text.dart';
import '../effect_icon.dart';
import 'stat_badge.dart';
import 'status_indicator.dart';
import '../../heros_draft_game.dart';
import '../../../models/data/card_data.dart';

class HeroCard extends PositionComponent
    with TapCallbacks, HasGameReference<HerosDraftGame> {
  EntityStats stats;
  int bonusAttack;
  final String imagePath;

  late final StatBadge armorBadge;
  late final StatBadge attackBadge;
  late final StatusIndicator statusIndicator;
  late final RectangleComponent borderInfo;

  HeroCard(
    this.stats, {
    this.bonusAttack = 0,
    required this.imagePath,
  }) : super(size: Vector2(120, 160));

  bool _isHighlighted = false;
  Effect? _highlightEffect;

  void setHighlight(bool highlight) {
    if (_isHighlighted == highlight) return;
    _isHighlighted = highlight;

    if (_isHighlighted) {
      borderInfo.paint.color = Colors.cyanAccent;
      borderInfo.paint.strokeWidth = 4;
      _highlightEffect = ScaleEffect.to(
        Vector2.all(1.02),
        EffectController(duration: 0.5, reverseDuration: 0.5, infinite: true),
      );
      add(_highlightEffect!);
    } else {
      borderInfo.paint.color = Colors.white;
      borderInfo.paint.strokeWidth = 2;
      
      final scaleEffects = children.whereType<ScaleEffect>().toList();
      removeAll(scaleEffects);
      _highlightEffect = null;
      
      scale = Vector2.all(1.0);
      add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1)));
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // Système Click-to-Play : Ciblage de soi-même
    if (game.focusedCard != null) {
      if (game.focusedCard!.card.data.target == CardTarget.self) {
        bool played = game.tryPlayCard(game.focusedCard!, null);
        if (played) {
          game.setFocusedCard(null);
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
    add(
      SpriteComponent(
        sprite: Sprite(game.images.fromCache(imagePath)),
        size: size,
      ),
    );

    // Encadré de la carte
    borderInfo = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    add(borderInfo);

    armorBadge = StatBadge(type: StatType.armor, value: '${stats.armure}');
    armorBadge.position = Vector2(-12, 35);
    add(armorBadge);

    attackBadge = StatBadge(type: StatType.attack, value: '${stats.attaque}');
    attackBadge.position = Vector2(-12, 80);
    add(attackBadge);

    statusIndicator = StatusIndicator(statuses: stats.statuses);
    statusIndicator.position = Vector2(0, -30); // Au dessus de la carte
    add(statusIndicator);

    _refreshBadges();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Mettre à jour l'échelle lors du redimensionnement (Agrandie pour le terrain)
    scale = Vector2.all(game.scaleFactor * 1.3);
  }

  void _refreshBadges() {
    int currentArmor = stats.armure;
    int mastery = stats.armorMastery;

    armorBadge.updateValue(
      '$currentArmor',
      baseValue: 0,
      bonusValue: currentArmor,
      tooltipTitle: 'ARMURE',
      tooltipDescription:
          'Réduit les prochains dégâts reçus. Temporaire : $currentArmor.\nMaîtrise : +$mastery à chaque gain.',
    );

    int totalAttack = stats.attaque + bonusAttack;
    attackBadge.updateValue(
      '$totalAttack',
      baseValue: stats.attaque,
      bonusValue: bonusAttack,
      tooltipTitle: 'FORCE',
      tooltipDescription: 'Base : ${stats.attaque}, Bonus : $bonusAttack.',
    );

    statusIndicator.updateStatuses(stats.statuses);
  }

  void updateStats(
    EntityStats newStats, {
    int bonusAttack = 0,
  }) {
    if (newStats.armure < stats.armure) {
      _spawnFloatingText(
        '-${stats.armure - newStats.armure}',
        Colors.blue,
        Vector2(size.x / 2, 0),
      );
    } else if (newStats.armure > stats.armure) {
      _spawnFloatingText(
        '+${newStats.armure - stats.armure}',
        Colors.lightBlueAccent,
        Vector2(size.x / 2, 0),
      );
    }

    if (newStats.currentPv < stats.currentPv) {
      _spawnFloatingText(
        '-${stats.currentPv - newStats.currentPv}',
        Colors.red,
        Vector2(size.x / 2, 20),
      );
    }

    stats = newStats;
    this.bonusAttack = bonusAttack;
    _refreshBadges();
  }

  void _spawnFloatingText(String text, Color color, Vector2 pos) {
    final ft = FloatingText(text: text, color: color, position: pos);
    add(ft);
  }

  void dashAnimation() {
    add(
      SequenceEffect([
        MoveEffect.by(
          Vector2(0, -50),
          EffectController(duration: 0.1, curve: Curves.easeOut),
        ),
        MoveEffect.by(
          Vector2(0, 50),
          EffectController(duration: 0.15, curve: Curves.bounceOut),
        ),
      ]),
    );
  }

  void buffAnimation(String iconType) {
    // Effet de concentration/respiration
    add(
      ScaleEffect.by(
        Vector2.all(1.05),
        EffectController(duration: 0.1, alternate: true),
      ),
    );

    // Faire popper l'icône
    final effectIcon = EffectIcon(
      iconType: iconType,
      position: Vector2(size.x / 2, 0), // Milieu haut
    );
    add(effectIcon);
  }
}
