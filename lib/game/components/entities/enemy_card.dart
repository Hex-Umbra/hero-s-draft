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
  late final StatBadge manaBadge;
  late final StatusIndicator statusIndicator;
  late final SpriteComponent sprite;

  EnemyIntent? currentIntent;
  bool isSelected = false;
  int _intentStep = 0;

  EnemyCard({
    required this.stats,
    this.data,
    this.isBoss = false,
    required this.onTapEnemy,
  }) : super(size: Vector2(100, 140));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    // Appliquer l'échelle initiale (Agrandie pour le terrain)
    scale = Vector2.all(game.scaleFactor * 1.3);

    String spriteName = data?.spritePath ?? 'enemy_goblin.png';
    if (spriteName.isEmpty) spriteName = 'enemy_goblin.png';

    sprite = SpriteComponent(
      sprite: Sprite(game.images.fromCache(spriteName)),
      size: size,
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

    intentionIndicator = IntentionIndicator(initialIntent: currentIntent);
    intentionIndicator.position = Vector2(
      size.x / 2,
      -30,
    ); // Juste au-dessus de la carte
    add(intentionIndicator);

    armorBadge = StatBadge(type: StatType.armor, value: '${stats.armure}');
    armorBadge.position = Vector2(-12, 25);
    add(armorBadge);

    attackBadge = StatBadge(type: StatType.attack, value: '${stats.attaque}');
    attackBadge.position = Vector2(-12, 55);
    add(attackBadge);

    manaBadge = StatBadge(
      type: StatType.mana,
      value: '${stats.currentMana}/${stats.maxMana}',
    );
    manaBadge.position = Vector2(-12, 85);
    add(manaBadge);

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
    intentionIndicator.updateIntent(currentIntent);
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
          value: stats.attaque,
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
    attackBadge.updateValue(
      stats.attaque.toString(),
      tooltipTitle: 'FORCE',
      tooltipDescription:
          'L\'ennemi inflige ${stats.attaque} dégâts de base avec ses attaques.',
    );
    manaBadge.updateValue(
      '${stats.currentMana}/${stats.maxMana}',
      tooltipTitle: 'MANA',
      tooltipDescription:
          'Énergie de l\'ennemi. Actuellement : ${stats.currentMana}/${stats.maxMana}.',
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
  Effect? _highlightEffect;

  void setHighlight(bool highlight) {
    if (_isHighlighted == highlight) return;
    _isHighlighted = highlight;

    if (_isHighlighted) {
      borderInfo.paint.color = Colors.cyanAccent;
      borderInfo.paint.strokeWidth = 3;
      _highlightEffect = ScaleEffect.to(
        Vector2.all(1.02),
        EffectController(duration: 0.5, reverseDuration: 0.5, infinite: true),
      );
      add(_highlightEffect!);
    } else {
      borderInfo.paint.color = isSelected ? Colors.amber : Colors.white;
      borderInfo.paint.strokeWidth = isSelected ? 4 : 2;
      
      final scaleEffects = children.whereType<ScaleEffect>().toList();
      removeAll(scaleEffects);
      _highlightEffect = null;
      
      scale = Vector2.all(1.0);
      add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.1)));
    }
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
    // Effet de concentration/respiration
    add(
      ScaleEffect.by(
        Vector2.all(1.05),
        EffectController(duration: 0.1, alternate: true),
      ),
    );

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
