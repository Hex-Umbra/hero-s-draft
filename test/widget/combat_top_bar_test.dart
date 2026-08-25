import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/widgets/hud/combat_top_bar.dart';

Widget _harness({required bool muted, required VoidCallback onMuteTap}) =>
    MaterialApp(
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
              act: 1,
              currentLevel: 1,
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
}
