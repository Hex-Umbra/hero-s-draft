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
  testWidgets('une carte sans rune est grisee et refusee, avec son motif',
      (tester) async {
    final card = CardInstance(
        data: shippedCard('strike_basic'), rarity: CardRarity.uncommon);
    final container = await _pumpSharpenSelection(tester, card);

    expect(tester.widget<UiCard>(find.byType(UiCard)).isGrayedOut, isTrue);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(SharpenRuneDialog), findsNothing);
    expect(container.read(notificationProvider).last.message,
        'Aucune rune de cette carte ne peut gagner de niveau.');

    await _settleNotifications(tester);
  });

  testWidgets('une carte dont les runes sont a leur plafond est refusee de '
      'meme', (tester) async {
    // Une Concentration rare portant Veloce, plafonnee a 1.
    final card = CardInstance(
      data: shippedCard('concentration'),
      rarity: CardRarity.rare,
      forgeUpgrades: const ['quick:1'],
    );
    final container = await _pumpSharpenSelection(tester, card);

    expect(tester.widget<UiCard>(find.byType(UiCard)).isGrayedOut, isTrue);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(SharpenRuneDialog), findsNothing);
    expect(container.read(notificationProvider).last.message,
        'Aucune rune de cette carte ne peut gagner de niveau.');

    await _settleNotifications(tester);
  });

  testWidgets('une carte portant une rune affutable ouvre le dialogue',
      (tester) async {
    final card = CardInstance(
      data: shippedCard('strike_basic'),
      rarity: CardRarity.uncommon,
      forgeUpgrades: const ['sharp:1'],
    );
    final container = await _pumpSharpenSelection(tester, card);

    expect(tester.widget<UiCard>(find.byType(UiCard)).isGrayedOut, isFalse);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(SharpenRuneDialog), findsOneWidget);
    expect(container.read(notificationProvider), isEmpty);

    await _settleNotifications(tester);
  });

  // Le Rémouleur (spec P-43 E3, §4.9, A21) : la sélection du feu, sans or.
  testWidgets('sans or, la carte ouvre le dialogue qui dit Choisir',
      (tester) async {
    final card = CardInstance(
      data: shippedCard('strike_basic'),
      rarity: CardRarity.uncommon,
      forgeUpgrades: const ['sharp:1'],
    );
    await _pumpSharpenSelection(tester, card, isFree: true);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(SharpenRuneDialog), findsOneWidget);
    expect(find.text('Choisir'), findsOneWidget);
    expect(find.textContaining('Affûter —'), findsNothing);
  });
}
