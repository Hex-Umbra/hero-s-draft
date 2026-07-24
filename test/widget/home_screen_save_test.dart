import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/home_screen.dart';
import 'package:roguelike_card_game/services/save_service.dart';

Widget wrapHome() {
  final container = ProviderContainer();
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: const Locale('fr', ''),
      home: const HomeScreen(),
    ),
  );
}

void main() {
  group('HomeScreen save/continue', () {
    testWidgets('CONTINUER is hidden when no save exists', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      expect(find.text('Continuer'), findsNothing);
    });

    testWidgets('CONTINUER appears when a save exists', (tester) async {
      SharedPreferences.setMockInitialValues({
        'run_save_v1': '{"schemaVersion":1,"run":{},"deck":{},"inventory":{},"skills":{}}',
      });
      // Seed a syntactically valid but minimal save purely to make hasSave() true;
      // the "Continuer" tap flow itself is exercised in SaveService's own unit tests.

      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      expect(find.text('Continuer'), findsOneWidget);
    });

    testWidgets('Nouvelle Partie shows a confirmation dialog when a save exists', (tester) async {
      SharedPreferences.setMockInitialValues({
        'run_save_v1': '{"schemaVersion":1,"run":{},"deck":{},"inventory":{},"skills":{}}',
      });

      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      await tester.tap(find.text('JOUER'));
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle Partie'), findsOneWidget);

      // Cancel so the test does not need to also stub ClassSelectionScreen navigation.
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(await SaveService.hasSave(), isTrue);
    });
  });
}
