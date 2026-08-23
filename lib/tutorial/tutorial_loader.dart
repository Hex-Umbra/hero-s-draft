import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/game_data_service.dart';
import 'tutorial_screen.dart';

/// Unique frontière Riverpod de `lib/tutorial/`.
///
/// Résout `gameDataLoaderProvider` — un `FutureProvider` de données
/// immuables, sans aucun état de run — et injecte le registre dans
/// [TutorialScreen], qui le passe au moteur. Aucun autre fichier du dossier
/// n'a le droit d'importer Riverpod : voir ADR-081.
class TutorialLoader extends ConsumerWidget {
  const TutorialLoader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return ref
        .watch(gameDataLoaderProvider)
        .when(
          data: (registry) => TutorialScreen(data: registry),
          loading: () => const Scaffold(
            backgroundColor: Color(0xFF0B0F19),
            body: Center(child: CircularProgressIndicator(color: Colors.amber)),
          ),
          error: (error, _) => Scaffold(
            backgroundColor: const Color(0xFF0B0F19),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isFrench
                          ? 'Impossible de charger les données du jeu.'
                          : 'Could not load game data.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(isFrench ? 'Retour' : 'Back'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
  }
}
