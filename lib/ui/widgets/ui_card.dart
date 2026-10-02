import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../models/data/card_data.dart';
import '../../models/card_instance.dart';
import '../../models/data/model_extensions.dart';
import 'ui_card/ui_card_helpers.dart';
import 'ui_card/polychromatic_border.dart';
import 'ui_card/card_mana_medallion.dart';
import 'ui_card/card_rune_sockets.dart';
import 'ui_card/card_compact_description.dart';

class UiCard extends StatelessWidget {
  final String title;
  final String description;
  final String? rarity;
  final String? target;
  final int? cost;
  final int? level;

  /// La carte, que ses rendus lisent par l'applicateur avec [cardRarity] et
  /// [forgeUpgrades] (spec P-43 E1, §4.2). Absente, le corps ne montre que
  /// [description].
  final CardData? data;

  /// La rareté de jeu de la carte ; [rarity] en est le libellé traduit.
  final CardRarity cardRarity;
  final List<String> forgeUpgrades;
  final CardType? type;
  final CardTarget? targetType;
  final bool isExhaust;
  final bool isSelected;
  final bool isGrayedOut;
  final VoidCallback? onTap;

  const UiCard({
    super.key,
    required this.title,
    required this.description,
    this.rarity,
    this.target,
    this.cost,
    this.level,
    this.data,
    this.cardRarity = CardRarity.common,
    this.forgeUpgrades = const [],
    this.type,
    this.targetType,
    this.isExhaust = false,
    this.isSelected = false,
    this.isGrayedOut = false,
    this.onTap,
  });

  factory UiCard.fromInstance({
    Key? key,
    required CardInstance card,
    required String locale,
    required AppLocalizations l10n,
    bool isSelected = false,
    bool isGrayedOut = false,
    VoidCallback? onTap,
  }) {
    return UiCard(
      key: key,
      title: card.data.getName(locale),
      description: card.data.getDescription(locale),
      rarity: card.rarity.getLabel(l10n),
      target: card.data.target.getLabel(l10n),
      cost: card.currentCost,
      level: 1,
      data: card.data,
      cardRarity: card.rarity,
      forgeUpgrades: card.forgeUpgrades,
      type: card.data.type,
      targetType: card.data.target,
      isExhaust: card.exhaustsOnPlay,
      isSelected: isSelected,
      isGrayedOut: isGrayedOut,
      onTap: onTap,
    );
  }

  factory UiCard.fromData({
    Key? key,
    required CardData card,
    required String locale,
    required AppLocalizations l10n,
    List<String> forgeUpgrades = const [],
    bool isSelected = false,
    bool isGrayedOut = false,
    VoidCallback? onTap,
  }) {
    return UiCard(
      key: key,
      title: card.getName(locale),
      description: card.getDescription(locale),
      rarity: card.rarity.getLabel(l10n),
      target: card.target.getLabel(l10n),
      cost: card.cost,
      level: 1,
      data: card,
      cardRarity: card.rarity,
      forgeUpgrades: forgeUpgrades,
      type: card.type,
      targetType: card.target,
      isExhaust: card.isExhaust,
      isSelected: isSelected,
      isGrayedOut: isGrayedOut,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeColor = getCardTypeColor(type, isGrayedOut: isGrayedOut);
    final bgColor = getCardBackgroundColor(type, isGrayedOut: isGrayedOut);
    final rarityColor = getCardRarityColor(context, rarity);

    final showBadge = isExhaust || type == CardType.power;
    final descriptionTop = showBadge ? 52.0 : 40.0;

    return AspectRatio(
      aspectRatio: 70 / 110,
      child: Tooltip(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C).withAlpha(245),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: rarityColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(185),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        preferBelow: false,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          height: 1.3,
        ),
        richMessage: TextSpan(
          children: [
            TextSpan(
              text: '${title.toUpperCase()}\n',
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const TextSpan(text: '\n'),
            TextSpan(
              text: buildDetailedDescription(
                context,
                title: title,
                description: description,
                data: data,
                cardRarity: cardRarity,
                forgeUpgrades: forgeUpgrades,
                target: target,
                targetType: targetType,
                rarity: rarity,
                type: type,
                cost: cost,
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Card body (clipped to rounded rect)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 4,
                      ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PolychromaticBorder(
                    rarityColor: rarityColor,
                    isUnique: rarity != null && rarity!.toLowerCase().contains('unique'),
                    isSelected: isSelected,
                    upgradeCount: forgeUpgrades.length,
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Titre, Ligne de Séparateur, Rareté et Rune Sockets groupés
                          Positioned(
                            top: 10,
                            left: 8,
                            right: 8,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 3),
                                Center(
                                  child: Container(
                                    height: 1.5,
                                    width: 30,
                                    color: typeColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                CardRuneSockets(forgeUpgrades: forgeUpgrades),
                                if (showBadge) ...[
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.5,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      l10n.oncePlayed.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 6,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Description (Centrée verticalement)
                          Positioned(
                            top: descriptionTop,
                            bottom: 22,
                            left: 8,
                            right: 8,
                            child: Center(
                              child: CardCompactDescription(
                                description: description,
                                data: data,
                                cardRarity: cardRarity,
                                forgeUpgrades: forgeUpgrades,
                                targetType: targetType,
                                target: target,
                              ),
                            ),
                          ),

                          // Type Label (Fixé tout en bas)
                          Positioned(
                            bottom: 6,
                            left: 0,
                            right: 0,
                            child: Text(
                              getCardTypeLabel(context, type).toUpperCase(),
                              style: TextStyle(
                                color: typeColor.withValues(alpha: 0.7),
                                fontSize: 6,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Circular Mana Medallion — outside ClipRRect so it's never cropped
              if (cost != null)
                Positioned(
                  top: -9,
                  left: -9,
                  child: CardManaMedallion(cost: cost!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
