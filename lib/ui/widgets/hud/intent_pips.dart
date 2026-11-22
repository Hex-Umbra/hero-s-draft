import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/enemy_intent.dart';
import 'enemy_intents_panel.dart';

/// Une pastille d'intention : son icône, sa couleur et sa valeur (spec P-05,
/// §4.2).
class IntentPip {
  final IconData icon;
  final Color color;
  final String value;

  /// La valeur est barrée : l'ennemi ne fait rien ce tour.
  final bool struck;

  /// La pastille d'attente d'une intention pas encore connue.
  final bool waiting;

  const IntentPip({
    required this.icon,
    required this.color,
    required this.value,
    required this.struck,
    required this.waiting,
  });
}

/// Les pastilles d'une intention, que le panneau et la fiche dessinent sans
/// rien savoir de plus.
abstract final class IntentPips {
  /// Une liste, la forme que le lot des intentions multiples remplira ; en
  /// 0.6.1, elle a toujours une pastille.
  static List<IntentPip> of(
    EnemyIntent? intent, {
    required bool skipped,
    required AppLocalizations l10n,
  }) {
    if (intent == null) {
      return [
        IntentPip(
          icon: Icons.hourglass_empty,
          color: Colors.white30,
          value: l10n.waitingIntents,
          struck: false,
          waiting: true,
        ),
      ];
    }
    final (icon, color) = _visuals(intent);
    return [
      IntentPip(
        icon: icon,
        color: skipped ? Colors.white38 : color,
        value: EnemyIntentsPanel.compactValue(intent),
        struck: skipped,
        waiting: false,
      ),
    ];
  }

  /// L'icône et la couleur du palier d'une intention : les quatre paliers
  /// d'attaque suivent les seuils des libellés (6, 12 et 20).
  static (IconData, Color) _visuals(EnemyIntent intent) {
    switch (intent.type) {
      case IntentType.attack:
        if (intent.value >= 20) {
          return (Icons.gavel, const Color(0xFFC0392B));
        } else if (intent.value >= 12) {
          return (Icons.whatshot, const Color(0xFFE74C3C));
        } else if (intent.value >= 6) {
          return (Icons.flash_on, const Color(0xFFFF7675));
        }
        return (Icons.bolt, const Color(0xFFF39C12));
      case IntentType.defend:
        return (Icons.shield, const Color(0xFF448AFF));
      case IntentType.buff:
        return (Icons.trending_up, const Color(0xFFE040FB));
    }
  }
}
