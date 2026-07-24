import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';

/// Avertissements de mana, bouton de fin de tour et compteur de tour,
/// ancrés au milieu droit de l'écran de combat.
class TurnControlPanel extends StatelessWidget {
  final bool canEndTurn;
  final VoidCallback onEndTurnTap;
  final bool showManaWarning;
  final bool showRemainingManaWarning;
  final int turnCount;

  const TurnControlPanel({
    super.key,
    required this.canEndTurn,
    required this.onEndTurnTap,
    required this.showManaWarning,
    required this.showRemainingManaWarning,
    required this.turnCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Positioned.fill(
      child: Stack(
        children: [
          // Avertissement "Plus de mana" placé au-dessus du bouton de Fin de Tour
          if (showManaWarning)
            Positioned(
              right: 20,
              top: screenHeight / 2 - 85,
              child: Container(
                width: 170,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C).withAlpha(245),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.cyanAccent.withAlpha(200),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(150),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  l10n.manaWarning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Avertissement "Mana restant" placé au-dessus du bouton de Fin de Tour
          if (showRemainingManaWarning)
            Positioned(
              right: 20,
              top: screenHeight / 2 - 85,
              child: Container(
                width: 170,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C).withAlpha(245),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amberAccent.withAlpha(200),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(150),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  l10n.remainingManaWarning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Bouton Fin de Tour (Milieu Droite)
          Positioned(
            right: 20,
            top: screenHeight / 2 - 25,
            child: SizedBox(
              width: 170,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: canEndTurn ? onEndTurnTap : null,
                icon: const Icon(Icons.check),
                label: Text(
                  l10n.endTurn,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          // Compteur de tour placé juste en dessous du bouton de Fin de Tour
          Positioned(
            right: 20,
            top: screenHeight / 2 + 33,
            child: Container(
              width: 170,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C).withAlpha(200),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                l10n.turnCount(turnCount),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
