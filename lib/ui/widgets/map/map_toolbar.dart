import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../screens/deck_screen.dart';
import 'dialogs/stats_dialog.dart';
import 'dialogs/relics_dialog.dart';
import 'dialogs/probabilities_dialog.dart';

/// Barre d'outils affichée dans l'AppBar de MapScreen : accès rapide au
/// deck, aux stats de run, aux reliques et aux probabilités de récompense.
class MapToolbar extends StatelessWidget {
  final bool canMerge;
  final int deckCount;
  final int relicsCount;

  const MapToolbar({
    super.key,
    required this.canMerge,
    required this.deckCount,
    required this.relicsCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(50, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DeckScreen()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.style, color: Color(0xFF4A3728), size: 20),
                if (deckCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: canMerge
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF8B4513),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE8D5B5),
                          width: 1,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$deckCount',
                        style: const TextStyle(
                          color: Color(0xFFE8D5B5),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: Text(
              canMerge ? 'DECK (!)' : l10n.myDeck.toUpperCase(),
              style: TextStyle(
                color: canMerge ? Colors.redAccent : const Color(0xFF4A3728),
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: const Color(0xFF4A3728).withAlpha(50),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(50, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => StatsDialog.show(context),
            icon: const Icon(
              Icons.bar_chart_rounded,
              color: Color(0xFF4A3728),
              size: 20,
            ),
            label: Text(
              l10n.stats.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF4A3728),
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: const Color(0xFF4A3728).withAlpha(50),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(50, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => RelicsDialog.show(context),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF4A3728),
                  size: 20,
                ),
                if (relicsCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFE8D5B5),
                          width: 1,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$relicsCount',
                        style: const TextStyle(
                          color: Color(0xFFE8D5B5),
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: Text(
              l10n.relics.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF4A3728),
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: const Color(0xFF4A3728).withAlpha(50),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(50, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => ProbabilitiesDialog.show(context),
            icon: const Icon(
              Icons.casino_outlined,
              color: Color(0xFF4A3728),
              size: 20,
            ),
            label: Text(
              l10n.chances.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF4A3728),
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
