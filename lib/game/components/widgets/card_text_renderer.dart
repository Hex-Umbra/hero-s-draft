import 'dart:math' show max;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../models/data/card_data.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../card_component.dart';
import '../../systems/cost_rules.dart';
import '../../systems/power_rules.dart';

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
      final damageBonus = card.game.heroCard?.stats.damageBonusFor(card.card.data.type) ?? 0;

      final isAllEnemies = card.card.data.target == CardTarget.allEnemies;

      // Les valeurs que la carte joue — rareté et runes comprises — viennent
      // de l'applicateur, seul à les calculer (spec P-43 E1, §4.2).
      final effects = card.card.effective.effects;
      for (int i = 0; i < effects.length; i++) {
        final effect = effects[i];
        final valueToDisplay = badgeValue(
          effect,
          damageBonus: damageBonus,
          scaleTerm: card.heroScaleTerm(effect),
        );

        final visuals = _getEffectVisuals(effect);
        final iconColor = visuals.color.withAlpha(alpha);

        final isPlayerEffect = effect.type == 'armor' ||
            effect.type == 'heal' ||
            effect.type == 'gain_mana' ||
            effect.type == 'draw' ||
            (effect.type == 'apply_status' &&
                (effect.statusId == 'might' ||
                    effect.statusId == 'might_regen' ||
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
        if (i < effects.length - 1) {
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

  /// Le chiffre du badge d'un effet : sa valeur plus le terme de croissance,
  /// plus la part de Puissance par coup pour un `damage`, suivi de `×coups` dès
  /// deux coups.
  static String badgeValue(
    CardEffect effect, {
    int damageBonus = 0,
    int scaleTerm = 0,
  }) {
    final isDamage = effect.type == 'damage';
    final value = effect.value +
        scaleTerm +
        (isDamage ? effect.mightPerHit(damageBonus) : 0);
    return isDamage && effect.hits >= 2 ? '$value×${effect.hits}' : '$value';
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
        case 'might':
        case 'might_regen':
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



    // Une prise par rune portée, aucune vide (spec P-43 E2, §4.10).
    final int totalSlots = card.card.forgeUpgrades.length;

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
      }
    }

    if (numRows > 0) {
      currentY += (numRows * socketDiameter + (numRows - 1) * socketSpacing) + spacing;
    } else {
      currentY += spacing;
    }

    // Badge Usage Unique (fixe) : la carte s'épuise-t-elle, runes comprises
    // (spec P-43 E2, A13) ?
    final showExhaustBadge = card.card.exhaustsOnPlay;
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

    // Le bas de l'en-tête : les prises de rune, puis le badge.
    final headerBottom = currentY + (showExhaustBadge ? 14 + spacing : 0);

    // Description (centrée sur la carte, sous l'en-tête)
    if (descPainter != null) {
      descPainter!.paint(
        canvas,
        Offset(
          size.x / 2 - descPainter!.width / 2,
          centerBlockTop(
            cardHeight: size.y,
            blockHeight: descPainter!.height,
            headerBottom: headerBottom,
          ),
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
      double startY = centerBlockTop(
        cardHeight: size.y,
        blockHeight: maxHeight,
        headerBottom: headerBottom,
      );

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

    // Les médaillons de coût (coin haut-gauche, rayon 12) : le mana en (6, 6),
    // puis un par coût non nul, PV puis Armure, sans trou. Celui d'une
    // ressource qui manque au héros passe au rouge.
    final data = card.card.data;
    final missing = card.game.currentRunState?.heroStats.missingFor(
          mana: card.card.currentCost,
          hp: data.hpCost,
          armor: data.armorCost,
        ) ??
        const <CostResource>{};
    _paintCostMedallion(canvas, const Offset(6, 6), CostResource.mana,
        card.card.currentCost, missing);
    var medallionY = 32.0;
    for (final (resource, amount) in [
      (CostResource.hp, data.hpCost),
      (CostResource.armor, data.armorCost),
    ]) {
      if (amount <= 0) continue;
      _paintCostMedallion(
          canvas, Offset(6, medallionY), resource, amount, missing);
      medallionY += 26;
    }

    // Type Label (tout en bas)
    typePainter.paint(canvas, Offset(size.x / 2 - typePainter.width / 2, 175));
  }

  /// Un médaillon de coût centré en [center] : cyan pour le mana, rouge vif
  /// pour les PV, gris-bleu pour l'Armure, rouge sombre si [missing] nomme sa
  /// ressource.
  void _paintCostMedallion(
    Canvas canvas,
    Offset center,
    CostResource resource,
    int amount,
    Set<CostResource> missing,
  ) {
    final isMissing = missing.contains(resource);
    final color = isMissing
        ? Colors.red
        : switch (resource) {
            CostResource.mana => Colors.cyanAccent,
            CostResource.hp => Colors.redAccent,
            CostResource.armor => Colors.blueGrey.shade200,
          };
    final background =
        isMissing ? const Color(0xFF2A0D0D) : const Color(0xFF0D1B2A);
    canvas.drawCircle(
      center,
      12.0,
      Paint()
        ..color = background.withValues(alpha: opacity)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      12.0,
      Paint()
        ..color = color.withValues(alpha: 0.8 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final icon = switch (resource) {
      CostResource.mana => null,
      CostResource.hp => Icons.water_drop_rounded,
      CostResource.armor => Icons.shield_rounded,
    };
    if (icon != null) {
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            color: color.withValues(alpha: 0.25 * opacity),
            fontSize: 17.0,
            fontFamily: 'MaterialIcons',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(
        canvas,
        center - Offset(iconPainter.width / 2, iconPainter.height / 2),
      );
    }

    final costPainter = TextPainter(
      text: TextSpan(
        text: '$amount',
        style: TextStyle(
          color: color.withValues(alpha: opacity),
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    costPainter.paint(
      canvas,
      center - Offset(costPainter.width / 2, costPainter.height / 2),
    );
  }

  /// Le haut du bloc central — la description ou les effets — de hauteur
  /// [blockHeight] : centré sur la carte, mais jamais au-dessus de
  /// [headerBottom], le bas des prises de rune et du badge « Usage unique ».
  /// Une carte porte jusqu'à neuf runes — deux rangées de prises — et
  /// `spectral` montre le badge sur une attaque (spec P-43 E2, partie 2).
  static double centerBlockTop({
    required double cardHeight,
    required double blockHeight,
    required double headerBottom,
  }) =>
      max(headerBottom, cardHeight / 2 - blockHeight / 2 + 5);

  /// L'emoji d'une rune, par l'analyseur unique des références (spec P-43
  /// E2, §1.3, E-S6) ; une référence mal formée, ou une rune absente du
  /// registre, prend l'emoji par défaut.
  String _getRuneEmoji(String upgrade) =>
      switch (ForgeUpgradeData.parseRef(upgrade)) {
        (final id, _) => ForgeUpgradeData.getById(id)?.emoji ?? '🔮',
        null => '🔮',
      };
}
