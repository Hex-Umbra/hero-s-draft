import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../../heros_draft_game.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/entity_stats.dart';
import '../../../models/combat_state.dart';
import '../../../services/audio/game_moment.dart';
import '../../../models/charge_track.dart';
import '../../../models/data/charge_data.dart';
import '../floating_text.dart';
import '../../game_constants.dart';
import '../../systems/entity_hover.dart';
import '../../systems/status_readout.dart';
import '../visual_effects/charge_halo.dart';
import '../visual_effects/fire_wave_effects.dart';
import '../visual_effects/frost_shell.dart';
import 'status_tabs.dart';

abstract class CombatEntity extends PositionComponent
    with HasGameReference<HerosDraftGame> {
  CombatEntity({super.position, super.size, super.scale, super.angle, super.anchor, super.children, super.priority});

  /// Delai entre les « +N » de deux coups d'une meme vague de coups.
  static const int chargeHitStaggerMs = 100;
  static const double chargeHitSpreadX = 28;

  SpriteComponent get sprite;
  /// Le flash d'un coup encaissé sur l'armure : cyan de 4, jusqu'à ce que la
  /// réaction rende la bordure (D12).
  void flashArmorHit();
  double get entityBaseScale;
  bool get isPlayer;
  EntityStats get stats;

  /// Le corps de la zone de la carte, en unités de la carte : sans ses
  /// languettes.
  Rect get bodyLocalRect;

  /// Le rectangle auquel s'ancrent la barre, les languettes, les textes et les
  /// effets (A16) : le gabarit d'un ennemi, la carte entière du héros.
  Rect get anchorLocalRect => Rect.fromLTWH(0, 0, size.x, size.y);

  /// La fenêtre de la carte, en unités de la carte : où se posent la gangue
  /// de givre et le halo. Le défaut est la carte entière.
  Rect get windowLocalRect => Rect.fromLTWH(0, 0, size.x, size.y);

  void refreshBorderVisuals();

  String get activeLocale {
    final context = game.buildContext;
    if (context != null) {
      return Localizations.localeOf(context).languageCode;
    }
    return 'fr'; // Langue par défaut en secours
  }

  /// Les textes de la langue active : la couche Flame n'a pas de contexte de
  /// widget où les lire.
  AppLocalizations get l10n => lookupAppLocalizations(Locale(activeLocale));

  late final StatusTabs leftTabs;
  late final StatusTabs rightTabs;

  bool _hovered = false;

  /// Pose les deux languettes contre [anchorLocalRect].
  void addStatusTabs() {
    leftTabs = StatusTabs(side: StatusSide.left, anchorRect: anchorLocalRect);
    rightTabs = StatusTabs(side: StatusSide.right, anchorRect: anchorLocalRect);
    addAll([leftTabs, rightTabs]);
  }

  /// Relit les entrées des deux languettes sur [stats] ; [counterId] est l'id
  /// du compteur du passif actif du héros.
  void refreshStatusTabs({String? counterId}) {
    final readout = StatusReadout.of(
      stats,
      game.chargeCatalog,
      l10n,
      activeLocale,
      counterId: counterId,
    );
    leftTabs.setEntries(readout.left);
    rightTabs.setEntries(readout.right);
    // Une largeur déroulée neuve peut changer le sens du déroulé.
    if (_hovered) setHovered(true);
  }

  /// La zone de la carte en unités de la carte (spec P-05, §4.5 ; vague 2,
  /// A17) : son corps et ses languettes, au repos comme déroulées. Le
  /// rectangle au repos reste dans la zone quand une languette se déroule vers
  /// l'intérieur : le pointeur qui l'a déroulée y est encore.
  List<Rect> get _localZone => [
        bodyLocalRect,
        if (isLoaded)
          for (final tabs in [leftTabs, rightTabs]) ...tabs.zoneLocalRects,
      ];

  /// La même zone, sur le canevas : le survol et le lâcher la lisent.
  List<Rect> get zone => [for (final local in _localZone) _absoluteRect(local)];

  bool zoneContains(Vector2 point) {
    final offset = point.toOffset();
    return zone.any((rect) => rect.contains(offset));
  }

  /// L'appui suit la même zone : la carte reçoit tout appui de sa zone, coins
  /// au-dessus du canevas et languettes comprises (A17).
  @override
  bool containsLocalPoint(Vector2 point) {
    final offset = point.toOffset();
    return _localZone.any((rect) => rect.contains(offset));
  }

  /// La carte est sous la souris : ses languettes sont déroulées.
  bool get isHovered => _hovered;

  /// La priorité de la carte parmi ses voisines : au-dessus d'elles quand elle
  /// est survolée.
  int get layerPriority => _hovered ? GameConstants.priorityEntityHovered : 0;

  /// La carte survolée passe au-dessus de ses voisines et déroule ses deux
  /// languettes, chacune vers l'intérieur si elle sortirait de l'écran (B39).
  void setHovered(bool hovered) {
    _hovered = hovered;
    priority = layerPriority;
    for (final tabs in [leftTabs, rightTabs]) {
      tabs.setUnfolded(
        hovered,
        inward: hovered &&
            unfoldsInward(
              side: tabs.side,
              attachEdge: absolutePositionOf(
                Vector2(
                  tabs.side == StatusSide.left
                      ? anchorLocalRect.left
                      : anchorLocalRect.right,
                  0,
                ),
              ).x,
              unfoldedWidth: tabs.unfoldedWidth * absoluteScale.x,
              screenWidth: game.size.x,
            ),
      );
    }
  }

  Rect _absoluteRect(Rect local) => Rect.fromPoints(
        absolutePositionOf(Vector2(local.left, local.top)).toOffset(),
        absolutePositionOf(Vector2(local.right, local.bottom)).toOffset(),
      );

  void shieldHitAnimation() {
    removeAll(children.whereType<ScaleEffect>());
    final double bScale = entityBaseScale;

    // Bump d'échelle pour l'armure
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(bScale * 1.08),
          EffectController(duration: 0.06, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(bScale),
          EffectController(duration: 0.2, curve: Curves.easeIn),
          onComplete: () {
            refreshBorderVisuals();
          },
        ),
      ]),
    );

    // Le flash cyan d'un coup sur l'armure (D12).
    flashArmorHit();
  }

  void shakeAndFlashAnimation({bool isPoison = false, bool isCritical = false}) {
    final double bScale = entityBaseScale;

    removeAll(children.whereType<ScaleEffect>());

    // 1. Sleek Scale Bump (Elastic Out)
    final double bumpMultiplier = isCritical ? 1.45 : (isPoison ? 1.12 : 1.22);
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(bScale * bumpMultiplier),
          EffectController(duration: 0.08, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(bScale),
          EffectController(duration: 0.35, curve: Curves.elasticOut),
        ),
      ]),
    );

    // 2. High-frequency Shake
    final rand = Random();
    final shakeIntensity = isCritical ? 28.0 : (isPoison ? 8.0 : 18.0);
    final shakeCount = isCritical ? 8 : 5;
    for (int i = 0; i < shakeCount; i++) {
      add(
        MoveEffect.by(
          Vector2(
            (rand.nextDouble() - 0.5) * shakeIntensity,
            (rand.nextDouble() - 0.5) * shakeIntensity,
          ),
          EffectController(duration: 0.025, alternate: true),
        ),
      );
    }

    // 3. Decoupled Color Tint on sprite
    final flashColor = isCritical
        ? const Color(0xFFF59E0B)
        : (isPoison ? const Color(0xFF10B981) : Colors.redAccent);
    _replaceSpriteTint(
      SequenceEffect([
        ColorEffect(
          flashColor,
          EffectController(duration: 0.1),
          opacityTo: isCritical ? 0.85 : 0.75,
        ),
        ColorEffect(
          flashColor,
          EffectController(duration: isCritical ? 0.35 : 0.25, curve: Curves.easeIn),
          opacityTo: 0.0,
        ),
      ]),
    );
  }

  void spawnDamageParticles({required Color color, required int count}) {
    final rand = Random();
    final centerPos = position.clone();

    game.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: count,
          lifespan: 0.6,
          generator: (i) {
            final angle = rand.nextDouble() * 2 * pi;
            final targetOffset =
                Vector2(cos(angle), sin(angle)) * (40 + rand.nextDouble() * 60);

            return MovingParticle(
              curve: Curves.easeOutCubic,
              from: centerPos,
              to: centerPos + targetOffset,
              child: ScaledParticle(
                child: CircleParticle(
                  radius: 1.5 + rand.nextDouble() * 2.0,
                  paint: Paint()
                    ..color = color.withValues(alpha: 0.95)
                    ..style = PaintingStyle.fill,
                ),
              ),
            );
          },
        ),
      )..priority = priority + 10,
    );
  }

  /// La teinte qui joue sur le sprite : deux `ColorEffect` concurrents se
  /// disputeraient son filtre, la suivante remplace donc celle-ci.
  Effect? _spriteTint;

  void _replaceSpriteTint(Effect tint) {
    _spriteTint?.removeFromParent();
    _spriteTint = tint;
    sprite.add(tint);
  }

  /// Le rougeoiement d'une carte que le Feu touche sans eclair, ou que sa
  /// boule de feu embrase (spec P-53, §5.2, F-a) : une teinte orange sur le
  /// sprite, qui remplace la teinte en cours.
  void emberFlash() {
    _replaceSpriteTint(
      SequenceEffect([
        ColorEffect(
          FireBurst.core,
          EffectController(duration: _emberSeconds / 2),
          opacityTo: 0.7,
        ),
        ColorEffect(
          FireBurst.core,
          EffectController(duration: _emberSeconds / 2, curve: Curves.easeIn),
          opacityFrom: 0.7,
          opacityTo: 0.0,
        ),
      ]),
    );
  }

  static const double _emberSeconds = 0.2;

  void dashAnimation({bool isDownward = false}) {
    final double direction = isDownward ? 1.0 : -1.0;
    add(
      SequenceEffect([
        MoveEffect.by(
          Vector2(0, 50 * direction),
          EffectController(duration: 0.1, curve: Curves.easeOut),
        ),
        MoveEffect.by(
          Vector2(0, -50 * direction),
          EffectController(duration: 0.15, curve: Curves.bounceOut),
        ),
      ]),
    );
  }

  void spawnFloatingText(
    String text,
    Color color,
    Vector2 globalPos, {
    bool isCritical = false,
    bool isPoison = false,
    bool isShield = false,
  }) {
    final ft = FloatingText(
      text: text,
      color: color,
      position: globalPos,
      isUpward: isPlayer,
      isCritical: isCritical,
      isPoison: isPoison,
      isShield: isShield,
    );
    ft.priority = 200;
    game.add(ft);
  }

  /// Le « +N » de chaque coup que le nouvel etat a de plus que l'ancien, un
  /// texte par coup, decales dans le temps et de cote pour ne pas se recouvrir.
  void _spawnChargeHitBonuses(EntityStats oldStats, EntityStats newStats) {
    final fresh = newStats.chargeHits.skip(oldStats.chargeHits.length).toList();
    for (var k = 0; k < fresh.length; k++) {
      final text = '+${fresh[k].bonus}';
      final offsetX = (k - (fresh.length - 1) / 2) * chargeHitSpreadX;
      Future.delayed(Duration(milliseconds: k * chargeHitStaggerMs), () {
        if (!isMounted) return;
        spawnFloatingText(
          text,
          ChargeHalo.color,
          position + Vector2(offsetX, -anchorLocalRect.height * scale.y / 2),
        );
      });
    }
  }

  FrostShell? _frostShell;
  FrostVignette? _frostVignette;

  /// Pose et retire les etats qui durent, a la transition de leur piste de
  /// charge : le halo d'une piste `amplifyHits` active, la gangue d'une piste
  /// `skipAction` en attente ou `weakenDealt` active, et le givre aux coins
  /// de l'ecran pour cette derniere.
  void refreshChargeVisuals(EntityStats oldStats, EntityStats newStats) {
    final wasHaloed = _hasActiveAmplify(oldStats);
    final isHaloed = _hasActiveAmplify(newStats);
    if (isHaloed && !wasHaloed) {
      final window = windowLocalRect;
      add(
        ChargeHalo(
          size: Vector2(window.width, window.height),
          position: Vector2(window.left, window.top),
        ),
      );
    } else if (wasHaloed && !isHaloed) {
      for (final halo in children.whereType<ChargeHalo>()) {
        halo.fadeOut();
      }
    }

    final oldFrost = _frostKind(oldStats);
    final newFrost = _frostKind(newStats);
    if (newFrost != null && oldFrost == null) {
      final window = windowLocalRect;
      _frostShell = FrostShell(
        size: Vector2(window.width, window.height),
        position: Vector2(window.left, window.top),
        opacity: newFrost == RuptureKind.skipAction
            ? FrostShell.enemyOpacity
            : FrostShell.heroOpacity,
      );
      add(_frostShell!);
      if (newFrost == RuptureKind.skipAction) {
        _squeezeAnimation();
      } else {
        _frostVignette = FrostVignette(
          size: game.size.clone(),
          priority: GameConstants.priorityFrostVignette,
        );
        game.add(_frostVignette!);
      }
    } else if (newFrost == null && oldFrost != null) {
      _frostShell?.fadeOut();
      _frostShell = null;
      _frostVignette?.fadeOut();
      _frostVignette = null;
    }
  }

  /// Cesse de tenir la gangue et la rend (nulle s'il n'y en a pas) : elle
  /// reste affichee, mais aucune transition ne la retrouve plus.
  FrostShell? releaseFrost() {
    final shell = _frostShell;
    _frostShell = null;
    return shell;
  }

  /// Le serrement de la carte pendant la montee de la gangue : echelle de
  /// base × 1 → 0,97 → 1, creux a mi-course.
  void _squeezeAnimation() {
    removeAll(children.whereType<ScaleEffect>());
    final double bScale = entityBaseScale;
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(bScale * 0.97),
          EffectController(duration: FrostShell.riseSeconds / 2),
        ),
        ScaleEffect.to(
          Vector2.all(bScale),
          EffectController(duration: FrostShell.riseSeconds / 2),
        ),
      ]),
    );
  }

  @override
  void onRemove() {
    _frostVignette?.removeFromParent();
    _frostVignette = null;
    super.onRemove();
  }

  /// La sorte de rupture dont la gangue est appelee par un etat : `skipAction`
  /// en attente ou `weakenDealt` active, nulle sinon.
  static RuptureKind? _frostKind(EntityStats stats) {
    for (final track in stats.charges.values) {
      if (track.rupture.kind == RuptureKind.skipAction &&
          track.state == ChargeState.brokenPending) {
        return RuptureKind.skipAction;
      }
      if (track.rupture.kind == RuptureKind.weakenDealt &&
          track.state == ChargeState.brokenActive) {
        return RuptureKind.weakenDealt;
      }
    }
    return null;
  }

  static bool _hasActiveAmplify(EntityStats stats) => stats.charges.values.any(
        (t) =>
            t.rupture.kind == RuptureKind.amplifyHits &&
            t.state == ChargeState.brokenActive,
      );

  /// [fireDamage] vrai : les degats viennent du Feu, et ne prennent jamais la
  /// teinte ni le texte du Poison.
  void triggerHitReactions(
    EntityStats oldStats,
    EntityStats newStats, {
    bool suppressArmorChange = false,
    bool fireDamage = false,
  }) {
    final isTurnPhaseForPoison = isPlayer
        ? game.currentPhase == TurnPhase.player
        : game.currentPhase == TurnPhase.enemy;
    final hadPoison = oldStats.statuses.any((s) => s.id == 'poison');
    final isPoisonDamage = !fireDamage && isTurnPhaseForPoison && hadPoison;

    if (!suppressArmorChange) {
      if (newStats.armure < oldStats.armure) {
        final lostArmor = oldStats.armure - newStats.armure;
        spawnFloatingText(
          '-$lostArmor',
          const Color(0xFF3B82F6), // Technical premium blue
          position + Vector2(0, (anchorLocalRect.height / 2 - 20) * scale.y),
          isShield: true,
        );
        game.audio.onMoment(GameMoment.armorHit);
        shieldHitAnimation();
      } else if (newStats.armure > oldStats.armure) {
        final gainedArmor = newStats.armure - oldStats.armure;
        spawnFloatingText(
          '+$gainedArmor',
          Colors.lightBlueAccent,
          position + Vector2(0, -anchorLocalRect.height * scale.y / 2),
        );
        // Gagner de l'armure et en encaisser un coup sont deux evenements
        // opposes : ils partageaient `armorHit` avant le 2026-08-29, si bien
        // qu'une carte defensive jouait le son du coup recu.
        game.audio.onMoment(GameMoment.armorGain);
      }
    }

    _spawnChargeHitBonuses(oldStats, newStats);

    if (newStats.currentPv < oldStats.currentPv) {
      final lostHp = oldStats.currentPv - newStats.currentPv;
      final isCritical = newStats.lastActionWasCrit;
      game.audio.onMoment(isCritical ? GameMoment.impactCrit : GameMoment.impact);
      final damageColor = isPoisonDamage
          ? const Color(0xFF10B981) // Poison neon green
          : (isCritical
              ? const Color(0xFFF59E0B)
              : const Color(0xFFF87171)); // Red spectrum

      final double verticalOffset = isPlayer
          ? -anchorLocalRect.height / 4
          : anchorLocalRect.height / 2;

      spawnFloatingText(
        '-$lostHp',
        damageColor,
        position + Vector2(0, verticalOffset * scale.y),
        isCritical: isCritical,
        isPoison: isPoisonDamage,
      );

      // Visual animations feedback
      shakeAndFlashAnimation(isPoison: isPoisonDamage, isCritical: isCritical);

      // Spawn particles
      spawnDamageParticles(
        color: damageColor,
        count: isCritical ? 35 : (isPoisonDamage ? 12 : 15),
      );
    } else if (newStats.currentPv > oldStats.currentPv) {
      // Toute hausse de PV est traitee comme un soin. Cela ne produit pas de
      // faux positif aujourd'hui pour deux raisons qui ne sont PAS des garde-fous
      // audio : la premiere synchro d'une entite passe par son constructeur et
      // non par `updateStats`, et `GameScreen` est depile avant que les gains de
      // niveau et les recompenses n'appliquent leurs modificateurs de PV max.
      // Un contenu qui accorderait des PV max EN COMBAT (relique, competence)
      // casserait cet equilibre et ferait sonner un soin sans soin — c'est le
      // meme defaut que `suppressArmorChange` corrige deja pour l'armure.
      game.audio.onMoment(GameMoment.heal);
    }
  }
}
