import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/ui/widgets/forge/sharpen_rune_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';

import '../unit/shipped_data.dart';

/// Une Frappe rare — 8 dégâts — portant [runes].
CardInstance _rareStrike(List<String> runes) => CardInstance(
      data: shippedCard('strike_basic'),
      rarity: CardRarity.rare,
      forgeUpgrades: runes,
    );

/// Ouvre le dialogue d'affûtage sur [card], posée dans le deck, avec [gold]
/// or, par `showDialog` au-dessus d'une page — comme la sélection du feu ;
/// [isFree] : le mode sans or du *Rémouleur* ; [onClosed] reçoit ce sur quoi
/// il se ferme.
Future<ProviderContainer> _openDialog(
  WidgetTester tester,
  CardInstance card, {
  required int gold,
  bool isFree = false,
  ValueChanged<String?>? onClosed,
}) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  shippedRuneRegistry(const ['eco', 'sharp'], cards: [card.data]);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(inventoryProvider.notifier).reset(initialGold: gold);
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
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final sharpened = await showDialog<String>(
                  context: context,
                  builder: (_) => SharpenRuneDialog(card: card, isFree: isFree),
                );
                onClosed?.call(sharpened);
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return container;
}

/// Le bouton de la ligne dont le libellé est [label].
GameButton _button(WidgetTester tester, String label) =>
    tester.widget<GameButton>(find.widgetWithText(GameButton, label));

/// Le dialogue d'affûtage (spec P-43 E2, A4, §4.7).
void main() {
  // Transcendance, lue par le dialogue (spec P-43 E3, §4.8, §8 ; A17).
  testWidgets('une rune plafonnee dit Niveau maximal, puis Niveau 1 -> 2 '
      'sous un plafond releve', (tester) async {
    final container =
        await _openDialog(tester, _rareStrike(const ['eco:1']), gold: 1000);
    expect(_button(tester, 'Niveau maximal').onPressed, isNull);

    container.read(runProvider.notifier).raiseRuneCap('eco');
    await tester.pump();

    expect(find.text('Niveau 1 → 2'), findsOneWidget);
    expect(_button(tester, 'Affûter — 50 or').onPressed, isNotNull);
  });
}
