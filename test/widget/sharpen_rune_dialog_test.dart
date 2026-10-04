import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/ui/widgets/forge/forge_slot_row.dart';
import 'package:roguelike_card_game/ui/widgets/forge/sharpen_rune_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import 'package:roguelike_card_game/ui/widgets/gold_indicator.dart';

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
  testWidgets('une ligne par rune portee ; Niveau 2 -> 3 et 100 or pour '
      'Tranchant 2', (tester) async {
    await _openDialog(tester, _rareStrike(const ['sharp:2', 'eco:1']),
        gold: 1000);

    expect(find.byType(ForgeSlotRow), findsNWidgets(2));
    expect(find.text('Niveau 2 → 3'), findsOneWidget);
    expect(_button(tester, 'Affûter — 100 or').onPressed, isNotNull);
  });

  testWidgets('une rune a son plafond : Niveau maximal, inactif, sans ligne '
      'de niveau', (tester) async {
    await _openDialog(tester, _rareStrike(const ['eco:1']), gold: 1000);

    expect(_button(tester, 'Niveau maximal').onPressed, isNull);
    expect(find.textContaining('Niveau 1 →'), findsNothing);
  });

  testWidgets('faute d or, Affuter est inactif', (tester) async {
    await _openDialog(tester, _rareStrike(const ['sharp:2']), gold: 99);

    expect(_button(tester, 'Affûter — 100 or').onPressed, isNull);
    // Le bouton grise s'explique : le solde est sous les yeux du joueur.
    expect(
      find.descendant(
          of: find.byType(GoldIndicator), matching: find.text('99')),
      findsOneWidget,
    );
  });

  testWidgets('la description dit ce que le niveau de plus ajoute a cette '
      'carte', (tester) async {
    // 8 degats en rare : Tranchant 2 ajoute +2, Tranchant 3 +4 — le niveau
    // de plus ajoute +2 (spec P-43 E1, §5.1).
    await _openDialog(tester, _rareStrike(const ['sharp:2']), gold: 1000);

    expect(
      find.text('+2 Dégâts sur la carte (+15% de la base, au moins +1)'),
      findsOneWidget,
    );
  });

  testWidgets('affuter monte la rune d un niveau et ferme le dialogue : '
      'aucun second affutage (D14)', (tester) async {
    String? closedOn;
    final container = await _openDialog(
      tester,
      _rareStrike(const ['sharp:2', 'eco:1']),
      gold: 1000,
      onClosed: (id) => closedOn = id,
    );

    await tester.tap(find.text('Affûter — 100 or'));
    await tester.pumpAndSettle();

    expect(find.byType(SharpenRuneDialog), findsNothing);
    expect(closedOn, 'sharp');
    expect(container.read(inventoryProvider).gold, 900);
    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['sharp:3', 'eco:1']);
  });

  // Le Rémouleur (spec P-43 E3, §4.9, A21) : choisir, sans payer ni écrire.
  testWidgets('sans or, Choisir rend la rune sans rien ecrire ni payer',
      (tester) async {
    String? closedOn;
    final container = await _openDialog(
      tester,
      _rareStrike(const ['sharp:2', 'eco:1']),
      gold: 0,
      isFree: true,
      onClosed: (id) => closedOn = id,
    );

    expect(find.text('Niveau 2 → 3'), findsOneWidget);
    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();

    expect(find.byType(SharpenRuneDialog), findsNothing);
    expect(closedOn, 'sharp');
    expect(container.read(inventoryProvider).gold, 0);
    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['sharp:2', 'eco:1']);
  });

  testWidgets('sans or, une rune a son plafond dit Niveau maximal, inactive',
      (tester) async {
    await _openDialog(tester, _rareStrike(const ['eco:1']),
        gold: 0, isFree: true);

    expect(_button(tester, 'Niveau maximal').onPressed, isNull);
    expect(find.text('Choisir'), findsNothing);
  });
}
