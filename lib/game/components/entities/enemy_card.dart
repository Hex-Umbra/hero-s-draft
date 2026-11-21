import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../../models/entity_stats.dart';
import '../../../models/data/enemy_data.dart';
import '../../../models/enemy_intent.dart';
import '../../../models/enemy_instance.dart';
import '../../game_constants.dart';
import '../../systems/armor_veil.dart';
import '../../systems/entity_hover.dart';
import '../visual_effects/frost_shell.dart';
import '../effect_icon.dart';
import 'enemy_health_bar.dart';
import 'combat_entity.dart';

class EnemyCard extends CombatEntity
    with TapCallbacks, HasPaint {
  EnemyInstance instance;
  /// Le toucher de la carte, de sa barre ou de ses languettes, avec le
  /// pointeur de l'appui : `HerosDraftGame` le retient quand il ouvre ou
  /// garde une fiche (spec P-05 vague 1, A12).
  final void Function(EnemyCard enemy, int pointerId) onTapEnemy;

  @override
  bool get isPlayer => false;

  @override
  late final RectangleComponent borderInfo;
  late final EnemyHealthBar healthBar;
  @override
  late final SpriteComponent sprite;

  String get id => instance.id;
  EnemyData get data => instance.data;
  @override
  EntityStats get stats => instance.stats;
  EnemyIntent? get currentIntent => instance.currentIntent;
  EnemyIntent? get effectiveIntent => instance.effectiveIntent;
  bool get skipsAction => instance.skipsAction;
  bool get isBoss => instance.isBoss;

  bool isSelected = false;
  bool isDead = false;
  bool isPendingDeath = false;
  EnemyInstance? _pendingVisualInstance;
  bool _pendingFireDamage = false;
  bool _holdingVisualStats = false;

  double _scaleMultiplier = 1.0;
  double get scaleMultiplier => _scaleMultiplier;
  set scaleMultiplier(double value) {
    if (_scaleMultiplier == value) return;
    _scaleMultiplier = value;
    _snapScale();
  }

  /// L'échelle de la carte au repos, fiche fermée.
  double get restScale =>
      game.scaleFactor * 1.45 * (isBoss ? 1.25 : 1.0) * _scaleMultiplier;

  /// L'échelle à laquelle les effets ramènent la carte : agrandie tant que sa
  /// fiche est ouverte (spec P-05 vague 1, A11).
  double get baseScale =>
      restScale * (_isInspected ? GameConstants.inspectionScale : 1.0);

  bool _isInspected = false;

  /// La fiche de cet ennemi est ouverte. Seul `HerosDraftGame` l'écrit ; ni
  /// la sélection ni la surbrillance n'y touchent.
  bool get isInspected => _isInspected;
  set isInspected(bool value) {
    _isInspected = value;
    if (isLoaded) _refreshBorderVisuals();
  }

  /// La place que la remise en page donne à la carte, fiche fermée.
  Vector2 restPosition = Vector2.zero();

  /// La place vers laquelle la carte va, effets de la fiche compris : chaque
  /// déplacement de la fiche ou de la remise en page s'ajoute à la position
  /// par écart relatif, si bien que les secousses en vol, qui reviennent à 0,
  /// ne faussent jamais l'arrivée.
  Vector2 _headingTo = Vector2.zero();

  ScaleEffect? _inspectionScale;
  double? _inspectionScaleTarget;

  /// Pose l'échelle de base, sauf si l'agrandissement de la fiche y va déjà :
  /// chaque reconstruction de `GameScreen` rappelle `onGameResize` à taille
  /// inchangée, et ne doit pas couper l'animation. Une cible neuve (vrai
  /// redimensionnement) l'arrête, dont le reste s'ajouterait sinon.
  void _snapScale() {
    final target = baseScale;
    final running = _inspectionScale;
    if (running != null &&
        !running.isRemoving &&
        !running.isRemoved &&
        _inspectionScaleTarget == target) {
      return;
    }
    running?.removeFromParent();
    _inspectionScale = null;
    scale = Vector2.all(target);
  }

  /// Un effet qui écrit l'échelle : un `ScaleEffect`, ou la séquence d'une
  /// réaction aux coups qui en porte un.
  static bool _carriesScale(Component c) =>
      c is ScaleEffect ||
      (c is SequenceEffect && c.children.any((e) => e is ScaleEffect));

  /// La descente de la carte ouverte : le haut de sa barre reste où il était
  /// quand elle grandit (B40).
  double get _inspectionDrop =>
      (size.y / 2 - GameConstants.enemyHealthBarTop) * (baseScale - restScale);

  Vector2 get _targetPosition => restPosition + Vector2(0, _inspectionDrop);

  /// Pose la carte à sa place, la descente de la fiche comprise, par l'écart
  /// à sa place précédente : une place inchangée ne touche à rien, une
  /// descente en vol va à son terme. `LayoutSystem.repositionEnemies` passe
  /// par ici.
  void place(Vector2 rest) {
    restPosition = rest;
    final target = _targetPosition;
    position += target - _headingTo;
    _headingTo = target;
  }

  /// Joue l'agrandissement ou le retour, la descente et la priorité qui
  /// suivent [isInspected] ; seulement pour une carte chargée et vivante.
  void animateInspection() {
    priority = _isInspected ? GameConstants.priorityInspectedEnemy : 0;
    removeAll(children.where(_carriesScale).toList());
    _inspectionScaleTarget = baseScale;
    add(
      _inspectionScale = ScaleEffect.to(
        Vector2.all(baseScale),
        EffectController(duration: GameConstants.inspectionSeconds),
      ),
    );
    final target = _targetPosition;
    final delta = target - _headingTo;
    _headingTo = target;
    if (!delta.isZero()) {
      add(
        MoveEffect.by(
          delta,
          EffectController(duration: GameConstants.inspectionSeconds),
        ),
      );
    }
    // La séquence d'un coup retirée ne rendra pas la bordure qu'elle teintait.
    _refreshBorderVisuals();
  }

  /// Le rectangle de la carte ouverte à l'arrivée, barre et languettes au
  /// repos comprises, sur le canevas : ce que `GameScreen` lit pour placer le
  /// cadre de la fiche.
  Rect inspectionRect() {
    var local = bodyLocalRect;
    if (isLoaded) {
      for (final tabs in [leftTabs, rightTabs]) {
        final rest = tabs.restLocalRect;
        if (rest != null) local = local.expandToInclude(rest);
      }
    }
    final s = baseScale;
    final c = _targetPosition;
    return Rect.fromLTRB(
      c.x + (local.left - size.x / 2) * s,
      c.y + (local.top - size.y / 2) * s,
      c.x + (local.right - size.x / 2) * s,
      c.y + (local.bottom - size.y / 2) * s,
    );
  }

  @override
  double get entityBaseScale => baseScale;

  @override
  void refreshBorderVisuals() {
    _refreshBorderVisuals();
  }

  @override
  Rect get bodyLocalRect => enemyBodyRect(size.x, size.y);

  /// Le plus haut montant d'armure atteint depuis qu'elle est tombee a 0 : le
  /// plein du voile de la barre de PV (`ArmorVeil`).
  int _armorPeak;

  EnemyCard({required this.instance, required this.onTapEnemy})
    : _armorPeak = instance.stats.armure,
      super(size: Vector2(100, 140));

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

    healthBar = EnemyHealthBar(width: size.x, onTap: onTapDown);
    add(healthBar);

    addStatusTabs(onTapDown);
    refreshStatusTabs();

    _refreshHealthBar();

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
    _snapScale();
  }

  void _refreshHealthBar() {
    healthBar.setValues(
      currentPv: stats.currentPv,
      maxPv: stats.maxPv,
      armor: stats.armure,
      veil: ArmorVeil.fraction(armor: stats.armure, peak: _armorPeak),
    );
  }

  String _brokenNameOf(String chargeId) =>
      game.chargeCatalog[chargeId]?.brokenName(activeLocale) ?? '';

  /// [fireDamage] suit l'etat retenu jusqu'a son application : un etat plus
  /// recent qui le remplace garde les degats du Feu qu'il contient.
  void updateStats(EnemyInstance newInstance, {bool fireDamage = false}) {
    if (game.isCardAnimating || _holdingVisualStats) {
      _pendingVisualInstance = newInstance;
      _pendingFireDamage = _pendingFireDamage || fireDamage;
    } else {
      _applyInstance(newInstance, fireDamage: fireDamage);
    }
  }

  /// Fait differer `updateStats`, comme pendant l'animation d'une carte,
  /// jusqu'a `resolvePendingVisualStats` : le voisin d'une explosion attend
  /// sa boule de feu (spec P-53, §5.2, F-a).
  void holdVisualStats() {
    _holdingVisualStats = true;
  }

  /// Applique ce qui attendait et cesse de retenir. Sans rien en attente, ne
  /// fait rien d'autre : appelable deux fois sans effet double.
  void resolvePendingVisualStats() {
    _holdingVisualStats = false;
    final pending = _pendingVisualInstance;
    if (pending != null) {
      final fireDamage = _pendingFireDamage;
      _pendingVisualInstance = null;
      _pendingFireDamage = false;
      _applyInstance(pending, fireDamage: fireDamage);
    }
  }

  /// L'unique application d'un etat a la carte, que `updateStats` la joue tout
  /// de suite ou que `resolvePendingVisualStats` la rejoue apres l'impact.
  void _applyInstance(EnemyInstance next, {bool fireDamage = false}) {
    triggerHitReactions(stats, next.stats, fireDamage: fireDamage);
    refreshChargeVisuals(stats, next.stats);
    _armorPeak = ArmorVeil.nextPeak(
      peak: _armorPeak,
      oldArmor: stats.armure,
      newArmor: next.stats.armure,
    );
    instance = next;
    _refreshHealthBar();
    refreshStatusTabs();
  }

  void _refreshBorderVisuals() {
    if (_isInspected || isSelected) {
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
    _refreshBorderVisuals();
  }

  bool _isHighlighted = false;
  double _glowOpacity = 1.0;
  dynamic _glowAnimation; // Dynamic to avoid exact type check compile error if Effect is not fully imported

  void setHighlight(bool highlight) {
    if (_isHighlighted == highlight) return;
    _isHighlighted = highlight;
    if (!isLoaded) return;

    _refreshBorderVisuals();
    if (!_isHighlighted) {
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

  /// L'action perdue d'un ennemi gele (spec P-53, §5.2, G-a) : trois secousses
  /// a la place de l'elan, puis la gangue se brise et l'etat rompu flotte
  /// au-dessus de la carte. La gangue n'est plus tenue des le debut, pour que
  /// l'etat consomme, qui arrive vers la fin des secousses, n'en trouve aucune
  /// a faire fondre.
  void frozenTurnAnimation() {
    final shell = releaseFrost();
    final skipping = instance.skippingCharge;
    final name = skipping == null ? '' : _brokenNameOf(skipping);
    add(
      MoveEffect.by(
        Vector2(10, 0),
        EffectController(
          duration: GameConstants.combatDelayFrozenShakeMs / 1000 / 6,
          alternate: true,
          repeatCount: 3,
        ),
        onComplete: () {
          shell?.shatter();
          if (name.isEmpty || !isMounted) return;
          spawnFloatingText(
            name,
            FrostShell.veilColor,
            position + Vector2(0, -size.y * scale.y / 2),
          );
        },
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapEnemy(this, event.pointerId);
  }
}
