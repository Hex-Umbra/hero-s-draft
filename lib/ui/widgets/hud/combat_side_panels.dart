import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../game/systems/charge_rules.dart';
import '../../../models/data/charge_data.dart';
import '../../../models/data/effect_icon_table.dart';
import '../../../models/enemy_instance.dart';
import '../../../models/status_effect.dart';
import 'status_effects_panel.dart';
import 'enemy_intents_panel.dart';

/// Piles de pioche/défausse et panneaux de statuts/intentions ennemies,
/// ancrés en bas de l'écran de combat.
class CombatSidePanels extends StatelessWidget {
  /// La hauteur, depuis le bas, où se pose le panneau des statuts du héros.
  static const double statusPanelBottom = 80;

  /// La place réservée au-dessus de [statusPanelBottom] au panneau des
  /// statuts : deux rangées. La barre des signatures n'y descend pas (A38).
  static const double statusPanelReserve = 120;

  /// La hauteur, depuis le bas, où se pose le panneau des intentions ennemies.
  static const double intentsPanelBottom = 80;

  /// Le bas du compteur de tour, mesuré depuis le milieu de l'écran.
  /// Recopie les positions de `TurnControlPanel` : son compteur se pose à
  /// `hauteur / 2 + 33` et mesure environ 30 px (6 px de marge de chaque côté
  /// d'un texte de 12). Si ces positions bougent, cette constante suit.
  static const double turnCounterBottomFromMiddle = 33 + 30;

  /// L'écart gardé entre le haut du panneau des intentions et le compteur.
  static const double intentsPanelMargin = 8;

  /// La hauteur sous laquelle le panneau des intentions ne descend pas, même
  /// sur un écran trop bas : le titre et un ennemi restent lisibles.
  static const double intentsPanelMinHeight = 100;

  /// La hauteur maximale du panneau des intentions pour un écran haut de
  /// [screenHeight] (la mesure de `TurnControlPanel`, `MediaQuery` size) :
  /// son haut ne remonte jamais au-dessus du compteur de tour, et il ne
  /// recouvre ni le bouton de fin de tour ni le compteur. Au-delà, il défile.
  static double intentsPanelMaxHeight(double screenHeight) {
    final available = (screenHeight - intentsPanelBottom) -
        (screenHeight / 2 + turnCounterBottomFromMiddle + intentsPanelMargin);
    return available < intentsPanelMinHeight
        ? intentsPanelMinHeight
        : available;
  }

  final int drawPileCount;
  final int discardPileCount;
  final List<StatusEffect> heroStatuses;
  final List<ChargeLine> heroChargeLines;
  final ChargeCatalog charges;
  final List<EnemyInstance> enemies;
  final EffectIconTable effectIcons;

  const CombatSidePanels({
    super.key,
    required this.drawPileCount,
    required this.discardPileCount,
    required this.heroStatuses,
    required this.heroChargeLines,
    required this.enemies,
    this.charges = const ChargeCatalog.empty(),
    this.effectIcons = const EffectIconTable.empty(),
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
            bottom: statusPanelBottom,
            left: 20,
            child: StatusEffectsPanel(
              statuses: heroStatuses,
              chargeLines: heroChargeLines,
              charges: charges,
              maxHeight: statusPanelReserve,
              effectIcons: effectIcons,
            ),
          ),

          // Panneau des Intentions Ennemies (Bas Droite, au-dessus de la Défausse)
          if (enemies.isNotEmpty)
            Positioned(
              bottom: intentsPanelBottom,
              right: 20,
              child: EnemyIntentsPanel(
                enemies: enemies,
                charges: charges,
                maxHeight: intentsPanelMaxHeight(
                  MediaQuery.of(context).size.height,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
