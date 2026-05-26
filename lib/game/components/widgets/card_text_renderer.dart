import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../models/data/card_data.dart';
import '../card_component.dart';

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
        text: card.card.data.name.toUpperCase(),
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
      text: TextSpan(
        text: buildDescription(),
        style: TextStyle(
          color: descColor,
          fontSize: 10,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: card.size.x - 20);

    usagePainter = TextPainter(
      text: TextSpan(
        text: 'USAGE UNIQUE',
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

    rarityPainter = TextPainter(
      text: TextSpan(
        text: card.card.data.rarity.name.toUpperCase(),
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

  String buildDescription() {
    String desc = '';
    final heroAttack = card.game.heroCard?.stats.effectiveAttaque ?? 0;

    for (var effect in card.card.data.effects) {
      final scaledValue = (effect.value * (1 + (card.card.level - 1) * 0.5)).round();
      if (effect.type == 'damage') {
        final totalDmg = scaledValue + heroAttack;
        if (card.card.data.target == CardTarget.allEnemies) {
          desc += 'Inflige $totalDmg dégâts à tous les ennemis.\n';
        } else {
          desc += 'Inflige $totalDmg dégâts.\n';
        }
      }
      if (effect.type == 'heal') desc += 'Soigne $scaledValue PV.\n';
      if (effect.type == 'armor') desc += 'Donne $scaledValue Armure.\n';
      if (effect.type == 'gain_mana') desc += 'Gagne $scaledValue Mana.\n';
      if (effect.type == 'draw') desc += 'Pioche $scaledValue cartes.\n';
      if (effect.type == 'apply_status') {
        final duration = effect.duration ?? 1;
        switch (effect.statusId) {
          case 'strength':
            desc += 'Gagne $scaledValue ATK pendant $duration tours.\n';
            break;
          case 'armor_regen':
            desc += 'Pendant $duration tours, gagne $scaledValue Armure au début du tour.\n';
            break;
          case 'poison':
            desc += 'Applique $scaledValue Poison.\n';
            break;
          case 'weakness':
            desc += 'Applique $scaledValue Faiblesse.\n';
            break;
          case 'vulnerable':
            desc += 'Applique $scaledValue Vulnérable.\n';
            break;
          case 'strength_regen':
            desc += 'Gagne $scaledValue Éveil d\'Attaque pendant $duration tours.\n';
            break;
          case 'burn':
            desc += 'Applique $scaledValue Brûlure.\n';
            break;
          case 'freeze':
            desc += 'Applique $scaledValue Gel.\n';
            break;
          case 'shock':
            desc += 'Applique $scaledValue Électrocution.\n';
            break;
        }
      }
    }
    if (desc.isEmpty) {
      desc = card.card.data.description;
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
