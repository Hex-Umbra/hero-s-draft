import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import '../../../data/models/entity_stats.dart';
import '../../../models/data/enemy_data.dart';
import '../../../models/enemy_intent.dart';
import '../../../models/status_effect.dart';
import '../floating_text.dart';
import '../effect_icon.dart';
import 'stat_badge.dart';
import 'intention_indicator.dart';
import 'status_indicator.dart';
import '../../heros_draft_game.dart';

class EnemyCard extends PositionComponent
    with TapCallbacks, HasGameReference<HerosDraftGame>, HasPaint {
  EntityStats stats;
  final EnemyData? data;
  final bool isBoss;
  final void Function(EnemyCard) onTapEnemy;

  late final RectangleComponent borderInfo;

  late final StatBadge hpBadge;
  late final IntentionIndicator intentionIndicator;
  late final StatBadge armorBadge;
  late final StatBadge attackBadge;
  late final StatusIndicator statusIndicator;
  late final SpriteComponent sprite;

  EnemyIntent? currentIntent;

  late final int _startingAttaque;
  late final double _spawnMultiplier;

  EnemyIntent? get effectiveIntent {
    final intent = currentIntent;
    if (intent == null) return null;
    if (intent.type == IntentType.attack) {
      final int scaledValue = (intent.value * _spawnMultiplier).round();
      final int inBattleBonus = stats.effectiveAttaque - _startingAttaque;
      return EnemyIntent(
        type: intent.type,
        value: max(stats.effectiveAttaque, scaledValue + inBattleBonus),
      );
    }
    return intent;
  }

  bool isSelected = false;
  int _intentStep = 0;

  EnemyCard({
    required this.stats,
    this.data,
    this.isBoss = false,
    required this.onTapEnemy,
  }) : super(size: Vector2(100, 140)) {
    _startingAttaque = stats.attaque;
    final int baseDmg = data?.baseDamage ?? stats.attaque;
    _spawnMultiplier = baseDmg > 0 ? stats.attaque / baseDmg : 1.0;
  }

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    // Appliquer l'échelle initiale (Agrandie pour le terrain)
    scale = Vector2.all(game.scaleFactor * 1.3);

    String spriteName = data?.spritePath ?? 'enemy_goblin.png';
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
      isCircle: true,
      fillPercentage: stats.maxPv > 0 ? stats.currentPv / stats.maxPv : 1.0,
    );
    hpBadge.position = Vector2(size.x / 2, size.y); // Centré en bas
    add(hpBadge);

    _determineNextIntent();

    intentionIndicator = IntentionIndicator(initialIntent: effectiveIntent);
    intentionIndicator.position = Vector2(
      size.x / 2,
      -30,
    ); // Juste au-dessus de la carte
    add(intentionIndicator);

    armorBadge = StatBadge(type: StatType.armor, value: '${stats.armure}');
    armorBadge.position = Vector2(-12, 25);
    add(armorBadge);

    final int initialStrength = stats.effectiveAttaque - stats.attaque;
    attackBadge = StatBadge(
      type: StatType.attack,
      value: '${stats.effectiveAttaque}',
      baseValue: stats.attaque,
      bonusValue: initialStrength > 0 ? initialStrength : null,
    );
    attackBadge.position = Vector2(-12, 55);
    add(attackBadge);



    statusIndicator = StatusIndicator(statuses: stats.statuses);
    statusIndicator.position = Vector2(
      0,
      size.y + 10,
    ); // En dessous de la carte
    add(statusIndicator);

    _refreshBadges();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Mettre à jour l'échelle lors du redimensionnement (Agrandie pour le terrain)
    scale = Vector2.all(game.scaleFactor * 1.3);
  }

  void rollIntent() {
    _determineNextIntent();
    intentionIndicator.updateIntent(effectiveIntent);
  }

  void _determineNextIntent() {
    if (data?.intents != null && data!.intents!.isNotEmpty) {
      currentIntent = data!.intents![_intentStep];
      _intentStep = (_intentStep + 1) % data!.intents!.length;
    } else {
      final random = Random();
      final roll = random.nextInt(100);

      if (roll < 60) {
        // 60% Attack
        currentIntent = EnemyIntent(
          type: IntentType.attack,
          value: data?.baseDamage ?? _startingAttaque,
        );
      } else if (roll < 85) {
        // 25% Defend
        currentIntent = EnemyIntent(
          type: IntentType.defend,
          value: 5 + random.nextInt(6),
        );
      } else {
        // 15% Buff
        currentIntent = EnemyIntent(type: IntentType.buff, value: 2);
      }
    }
  }

  void _refreshBadges() {
    hpBadge.updateValue(
      '${stats.currentPv}/${stats.maxPv}',
      fillPercentage: stats.maxPv > 0 ? stats.currentPv / stats.maxPv : 0,
      tooltipTitle: 'POINTS DE VIE',
      tooltipDescription:
          'Santé actuelle de l\'ennemi : ${stats.currentPv} / ${stats.maxPv}.',
    );
    armorBadge.updateValue(
      '${stats.armure}',
      tooltipTitle: 'ARMURE',
      tooltipDescription:
          'L\'ennemi possède ${stats.armure} d\'armure. Elle doit être brisée avant de toucher aux PV.',
    );
    final int strengthBonus = stats.effectiveAttaque - stats.attaque;
    attackBadge.updateValue(
      stats.effectiveAttaque.toString(),
      baseValue: stats.attaque,
      bonusValue: strengthBonus > 0 ? strengthBonus : null,
      tooltipTitle: 'FORCE',
      tooltipDescription: strengthBonus > 0
          ? 'Base : ${stats.attaque}, Bonus : +$strengthBonus. L\'ennemi inflige ${stats.effectiveAttaque} dégâts.'
          : 'L\'ennemi inflige ${stats.attaque} dégâts de base avec ses attaques.',
    );

    statusIndicator.updateStatuses(stats.statuses);
  }

  void updateStats(EntityStats newStats) {
    if (newStats.armure < stats.armure) {
      _spawnFloatingText(
        '-${stats.armure - newStats.armure}',
        Colors.blue,
        Vector2(size.x / 2, size.y - 20),
      );
    }
    if (newStats.currentPv < stats.currentPv) {
      _spawnFloatingText(
        '-${stats.currentPv - newStats.currentPv}',
        Colors.red,
        Vector2(size.x / 2, size.y),
      );
      // Feedback visuel d'impact
      shakeAndFlashAnimation();
    }

    stats = newStats;
    _refreshBadges();
    intentionIndicator.updateIntent(effectiveIntent);
  }

  void shakeAndFlashAnimation() {
    // TODO: Audio Hook - sfx_impact_heavy (Jouer un son d'impact lors de la réception de dégâts)

    // 1. Tremblement (Shake)
    // On utilise un petit effet de va-et-vient aléatoire
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

    // 2. Flash Blanc (via Opacity et ColorFilter ou simplement en changeant la couleur du sprite si possible)
    // Ici on va utiliser un ColorEffect s'il est disponible, sinon on joue sur l'opacité
    add(
      ColorEffect(
        Colors.white,
        EffectController(duration: 0.1, alternate: true),
        opacityTo: 0.8,
      ),
    );
  }

  /// Applique les effets de début de tour de l'ennemi
  void startTurn() {
    int poisonDamage = 0;
    int strengthGain = 0;
    int armorGain = 0;

    for (var status in stats.statuses) {
      if (status.id == 'poison') {
        poisonDamage += status.value;
      } else if (status.id == 'strength_regen') {
        strengthGain += status.value;
      } else if (status.id == 'armor_regen') {
        armorGain += status.value;
      }
    }

    EntityStats updatedStats = stats;
    if (poisonDamage > 0) {
      updatedStats = updatedStats.takeDamage(poisonDamage);
    }
    if (strengthGain > 0) {
      updatedStats = updatedStats.addStatus(
        StatusEffect(
          id: 'strength',
          name: 'Force',
          type: StatusType.buff,
          value: strengthGain,
          duration: 1,
        ),
      );
    }
    if (armorGain > 0) {
      updatedStats = updatedStats.copyWith(
        armure: updatedStats.armure + armorGain,
      );
    }

    updateStats(updatedStats);

    // Décrémenter les statuts pour le tour suivant
    updateStats(stats.tickStatuses());
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

    if (_isHighlighted) {
      borderInfo.paint.color = Colors.cyanAccent;
      borderInfo.paint.strokeWidth = 3;
      
      // Animation de pulsation de l'opacité du halo
      _glowAnimation = SequenceEffect([
        OpacityEffect.to(0.3, EffectController(duration: 0.8, curve: Curves.easeInOut)),
        OpacityEffect.to(1.0, EffectController(duration: 0.8, curve: Curves.easeInOut)),
      ], onComplete: () {}, infinite: true);
      
      // Note: On ne peut pas appliquer OpacityEffect directement sur un Paint dans render facilement sans ruse.
      // On va utiliser un timer ou simplement laisser le render utiliser une valeur sinusoïdale basée sur le temps de jeu
      // pour une pulsation fluide du contraste/transparence.
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
      // Oscillation entre 0.2 et 0.8 pour l'opacité du halo
      _glowOpacity = 0.5 + 0.3 * sin(_totalTime * 4);
    }
  }

  @override
  void render(Canvas canvas) {
    // Si surbrillance active, on dessine un halo pulsant
    if (_isHighlighted) {
      final rect = size.toRect();
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(0));
      final glowPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: _glowOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 + (2 * _glowOpacity) // Légère variation d'épaisseur pour le "poids" visuel
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
    // Faire popper l'icône
    final effectIcon = EffectIcon(
      iconType: type == IntentType.defend ? 'defend' : 'buff',
      position: Vector2(size.x / 2, 0), // Milieu haut
    );
    add(effectIcon);
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapEnemy(this);
  }
}
