import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/ui/widgets/forge/forge_slot_row.dart';
import 'package:roguelike_card_game/ui/widgets/forge_upgrade_dialog.dart';

import '../unit/shipped_data.dart';

/// Une Frappe peu commune : la carte qu'une première fusion de Frappes rend.
CardInstance _mergedStrike() => CardInstance(
      data: shippedCard('strike_basic'),
      rarity: CardRarity.uncommon,
    );

/// Ouvre le dialogue de fusion sur [card], posée dans le deck, par
/// `showDialog` au-dessus d'une page — comme l'écran de deck ; [onClosed]
/// reçoit ce sur quoi il se ferme.
Future<ProviderContainer> _openDialog(
  WidgetTester tester,
  CardInstance card,
  List<String> offer, {
  ValueChanged<String?>? onClosed,
}) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  shippedRuneRegistry(const ['burning', 'sharp', 'shocking'],
      cards: [card.data]);
  final container = ProviderContainer();
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
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final chosen = await showDialog<String>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ForgeUpgradeDialog(card: card, offer: offer),
                );
                onClosed?.call(chosen);
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

/// Le dialogue de fusion, réduit au choix (spec P-43 E2, A1, A2, §4.5).
void main() {
  testWidgets('une ligne par rune offerte : trois pour trois, une pour une',
      (tester) async {
    await _openDialog(
        tester, _mergedStrike(), const ['sharp', 'burning', 'shocking']);

    expect(find.text('FUSION — CHOISISSEZ UNE RUNE'), findsOneWidget);
    expect(find.byType(ForgeSlotRow), findsNWidgets(3));
    expect(find.text('Choisir'), findsNWidgets(3));
    // Au niveau 1, sur cette carte : 7 degats en peu commune, +1.
    expect(
      find.text('+1 Dégâts sur la carte (+15% de la base, au moins +1)'),
      findsOneWidget,
    );

    // Le premier dialogue ne se ferme que par un choix : l'arbre est démonté
    // avant d'en ouvrir un second, sans quoi il resterait sur le Navigator.
    await tester.pumpWidget(const SizedBox());
    await _openDialog(tester, _mergedStrike(), const ['burning']);

    expect(find.byType(ForgeSlotRow), findsOneWidget);
    expect(find.text('Brûlant 1'), findsOneWidget);
  });

  testWidgets('ni Annuler, ni retour, ni relance, ni fente achetee',
      (tester) async {
    await _openDialog(tester, _mergedStrike(), const ['sharp', 'burning']);

    expect(find.text('Annuler'), findsNothing);
    expect(find.byIcon(Icons.autorenew), findsNothing);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);

    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();

    expect(find.byType(ForgeUpgradeDialog), findsOneWidget);
  });

  testWidgets('le choix pose la rune au niveau 1 et ferme le dialogue sur elle',
      (tester) async {
    String? chosen;
    final container = await _openDialog(
      tester,
      _mergedStrike(),
      const ['sharp', 'burning'],
      onClosed: (id) => chosen = id,
    );

    await tester.tap(find.descendant(
      of: find.widgetWithText(ForgeSlotRow, 'Brûlant 1'),
      matching: find.text('Choisir'),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ForgeUpgradeDialog), findsNothing);
    expect(chosen, 'burning');
    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['burning:1']);
  });
}
