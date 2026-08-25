import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/services/audio/audio_providers.dart';
import 'package:roguelike_card_game/ui/screens/settings_screen.dart';

Widget _harness() => const ProviderScope(
  child: MaterialApp(
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [Locale('en', ''), Locale('fr', '')],
    locale: Locale('fr', ''),
    home: SettingsScreen(),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SettingsScreen', () {
    testWidgets('affiche trois curseurs et un interrupteur', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsNWidgets(3));
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('l interrupteur bascule la coupure globale', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(SettingsScreen));
      final container = ProviderScope.containerOf(element);
      expect(container.read(audioSettingsProvider).muted, isFalse);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(container.read(audioSettingsProvider).muted, isTrue);
    });

    testWidgets('deplacer le curseur des bruitages met a jour le reglage', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(SettingsScreen));
      final container = ProviderScope.containerOf(element);

      await tester.drag(find.byType(Slider).at(1), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(container.read(audioSettingsProvider).sfx, lessThan(1.0));
    });
  });
}
