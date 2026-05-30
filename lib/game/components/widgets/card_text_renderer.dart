import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../models/data/card_data.dart';
import '../card_component.dart';

class _RendererEffectVisuals {
  final IconData icon;
  final Color color;
  const _RendererEffectVisuals({required this.icon, required this.color});
}

class CardTextRenderer {
  final CardComponent card;

  // TextPainters pour le rendu manuel
  late TextPainter namePainter;
  late TextPainter descPainter;
  late TextPainter usagePainter;
  late TextPainter typePainter;
  late TextPainter bgIconPainter;
  late TextPainter rarityPainter;
  TextPainter? manaPainter;

  CardTextRenderer(this.card);

  void refreshVisuals(double opacity, bool isFlashing, bool isCancelling) {
    final int alpha = (opacity * 255).toInt();
    final typeColor = card.getTypeColor();
    
    // Configurer le style de base selon l'état
    Color nameColor = isFlashing ? Colors.transparent : Colors.white.withAlpha(alpha);
    Color descColor = isFlashing ? Colors.transparent : Colors.white.withAlpha(alpha);
    Color usageColor = isFlashing ? Colors.transparent : Colors.white.withAlpha(alpha);
    Color typeLabelColor = isFlashing ? Colors.transparent : typeColor.withAlpha((alpha * 0.7).toInt());
    Color rarityColor = isFlashing ? Colors.transparent : card.getRarityColor().withAlpha(alpha);
    Color manaColor = isFlashing ? Colors.transparent : Colors.cyanAccent.withAlpha(alpha);

    if (isCancelling) {
      final cancelAlpha = (alpha * 0.6).toInt();
      nameColor = nameColor.withAlpha(cancelAlpha);
      descColor = descColor.withAlpha(cancelAlpha);
      typeLabelColor = typeLabelColor.withAlpha(cancelAlpha);
      rarityColor = rarityColor.withAlpha(cancelAlpha);
      manaColor = manaColor.withAlpha(cancelAlpha);
    }

    namePainter = TextPainter(
      text: TextSpan(
        text: card.card.data.getName(card.activeLocale).toUpperCase(),
        style: TextStyle(
          color: nameColor,
          fontSize: 12,
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
            fontSize: 16,
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

    descPainter = TextPainter(
      text: _buildCompactDescriptionSpan(descColor, opacity),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: card.size.x - 20);

    usagePainter = TextPainter(
      text: TextSpan(
        text: card.getTranslation((l) => l.oncePlayed, fallback: 'USAGE UNIQUE').toUpperCase(),
        style: TextStyle(
          color: usageColor,
          fontSize: 8,
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
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rarityName = card.card.data.rarity.name.toLowerCase();
    String rarityLabel = card.card.data.rarity.name;
    if (rarityName.contains('legendary')) {
      rarityLabel = card.getTranslation((l) => l.rarityLegendary, fallback: 'LÉGENDAIRE');
    } else if (rarityName.contains('epic')) {
      rarityLabel = card.getTranslation((l) => l.rarityEpic, fallback: 'ÉPIQUE');
    } else if (rarityName.contains('rare')) {
      rarityLabel = card.getTranslation((l) => l.rarityRare, fallback: 'RARE');
    } else if (rarityName.contains('uncommon')) {
      rarityLabel = card.getTranslation((l) => l.rarityUncommon, fallback: 'PEU COMMUN');
    } else if (rarityName.contains('common')) {
      rarityLabel = card.getTranslation((l) => l.rarityCommon, fallback: 'COMMUN');
    }

    rarityPainter = TextPainter(
      text: TextSpan(
        text: rarityLabel.toUpperCase(),
        style: TextStyle(
          color: rarityColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final iconData = card.getTypeIconData();
    bgIconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          color: Colors.white.withAlpha((alpha * 0.05).toInt()),
          fontSize: 80,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }



  String _determineDamageType() {
    final lowerTitle = '${card.card.data.getName(card.activeLocale).toLowerCase()} ${card.card.data.id.toLowerCase()}';
    
    for (var effect in card.card.data.effects) {
      if (effect.type == 'apply_status') {
        if (effect.statusId == 'burn') return 'fire';
        if (effect.statusId == 'freeze') return 'cold';
        if (effect.statusId == 'shock') return 'electric';
      }
    }
    
    if (lowerTitle.contains('feu') || lowerTitle.contains('fire') || lowerTitle.contains('brûlure') || lowerTitle.contains('burn')) {
      return 'fire';
    }
    if (lowerTitle.contains('glace') || lowerTitle.contains('ice') || lowerTitle.contains('gel') || lowerTitle.contains('freeze') || lowerTitle.contains('froid') || lowerTitle.contains('cold')) {
      return 'cold';
    }
    if (lowerTitle.contains('foudre') || lowerTitle.contains('thunder') || lowerTitle.contains('shock') || lowerTitle.contains('lightning') || lowerTitle.contains('tonnerre') || lowerTitle.contains('élec')) {
      return 'electric';
    }
    return 'physical';
  }

  _RendererEffectVisuals _getEffectVisuals(CardEffect effect) {
    if (effect.type == 'damage') {
      final damageType = _determineDamageType();
      switch (damageType) {
        case 'fire':
          return const _RendererEffectVisuals(
            icon: Icons.local_fire_department_rounded,
            color: Colors.orangeAccent,
          );
        case 'cold':
          return const _RendererEffectVisuals(
            icon: Icons.ac_unit_rounded,
            color: Colors.lightBlueAccent,
          );
        case 'poison':
          return const _RendererEffectVisuals(
            icon: Icons.science_rounded,
            color: Colors.greenAccent,
          );
        case 'electric':
          return const _RendererEffectVisuals(
            icon: Icons.flash_on_rounded,
            color: Colors.amberAccent,
          );
        default:
          return const _RendererEffectVisuals(
            icon: Icons.hardware_rounded,
            color: Colors.redAccent,
          );
      }
    }
    if (effect.type == 'armor') {
      final damageType = _determineDamageType();
      Color armorColor = Colors.blueAccent;
      if (damageType == 'cold') {
        armorColor = Colors.cyanAccent;
      } else if (damageType == 'fire') {
        armorColor = Colors.deepOrangeAccent;
      }
      return _RendererEffectVisuals(
        icon: Icons.shield_rounded,
        color: armorColor,
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

  TextSpan _buildCompactDescriptionSpan(Color descColor, double opacity) {
    if (card.card.data.effects.isEmpty) {
      return TextSpan(
        text: card.card.data.getDescription(card.activeLocale),
        style: TextStyle(
          color: descColor,
          fontSize: 9,
          height: 1.2,
        ),
      );
    }

    final heroAttack = card.game.heroCard?.stats.effectiveAttaque ?? 0;
    final List<InlineSpan> children = [];

    for (int i = 0; i < card.card.data.effects.length; i++) {
      final effect = card.card.data.effects[i];
      final scaledValue = (effect.value * (1 + (card.card.level - 1) * 0.5)).round();
      
      int valueToDisplay = scaledValue;
      if (effect.type == 'damage') {
        valueToDisplay = scaledValue + heroAttack;
      }

      final visuals = _getEffectVisuals(effect);
      final iconColor = visuals.color.withAlpha((opacity * 255).toInt());

      children.add(
        TextSpan(
          text: String.fromCharCode(visuals.icon.codePoint),
          style: TextStyle(
            color: iconColor,
            fontSize: 36, // Tripled icon size
            fontFamily: 'MaterialIcons',
          ),
        ),
      );

      children.add(
        TextSpan(
          text: ' $valueToDisplay',
          style: TextStyle(
            color: Colors.white.withAlpha((opacity * 255).toInt()),
            fontSize: 22, // Enlarged value font size
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      if (i < card.card.data.effects.length - 1) {
        children.add(
          TextSpan(
            text: '  |  ',
            style: TextStyle(
              color: Colors.white24.withAlpha((opacity * 255).toInt()),
              fontSize: 22,
              fontWeight: FontWeight.w200,
            ),
          ),
        );
      }
    }

    return TextSpan(children: children);
  }

  String buildDescription() {
    String desc = '';
    final heroAttack = card.game.heroCard?.stats.effectiveAttaque ?? 0;

    for (var effect in card.card.data.effects) {
      final scaledValue = (effect.value * (1 + (card.card.level - 1) * 0.5)).round();
      if (effect.type == 'damage') {
        final totalDmg = scaledValue + heroAttack;
        if (card.card.data.target == CardTarget.allEnemies) {
          desc += '${card.getTranslation((l) => l.cardDescDamageAll(totalDmg), fallback: 'Inflige $totalDmg dégâts à tous les ennemis.')}\n';
        } else {
          desc += '${card.getTranslation((l) => l.cardDescDamage(totalDmg), fallback: 'Inflige $totalDmg dégâts.')}\n';
        }
      }
      if (effect.type == 'heal') {
        desc += '${card.getTranslation((l) => l.cardDescHeal(scaledValue), fallback: 'Soigne $scaledValue PV.')}\n';
      }
      if (effect.type == 'armor') {
        desc += '${card.getTranslation((l) => l.cardDescArmor(scaledValue), fallback: 'Donne $scaledValue Armure.')}\n';
      }
      if (effect.type == 'gain_mana') {
        desc += '${card.getTranslation((l) => l.cardDescGainMana(scaledValue), fallback: 'Gagne $scaledValue Mana.')}\n';
      }
      if (effect.type == 'draw') {
        desc += '${card.getTranslation((l) => l.cardDescDraw(scaledValue), fallback: 'Pioche $scaledValue cartes.')}\n';
      }
      if (effect.type == 'apply_status') {
        final duration = effect.duration ?? 1;
        switch (effect.statusId) {
          case 'strength':
            desc += '${card.getTranslation((l) => l.cardDescStatusStrength(scaledValue, duration), fallback: 'Gagne $scaledValue ATK pendant $duration tours.')}\n';
            break;
          case 'armor_regen':
            desc += '${card.getTranslation((l) => l.cardDescStatusArmorRegen(scaledValue, duration), fallback: 'Pendant $duration tours, gagne $scaledValue Armure au début du tour.')}\n';
            break;
          case 'poison':
            desc += '${card.getTranslation((l) => l.cardDescStatusPoison(scaledValue), fallback: 'Applique $scaledValue Poison.')}\n';
            break;
          case 'weakness':
            desc += '${card.getTranslation((l) => l.cardDescStatusWeakness(scaledValue), fallback: 'Applique $scaledValue Faiblesse.')}\n';
            break;
          case 'vulnerable':
            desc += '${card.getTranslation((l) => l.cardDescStatusVulnerable(scaledValue), fallback: 'Applique $scaledValue Vulnérable.')}\n';
            break;
          case 'strength_regen':
            desc += '${card.getTranslation((l) => l.cardDescStatusStrengthRegen(scaledValue, duration), fallback: 'Gagne $scaledValue Éveil d\'Attaque pendant $duration tours.')}\n';
            break;
          case 'burn':
            desc += '${card.getTranslation((l) => l.cardDescStatusBurn(scaledValue), fallback: 'Applique $scaledValue Brûlure.')}\n';
            break;
          case 'freeze':
            desc += '${card.getTranslation((l) => l.cardDescStatusFreeze(scaledValue), fallback: 'Applique $scaledValue Gel.')}\n';
            break;
          case 'shock':
            desc += '${card.getTranslation((l) => l.cardDescStatusShock(scaledValue), fallback: 'Applique $scaledValue Électrocution.')}\n';
            break;
        }
      }
    }
    if (desc.isEmpty) {
      desc = card.card.data.getDescription(card.activeLocale);
    }
    return desc.trim();
  }

  void render(Canvas canvas, Vector2 size) {
    final typeColor = card.getTypeColor();

    // Icône de fond subtile
    bgIconPainter.paint(
      canvas,
      Offset(size.x / 2 - bgIconPainter.width / 2, size.y / 2 - bgIconPainter.height / 2),
    );

    // Titre (centré, fixe en haut)
    namePainter.paint(
      canvas,
      Offset(size.x / 2 - namePainter.width / 2, 14),
    );

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
      Offset(size.x / 2 - rarityPainter.width / 2, 42),
    );

    // Badge Usage Unique (fixe)
    if (card.card.data.isExhaust || card.card.data.type == CardType.power) {
      final badgeWidth = usagePainter.width + 12;
      final badgeRect = Rect.fromCenter(
        center: Offset(size.x / 2, 62),
        width: badgeWidth,
        height: 14,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
        Paint()..color = Colors.redAccent.withAlpha(200),
      );
      usagePainter.paint(
        canvas,
        Offset(size.x / 2 - usagePainter.width / 2, 62 - usagePainter.height / 2),
      );
    }

    // Description (centrée parfaitement sur la carte)
    descPainter.paint(
      canvas,
      Offset(
        size.x / 2 - descPainter.width / 2,
        (size.y / 2) - descPainter.height / 2 + 5, // Légèrement décalée vers le bas pour l'équilibre
      ),
    );

    // Cristaux de Mana (En bas au centre)
    if (manaPainter != null) {
      manaPainter!.paint(
        canvas,
        Offset(size.x / 2 - manaPainter!.width / 2, 150),
      );
    }

    // Type Label (tout en bas)
    typePainter.paint(
      canvas,
      Offset(size.x / 2 - typePainter.width / 2, 175),
    );
  }
}
