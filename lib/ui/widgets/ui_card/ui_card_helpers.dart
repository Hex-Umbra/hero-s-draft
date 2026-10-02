import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/data/card_data.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../../../models/effective_card.dart';

class UiCardEffectVisuals {
  final IconData icon;
  final Color color;
  const UiCardEffectVisuals({required this.icon, required this.color});
}

CardTarget? resolveTarget(CardTarget? targetType, String? target) {
  if (targetType != null) return targetType;
  if (target == null) return null;
  final t = target.toLowerCase();
  if (t.contains('single') || t.contains('unique') || t == 'singleenemy') {
    return CardTarget.singleEnemy;
  }
  if (t.contains('all') || t.contains('tous') || t == 'allenemies') {
    return CardTarget.allEnemies;
  }
  if (t.contains('self') || t.contains('soi')) {
    return CardTarget.self;
  }
  if (t.contains('none') || t.contains('aucun')) {
    return CardTarget.none;
  }
  return null;
}

String determineDamageType(String title, List<CardEffect>? effects) {
  final lowerTitle = title.toLowerCase();

  if (effects != null) {
    for (var effect in effects) {
      if (effect.type == 'apply_status') {
        if (effect.statusId == 'burn') return 'fire';
        if (effect.statusId == 'freeze') return 'cold';
        if (effect.statusId == 'shock') return 'electric';
      }
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
  return 'physical';
}

UiCardEffectVisuals getEffectVisuals(CardEffect effect) {
  if (effect.type == 'damage') {
    return const UiCardEffectVisuals(
      icon: Icons.hardware_rounded,
      color: Colors.redAccent,
    );
  }
  if (effect.type == 'armor') {
    return const UiCardEffectVisuals(
      icon: Icons.shield_rounded,
      color: Colors.blueAccent,
    );
  }
  if (effect.type == 'heal') {
    return const UiCardEffectVisuals(
      icon: Icons.favorite_rounded,
      color: Colors.pinkAccent,
    );
  }
  if (effect.type == 'gain_mana') {
    return const UiCardEffectVisuals(
      icon: Icons.diamond_rounded,
      color: Colors.cyanAccent,
    );
  }
  if (effect.type == 'draw') {
    return const UiCardEffectVisuals(
      icon: Icons.style_rounded,
      color: Colors.amber,
    );
  }
  if (effect.type == 'apply_status') {
    switch (effect.statusId) {
      case 'might':
      case 'might_regen':
        return const UiCardEffectVisuals(
          icon: Icons.bolt_rounded,
          color: Colors.orangeAccent,
        );
      case 'armor_regen':
        return const UiCardEffectVisuals(
          icon: Icons.autorenew_rounded,
          color: Colors.blueAccent,
        );
      case 'poison':
        return const UiCardEffectVisuals(
          icon: Icons.science_rounded,
          color: Colors.greenAccent,
        );
      case 'weakness':
        return const UiCardEffectVisuals(
          icon: Icons.trending_down_rounded,
          color: Colors.purpleAccent,
        );
      case 'vulnerable':
        return const UiCardEffectVisuals(
          icon: Icons.gps_fixed_rounded,
          color: Colors.deepOrangeAccent,
        );
      case 'burn':
        return const UiCardEffectVisuals(
          icon: Icons.local_fire_department_rounded,
          color: Colors.orangeAccent,
        );
      case 'freeze':
        return const UiCardEffectVisuals(
          icon: Icons.ac_unit_rounded,
          color: Colors.lightBlueAccent,
        );
      case 'shock':
        return const UiCardEffectVisuals(
          icon: Icons.flash_on_rounded,
          color: Colors.amberAccent,
        );
    }
  }
  return const UiCardEffectVisuals(
    icon: Icons.help_outline,
    color: Colors.grey,
  );
}

Color getCardTypeColor(CardType? type, {bool isGrayedOut = false}) {
  if (isGrayedOut) return Colors.grey;
  switch (type) {
    case CardType.attack:
      return Colors.redAccent;
    case CardType.skill:
      return Colors.blueAccent;
    case CardType.power:
      return Colors.amber;
    case CardType.status:
      return Colors.blueGrey;
    default:
      return Colors.blueAccent;
  }
}

Color getCardBackgroundColor(CardType? type, {bool isGrayedOut = false}) {
  if (isGrayedOut) return const Color(0xFF1A1A1A);
  switch (type) {
    case CardType.attack:
      return const Color(0xFF4A1D1D);
    case CardType.skill:
      return const Color(0xFF152A4A);
    case CardType.power:
      return const Color(0xFF453215);
    case CardType.status:
      return const Color(0xFF2D2D2D);
    default:
      return const Color(0xFF2A2A3D);
  }
}

Color getCardRarityColor(BuildContext context, String? rarity) {
  if (rarity == null) return Colors.white54;
  final l10n = AppLocalizations.of(context)!;
  final r = rarity.toLowerCase();
  if (r.contains('unique')) {
    return const Color(0xFFFFD700); // Gold pur — rareté Unique
  }
  if (r == l10n.rarityLegendary.toLowerCase() ||
      r.contains('legendary') ||
      r.contains('légendaire')) {
    return Colors.orangeAccent;
  }
  if (r == l10n.rarityEpic.toLowerCase() ||
      r.contains('epic') ||
      r.contains('épique')) {
    return Colors.purpleAccent;
  }
  if (r == l10n.rarityRare.toLowerCase() || r.contains('rare')) {
    return Colors.blueAccent;
  }
  if (r == l10n.rarityUncommon.toLowerCase() ||
      r.contains('uncommon') ||
      r.contains('peu commun')) {
    return Colors.greenAccent;
  }
  if (r == l10n.rarityCommon.toLowerCase() ||
      r.contains('common') ||
      r.contains('commun')) {
    return Colors.white70;
  }
  return Colors.white54;
}

/// L'emoji d'une rune, lu dans sa donnée comme le rendu Flame le lit déjà
/// (spec P-43 E1, §5.2) ; une rune absente du registre prend l'emoji par
/// défaut.
String getRuneEmoji(String upgrade) =>
    ForgeUpgradeData.getById(upgrade.split(':')[0])?.emoji ?? '🔮';

String getCardTypeLabel(BuildContext context, CardType? type) {
  final l10n = AppLocalizations.of(context)!;
  switch (type) {
    case CardType.attack:
      return l10n.cardTypeAttack;
    case CardType.skill:
      return l10n.cardTypeSkill;
    case CardType.power:
      return l10n.cardTypePower;
    case CardType.status:
      return l10n.cardTypeStatus;
    default:
      return 'Carte';
  }
}

String buildDetailedDescription(
  BuildContext context, {
  required String title,
  required String description,
  required CardData? data,
  required CardRarity cardRarity,
  required List<String> forgeUpgrades,
  String? target,
  CardTarget? targetType,
  String? rarity,
  CardType? type,
  int? cost,
}) {
  final l10n = AppLocalizations.of(context)!;

  // Format Card Details header
  final activeLocale = Localizations.localeOf(context).languageCode;
  String details = '';

  // 1. Target Type
  final resolvedTarget = resolveTarget(targetType, target);
  if (resolvedTarget != null) {
    final targetHeader = activeLocale == 'fr' ? '🎯 Cible : ' : '🎯 Target: ';
    String targetText = '';
    switch (resolvedTarget) {
      case CardTarget.singleEnemy:
        targetText = l10n.targetSingleEnemy;
        break;
      case CardTarget.allEnemies:
        targetText = l10n.targetAllEnemies;
        break;
      case CardTarget.self:
        targetText = l10n.targetSelf;
        break;
      case CardTarget.none:
        targetText = l10n.targetNone;
        break;
    }
    details += '$targetHeader$targetText\n';
  }

  // 2. Rarity
  if (rarity != null) {
    final rarityHeader = activeLocale == 'fr' ? '⚡ Rareté : ' : '⚡ Rarity: ';
    String rarityText = rarity;
    final r = rarity.toLowerCase();
    if (r.contains('unique')) {
      rarityText = activeLocale == 'fr' ? 'Unique' : 'Unique';
    } else if (r == l10n.rarityLegendary.toLowerCase() || r.contains('legendary') || r.contains('légendaire')) {
      rarityText = l10n.rarityLegendary;
    } else if (r == l10n.rarityEpic.toLowerCase() || r.contains('epic') || r.contains('épique')) {
      rarityText = l10n.rarityEpic;
    } else if (r == l10n.rarityRare.toLowerCase() || r.contains('rare')) {
      rarityText = l10n.rarityRare;
    } else if (r == l10n.rarityUncommon.toLowerCase() || r.contains('uncommon') || r.contains('peu commun')) {
      rarityText = l10n.rarityUncommon;
    } else if (r == l10n.rarityCommon.toLowerCase() || r.contains('common') || r.contains('commun')) {
      rarityText = l10n.rarityCommon;
    }
    details += '$rarityHeader$rarityText\n';
  }

  // 3. Type
  if (type != null) {
    final typeHeader = activeLocale == 'fr' ? '🏷️ Type : ' : '🏷️ Type: ';
    final typeText = getCardTypeLabel(context, type);
    details += '$typeHeader$typeText\n';
  }

  // 4. Cost
  if (cost != null) {
    final costHeader = activeLocale == 'fr' ? '💎 Coût : ' : '💎 Cost: ';
    details += '$costHeader$cost Mana\n';
  }

  // Add elemental header if applicable
  String desc = details.isNotEmpty ? '$details\n' : '';
  final effects = data?.effects;
  final elementalType = determineDamageType(title, effects);
  if (effects != null && effects.isNotEmpty && elementalType != 'physical') {
    final typeStr = elementalType == 'fire'
        ? 'FEU 🔥'
        : elementalType == 'cold'
        ? 'FROID ❄️'
        : elementalType == 'poison'
        ? 'POISON 🧪'
        : 'FOUDRE ⚡';
    desc += '[$typeStr]\n';
  }

  if (data == null || data.effects.isEmpty) {
    return desc + description;
  }

  // Les valeurs que la carte joue — rareté et runes comprises — viennent de
  // l'applicateur, seul à les calculer (spec P-43 E1, §4.2).
  for (final effect
      in EffectiveCard.withRunes(data, cardRarity, forgeUpgrades).effects) {
    final scaledValue = effect.value;

    if (effect.type == 'damage') {
      if (target == 'Tous les ennemis' || target == 'allEnemies') {
        desc += '${l10n.cardDescDamageAll(scaledValue)}\n';
      } else {
        desc += '${l10n.cardDescDamage(scaledValue)}\n';
      }
    }
    if (effect.type == 'heal') desc += '${l10n.cardDescHeal(scaledValue)}\n';
    if (effect.type == 'armor') {
      desc += '${l10n.cardDescArmor(scaledValue)}\n';
    }
    if (effect.type == 'gain_mana') {
      desc += '${l10n.cardDescGainMana(scaledValue)}\n';
    }
    if (effect.type == 'draw') desc += '${l10n.cardDescDraw(scaledValue)}\n';
    if (effect.type == 'apply_status') {
      final duration = effect.duration ?? 1;
      final localeCode = Localizations.localeOf(context).languageCode;
      switch (effect.statusId) {
        case 'might':
          desc += '${l10n.cardDescStatusMight(scaledValue, duration)}\n';
          break;
        case 'armor_regen':
          desc += '${l10n.cardDescStatusArmorRegen(scaledValue, duration)}\n';
          break;
        case 'poison':
          desc +=
              '${l10n.cardDescStatusPoisonDuration(scaledValue, duration)}\n';
          desc += localeCode == 'fr'
              ? '  (Subit des dégâts égaux au Poison au début de son tour, puis la durée diminue)\n'
              : '  (Takes damage equal to Poison at turn start, then duration decreases)\n';
          break;
        case 'weakness':
          desc +=
              '${l10n.cardDescStatusWeaknessDuration(scaledValue, duration)}\n';
          desc += localeCode == 'fr'
              ? '  (Réduit les dégâts infligés par l\'ennemi de 25%)\n'
              : '  (Reduces damage dealt by the enemy by 25%)\n';
          break;
        case 'vulnerable':
          desc +=
              '${l10n.cardDescStatusVulnerableDuration(scaledValue, duration)}\n';
          desc += localeCode == 'fr'
              ? '  (L\'ennemi subit 50% de dégâts supplémentaires)\n'
              : '  (Enemy takes 50% more damage from attacks)\n';
          break;
        case 'might_regen':
          desc +=
              '${l10n.cardDescStatusMightRegen(scaledValue, duration)}\n';
          break;
        case 'burn':
          desc +=
              '${l10n.cardDescStatusBurnDuration(scaledValue, duration)}\n';
          desc += localeCode == 'fr'
              ? '  (Subit des dégâts de feu égaux à la Brûlure au début de son tour, puis la valeur diminue de 1)\n'
              : '  (Takes fire damage equal to Burn at turn start, then the value decreases by 1)\n';
          break;
        case 'freeze':
          desc +=
              '${l10n.cardDescStatusFreezeDuration(scaledValue, duration)}\n';
          desc += localeCode == 'fr'
              ? '  (Réduit les dégâts de la prochaine attaque de l\'ennemi de 50%)\n'
              : '  (Reduces next enemy attack damage by 50%)\n';
          break;
        case 'shock':
          desc +=
              '${l10n.cardDescStatusShockDuration(scaledValue, duration)}\n';
          desc += localeCode == 'fr'
              ? '  (Subit des dégâts supplémentaires égaux à l\'Électrocution à chaque coup reçu)\n'
              : '  (Takes extra damage equal to Shock on every hit)\n';
          break;
      }
    }
  }

  // Une ligne par rune, au niveau total de ses exemplaires — celui que joue
  // le moteur —, lue dans la donnée (spec P-43 E1, §5.2).
  final upgradeDescs = ForgeUpgradeData.tooltipLines(
      forgeUpgrades, activeLocale, data, cardRarity);
  if (upgradeDescs.isNotEmpty) {
    desc += '\n⚙️ Upgrades:\n${upgradeDescs.map((u) => '• $u').join('\n')}\n';
  }

  return desc.isNotEmpty ? desc.trim() : description;
}
