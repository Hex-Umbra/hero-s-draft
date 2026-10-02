import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/screens/rest_card_selection_screen.dart';
import 'package:roguelike_card_game/ui/widgets/forge_upgrade_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';

import '../unit/shipped_data.dart';

/// Monte la sélection de la forge du feu sur un deck d'une seule [card], avec
/// les huit runes livrées.
Future<ProviderContainer> _pumpForgeSelection(
  WidgetTester tester,
  CardInstance card,
) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final registry = shippedRuneRegistry(shippedRuneIds(), cards: [card.data]);
  final container = ProviderContainer(
    overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
  );
  addTearDown(container.dispose);
  container.read(deckProvider.notifier).addCardToMasterDeck(card);

  await tester.pumpWidget(
    UncontrolledProviderScope(
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
        home: const RestCardSelectionScreen(
          title: 'FORGER UNE CARTE',
          subtitle: 'Choisissez une carte à améliorer définitivement.',
          isForge: true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Une notification programme un minuteur de 3,5 s qu'aucun overlay ne
/// démonte ici : il doit expirer avant la fin du test.
Future<void> _settleNotifications(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpWidget(const SizedBox());
}

/// Le refus de la sélection du feu (spec P-43 E1, A11, §5.3).
void main() {
  testWidgets('une Concentration peu commune portant Veloce est refusee, avec '
      'le motif', (tester) async {
    // Sa fente libre ne peut rien recevoir : Veloce est sa seule rune
    // eligible, et son plafond est atteint.
    final card = CardInstance(
      data: shippedCard('concentration'),
      rarity: CardRarity.uncommon,
      forgeUpgrades: const ['quick:1'],
    );
    final container = await _pumpForgeSelection(tester, card);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(ForgeUpgradeDialog), findsNothing);
    expect(container.read(notificationProvider).last.message,
        'Aucune rune ne peut être ajoutée à cette carte.');

    await _settleNotifications(tester);
  });

  testWidgets('une Frappe commune sans rune ouvre le dialogue de forge',
      (tester) async {
    final card = CardInstance(data: shippedCard('strike_basic'));
    final container = await _pumpForgeSelection(tester, card);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(ForgeUpgradeDialog), findsOneWidget);
    expect(container.read(notificationProvider), isEmpty);

    await _settleNotifications(tester);
  });

  testWidgets('une carte pleine garde son message', (tester) async {
    final card = CardInstance(
      data: shippedCard('strike_basic'),
      forgeUpgrades: const ['sharp:1'],
    );
    final container = await _pumpForgeSelection(tester, card);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(ForgeUpgradeDialog), findsNothing);
    expect(container.read(notificationProvider).last.message,
        "Cette carte a atteint sa capacité maximale d'améliorations de forge !");

    await _settleNotifications(tester);
  });
}
