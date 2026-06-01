import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';

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

    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A3D),
      title: Text(
        l10n.pauseTitle,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: onExit,
            child: Text(
              l10n.backToMainMenu,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onResume,
            child: Text(
              l10n.resumeCombat,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
