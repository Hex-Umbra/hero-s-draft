import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/model_extensions.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../widgets/ui_card.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/forge_upgrade_dialog.dart';

class RestCardSelectionScreen extends ConsumerWidget {
  final String title;
  final String subtitle;
  final bool isForge;

  const RestCardSelectionScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isForge,
  });

  void _onCardTapped(BuildContext context, WidgetRef ref, CardInstance card) async {
    final locale = Localizations.localeOf(context).languageCode;

    if (isForge) {
      final rarityIndex = card.rarity.index;
      final totalMaxForgeUpgrades =
          card.data.baseMaxForgeUpgrades + rarityIndex;
      
      if (card.forgeUpgrades.length >= totalMaxForgeUpgrades) {
        context.showNotification(
          locale == 'fr'
              ? "Cette carte a atteint sa capacité maximale d'améliorations de forge !"
              : "This card has reached its maximum forge upgrades capacity!",
          type: NotificationType.error,
        );
        return;
      }

      final selectedUpgrade = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ForgeUpgradeDialog(card: card),
      );

      if (selectedUpgrade != null) {
        if (context.mounted) {
          Navigator.of(context).pop({
            'card': card,
            'upgrade': selectedUpgrade,
          });
        }
      } else {
        // If the upgrade dialog is cancelled, pop back to the Rest Node menu directly
        if (context.mounted) {
          Navigator.of(context).pop(null);
        }
      }
    } else {
      // Card Removal
      Navigator.of(context).pop(card);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final deck = ref.watch(deckProvider).masterDeck;

    // Theme color based on action (Forge is amber, Remove is red)
    final Color themeColor = isForge ? Colors.amber : Colors.redAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF13131E),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER (Immersive & Thematic style matching other draft screens)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: themeColor,
                      onPressed: () => Navigator.of(context).pop(null),
                      tooltip: locale == 'fr' ? 'Annuler' : 'Cancel',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 26,
                              fontWeight: FontWeight.w900,
                              color: themeColor,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: themeColor.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isMobile ? 11 : 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // CARD GRID
              Expanded(
                child: deck.isEmpty
                    ? Center(
                        child: Text(
                          locale == 'fr' ? 'Votre deck est vide' : 'Your deck is empty',
                          style: const TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isMobile ? 140 : 180,
                          childAspectRatio: 70 / 110,
                          crossAxisSpacing: isMobile ? 8 : 16,
                          mainAxisSpacing: isMobile ? 8 : 16,
                        ),
                        itemCount: deck.length,
                        itemBuilder: (context, index) {
                          final card = deck[index];
                          return GestureDetector(
                            onTap: () => _onCardTapped(context, ref, card),
                            child: UiCard(
                              title: card.data.getName(locale),
                              description: card.data.getDescription(locale),
                              cost: card.data.cost,
                              effects: card.data.effects,
                              type: card.data.type,
                              targetType: card.data.target,
                              isExhaust: card.data.isExhaust,
                              rarity: card.rarity.getLabel(l10n),
                              forgeUpgrades: card.forgeUpgrades,
                              baseMaxForgeUpgrades: card.data.baseMaxForgeUpgrades,
                              rarityMultiplier: card.rarityMultiplier,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
