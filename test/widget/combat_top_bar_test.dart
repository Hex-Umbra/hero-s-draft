import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/widgets/hud/combat_top_bar.dart';

Widget _harness({
  required bool muted,
  required VoidCallback onMuteTap,
  int act = 1,
  int currentLevel = 1,
}) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en', ''), Locale('fr', '')],
  locale: const Locale('fr', ''),
  home: Scaffold(
    body: Stack(
      children: [
        CombatTopBar(
          act: act,
          currentLevel: currentLevel,
          onPauseTap: () {},
          muted: muted,
          onMuteTap: onMuteTap,
        ),
      ],
    ),
  ),
);

void main() {
  group('CombatTopBar - bouton de coupure du son', () {
    testWidgets('affiche l icone haut-parleur actif quand non coupe', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(muted: false, onMuteTap: () {}));

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.volume_off), findsNothing);
    });

    testWidgets('affiche l icone haut-parleur coupe quand coupe', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(muted: true, onMuteTap: () {}));

      expect(find.byIcon(Icons.volume_off), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsNothing);
    });

    testWidgets('un tap declenche le callback fourni, exactement une fois', (
      tester,
    ) async {
      var tapCount = 0;
      await tester.pumpWidget(
        _harness(muted: false, onMuteTap: () => tapCount++),
      );

      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();

      expect(tapCount, 1);
    });

    testWidgets(
      'rejoint le groupe Deck/Pause existant plutot que d occuper un nouveau coin',
      (tester) async {
        await tester.pumpWidget(_harness(muted: false, onMuteTap: () {}));

        // Les trois boutons doivent partager la meme ligne (meme "top"),
        // preuve qu'aucun nouveau coin du HUD n'a ete utilise.
        final muteTop = tester.getTopLeft(find.byIcon(Icons.volume_up)).dy;
        final deckTop = tester.getTopLeft(find.byIcon(Icons.style)).dy;
        final pauseTop = tester
            .getTopLeft(find.byIcon(Icons.pause_circle_outline))
            .dy;

        expect(muteTop, equals(deckTop));
        expect(muteTop, equals(pauseTop));
      },
    );
  });

  group('CombatTopBar - indicateur Acte/Niveau contraint', () {
    testWidgets(
      'ne chevauche pas le cluster de boutons sur telephone etroit (360px)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Acte/niveau a deux chiffres chacun : le plus long realistement
        // atteignable dans une run (voir le rapport pour le detail).
        await tester.pumpWidget(
          _harness(muted: false, onMuteTap: () {}, act: 9, currentLevel: 99),
        );
        await tester.pumpAndSettle();

        // Aucun debordement dur (RenderFlex/overflow) signale pendant le
        // layout.
        expect(tester.takeException(), isNull);

        final textRight = tester.getRect(find.textContaining('Acte')).right;
        final muteButtonLeft = tester
            .getRect(
              find.ancestor(
                of: find.byIcon(Icons.volume_up),
                matching: find.byType(IconButton),
              ),
            )
            .left;

        // Le texte peint (apres mise a l'echelle par le FittedBox) doit
        // rester entierement a gauche du bouton le plus a gauche du trio.
        expect(textRight, lessThanOrEqualTo(muteButtonLeft));
      },
    );
  });
}
