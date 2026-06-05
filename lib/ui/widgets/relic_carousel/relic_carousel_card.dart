import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/data/relic_data.dart';

class RelicCarouselCard extends StatelessWidget {
  final RelicData relic;
  final bool isFocused;
  final bool isWon;

  const RelicCarouselCard({
    super.key,
    required this.relic,
    this.isFocused = false,
    this.isWon = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    Color triggerColor = Colors.grey;
    String triggerText = 'Passif';
    switch (relic.trigger) {
      case RelicTrigger.startOfRun:
        triggerText = l10n.relicTriggerRun;
        triggerColor = Colors.blueAccent;
        break;
      case RelicTrigger.startOfCombat:
        triggerText = l10n.relicTriggerCombat;
        triggerColor = Colors.redAccent;
        break;
      case RelicTrigger.startOfTurn:
        triggerText = l10n.relicTriggerTurnStart;
        triggerColor = Colors.greenAccent;
        break;
      case RelicTrigger.endOfTurn:
        triggerText = l10n.relicTriggerTurnEnd;
        triggerColor = Colors.amberAccent;
        break;
      case RelicTrigger.onCardPlayed:
        triggerText = l10n.relicTriggerCardPlayed;
        triggerColor = Colors.purpleAccent;
        break;
      case RelicTrigger.onEnemyKilled:
        triggerText = l10n.relicTriggerEnemyKilled;
        triggerColor = Colors.orangeAccent;
        break;
      case RelicTrigger.onAttackPlayed:
        triggerText = locale == 'fr' ? 'Attaque Jouée' : 'Attack Played';
        triggerColor = Colors.redAccent;
        break;
      case RelicTrigger.onSkillPlayed:
        triggerText = locale == 'fr' ? 'Compétence Jouée' : 'Skill Played';
        triggerColor = Colors.cyanAccent;
        break;
      case RelicTrigger.onPowerPlayed:
        triggerText = locale == 'fr' ? 'Pouvoir Joué' : 'Power Played';
        triggerColor = Colors.pinkAccent;
        break;
    }

    Color rarityColor = Colors.grey;
    String rarityText = l10n.rarityCommon;
    switch (relic.rarity) {
      case RelicRarity.common:
        rarityColor = const Color(0xFF8E8E93);
        rarityText = l10n.rarityCommon.toUpperCase();
        break;
      case RelicRarity.uncommon:
        rarityColor = const Color(0xFF34C759);
        rarityText = l10n.rarityUncommon.toUpperCase();
        break;
      case RelicRarity.rare:
        rarityColor = const Color(0xFF007AFF);
        rarityText = l10n.rarityRare.toUpperCase();
        break;
      case RelicRarity.epic:
        rarityColor = const Color(0xFFAF52DE);
        rarityText = l10n.rarityEpic.toUpperCase();
        break;
      case RelicRarity.legendary:
        rarityColor = const Color(0xFFFFCC00);
        rarityText = l10n.rarityLegendary.toUpperCase();
        break;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isFocused ? 1.0 : 0.4,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        scale: isFocused ? 1.0 : 0.85,
        curve: Curves.easeOutBack,
        child: Container(
          width: 220,
          height: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isFocused
                ? const Color(0xFF2A2A3D)
                : const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isFocused
                  ? rarityColor.withValues(alpha: isWon ? 0.9 : 0.6)
                  : rarityColor.withValues(alpha: 0.25),
              width: isFocused && isWon ? 3.0 : 2.0,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: isWon ? 0.4 : 0.15),
                      blurRadius: isWon ? 25 : 12,
                      spreadRadius: isWon ? 4 : 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rarity Badge and Trigger Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rarityText,
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: triggerColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      triggerText,
                      style: TextStyle(
                        color: triggerColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),

              // Large Emoji
              Center(
                child: Hero(
                  tag: 'relic_carousel_${relic.id}',
                  child: Text(
                    relic.emoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
              const Spacer(flex: 2),

              // Relic Name
              Text(
                relic.getName(locale),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Relic Description
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    relic.getDescription(locale),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
