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
import 'widgets/card_renderer.dart';
import 'widgets/card_interaction_handler.dart';

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
  late final CardRenderer renderer;
  late final CardInteractionHandler interactionHandler;

  // État visuel actuel (exposé aux classes d'accompagnement)
  bool isFlashing = false;
  bool isCancelling = false;
  bool isHoveringCancelZone = false;
  bool isPlayed = false;
  bool isEnteringHand = false;

  bool get isSelected => game.focusedCard == this;

  @override
  set opacity(double value) {
    if (_opacity == value) return;
    _opacity = value;
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
    if (isCancelling) return const Color(0xFF1A1A1A);
    switch (card.data.type) {
      case CardType.attack:
        return const Color(0xFF4A1D1D);
      case CardType.skill:
        return const Color(0xFF152A4A);
      case CardType.power:
        return const Color(0xFF453215);
      case CardType.status:
        return const Color(0xFF2D2D2D);
    }
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
    if (r.contains('unique')) return const Color(0xFFFFD700);
    if (r.contains('legendary')) return Colors.orangeAccent;
    if (r.contains('epic')) return Colors.purpleAccent;
    if (r.contains('rare')) return Colors.blueAccent;
    if (r.contains('uncommon')) return Colors.greenAccent;
    return Colors.white70;
  }

  List<Color> getRarityShineColors() {
    // Rareté Unique → arc-en-ciel progressif basé sur le nombre d'upgrades
    if (card.data.rarity.name.toLowerCase().contains('unique')) {
      final baseColor = getRarityColor();
      final pool = [
        baseColor,
        Colors.white70,
        Colors.greenAccent,
        Colors.blueAccent,
        Colors.purpleAccent,
        Colors.orangeAccent,
        Colors.red,
        Colors.yellow,
        Colors.cyan,
        Colors.pink,
      ];
      final upgradeCount = card.forgeUpgrades.length;
      final count = (upgradeCount + 1).clamp(1, pool.length);
      final colors = pool.sublist(0, count);
      return [...colors, colors.first];
    }
    final baseColor = getRarityColor();
    final hsv = HSVColor.fromColor(baseColor);
    if (hsv.saturation < 0.15 || hsv.value < 0.15) {
      return [
        baseColor,
        Colors.white,
        const Color(0xFFE0E0E0),
        const Color(0xFFBDBDBD),
        Colors.white,
        baseColor,
      ];
    }
    final hue = hsv.hue;
    if (hue >= 340 || hue < 20) {
      return [baseColor, Colors.orangeAccent, Colors.red, Colors.pinkAccent, baseColor];
    } else if (hue >= 20 && hue < 50) {
      return [baseColor, Colors.amber, Colors.yellow, Colors.deepOrange, baseColor];
    } else if (hue >= 50 && hue < 70) {
      return [baseColor, Colors.lightGreenAccent, Colors.yellowAccent, Colors.amberAccent, baseColor];
    } else if (hue >= 70 && hue < 165) {
      return [baseColor, Colors.limeAccent, Colors.tealAccent, Colors.green, baseColor];
    } else if (hue >= 165 && hue < 200) {
      return [baseColor, Colors.cyanAccent, Colors.blueAccent, Colors.tealAccent, baseColor];
    } else if (hue >= 200 && hue < 260) {
      return [baseColor, Colors.cyan, Colors.indigoAccent, Colors.blue, baseColor];
    } else {
      return [baseColor, Colors.pinkAccent, Colors.deepPurpleAccent, Colors.purple, baseColor];
    }
  }

  void refreshVisuals() {
    textRenderer.refreshVisuals(1.0, isFlashing, isCancelling);
  }

  String _determineDamageType() {
    final lowerTitle =
        '${card.data.getName(activeLocale).toLowerCase()} ${card.data.id.toLowerCase()}';

    for (var effect in card.data.effects) {
      if (effect.type == 'apply_status') {
        if (effect.statusId == 'burn') return 'fire';
        if (effect.statusId == 'freeze') return 'cold';
        if (effect.statusId == 'shock') return 'electric';
        if (effect.statusId == 'poison') return 'poison';
      }
    }

    if (lowerTitle.contains('feu') ||
        lowerTitle.contains('fire') ||
        lowerTitle.contains('brûlure') ||
        lowerTitle.contains('burn')) {
      return 'fire';
    }
    if (lowerTitle.contains('glace') ||
        lowerTitle.contains('ice') ||
        lowerTitle.contains('gel') ||
        lowerTitle.contains('freeze') ||
        lowerTitle.contains('froid') ||
        lowerTitle.contains('cold')) {
      return 'cold';
    }
    if (lowerTitle.contains('foudre') ||
        lowerTitle.contains('thunder') ||
        lowerTitle.contains('shock') ||
        lowerTitle.contains('lightning') ||
        lowerTitle.contains('tonnerre') ||
        lowerTitle.contains('élec')) {
      return 'electric';
    }
    if (lowerTitle.contains('poison') ||
        lowerTitle.contains('tox') ||
        lowerTitle.contains('venin') ||
        lowerTitle.contains('venom')) {
      return 'poison';
    }
    return 'physical';
  }

  Color getElementalColor() {
    final type = _determineDamageType();
    switch (type) {
      case 'fire':
        return Colors.orangeAccent;
      case 'cold':
        return Colors.cyanAccent;
      case 'poison':
        return const Color(0xFF10B981); // Emerald green
      case 'electric':
        return Colors.amberAccent;
      case 'physical':
      default:
        return card.data.type == CardType.attack
            ? const Color(0xFFEF4444)
            : Colors.white70;
    }
  }

  String buildDetailedDescription() {
    String desc = '';

    // Prepend card details header matching the menu tooltip style
    String details = '';

    // 1. Target Type
    final targetHeader = activeLocale == 'fr' ? '🎯 Cible : ' : '🎯 Target: ';
    String targetText = '';
    switch (card.data.target) {
      case CardTarget.singleEnemy:
        targetText = getTranslation((l) => l.targetSingleEnemy, fallback: 'Single enemy');
        break;
      case CardTarget.allEnemies:
        targetText = getTranslation((l) => l.targetAllEnemies, fallback: 'All enemies');
        break;
      case CardTarget.self:
        targetText = getTranslation((l) => l.targetSelf, fallback: 'Self');
        break;
      case CardTarget.none:
        targetText = getTranslation((l) => l.targetNone, fallback: 'None');
        break;
    }
    details += '$targetHeader$targetText\n';

    // 2. Rarity
    final rarityHeader = activeLocale == 'fr' ? '💎 Rareté : ' : '💎 Rarity: ';
    String rarityText = '';
    switch (card.data.rarity) {
      case CardRarity.common:
        rarityText = getTranslation((l) => l.rarityCommon, fallback: 'Common');
        break;
      case CardRarity.uncommon:
        rarityText = getTranslation((l) => l.rarityUncommon, fallback: 'Uncommon');
        break;
      case CardRarity.rare:
        rarityText = getTranslation((l) => l.rarityRare, fallback: 'Rare');
        break;
      case CardRarity.epic:
        rarityText = getTranslation((l) => l.rarityEpic, fallback: 'Epic');
        break;
      case CardRarity.legendary:
        rarityText = getTranslation((l) => l.rarityLegendary, fallback: 'Legendary');
        break;
      case CardRarity.unique:
        rarityText = activeLocale == 'fr' ? 'Unique' : 'Unique';
        break;
    }
    details += '$rarityHeader$rarityText\n';

    // 3. Type
    final typeHeader = activeLocale == 'fr' ? '🏷️ Type : ' : '🏷️ Type: ';
    final typeText = getTypeLabel();
    details += '$typeHeader$typeText\n';

    // 4. Cost
    final costHeader = activeLocale == 'fr' ? '⚡ Coût : ' : '⚡ Cost: ';
    details += '$costHeader${card.currentCost} Mana\n';

    desc += '$details\n';

    final elementalType = _determineDamageType();
    if (card.data.effects.isNotEmpty && elementalType != 'physical') {
      final typeStr = elementalType == 'fire'
          ? (activeLocale == 'fr' ? 'FEU 🔥' : 'FIRE 🔥')
          : elementalType == 'cold'
          ? (activeLocale == 'fr' ? 'FROID ❄️' : 'COLD ❄️')
          : elementalType == 'poison'
          ? (activeLocale == 'fr' ? 'POISON 🧪' : 'POISON 🧪')
          : (activeLocale == 'fr' ? 'FOUDRE ⚡' : 'LIGHTNING ⚡');
      desc += '[$typeStr]\n';
    }

    desc += '${card.data.getDescription(activeLocale)}\n\n';

    if (card.data.type == CardType.power || card.data.isExhaust) {
      desc +=
          '${getTranslation((l) => l.exhaustWarning, fallback: '⚠️ USAGE UNIQUE (Épuisement)')}\n\n';
    }

    final heroAttack = game.heroCard?.stats.effectiveAttaque ?? 0;

    int extraDamage = 0;
    int extraArmor = 0;
    for (var upgrade in card.forgeUpgrades) {
      final parts = upgrade.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final k = int.tryParse(parts[1]) ?? 0;
      if (k <= 0) continue;
      if (id == 'sharp') extraDamage += 2 * k;
      if (id == 'hardened') extraArmor += 2 * k;
    }

    for (var effect in card.data.effects) {
      int scaledValue = (effect.value * card.rarityMultiplier).round();
      if (effect.type == 'damage') {
        scaledValue += extraDamage;
      } else if (effect.type == 'armor') {
        scaledValue += extraArmor;
      }
      if (effect.type == 'damage') {
        final totalDmg = scaledValue + heroAttack;
        if (card.data.target == CardTarget.allEnemies) {
          desc +=
              '• ${getTranslation((l) => l.cardDescDamageAll(totalDmg), fallback: 'Inflige $totalDmg dégâts à tous les ennemis.')}\n';
        } else {
          desc +=
              '• ${getTranslation((l) => l.cardDescDamage(totalDmg), fallback: 'Inflige $totalDmg dégâts.')}\n';
        }
      }
      if (effect.type == 'heal') {
        desc +=
            '• ${getTranslation((l) => l.cardDescHeal(scaledValue), fallback: 'Soigne $scaledValue PV.')}\n';
      }
      if (effect.type == 'armor') {
        desc +=
            '• ${getTranslation((l) => l.cardDescArmor(scaledValue), fallback: 'Donne $scaledValue Armure.')}\n';
      }
      if (effect.type == 'gain_mana') {
        desc +=
            '• ${getTranslation((l) => l.cardDescGainMana(scaledValue), fallback: 'Gagne $scaledValue Mana.')}\n';
      }
      if (effect.type == 'draw') {
        desc +=
            '• ${getTranslation((l) => l.cardDescDraw(scaledValue), fallback: 'Pioche $scaledValue cartes.')}\n';
      }
      if (effect.type == 'apply_status') {
        final duration = effect.duration ?? 1;
        switch (effect.statusId) {
          case 'strength':
            desc +=
                '• ${getTranslation((l) => l.cardDescStatusStrength(scaledValue, duration), fallback: 'Gagne $scaledValue ATK pendant $duration tours.')}\n';
            break;
          case 'armor_regen':
            desc +=
                '• ${getTranslation((l) => l.cardDescStatusArmorRegen(scaledValue, duration), fallback: 'Pendant $duration tours, gagne $scaledValue Armure au début du tour.')}\n';
            break;
          case 'poison':
            desc +=
                '• ${getTranslation((l) => l.cardDescStatusPoisonDuration(scaledValue, duration), fallback: 'Applique $scaledValue Poison pendant $duration tours.')}\n';
            desc += activeLocale == 'fr'
                ? '  (Subit des dégâts égaux au Poison au début de son tour, puis la durée diminue)\n'
                : '  (Takes damage equal to Poison at turn start, then duration decreases)\n';
            break;
          case 'weakness':
            desc +=
                '• ${getTranslation((l) => l.cardDescStatusWeaknessDuration(scaledValue, duration), fallback: 'Applique $scaledValue Faiblesse pendant $duration tours.')}\n';
            desc += activeLocale == 'fr'
                ? '  (Réduit les dégâts infligés par l\'ennemi de 25%)\n'
                : '  (Reduces damage dealt by the enemy by 25%)\n';
            break;
          case 'vulnerable':
            desc +=
                '• ${getTranslation((l) => l.cardDescStatusVulnerableDuration(scaledValue, duration), fallback: 'Applique $scaledValue Vulnérable pendant $duration tours.')}\n';
            desc += activeLocale == 'fr'
                ? '  (L\'ennemi subit 50% de dégâts supplémentaires)\n'
                : '  (Enemy takes 50% more damage from attacks)\n';
            break;
          case 'strength_regen':
            desc +=
                '• ${getTranslation((l) => l.cardDescStatusStrengthRegen(scaledValue, duration), fallback: 'Gagne $scaledValue Éveil d\'Attaque pendant $duration tours.')}\n';
            break;
          case 'burn':
            desc +=
                '• ${getTranslation((l) => l.cardDescStatusBurnDuration(scaledValue, duration), fallback: 'Applique $scaledValue Brûlure pendant $duration tours.')}\n';
            desc += activeLocale == 'fr'
                ? '  (Subit des dégâts de feu égaux à la Brûlure au début de son tour, puis la valeur diminue de 1)\n'
                : '  (Takes fire damage equal to Burn at turn start, then the value decreases by 1)\n';
            break;
          case 'freeze':
            desc +=
                '• ${getTranslation((l) => l.cardDescStatusFreezeDuration(scaledValue, duration), fallback: 'Applique $scaledValue Gel pendant $duration tours.')}\n';
            desc += activeLocale == 'fr'
                ? '  (Réduit les dégâts de la prochaine attaque de l\'ennemi de 50%)\n'
                : '  (Reduces next enemy attack damage by 50%)\n';
            break;
          case 'shock':
            desc +=
                '• ${getTranslation((l) => l.cardDescStatusShockDuration(scaledValue, duration), fallback: 'Applique $scaledValue Électrocution pendant $duration tours.')}\n';
            desc += activeLocale == 'fr'
                ? '  (Subit des dégâts supplémentaires égaux à l\'Électrocution à chaque coup reçu)\n'
                : '  (Takes extra damage equal to Shock on every hit)\n';
            break;
        }
      }
    }

    if (card.forgeUpgrades.isNotEmpty) {
      desc += '\n\n${activeLocale == 'fr' ? '=== AMÉLIORATIONS DE LA FORGE ===' : '=== FORGE UPGRADES ==='}';
      for (var upgrade in card.forgeUpgrades) {
        final parts = upgrade.split(':');
        final id = parts[0];
        final tierStr = parts.length > 1 ? parts[1] : '1';
        final tier = int.tryParse(tierStr) ?? 1;
        final isFr = activeLocale == 'fr';
        
        String upgName = '';
        String upgDesc = '';
        
        switch (id) {
          case 'sharp':
            upgName = isFr ? 'Tranchant $tier' : 'Sharp $tier';
            final val = 2 * tier;
            upgDesc = isFr ? '+$val Dégâts sur la carte' : '+$val Damage on the card';
            break;
          case 'hardened':
            upgName = isFr ? 'Endurci $tier' : 'Hardened $tier';
            final val = 2 * tier;
            upgDesc = isFr ? '+$val Armure sur la carte' : '+$val Block on the card';
            break;
          case 'burning':
            upgName = isFr ? 'Brûlant $tier' : 'Burning $tier';
            upgDesc = isFr ? 'Applique $tier Brûlure' : 'Applies $tier Burn';
            break;
          case 'freezing':
            upgName = isFr ? 'Congelant $tier' : 'Freezing $tier';
            upgDesc = isFr ? 'Applique $tier Gel' : 'Applies $tier Freeze';
            break;
          case 'shocking':
            upgName = isFr ? 'Surchargé $tier' : 'Shocking $tier';
            upgDesc = isFr ? 'Applique $tier Électrocution' : 'Applies $tier Shock';
            break;
          case 'quick':
            upgName = isFr ? 'Véloce $tier' : 'Quick $tier';
            upgDesc = isFr ? 'Pioche +$tier carte(s)' : 'Draw +$tier card(s)';
            break;
          case 'eco':
            upgName = isFr ? 'Économe $tier' : 'Eco $tier';
            upgDesc = isFr ? 'Gagne +$tier Mana à l\'utilisation' : 'Gains +$tier Mana on play';
            break;
          case 'enduring':
            upgName = isFr ? 'Persistant' : 'Enduring';
            upgDesc = isFr ? 'Retire Épuisement (Exhaust)' : 'Removes Exhaust';
            break;
          default:
            upgName = id;
            upgDesc = '';
        }
        
        desc += '\n• $upgName : $upgDesc';
      }
    }

    return desc.trim();
  }

  Vector2 originalPosition = Vector2.zero();
  double originalAngle = 0;
  int basePriority = 10;

  bool isDragging = false;
  double targetTilt = 0;
  RibbonTrail? activeTrail;
  double foilTime = 0.0;

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
    renderer = CardRenderer(this);
    interactionHandler = CardInteractionHandler(this);
  }

  @override
  void onHoverEnter() => interactionHandler.onHoverEnter();

  @override
  void onHoverExit() => interactionHandler.onHoverExit();

  @override
  void update(double dt) {
    super.update(dt);
    if (isDragging) {
      angle += (targetTilt - angle) * 15 * dt;
      targetTilt += (0 - targetTilt) * 5 * dt;

      animator.spawnTrailParticles();
      activeTrail?.addPoint(position);
    }
    if (game.hoveredCard == this) {
      foilTime += dt * 3.0;
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
  void render(Canvas canvas) => renderer.render(canvas);

  void superRender(Canvas canvas) {
    super.render(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) => interactionHandler.onTapDown(event);

  void clearEffects() {
    final effects = children.whereType<Effect>().toList();
    if (effects.isNotEmpty) {
      removeAll(effects);
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    interactionHandler.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    interactionHandler.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    interactionHandler.onDragEnd(event);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    interactionHandler.onDragCancel(event);
  }

  void shakeAnimation() {
    animator.shakeAnimation();
  }

  void playAnimation(
    EnemyCard? target, {
    required VoidCallback onImpact,
    required VoidCallback onComplete,
  }) {
    animator.playAnimation(target, onImpact: onImpact, onComplete: onComplete);
  }

  void applyFlashVisual() {
    isFlashing = true;
    borderPaint.color = Colors.white;
    refreshVisuals();
  }
}
