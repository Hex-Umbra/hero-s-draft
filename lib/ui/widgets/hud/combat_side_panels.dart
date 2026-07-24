import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/enemy_instance.dart';
import '../../../models/status_effect.dart';
import 'status_effects_panel.dart';
import 'enemy_intents_panel.dart';

/// Piles de pioche/défausse et panneaux de statuts/intentions ennemies,
/// ancrés en bas de l'écran de combat.
class CombatSidePanels extends StatelessWidget {
  final int drawPileCount;
  final int discardPileCount;
  final List<StatusEffect> heroStatuses;
  final List<EnemyInstance> enemies;

  const CombatSidePanels({
    super.key,
    required this.drawPileCount,
    required this.discardPileCount,
    required this.heroStatuses,
    required this.enemies,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: Stack(
        children: [
          // Draw Pile (Bas Gauche)
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.drawPile(drawPileCount),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Discard Pile (Bas Droite)
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.discardPile(discardPileCount),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Panneau des Status/Buffs du Joueur (Bas Gauche, au-dessus de la Pioche)
          Positioned(
            bottom: 80,
            left: 20,
            child: StatusEffectsPanel(statuses: heroStatuses),
          ),

          // Panneau des Intentions Ennemies (Bas Droite, au-dessus de la Défausse)
          if (enemies.isNotEmpty)
            Positioned(
              bottom: 80,
              right: 20,
              child: EnemyIntentsPanel(enemies: enemies),
            ),
        ],
      ),
    );
  }
}
