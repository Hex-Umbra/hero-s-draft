import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/debug_run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/widgets/game_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import 'package:roguelike_card_game/ui/theme/app_spacing.dart';

class PauseDialog extends ConsumerWidget {
  final VoidCallback onResume;
  final VoidCallback onExit;

  /// Conserve pour les appelants, qui savent dans quel ecran ils sont.
  /// Le dialogue ne s'en sert plus depuis que les commandes de debug ont
  /// rejoint `DebugDrawer`, ancre a meme l'ecran.
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDebugRun = kDebugMode && ref.watch(debugRunProvider).isDebugRun;

    return GameDialog(
      showCloseButton: false,
      title: Text(l10n.pauseTitle, textAlign: TextAlign.center),
      // Le marqueur reste ici, meme si les commandes n'y sont plus : c'est en
      // mettant le jeu en pause qu'on se demande si la partie est enregistree,
      // et la poignee du tiroir ne dit pas, elle, que rien ne l'est.
      subtitle: isDebugRun
          ? const Text(
              'RUN DEBUG — aucune sauvegarde',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameButton(text: l10n.resumeCombat, onPressed: onResume),
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
