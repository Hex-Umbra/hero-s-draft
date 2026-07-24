import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../services/save_service.dart';
import '../../screens/class_selection_screen.dart';

/// Écran de fin de run affiché à la mort du héros (GameScreen).
class DeathOverlay extends StatelessWidget {
  const DeathOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: Container(
        color: Colors.red.withAlpha(230),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.youAreDead,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      await SaveService.clear();
                      if (!context.mounted) return;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Text(l10n.mainMenu),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      await SaveService.clear();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const ClassSelectionScreen(),
                        ),
                      );
                    },
                    child: Text(l10n.changeClass),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
