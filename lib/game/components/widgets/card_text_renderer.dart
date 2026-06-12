import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../models/data/card_data.dart';
import '../card_component.dart';

class _RendererEffectVisuals {
  final IconData icon;
  final Color color;
  const _RendererEffectVisuals({required this.icon, required this.color});
}

class BadgePainters {
  final TextPainter iconAndValuePainter;
  final TextPainter? timerPainter;
  final TextPainter? separatorPainter;

  BadgePainters({
    required this.iconAndValuePainter,
    this.timerPainter,
    this.separatorPainter,
  });
}

class CardTextRenderer {
  final CardComponent card;

  // TextPainters pour le rendu manuel
  late TextPainter namePainter;
  TextPainter? descPainter;
  final List<BadgePainters> badges = [];
  late TextPainter usagePainter;
  late TextPainter typePainter;
  late TextPainter starsPainter;
  TextPainter? manaPainter;
  TextPainter? targetPainter;

  CardTextRenderer(this.card);

  double get opacity => card.opacity;

  void refreshVisuals(double opacity, bool isFlashing, bool isCancelling) {
    final int alpha = (opacity * 255).toInt();
    final typeColor = card.getTypeColor();

    // Configurer le style de base selon l'état
    Color nameColor = isFlashing
        ? Colors.transparent
        : Colors.white.withAlpha(alpha);
    Color descColor = isFlashing
        ? Colors.transparent
        : Colors.white.withAlpha(alpha);
    Color usageColor = isFlashing
        ? Colors.transparent
        : Colors.white.withAlpha(alpha);
    Color typeLabelColor = isFlashing
        ? Colors.transparent
        : typeColor.withAlpha((alpha * 0.7).toInt());

    // Les badges textuels de ciblage ont été supprimés.
    targetPainter = null;

    namePainter = TextPainter(
      text: TextSpan(
        text: card.card.data.getName(card.activeLocale).toUpperCase(),
        style: TextStyle(
          color: nameColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: card.size.x - 24);

    // Les cristaux de mana en bas ont été supprimés en faveur du médaillon de mana.
    manaPainter = null;

    if (card.card.data.effects.isEmpty) {
      descPainter = TextPainter(
        text: TextSpan(
          text: card.card.data.getDescription(card.activeLocale),
          style: TextStyle(color: descColor, fontSize: 8.0, height: 1.2),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: card.size.x - 20);
      badges.clear();
    } else {
      descPainter = null;
      badges.clear();
      final heroAttack = card.game.heroCard?.stats.effectiveAttaque ?? 0;

      int extraDamage = 0;
      int extraArmor = 0;
      for (var upgrade in card.card.forgeUpgrades) {
        final parts = upgrade.split(':');
        if (parts.length != 2) continue;
        final id = parts[0];
        final k = int.tryParse(parts[1]) ?? 0;
        if (k <= 0) continue;
        if (id == 'sharp') extraDamage += 2 * k;
        if (id == 'hardened') extraArmor += 2 * k;
      }

      final isAllEnemies = card.card.data.target == CardTarget.allEnemies;

      for (int i = 0; i < card.card.data.effects.length; i++) {
        final effect = card.card.data.effects[i];
        int scaledValue = (effect.value * card.card.rarityMultiplier).round();
        if (effect.type == 'damage') {
          scaledValue += extraDamage;
        } else if (effect.type == 'armor') {
          scaledValue += extraArmor;
        }

        int valueToDisplay = scaledValue;
        if (effect.type == 'damage') {
          valueToDisplay = scaledValue + heroAttack;
        }

        final visuals = _getEffectVisuals(effect);
        final iconColor = visuals.color.withAlpha(alpha);

        final isPlayerEffect = effect.type == 'armor' ||
            effect.type == 'heal' ||
            effect.type == 'gain_mana' ||
            effect.type == 'draw' ||
            (effect.type == 'apply_status' &&
                (effect.statusId == 'strength' ||
                    effect.statusId == 'strength_regen' ||
                    effect.statusId == 'armor_regen'));
        final shouldDouble = isAllEnemies && !isPlayerEffect;

        final iconAndValuePainter = TextPainter(
          text: TextSpan(
            children: [
              if (shouldDouble) ...[
                TextSpan(
                  text: String.fromCharCode(visuals.icon.codePoint),
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 19.0,
                    fontFamily: 'MaterialIcons',
                  ),
                ),
                TextSpan(
                  text: String.fromCharCode(visuals.icon.codePoint),
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 19.0,
                    fontFamily: 'MaterialIcons',
                  ),
                ),
              ] else ...[
                TextSpan(
                  text: String.fromCharCode(visuals.icon.codePoint),
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 19.0,
                    fontFamily: 'MaterialIcons',
                  ),
                ),
              ],
              TextSpan(
                text: ' $valueToDisplay',
                style: TextStyle(
                  color: Colors.white.withAlpha(alpha),
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        TextPainter? timerPainter;
        if (effect.type == 'apply_status') {
          final duration = effect.duration ?? 1;
          timerPainter = TextPainter(
            text: TextSpan(
              children: [
                TextSpan(
                  text: String.fromCharCode(Icons.timer_outlined.codePoint),
                  style: TextStyle(
                    color: Colors.white60.withAlpha(alpha),
                    fontSize: 8,
                    fontFamily: Icons.timer_outlined.fontFamily,
                    package: Icons.timer_outlined.fontPackage,
                  ),
                ),
                TextSpan(
                  text: ' $duration',
                  style: TextStyle(
                    color: Colors.white60.withAlpha(alpha),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            textDirection: TextDirection.ltr,
          )..layout();
        }

        TextPainter? separatorPainter;
        if (i < card.card.data.effects.length - 1) {
          separatorPainter = TextPainter(
            text: TextSpan(
              text: '  |  ',
              style: TextStyle(
                color: Colors.white24.withAlpha(alpha),
                fontSize: 15.0,
                fontWeight: FontWeight.w200,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
        }

        badges.add(
          BadgePainters(
            iconAndValuePainter: iconAndValuePainter,
            timerPainter: timerPainter,
            separatorPainter: separatorPainter,
          ),
        );
      }
    }

    usagePainter = TextPainter(
      text: TextSpan(
        text: card
            .getTranslation((l) => l.oncePlayed, fallback: 'USAGE UNIQUE')
            .toUpperCase(),
        style: TextStyle(
          color: usageColor,
          fontSize: 7.0,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    typePainter = TextPainter(
      text: TextSpan(
        text: card.getTypeLabel().toUpperCase(),
        style: TextStyle(
          color: typeLabelColor,
          fontSize: 7.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();



    // L'ancien starsPainter n'est plus utilisé en combat au profit du dessin manuel des rune sockets.
    starsPainter = TextPainter(
      text: const TextSpan(text: ''),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  _RendererEffectVisuals _getEffectVisuals(CardEffect effect) {
    if (effect.type == 'damage') {
      return const _RendererEffectVisuals(
        icon: Icons.hardware_rounded,
        color: Colors.redAccent,
      );
    }
    if (effect.type == 'armor') {
      return const _RendererEffectVisuals(
        icon: Icons.shield_rounded,
        color: Colors.blueAccent,
      );
    }
    if (effect.type == 'heal') {
      return const _RendererEffectVisuals(
        icon: Icons.favorite_rounded,
        color: Colors.pinkAccent,
      );
    }
    if (effect.type == 'gain_mana') {
      return const _RendererEffectVisuals(
        icon: Icons.diamond_rounded,
        color: Colors.cyanAccent,
      );
    }
    if (effect.type == 'draw') {
      return const _RendererEffectVisuals(
        icon: Icons.style_rounded,
        color: Colors.amber,
      );
    }
    if (effect.type == 'apply_status') {
      switch (effect.statusId) {
        case 'strength':
        case 'strength_regen':
          return const _RendererEffectVisuals(
            icon: Icons.bolt_rounded,
            color: Colors.orangeAccent,
          );
        case 'armor_regen':
          return const _RendererEffectVisuals(
            icon: Icons.autorenew_rounded,
            color: Colors.blueAccent,
          );
        case 'poison':
          return const _RendererEffectVisuals(
            icon: Icons.science_rounded,
            color: Colors.greenAccent,
          );
        case 'weakness':
          return const _RendererEffectVisuals(
            icon: Icons.trending_down_rounded,
            color: Colors.purpleAccent,
          );
        case 'vulnerable':
          return const _RendererEffectVisuals(
            icon: Icons.gps_fixed_rounded,
            color: Colors.deepOrangeAccent,
          );
        case 'burn':
          return const _RendererEffectVisuals(
            icon: Icons.local_fire_department_rounded,
            color: Colors.orangeAccent,
          );
        case 'freeze':
          return const _RendererEffectVisuals(
            icon: Icons.ac_unit_rounded,
            color: Colors.lightBlueAccent,
          );
        case 'shock':
          return const _RendererEffectVisuals(
            icon: Icons.flash_on_rounded,
            color: Colors.amberAccent,
          );
      }
    }
    return const _RendererEffectVisuals(
      icon: Icons.help_outline,
      color: Colors.grey,
    );
  }

  String buildDescription() {
    String desc = '';
    final heroAttack = card.game.heroCard?.stats.effectiveAttaque ?? 0;

    int extraDamage = 0;
    int extraArmor = 0;
    for (var upgrade in card.card.forgeUpgrades) {
      final parts = upgrade.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final k = int.tryParse(parts[1]) ?? 0;
      if (k <= 0) continue;
      if (id == 'sharp') extraDamage += 2 * k;
      if (id == 'hardened') extraArmor += 2 * k;
    }

    for (var effect in card.card.data.effects) {
      int scaledValue = (effect.value * card.card.rarityMultiplier).round();
      if (effect.type == 'damage') {
        scaledValue += extraDamage;
      } else if (effect.type == 'armor') {
        scaledValue += extraArmor;
      }

      if (effect.type == 'damage') {
        final totalDmg = scaledValue + heroAttack;
        if (card.card.data.target == CardTarget.allEnemies) {
          desc +=
              '${card.getTranslation((l) => l.cardDescDamageAll(totalDmg), fallback: "Inflige $totalDmg dégâts à tous les ennemis.")}\n';
        } else {
          desc +=
              '${card.getTranslation((l) => l.cardDescDamage(totalDmg), fallback: "Inflige $totalDmg dégâts.")}\n';
        }
      }
      if (effect.type == 'heal') {
        desc +=
            '${card.getTranslation((l) => l.cardDescHeal(scaledValue), fallback: "Soigne $scaledValue PV.")}\n';
      }
      if (effect.type == 'armor') {
        desc +=
            '${card.getTranslation((l) => l.cardDescArmor(scaledValue), fallback: "Donne $scaledValue Armure.")}\n';
      }
      if (effect.type == 'gain_mana') {
        desc +=
            '${card.getTranslation((l) => l.cardDescGainMana(scaledValue), fallback: "Gagne $scaledValue Mana.")}\n';
      }
      if (effect.type == 'draw') {
        desc +=
            '${card.getTranslation((l) => l.cardDescDraw(scaledValue), fallback: "Pioche $scaledValue cartes.")}\n';
      }
      if (effect.type == 'apply_status') {
        final duration = effect.duration ?? 1;
        switch (effect.statusId) {
          case 'strength':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusStrength(scaledValue, duration), fallback: "Gagne $scaledValue ATK pendant $duration tours.")}\n';
            break;
          case 'armor_regen':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusArmorRegen(scaledValue, duration), fallback: "Pendant $duration tours, gagne $scaledValue Armure au début du tour.")}\n';
            break;
          case 'poison':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusPoisonDuration(scaledValue, duration), fallback: "Applique $scaledValue Poison pendant $duration tours.")}\n';
            break;
          case 'weakness':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusWeaknessDuration(scaledValue, duration), fallback: "Applique $scaledValue Faiblesse pendant $duration tours.")}\n';
            break;
          case 'vulnerable':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusVulnerableDuration(scaledValue, duration), fallback: "Applique $scaledValue Vulnérable pendant $duration tours.")}\n';
            break;
          case 'strength_regen':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusStrengthRegen(scaledValue, duration), fallback: "Gagne $scaledValue Éveil d'Attaque pendant $duration tours.")}\n';
            break;
          case 'burn':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusBurnDuration(scaledValue, duration), fallback: "Applique $scaledValue Brûlure pendant $duration tours.")}\n';
            break;
          case 'freeze':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusFreezeDuration(scaledValue, duration), fallback: "Applique $scaledValue Gel pendant $duration tours.")}\n';
            break;
          case 'shock':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusShockDuration(scaledValue, duration), fallback: "Applique $scaledValue Électrocution pendant $duration tours.")}\n';
            break;
        }
      }
    }
    if (desc.isEmpty) {
      desc = card.card.data.getDescription(card.activeLocale);
    }

    final List<String> upgradeDescs = [];
    final activeLocale = card.activeLocale;
    for (var upgrade in card.card.forgeUpgrades) {
      final parts = upgrade.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final k = int.tryParse(parts[1]) ?? 0;
      if (k <= 0) continue;
      switch (id) {
        case 'sharp':
          upgradeDescs.add(activeLocale == 'fr' ? 'Tranchant $k (+${2 * k} Dégâts)' : 'Sharp $k (+${2 * k} Damage)');
          break;
        case 'hardened':
          upgradeDescs.add(activeLocale == 'fr' ? 'Endurci $k (+${2 * k} Armure)' : 'Hardened $k (+${2 * k} Armor)');
          break;
        case 'quick':
          upgradeDescs.add(activeLocale == 'fr' ? 'Véloce $k (+$k Carte(s) piochée(s))' : 'Quick $k (+$k Card(s) drawn)');
          break;
        case 'eco':
          upgradeDescs.add(activeLocale == 'fr' ? 'Économe $k (+$k Mana)' : 'Eco $k (+$k Mana)');
          break;
        case 'burning':
          upgradeDescs.add(activeLocale == 'fr' ? 'Brûlant $k (Applique $k Brûlure)' : 'Burning $k (Apply $k Burn)');
          break;
        case 'freezing':
          upgradeDescs.add(activeLocale == 'fr' ? 'Congelant $k (Applique $k Gel)' : 'Freezing $k (Apply $k Freeze)');
          break;
        case 'shocking':
          upgradeDescs.add(activeLocale == 'fr' ? 'Surchargé $k (Applique $k Électrocution)' : 'Shocking $k (Apply $k Shock)');
          break;
        case 'enduring':
          upgradeDescs.add(activeLocale == 'fr' ? 'Persistant' : 'Enduring');
          break;
      }
    }
    if (upgradeDescs.isNotEmpty) {
      desc += '\n⚙️ Upgrades:\n${upgradeDescs.map((u) => "• $u").join('\n')}\n';
    }

    return desc.trim();
  }

  void render(Canvas canvas, Vector2 size) {
    final typeColor = card.getTypeColor();
    final double spacing = 6.0;

    // Titre (centré, fixe en haut)
    double currentY = 10.0;
    namePainter.paint(canvas, Offset(size.x / 2 - namePainter.width / 2, currentY));
    currentY += namePainter.height + spacing;

    // Ligne séparatrice
    final linePaint = Paint()
      ..color = typeColor.withValues(alpha: 0.3 * opacity)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.x / 2 - 20, currentY),
      Offset(size.x / 2 + 20, currentY),
      linePaint,
    );
    currentY += 1.5 + spacing;



    // Rune sockets row instead of stars
    final int baseMaxForgeUpgrades = card.card.data.baseMaxForgeUpgrades;
    final int rarityIndex = card.card.rarity.index;
    final int totalSlots = baseMaxForgeUpgrades + rarityIndex;
    final int appliedUpgradesCount = card.card.forgeUpgrades.length;

    final double socketDiameter = 14.0;
    final double socketRadius = 7.0;
    final double socketSpacing = 2.0;
    const int maxSlotsPerRow = 5;
    final int numRows = totalSlots == 0 ? 0 : (totalSlots + maxSlotsPerRow - 1) ~/ maxSlotsPerRow;

    for (int r = 0; r < numRows; r++) {
      final int rowStartIndex = r * maxSlotsPerRow;
      final int rowEndIndex = (rowStartIndex + maxSlotsPerRow < totalSlots)
          ? rowStartIndex + maxSlotsPerRow
          : totalSlots;
      final int rowSlotsCount = rowEndIndex - rowStartIndex;
      final double rowWidth = rowSlotsCount * socketDiameter + (rowSlotsCount - 1) * socketSpacing;
      final double startX = size.x / 2 - rowWidth / 2;
      final double socketsY = currentY + socketRadius + r * (socketDiameter + socketSpacing);

      for (int i = 0; i < rowSlotsCount; i++) {
        final int globalIndex = rowStartIndex + i;
        final double centerX = startX + i * (socketDiameter + socketSpacing) + socketRadius;
        if (globalIndex < appliedUpgradesCount) {
          // Filled socket
          final socketBgPaint = Paint()
            ..color = Colors.black45.withValues(alpha: opacity)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(centerX, socketsY), socketRadius, socketBgPaint);

          final socketBorderPaint = Paint()
            ..color = Colors.cyanAccent.withValues(alpha: 0.8 * opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          canvas.drawCircle(Offset(centerX, socketsY), socketRadius, socketBorderPaint);

          final emoji = _getRuneEmoji(card.card.forgeUpgrades[globalIndex]);
          final emojiPainter = TextPainter(
            text: TextSpan(
              text: emoji,
              style: const TextStyle(fontSize: 8.0),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          emojiPainter.paint(
            canvas,
            Offset(centerX - emojiPainter.width / 2, socketsY - emojiPainter.height / 2),
          );
        } else {
          // Empty socket
          final emptyBgPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.05 * opacity)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(centerX, socketsY), socketRadius, emptyBgPaint);

          final emptyBorderPaint = Paint()
            ..color = Colors.white24.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          canvas.drawCircle(Offset(centerX, socketsY), socketRadius, emptyBorderPaint);
        }
      }
    }

    if (numRows > 0) {
      currentY += (numRows * socketDiameter + (numRows - 1) * socketSpacing) + spacing;
    } else {
      currentY += spacing;
    }

    // Badge Usage Unique (fixe)
    final showExhaustBadge = card.card.data.isExhaust || card.card.data.type == CardType.power;
    if (showExhaustBadge) {
      final badgeWidth = usagePainter.width + 12;
      final badgeRect = Rect.fromCenter(
        center: Offset(size.x / 2, currentY + 7),
        width: badgeWidth,
        height: 14,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
        Paint()..color = Colors.redAccent.withValues(alpha: 0.8 * opacity),
      );
      usagePainter.paint(
        canvas,
        Offset(
          size.x / 2 - usagePainter.width / 2,
          currentY + 7 - usagePainter.height / 2,
        ),
      );
    }

    // Le badge de ciblage textuel a été supprimé.

    // Description (centrée parfaitement sur la carte)
    if (descPainter != null) {
      descPainter!.paint(
        canvas,
        Offset(
          size.x / 2 - descPainter!.width / 2,
          (size.y / 2) - descPainter!.height / 2 + 5,
        ),
      );
    } else if (badges.isNotEmpty) {
      double totalWidth = 0;
      double maxHeight = 0;
      for (final b in badges) {
        double w = b.iconAndValuePainter.width;
        if (b.separatorPainter != null) {
          w += b.separatorPainter!.width;
        }
        totalWidth += w;

        double h = b.iconAndValuePainter.height;
        if (b.timerPainter != null) {
          h += b.timerPainter!.height + 2;
        }
        if (h > maxHeight) maxHeight = h;
      }

      double currentX = size.x / 2 - totalWidth / 2;
      double startY = (size.y / 2) - maxHeight / 2 + 5;

      for (final b in badges) {
        b.iconAndValuePainter.paint(canvas, Offset(currentX, startY));

        if (b.timerPainter != null) {
          double centerOffset =
              (b.iconAndValuePainter.width - b.timerPainter!.width) / 2;
          b.timerPainter!.paint(
            canvas,
            Offset(
              currentX + centerOffset,
              startY + b.iconAndValuePainter.height + 2,
            ),
          );
        }

        currentX += b.iconAndValuePainter.width;

        if (b.separatorPainter != null) {
          b.separatorPainter!.paint(
            canvas,
            Offset(
              currentX,
              startY +
                  (b.iconAndValuePainter.height - b.separatorPainter!.height) /
                      2,
            ),
          );
          currentX += b.separatorPainter!.width;
        }
      }
    }

    // Circular Mana Medallion (Top-Left Overlapping) - radius 12, center (6, 6)
    final cost = card.card.currentCost;
    final medallionPaint = Paint()
      ..color = const Color(0xFF0D1B2A).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(6, 6), 12.0, medallionPaint);

    final medallionBorderPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.8 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(const Offset(6, 6), 12.0, medallionBorderPaint);

    final costPainter = TextPainter(
      text: TextSpan(
        text: '$cost',
        style: TextStyle(
          color: Colors.cyanAccent.withValues(alpha: opacity),
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    costPainter.paint(
      canvas,
      Offset(6.0 - costPainter.width / 2, 6.0 - costPainter.height / 2),
    );

    // Type Label (tout en bas)
    typePainter.paint(canvas, Offset(size.x / 2 - typePainter.width / 2, 175));
  }

  String _getRuneEmoji(String upgrade) {
    final id = upgrade.split(':')[0];
    switch (id) {
      case 'sharp':
        return '⚔️';
      case 'hardened':
        return '🛡️';
      case 'quick':
        return '🪶';
      case 'eco':
        return '💎';
      case 'burning':
        return '🔥';
      case 'freezing':
        return '❄️';
      case 'shocking':
        return '⚡';
      case 'enduring':
        return '⏳';
      default:
        return '🔮';
    }
  }
}
