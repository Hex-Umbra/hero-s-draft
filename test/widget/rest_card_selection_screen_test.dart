import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/screens/rest_card_selection_screen.dart';
import 'package:roguelike_card_game/ui/widgets/forge/sharpen_rune_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';

import '../unit/shipped_data.dart';

/// Monte la sélection de l'affûtage sur un deck d'une seule [card], avec les
/// runes livrées ; [isFree] : le mode sans or du *Rémouleur*.
Future<ProviderContainer> _pumpSharpenSelection(
  WidgetTester tester,
  CardInstance card, {
  bool isFree = false,
}) async {
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
        home: RestCardSelectionScreen(
          title: 'AFFÛTER UNE RUNE',
          subtitle: 'Choisissez une carte, puis la rune qui gagne un niveau.',
          isSharpen: true,
          isFree: isFree,
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

/// La sélection de l'affûtage (spec P-43 E2, A4, §4.7).
void main() {
  // Transcendance, lue par la sélection dans ses deux modes — le feu et le
  // Rémouleur (spec P-43 E3, §4.8, §8 ; A17 ; constat n° 2 du tour 3).
  for (final isFree in [false, true]) {
    testWidgets('${isFree ? 'sans or' : 'au feu'}, une rune plafonnee se '
        'grise, puis ouvre le dialogue sur Niveau 1 -> 2 sous un plafond '
        'releve', (tester) async {
      final card = CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.rare,
        forgeUpgrades: const ['eco:1'],
      );
      final container =
          await _pumpSharpenSelection(tester, card, isFree: isFree);

      expect(tester.widget<UiCard>(find.byType(UiCard)).isGrayedOut, isTrue);
      await tester.tap(find.byType(UiCard));
      await tester.pumpAndSettle();
      expect(find.byType(SharpenRuneDialog), findsNothing);
      expect(container.read(notificationProvider).last.message,
          'Aucune rune de cette carte ne peut gagner de niveau.');

      container.read(runProvider.notifier).raiseRuneCap('eco');
      await tester.pumpAndSettle();

      expect(tester.widget<UiCard>(find.byType(UiCard)).isGrayedOut, isFalse);
      await tester.tap(find.byType(UiCard));
      await tester.pumpAndSettle();
      expect(find.byType(SharpenRuneDialog), findsOneWidget);
      expect(find.text('Niveau 1 → 2'), findsOneWidget);

      await _settleNotifications(tester);
    });
  }
}
