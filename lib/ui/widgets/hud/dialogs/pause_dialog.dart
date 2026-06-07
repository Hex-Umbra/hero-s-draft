import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/widgets/game_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import 'package:roguelike_card_game/ui/theme/app_spacing.dart';

class PauseDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onExit;

  const PauseDialog({super.key, required this.onResume, required this.onExit});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onResume,
    required VoidCallback onExit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PauseDialog(onResume: onResume, onExit: onExit);
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
