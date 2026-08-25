import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../screens/deck_screen.dart';

/// Boutons Deck/Pause/Coupure du son et indicateur Acte/Niveau en haut de
/// l'écran de combat.
class CombatTopBar extends StatelessWidget {
  final int act;
  final int currentLevel;
  final VoidCallback onPauseTap;
  final bool muted;
  final VoidCallback onMuteTap;

  const CombatTopBar({
    super.key,
    required this.act,
    required this.currentLevel,
    required this.onPauseTap,
    required this.muted,
    required this.onMuteTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: Stack(
        children: [
          // Bouton Coupure du son (Haut Droite, rejoint Deck/Pause).
          // Volontairement le plus a gauche du trio : c'est le controle le
          // moins urgent des trois, donc le plus loin du bord.
          Positioned(
            top: 10,
            right: 130,
            child: IconButton(
              icon: Icon(
                muted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 40,
              ),
              tooltip: l10n.muteAll,
              onPressed: onMuteTap,
            ),
          ),

          // Bouton Mon Deck (Haut Droite, à côté de Pause)
          Positioned(
            top: 10,
            right: 75,
            child: IconButton(
              icon: const Icon(Icons.style, color: Colors.amber, size: 40),
              tooltip: l10n.myDeck,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DeckScreen(allowMerge: false),
                  ),
                );
              },
            ),
          ),

          // Bouton Pause (Haut Droite)
          Positioned(
            top: 10,
            right: 20,
            child: IconButton(
              icon: const Icon(
                Icons.pause_circle_outline,
                color: Colors.white,
                size: 40,
              ),
              onPressed: onPauseTap,
            ),
          ),

          // Indicateurs de niveau (Haut Gauche).
          // `right: 196` borne la largeur disponible pour ne jamais empieter
          // sur le trio de boutons : mesure reelle (test a 360 px, theme de
          // l'appli), le bouton son (le plus a gauche du trio, right: 130)
          // a son bord gauche a 174px du bord ecran, donc a 186px de son
          // bord droit ; 196 laisse 10px de marge. `FittedBox(scaleDown)`
          // plutot qu'une ellipse : Acte/Niveau sont des nombres que le
          // joueur doit pouvoir lire entierement, jamais tronquer.
          Positioned(
            top: 10,
            left: 20,
            right: 196,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.actLevel(act, currentLevel),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
