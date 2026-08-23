import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/tutorial/tutorial_screen.dart';

import '../tutorial/tutorial_test_registry.dart';

/// Les cartes du pool de départ portent une clé stable
/// (`tutorial-pool-<id>`, posée par `TutorialStarterDeckWidget`) : ce test
/// n'a besoin que d'en taper les 5 premières, jamais de connaître leurs ids.
Finder _poolCards() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is SizedBox &&
        (widget.key?.toString() ?? '').contains('tutorial-pool-'),
  );
}

/// Avance d'une étape via le bouton SUIVANT, puis laisse l'animation de 300 ms
/// de la `PageView` se dérouler. Jamais de `pumpAndSettle()` dans ce fichier :
/// l'étape "Les Effets Élémentaires" démarre un `Timer.periodic` qui ne
/// s'arrête jamais tout seul, ce qui ferait tourner `pumpAndSettle()`
/// indéfiniment.
Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.text('SUIVANT'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets(
    'franchir l\'étape Fusion (avec et sans fusionner) ne lève aucune exception',
    (tester) async {
      // Régression (revue de branche P-45, critique 1) : `TutorialMergeWidget`
      // indexait `hand[0..2]`/`hand.first` sans garde. `nextStep()`/`prevStep()`
      // vident la main via `resetScratch()` avant que la `PageView` n'ait fini
      // d'animer vers la page suivante ; l'`AnimatedBuilder` de
      // `tutorial_screen.dart` reconstruit alors la page de fusion, encore
      // affichée, avec une main vide. Ce test monte le vrai `TutorialScreen`
      // (pas seulement le widget) car le défaut naît précisément de
      // l'interaction entre son `AnimatedBuilder` et la `PageView`.
      tester.view.physicalSize = const Size(1600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', ''), Locale('fr', '')],
          locale: const Locale('fr', ''),
          home: TutorialScreen(data: buildTutorialTestRegistry()),
        ),
      );
      await tester.pump();

      // Étape 0 (Bienvenue) -> 1 (Choix de classe).
      await _tapNext(tester);

      // Étape 1 : choisir le Paladin.
      await tester.tap(find.text('Le Paladin'));
      await tester.pump();
      await _tapNext(tester);

      // Étape 2 : drafter 5 cartes du pool commun.
      final pool = _poolCards();
      for (var i = 0; i < 5; i++) {
        await tester.tap(pool.at(i));
        await tester.pump();
      }
      await _tapNext(tester);

      // Étapes 3, 4, 5, 6 : pas d'action requise.
      await _tapNext(tester); // -> 4 Types de Rencontres
      await _tapNext(tester); // -> 5 Vue d'ensemble du combat
      await _tapNext(tester); // -> 6 Cartes & Mana
      await _tapNext(tester); // -> 7 Jouer des cartes & finir le tour

      // Étape 7 : jouer la carte affichée sur le Slime, puis celle affichée
      // sur le Héros. `TutorialPlayCardWidget` ne montre qu'une seule carte
      // par phase (l'attaque, puis la compétence d'Armure) ; on ne présume
      // pas de son identité, `_seedPlayCardHand` pouvant tout aussi bien
      // retenir une carte de classe (le Paladin en a deux qui correspondent)
      // qu'une carte commune du pool.
      await tester.tap(find.byType(Draggable<CardInstance>));
      await tester.pump();
      await tester.tap(find.text('Slime'));
      await tester.pump();

      await tester.tap(find.byType(Draggable<CardInstance>));
      await tester.pump();
      await tester.tap(find.text('HÉROS'));
      await tester.pump();

      await _tapNext(tester); // -> 8 Armure & Dégâts
      await _tapNext(tester); // -> 9 Effets Élémentaires (démarre un Timer.periodic)
      await _tapNext(tester); // -> 10 Intentions Ennemies

      // Purge : à cette taille de test, le vrai `EnemyIntentsPanel` déborde
      // (défaut préexistant, hors sujet ici — voir la tâche de suivi signalée
      // séparément). Ce test ne porte que sur la Fusion ; on efface ce bruit
      // avant d'y entrer pour ne pas le confondre avec la régression visée.
      tester.takeException();

      await _tapNext(tester); // -> 11 La Fusion de Cartes

      expect(tester.takeException(), isNull);

      // Sans fusionner : Précédent doit repasser par la même défaillance que
      // Suivant (branche `!_isMerged`, `hand[0]` sur une main vidée par
      // `prepareStep(10)`).
      await tester.tap(find.byTooltip('Précédent'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Revenir sur l'étape Fusion (main de 3 cartes re-semée par
      // `prepareStep(11)`), fusionner pour de bon cette fois, puis avancer :
      // branche `_isMerged`, `hand.first` sur une main vidée par
      // `prepareStep(12)`.
      await _tapNext(tester); // -> 11 La Fusion de Cartes (main re-semée)
      await tester.tap(find.text('Sélectionner les 3 et fusionner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650)); // fin du contrôleur (600 ms) + flash
      await tester.pump(const Duration(milliseconds: 200)); // callback différé de 150 ms

      await _tapNext(tester); // -> 12 L'Expérience & le Level Up
      expect(tester.takeException(), isNull);
    },
  );
}
