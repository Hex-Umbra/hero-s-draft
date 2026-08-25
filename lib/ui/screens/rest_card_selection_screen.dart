import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/ui_card.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/forge_upgrade_dialog.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/page_header.dart';

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
      }
    } else {
      // Card Removal
      Navigator.of(context).pop(card);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final deck = ref.watch(deckProvider).masterDeck;

    final appBar = PageHeader(
      title: title,
      showBackButton: true,
      isParchment: false,
      onBackPressed: () => Navigator.of(context).pop(null),
    );

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      appBar: appBar,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white70,
                fontSize: isMobile ? 12 : 15,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
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
                        return UiCard.fromInstance(
                          card: card,
                          locale: locale,
                          l10n: l10n,
                          onTap: () => _onCardTapped(context, ref, card),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
