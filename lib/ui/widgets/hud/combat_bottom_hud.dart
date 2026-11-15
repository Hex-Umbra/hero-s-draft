import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../game/systems/mana_reserve.dart';
import 'mana_indicator.dart';
import 'player_health_bar.dart';

/// Cristaux de mana + barre de vie du joueur, ancrés en bas de l'écran de combat.
class CombatBottomHud extends StatelessWidget {
  final double hudHeight;
  final double hudWidth;
  final int currentMana;
  final int maxMana;
  final int currentPv;
  final int maxPv;
  final int armure;
  final int effectiveMight;

  /// Ce qui passera en réserve au prochain tour, ou `null` hors *Canalisation*.
  final ManaReservePreview? reservePreview;

  /// Hauteur de la ligne de légende de la réserve, et marge du haut qui la
  /// compense : les cristaux, centrés, restent à leur hauteur d'avant.
  static const double reserveLegendHeight = 14;

  const CombatBottomHud({
    super.key,
    required this.hudHeight,
    required this.hudWidth,
    required this.currentMana,
    required this.maxMana,
    required this.currentPv,
    required this.maxPv,
    required this.armure,
    required this.effectiveMight,
    this.reservePreview,
  });

  @override
  Widget build(BuildContext context) {
    final preview = reservePreview;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: hudHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: hudWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (preview != null)
                    const SizedBox(height: reserveLegendHeight),
                  // Cristaux de Mana
                  ManaIndicator(
                    currentMana: currentMana,
                    maxMana: maxMana,
                    reserveArrows: preview?.banked ?? 0,
                  ),
                  if (preview != null) _reserveLegend(context, preview),
                  const SizedBox(height: 4),
                  PlayerHealthBar(
                    currentPv: currentPv,
                    maxPv: maxPv,
                    armure: armure,
                    effectiveMight: effectiveMight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// La légende cyan sous les cristaux ; la ligne reste quand rien ne passe
  /// en réserve, pour que la barre de vie ne saute pas.
  Widget _reserveLegend(BuildContext context, ManaReservePreview preview) {
    final l10n = AppLocalizations.of(context)!;
    final text = preview.capped
        ? l10n.manaReserveNextTurnCapped(preview.banked)
        : l10n.manaReserveNextTurn(preview.banked);
    return SizedBox(
      height: reserveLegendHeight,
      child: preview.banked == 0
          ? null
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}
