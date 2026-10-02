import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/ui/widgets/forge_upgrade_dialog.dart';

import '../unit/shipped_data.dart';

/// Monte le dialogue de la forge du feu sur [card]. Une [session] — les
/// fentes `id:niveau:relances` qu'une forge en cours a sauvegardées — fixe les
/// fentes ; sans elle, le dialogue les tire.
Future<ProviderContainer> _pumpDialog(
  WidgetTester tester,
  CardInstance card, {
  List<String>? session,
}) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(inventoryProvider.notifier).reset(initialGold: 100000);
  if (session != null) {
    container.read(runProvider.notifier).setForgeSession(card.uniqueId, session);
  }

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
        home: ForgeUpgradeDialog(card: card),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// Les fentes `id:niveau` que la forge propose à [card] : celles de départ,
/// puis celles de [rerolls] relances de la première.
Future<Set<String>> _offeredSlots(
  WidgetTester tester,
  CardInstance card, {
  int rerolls = 20,
}) async {
  final container = await _pumpDialog(tester, card);
  Iterable<String> slots() =>
      (container.read(runProvider).forgeTargetSessions[card.uniqueId] ??
              const <String>[])
          .map((slot) => slot.split(':').take(2).join(':'));

  final offered = {...slots()};
  for (var i = 0; i < rerolls; i++) {
    await tester.tap(find.byIcon(Icons.autorenew).first);
    await tester.pump();
    offered.addAll(slots());
  }
  return offered;
}

Set<String> _ids(Set<String> slots) =>
    {for (final slot in slots) slot.split(':').first};

/// L'offre de la forge du feu (spec P-43 E1, §4.6, §4.7, §5.1).
void main() {
  testWidgets('aucune fente ne propose Endurci sur une Frappe', (tester) async {
    shippedRuneRegistry(const ['sharp', 'hardened']);

    final offered = await _offeredSlots(
        tester, CardInstance(data: shippedCard('strike_basic')));

    expect(_ids(offered), {'sharp'});
  });

  testWidgets('aucune fente ne propose Econome sur une Concentration',
      (tester) async {
    // Une carte gratuite, qui pioche : seule Veloce lui reste (D44).
    shippedRuneRegistry(const ['eco', 'quick']);

    final offered = await _offeredSlots(
        tester, CardInstance(data: shippedCard('concentration')));

    expect(_ids(offered), {'quick'});
  });

  testWidgets('une fente Tranchant 1 dit son gain sur une Frappe epique qui '
      'en porte deja un', (tester) async {
    shippedRuneRegistry(const ['sharp']);
    final card = CardInstance(
      data: shippedCard('strike_basic'),
      rarity: CardRarity.epic,
      forgeUpgrades: const ['sharp:1'],
    );

    await _pumpDialog(tester, card, session: const ['sharp:1:0']);

    // 10 a la rarete : Tranchant 1 donne +2, Tranchant 2 +3 — la fente
    // ajoute +1, ce que le moteur jouera.
    expect(
      find.text('+1 Dégâts sur la carte (+15% de la base, au moins +1)'),
      findsOneWidget,
    );
  });
}
