import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/widgets/debug/debug_menu_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import 'package:roguelike_card_game/ui/theme/app_spacing.dart';

class PauseDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onExit;

  /// Transmis au menu de debug : en combat, l'onglet Combat apparait et
  /// l'action d'acte suivant disparait.
  final bool inCombat;

  const PauseDialog({
    super.key,
    required this.onResume,
    required this.onExit,
    required this.inCombat,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onResume,
    required VoidCallback onExit,
    required bool inCombat,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PauseDialog(
          onResume: onResume,
          onExit: onExit,
          inCombat: inCombat,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GameDialog(
      showCloseButton: false,
      title: Text(
        l10n.pauseTitle,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameButton(
            text: l10n.resumeCombat,
            onPressed: onResume,
          ),
          // `kDebugMode` est une constante de compilation : en release la
          // condition est repliee a false et tout ce sous-arbre devient
          // inatteignable, donc elimine au tree-shaking.
          if (kDebugMode) ...[
            AppSpacing.heightSm,
            GameButton(
              text: 'Menu de debug',
              baseColor: Colors.deepPurpleAccent,
              onPressed: () =>
                  DebugMenuDialog.show(context, inCombat: inCombat),
            ),
          ],
          AppSpacing.heightSm,
          GameButton(
            text: l10n.backToMainMenu,
            baseColor: Colors.redAccent,
            onPressed: onExit,
          ),
        ],
      ),
    );
  }
}
