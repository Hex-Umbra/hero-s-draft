import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/deck_screen.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';

import '../unit/shipped_data.dart';

void main() {
  Widget buildApp(ProviderContainer container, {bool allowMerge = true}) {
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
        home: DeckScreen(allowMerge: allowMerge),
      ),
    );
  }

  /// Une vue large : le dialogue de fusion est plein écran.
  void largeView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Un deck de [cards], sur le registre des runes livrées, que l'écran de
  /// deck lit pour tirer l'offre.
  ProviderContainer deckOf(List<CardInstance> cards) {
    shippedRuneRegistry(shippedRuneIds());
    final container = ProviderContainer();
    addTearDown(container.dispose);
    for (final card in cards) {
      container.read(deckProvider.notifier).addCardToMasterDeck(card);
    }
    return container;
  }

  /// Laisse expirer les notifications avant de démonter l'arbre.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  }

  // Transcendance, lue par la fusion de l'écran de deck (spec P-43 E3, §4.8,
  // §8 ; A17) : sans le bonus de la run, la somme serait bornée à 1.
  testWidgets('trois rares a Econome 1 fusionnent en epique a Econome 2 sous '
      'le plafond releve de la run', (WidgetTester tester) async {
    largeView(tester);
    final container = deckOf([
      for (var i = 0; i < 3; i++)
        CardInstance(
          data: shippedCard('strike_basic'),
          rarity: CardRarity.rare,
          forgeUpgrades: const ['eco:1'],
        ),
    ]);
    container.read(runProvider.notifier).raiseRuneCap('eco');

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FUSIONNER (3)'));
    await tester.pumpAndSettle();
    // L'offre de la carte fusionnée — Tranchant au moins s'y offre.
    await tester.tap(find.text('Choisir').first);
    await tester.pumpAndSettle();

    final merged = container.read(deckProvider).masterDeck.single;
    expect(merged.rarity, CardRarity.epic);
    expect(ForgeUpgradeData.levelsOf(merged.forgeUpgrades)['eco'], 2);
    await settle(tester);
  });
}
