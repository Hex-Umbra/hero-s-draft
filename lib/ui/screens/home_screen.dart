import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'class_selection_screen.dart';
import 'card_dictionary_screen.dart';
import 'patch_notes_screen.dart';
import 'map_screen.dart';
import '../../tutorial/tutorial_loader.dart';
import '../../tutorial/tutorial_progress_service.dart';
import '../../services/save_service.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/game_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _continueGame() async {
    final result = await SaveService.load(ref.read);
    if (!mounted) return;

    if (!result.success) {
      // The save was corrupted or unreadable; SaveService.load already
      // cleared it internally, so simply refresh this screen — the
      // "Continuer" button will disappear on rebuild.
      setState(() {});
      return;
    }

    if (result.missingItems.isNotEmpty) {
      final locale = Localizations.localeOf(context).languageCode;
      final names = result.missingItems
          .map((m) => locale == 'fr' ? m.nameFr : m.nameEn)
          .join(', ');
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => GameDialog(
          title: Text(AppLocalizations.of(context)!.missingItemsTitle),
          content: Text(AppLocalizations.of(context)!.missingItemsMessage(names)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
    // The pause menu and the death overlay both return here via
    // Navigator.popUntil((route) => route.isFirst) rather than recreating
    // this screen, so the save state must be re-checked on return.
    if (mounted) setState(() {});
  }

  Future<void> _startNewGame(bool hasSave) async {
    if (hasSave) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => GameDialog(
          title: Text(AppLocalizations.of(context)!.newGameOverwriteTitle),
          content: Text(AppLocalizations.of(context)!.newGameOverwriteMessage),
          onClose: () => Navigator.of(dialogContext).pop(false),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(AppLocalizations.of(context)!.newGameOverwriteConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await SaveService.clear();
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ClassSelectionScreen()),
    );
    // Same reasoning as _continueGame: refresh save state on return, since
    // the pause menu / death overlay pop back here without recreating this
    // screen.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.menu);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "HERO'S DRAFT",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Roguelike Deckbuilder MVP",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 60),
            FutureBuilder<bool>(
              future: SaveService.hasSave(),
              builder: (context, snapshot) {
                final hasSave = snapshot.data ?? false;
                return Column(
                  children: [
                    if (hasSave)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 60,
                              vertical: 20,
                            ),
                            backgroundColor: Colors.green,
                            textStyle: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _continueGame,
                          child: Text(
                            AppLocalizations.of(context)!.continueGame,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 20,
                        ),
                        backgroundColor: Colors.blueAccent,
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _startNewGame(hasSave),
                      child: const Text(
                        'JOUER',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            FutureBuilder<bool>(
              future: TutorialProgressService.hasCompletedTutorial(),
              builder: (context, snapshot) {
                final isCompleted = snapshot.data ?? false;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        side: const BorderSide(color: Colors.white70, width: 2),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TutorialLoader(),
                          ),
                        );
                        // Refresh the UI to update the 'NEW' badge state
                        setState(() {});
                      },
                      child: const Text(
                        'TUTORIEL',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                    if (!isCompleted)
                      Positioned(
                        right: -10,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                side: const BorderSide(color: Colors.white70, width: 2),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CardDictionaryScreen(),
                  ),
                );
              },
              child: const Text(
                'DICTIONNAIRE',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                side: const BorderSide(
                  color: Colors.amberAccent,
                  width: 1.5,
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PatchNotesScreen(),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.article_outlined,
                    color: Colors.amberAccent,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'PATCH NOTES',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
