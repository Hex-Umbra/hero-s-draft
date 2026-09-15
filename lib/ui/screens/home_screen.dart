import 'dart:ui' show AppExitType;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/debug_run_controller.dart';
import 'class_selection_screen.dart';
import 'card_dictionary_screen.dart';
import 'content_editor_screen.dart';
import 'patch_notes_screen.dart';
import 'settings_screen.dart';
import 'map_screen.dart';
import '../../tutorial/tutorial_loader.dart';
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
          content: Text(
            AppLocalizations.of(context)!.missingItemsMessage(names),
          ),
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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const MapScreen()));
    // The pause menu and the death overlay both return here via
    // Navigator.popUntil((route) => route.isFirst) rather than recreating
    // this screen, so the save state must be re-checked on return.
    if (mounted) setState(() {});
  }

  /// Lance une run de test.
  ///
  /// Contrairement à [_startNewGame], elle **ne demande pas** à écraser la
  /// sauvegarde existante et n'y touche pas : une run debug ne persiste rien,
  /// donc elle n'a rien à écraser. Passer par le chemin normal détruirait la
  /// vraie partie avant même que la run de test ne commence.
  Future<void> _startDebugRun() async {
    ref.read(debugRunProvider.notifier).requestDebugRun();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ClassSelectionScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _startNewGame(bool hasSave) async {
    // Chaque départ déclare son mode : sans cela, un appui sur « Run Debug »
    // suivi d'un retour ici teindrait silencieusement cette run normale.
    ref.read(debugRunProvider.notifier).requestNormalRun();

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
              child: Text(
                AppLocalizations.of(context)!.newGameOverwriteConfirm,
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await SaveService.clear(ref.read);
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

  /// Ferme le jeu.
  ///
  /// Sur desktop, la fermeture passe par le moteur ; Android n'implémente pas
  /// cette requête, il faut y dépiler l'activité.
  Future<void> _quitGame() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await SystemNavigator.pop();
      return;
    }
    await ServicesBinding.instance.exitApplication(AppExitType.required);
  }

  /// Un onglet de navigateur ne se ferme pas depuis la page, et iOS interdit
  /// à une app de se fermer elle-même : le bouton n'y aurait aucun effet.
  bool get _canQuit => !kIsWeb && defaultTargetPlatform != TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.menu);

    return Scaffold(
      // SafeArea + defilement : chaque colonne defile si elle ne tient pas en
      // hauteur (voir l'audit responsive du 05/08), plutot que de deborder
      // silencieusement hors ecran.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mainMenu = _buildMainMenu(context);
            // `kDebugMode` est une constante de compilation : en release, le
            // menu de debug et tout ce qu'il atteint sont eliminés au
            // tree-shaking.
            if (!kDebugMode) {
              return _scrollable(constraints, mainMenu);
            }
            final debugMenu = _buildDebugMenu(context);
            // Trop etroit pour deux colonnes : le menu de debug passe sous le
            // menu principal.
            if (constraints.maxWidth < 700) {
              return _scrollable(
                constraints,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [mainMenu, const SizedBox(height: 40), debugMenu],
                ),
              );
            }
            return Row(
              children: [
                Expanded(child: _scrollable(constraints, mainMenu)),
                _scrollable(constraints, debugMenu),
              ],
            );
          },
        ),
      ),
    );
  }

  static const _pagePadding = EdgeInsets.symmetric(horizontal: 48, vertical: 24);

  Widget _scrollable(BoxConstraints constraints, Widget child) {
    return SingleChildScrollView(
      padding: _pagePadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight - _pagePadding.vertical,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [child],
        ),
      ),
    );
  }

  Widget _buildMainMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const outlinedPadding = EdgeInsets.symmetric(horizontal: 40, vertical: 15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        // Largeur commune : alignés à gauche, des boutons de largeurs
        // différentes formeraient un bord droit en escalier.
        SizedBox(
          width: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder<bool>(
                future: SaveService.hasSave(),
                builder: (context, snapshot) {
                  final hasSave = snapshot.data ?? false;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              l10n.continueGame,
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
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: outlinedPadding,
                  side: const BorderSide(color: Colors.white70, width: 2),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TutorialLoader(),
                    ),
                  );
                },
                child: const Text(
                  'TUTORIEL',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: outlinedPadding,
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
                  padding: outlinedPadding,
                  side: const BorderSide(color: Colors.amberAccent, width: 1.5),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PatchNotesScreen(),
                    ),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: outlinedPadding,
                  side: const BorderSide(color: Colors.white70, width: 2),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.settings_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.settingsTitle.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              if (_canQuit) ...[
                const SizedBox(height: 20),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: outlinedPadding,
                    side: const BorderSide(color: Colors.redAccent, width: 2),
                  ),
                  onPressed: _quitGame,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.power_settings_new,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.quitGame.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDebugMenu(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'DEBUG',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              backgroundColor: Colors.deepPurpleAccent,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _startDebugRun,
            child: const Text(
              'RUN DEBUG',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              backgroundColor: Colors.teal,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ContentEditorScreen(),
              ),
            ),
            child: const Text(
              'EDITEUR DE CONTENU',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
