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
  late TextPainter rarityPainter;
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
    Color rarityColor = isFlashing
        ? Colors.transparent
        : card.getRarityColor().withAlpha(alpha);
    Color manaColor = isFlashing
        ? Colors.transparent
        : Colors.cyanAccent.withAlpha(alpha);
    Color starColor = isFlashing
        ? Colors.transparent
        : Colors.amber.withAlpha(alpha);

    if (isCancelling) {
      final cancelAlpha = (alpha * 0.6).toInt();
      nameColor = nameColor.withAlpha(cancelAlpha);
      descColor = descColor.withAlpha(cancelAlpha);
      typeLabelColor = typeLabelColor.withAlpha(cancelAlpha);
      rarityColor = rarityColor.withAlpha(cancelAlpha);
      manaColor = manaColor.withAlpha(cancelAlpha);
      starColor = starColor.withAlpha(cancelAlpha);
    }

    // Configurer le style de ciblage
    final target = card.card.data.target;
    if (target != CardTarget.none) {
      String emoji = '';
      String label = '';
      switch (target) {
        case CardTarget.singleEnemy:
          emoji = '🎯';
          label = card.activeLocale == 'fr' ? 'Cible unique' : 'Single Target';
          break;
        case CardTarget.allEnemies:
          emoji = '💥';
          label = card.activeLocale == 'fr' ? 'Tous' : 'All';
          break;
        case CardTarget.self:
          emoji = '🛡️';
          label = card.activeLocale == 'fr' ? 'Soi-même' : 'Self';
          break;
        default:
          break;
      }

      Color tColor = isFlashing
          ? Colors.transparent
          : Colors.white.withAlpha(alpha);

      targetPainter = TextPainter(
        text: TextSpan(
          text: '$emoji $label'.toUpperCase(),
          style: TextStyle(
            color: tColor,
            fontSize: 7.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    } else {
      targetPainter = null;
    }

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

    if (card.card.currentCost > 0) {
      final manaString = String.fromCharCode(Icons.diamond_rounded.codePoint);
      String fullManaString = '';
      for (int i = 0; i < card.card.currentCost; i++) {
        fullManaString += manaString;
      }

      manaPainter = TextPainter(
        text: TextSpan(
          text: fullManaString,
          style: TextStyle(
            color: manaColor,
            fontSize: 15.0,
            fontFamily: Icons.diamond_rounded.fontFamily,
            package: Icons.diamond_rounded.fontPackage,
            letterSpacing: 2.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    } else {
      manaPainter = null;
    }

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

        final iconAndValuePainter = TextPainter(
          text: TextSpan(
            children: [
              TextSpan(
                text: String.fromCharCode(visuals.icon.codePoint),
                style: TextStyle(
                  color: iconColor,
                  fontSize: 22.0,
                  fontFamily: 'MaterialIcons',
                ),
              ),
              TextSpan(
                text: ' $valueToDisplay',
                style: TextStyle(
                  color: Colors.white.withAlpha(alpha),
                  fontSize: 15.0,
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
                    fontSize: 10,
                    fontFamily: Icons.timer_outlined.fontFamily,
                    package: Icons.timer_outlined.fontPackage,
                  ),
                ),
                TextSpan(
                  text: ' $duration',
                  style: TextStyle(
                    color: Colors.white60.withAlpha(alpha),
                    fontSize: 10,
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

    final rarityName = card.card.data.rarity.name.toLowerCase();
    String rarityLabel = card.card.data.rarity.name;
    if (rarityName.contains('legendary')) {
      rarityLabel = card.getTranslation(
        (l) => l.rarityLegendary,
        fallback: 'LÉGENDAIRE',
      );
    } else if (rarityName.contains('epic')) {
      rarityLabel = card.getTranslation(
        (l) => l.rarityEpic,
        fallback: 'ÉPIQUE',
      );
    } else if (rarityName.contains('rare')) {
      rarityLabel = card.getTranslation((l) => l.rarityRare, fallback: 'RARE');
    } else if (rarityName.contains('uncommon')) {
      rarityLabel = card.getTranslation(
        (l) => l.rarityUncommon,
        fallback: 'PEU COMMUN',
      );
    } else if (rarityName.contains('common')) {
      rarityLabel = card.getTranslation(
        (l) => l.rarityCommon,
        fallback: 'COMMUN',
      );
    }

    rarityPainter = TextPainter(
      text: TextSpan(
        text: rarityLabel.toUpperCase(),
        style: TextStyle(
          color: rarityColor,
          fontSize: 7.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final int totalLimit = card.card.data.baseMaxForgeUpgrades + card.card.rarity.index;
    final int appliedUpgradesCount = card.card.forgeUpgrades.length;
    final starString = List.generate(totalLimit, (index) {
      return index < appliedUpgradesCount
          ? String.fromCharCode(Icons.star.codePoint)
          : String.fromCharCode(Icons.star_border.codePoint);
    }).join(' ');

    starsPainter = TextPainter(
      text: TextSpan(
        text: starString,
        style: TextStyle(
          color: starColor,
          fontSize: 8.0,
          fontFamily: Icons.star.fontFamily,
          package: Icons.star.fontPackage,
        ),
      ),
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
              '${card.getTranslation((l) => l.cardDescDamageAll(totalDmg), fallback: 'Inflige $totalDmg dégâts à tous les ennemis.')}\n';
        } else {
          desc +=
              '${card.getTranslation((l) => l.cardDescDamage(totalDmg), fallback: 'Inflige $totalDmg dégâts.')}\n';
        }
      }
      if (effect.type == 'heal') {
        desc +=
            '${card.getTranslation((l) => l.cardDescHeal(scaledValue), fallback: 'Soigne $scaledValue PV.')}\n';
      }
      if (effect.type == 'armor') {
        desc +=
            '${card.getTranslation((l) => l.cardDescArmor(scaledValue), fallback: 'Donne $scaledValue Armure.')}\n';
      }
      if (effect.type == 'gain_mana') {
        desc +=
            '${card.getTranslation((l) => l.cardDescGainMana(scaledValue), fallback: 'Gagne $scaledValue Mana.')}\n';
      }
      if (effect.type == 'draw') {
        desc +=
            '${card.getTranslation((l) => l.cardDescDraw(scaledValue), fallback: 'Pioche $scaledValue cartes.')}\n';
      }
      if (effect.type == 'apply_status') {
        final duration = effect.duration ?? 1;
        switch (effect.statusId) {
          case 'strength':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusStrength(scaledValue, duration), fallback: 'Gagne $scaledValue ATK pendant $duration tours.')}\n';
            break;
          case 'armor_regen':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusArmorRegen(scaledValue, duration), fallback: 'Pendant $duration tours, gagne $scaledValue Armure au début du tour.')}\n';
            break;
          case 'poison':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusPoisonDuration(scaledValue, duration), fallback: 'Applique $scaledValue Poison pendant $duration tours.')}\n';
            break;
          case 'weakness':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusWeaknessDuration(scaledValue, duration), fallback: 'Applique $scaledValue Faiblesse pendant $duration tours.')}\n';
            break;
          case 'vulnerable':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusVulnerableDuration(scaledValue, duration), fallback: 'Applique $scaledValue Vulnérable pendant $duration tours.')}\n';
            break;
          case 'strength_regen':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusStrengthRegen(scaledValue, duration), fallback: 'Gagne $scaledValue Éveil d\'Attaque pendant $duration tours.')}\n';
            break;
          case 'burn':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusBurnDuration(scaledValue, duration), fallback: 'Applique $scaledValue Brûlure pendant $duration tours.')}\n';
            break;
          case 'freeze':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusFreezeDuration(scaledValue, duration), fallback: 'Applique $scaledValue Gel pendant $duration tours.')}\n';
            break;
          case 'shock':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusShockDuration(scaledValue, duration), fallback: 'Applique $scaledValue Électrocution pendant $duration tours.')}\n';
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
      desc += '\n⚙️ Upgrades:\n${upgradeDescs.map((u) => '• $u').join('\n')}\n';
    }

    return desc.trim();
  }

  void render(Canvas canvas, Vector2 size) {
    final typeColor = card.getTypeColor();

    // Titre (centré, fixe en haut)
    namePainter.paint(canvas, Offset(size.x / 2 - namePainter.width / 2, 14));

    // Ligne séparatrice (fixe)
    final linePaint = Paint()
      ..color = typeColor.withAlpha(100)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.x / 2 - 20, 32),
      Offset(size.x / 2 + 20, 32),
      linePaint,
    );

    // Rareté (fixe sous la ligne)
    rarityPainter.paint(
      canvas,
      Offset(size.x / 2 - rarityPainter.width / 2, 40),
    );

    // Etoiles d'améliorations (juste sous la rareté)
    starsPainter.paint(
      canvas,
      Offset(size.x / 2 - starsPainter.width / 2, 50),
    );

    double currentY = 66.0;

    // Badge Usage Unique (fixe)
    if (card.card.data.isExhaust || card.card.data.type == CardType.power) {
      final badgeWidth = usagePainter.width + 12;
      final badgeRect = Rect.fromCenter(
        center: Offset(size.x / 2, currentY),
        width: badgeWidth,
        height: 14,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
        Paint()..color = Colors.redAccent.withAlpha(200),
      );
      usagePainter.paint(
        canvas,
        Offset(
          size.x / 2 - usagePainter.width / 2,
          currentY - usagePainter.height / 2,
        ),
      );
      currentY += 16.0;
    }

    // Badge de ciblage
    if (targetPainter != null) {
      final target = card.card.data.target;
      Color badgeColor = Colors.grey;
      switch (target) {
        case CardTarget.singleEnemy:
          badgeColor = Colors.redAccent;
          break;
        case CardTarget.allEnemies:
          badgeColor = Colors.orangeAccent;
          break;
        case CardTarget.self:
          badgeColor = Colors.blueAccent;
          break;
        default:
          break;
      }

      final badgeWidth = targetPainter!.width + 10;
      final badgeRect = Rect.fromCenter(
        center: Offset(size.x / 2, currentY),
        width: badgeWidth,
        height: 12,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
        Paint()..color = badgeColor.withAlpha(180),
      );
      targetPainter!.paint(
        canvas,
        Offset(
          size.x / 2 - targetPainter!.width / 2,
          currentY - targetPainter!.height / 2,
        ),
      );
    }

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

    // Cristaux de Mana (En bas au centre)
    if (manaPainter != null) {
      manaPainter!.paint(
        canvas,
        Offset(size.x / 2 - manaPainter!.width / 2, 150),
      );
    }

    // Type Label (tout en bas)
    typePainter.paint(canvas, Offset(size.x / 2 - typePainter.width / 2, 175));
  }
}
