import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';
import '../../../data/models/entity_stats.dart';
import '../../../models/data/enemy_data.dart';
import '../../../models/enemy_intent.dart';
import '../floating_text.dart';
import '../effect_icon.dart';
import 'stat_badge.dart';
import 'health_bar.dart';
import 'intention_indicator.dart';
import '../../heros_draft_game.dart';

class EnemyCard extends PositionComponent with TapCallbacks, HasGameReference<HerosDraftGame> {
  EntityStats stats;
  final EnemyData? data;
  final bool isBoss;
  final void Function(EnemyCard) onTapEnemy;

  late final RectangleComponent borderInfo;
  late final TextComponent titleText;
  
  late final HealthBarComponent healthBar;
  late final IntentionIndicator intentionIndicator;
  late final StatBadge armorBadge;
  late final StatBadge attackBadge;
  late final StatBadge manaBadge;

  EnemyIntent? currentIntent;
  bool isSelected = false;

  EnemyCard({
    required this.stats,
    this.data,
    this.isBoss = false,
    required this.onTapEnemy,
  }) : super(size: Vector2(140, 200));

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;

    String spriteName = isBoss ? 'enemy_boss.png' : 'enemy_goblin.png';
    add(
      SpriteComponent(
        sprite: Sprite(game.images.fromCache(spriteName)),
        size: size,
      ),
    );

    borderInfo = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    add(borderInfo);

    String title = data?.name ?? (isBoss ? 'BOSS' : 'ENNEMI');
    titleText = TextComponent(
      text: title,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 10),
    );
    add(titleText);

    healthBar = HealthBarComponent(
      barWidth: size.x - 20,
      barHeight: 16,
      currentPv: stats.currentPv.toDouble(),
      maxPv: stats.maxPv.toDouble(),
    );
    healthBar.position = Vector2(10, -25); // Position initiale fonctionnelle
    add(healthBar);

    // Génère l'intention initiale manuellement pour éviter les soucis de synchronisation
    final random = Random();
    final roll = random.nextInt(100);
    if (roll < 60) {
      currentIntent = EnemyIntent(type: IntentType.attack, value: stats.attaque);
    } else if (roll < 90) {
      currentIntent = EnemyIntent(type: IntentType.defend, value: 5 + random.nextInt(6));
    } else {
      currentIntent = EnemyIntent(type: IntentType.buff, value: 2);
    }

    intentionIndicator = IntentionIndicator(initialIntent: currentIntent);
    intentionIndicator.position = Vector2(size.x / 2, -55); // Juste au-dessus de la barre de vie
    add(intentionIndicator);

    armorBadge = StatBadge(type: StatType.armor, value: '${stats.armure}');
    armorBadge.position = Vector2(size.x, 0);
    add(armorBadge);

    attackBadge = StatBadge(type: StatType.attack, value: '${stats.attaque}');
    attackBadge.position = Vector2(0, size.y);
    add(attackBadge);

    manaBadge = StatBadge(type: StatType.mana, value: '${stats.currentMana}/${stats.maxMana}');
    manaBadge.position = Vector2(size.x / 2, size.y - 25);
    add(manaBadge);
  }

  void rollIntent() {
    final random = Random();
    final roll = random.nextInt(100);
    
    if (roll < 60) {
      // 60% Attack
      currentIntent = EnemyIntent(type: IntentType.attack, value: stats.attaque);
    } else if (roll < 90) {
      // 30% Defend
      currentIntent = EnemyIntent(type: IntentType.defend, value: 5 + random.nextInt(6));
    } else {
      // 10% Buff
      currentIntent = EnemyIntent(type: IntentType.buff, value: 2);
    }
    
    intentionIndicator.updateIntent(currentIntent);
  }

  void _refreshBadges() {
    healthBar.updateValues(stats.currentPv.toDouble(), stats.maxPv.toDouble());
    armorBadge.updateValue('${stats.armure}');
    attackBadge.updateValue(stats.attaque.toString());
    manaBadge.updateValue('${stats.currentMana}/${stats.maxMana}');
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
    }

    stats = newStats;
    _refreshBadges();
  }

  void _spawnFloatingText(String text, Color color, Vector2 pos) {
    final ft = FloatingText(
      text: text,
      color: color,
      position: pos,
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
