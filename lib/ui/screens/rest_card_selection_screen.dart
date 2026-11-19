import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/services/forge_rune_rules.dart';
import '../../models/card_instance.dart';
import '../../models/data/game_data_registry.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/ui_card.dart';
import '../widgets/forge/sharpen_rune_dialog.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/page_header.dart';

/// La sélection d'une carte du deck : au feu de camp, pour en affûter une
/// rune ou pour l'oublier ; au *Rémouleur*, pour en affûter une sans or.
class RestCardSelectionScreen extends ConsumerWidget {
  final String title;
  final String subtitle;

  /// Vrai pour l'affûtage (spec P-43 E2, §4.7) : seules les cartes portant
  /// une rune affûtable sont listées — les autres sont masquées, non plus
  /// grisées comme le voulait A4 ; une carte touchée ouvre le dialogue
  /// d'affûtage, et l'écran se ferme sur la carte et la rune choisie. Faux
  /// pour l'oubli : tout le deck est listé, et l'écran se ferme sur la carte
  /// touchée.
  final bool isSharpen;

  /// Vrai pour l'affûtage sans or du *Rémouleur* (spec P-43 E3, §4.9, A21) :
  /// le dialogue rend la rune choisie, sans coût ni condition d'or, et
  /// n'écrit rien — l'événement la monte. Faux au feu, qui paie. Sans effet
  /// hors de l'affûtage.
  final bool isFree;

  const RestCardSelectionScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSharpen,
    this.isFree = false,
  });

  void _onCardTapped(BuildContext context, CardInstance card) async {
    if (!isSharpen) {
      Navigator.of(context).pop(card);
      return;
    }

    final runeId = await showDialog<String>(
      context: context,
      builder: (context) => SharpenRuneDialog(card: card, isFree: isFree),
    );
    if (runeId != null && context.mounted) {
      Navigator.of(context).pop((card, runeId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final masterDeck = ref.watch(deckProvider).masterDeck;
    final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];
    // Le plafond effectif de la run (spec P-43 E3, §4.8, A17), au feu comme
    // au *Rémouleur* : relevé, il rend une carte affûtable, et l'écran la
    // montre aussitôt.
    final capBonus = ref.watch(runProvider).runeCapBonus;
    final deck = isSharpen
        ? [
            for (final card in masterDeck)
              if (ForgeRuneRules.hasSharpenableRune(
                card,
                catalog,
                capBonus: capBonus,
              ))
                card,
          ]
        : masterDeck;

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
                        // Un filet : les deux appelants ferment déjà
                        // l'affûtage quand rien n'est affûtable.
                        isSharpen
                            ? l10n.restCampSharpenNone
                            : l10n.restCardSelectionDeckEmpty,
                        style: const TextStyle(color: Colors.white54, fontSize: 16),
                        textAlign: TextAlign.center,
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
                      // La sélection se ferme par le `context` de l'écran,
                      // non par celui d'une case de la grille.
                      itemBuilder: (_, index) {
                        final card = deck[index];
                        return UiCard.fromInstance(
                          card: card,
                          locale: locale,
                          l10n: l10n,
                          onTap: () => _onCardTapped(context, card),
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
