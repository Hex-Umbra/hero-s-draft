import 'package:flutter/material.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../game_button.dart';
import 'rune_style.dart';

/// La ligne d'une rune, commune aux écrans qui en proposent une — le choix
/// de la fusion, l'affûtage du feu, l'échange au Puits (spec P-43 E2,
/// §4.5) : l'icône et la couleur de la rune, un titre, sa description, et un
/// bouton dont l'écran donne le libellé et l'état.
class ForgeSlotRow extends StatelessWidget {
  final ForgeUpgradeData rune;
  final String title;

  /// Une ligne sous le titre — le niveau et le suivant, à l'affûtage ;
  /// `null` : aucune.
  final String? detail;
  final String description;
  final String actionLabel;

  /// L'action du bouton ; `null` : le bouton est inactif.
  final VoidCallback? onAction;

  const ForgeSlotRow({
    super.key,
    required this.rune,
    required this.title,
    this.detail,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // Un nom inconnu retombe sur du gris et une icône d'aide (A19).
    final color = runeColors[rune.color] ?? Colors.grey;
    final icon = runeIcons[rune.icon] ?? Icons.help_outline;
    final detail = this.detail;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(60),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withAlpha(100),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GameButton(
            text: actionLabel,
            onPressed: onAction,
            baseColor: color,
            height: 36,
            fontSize: 13,
          ),
        ],
      ),
    );
  }
}
