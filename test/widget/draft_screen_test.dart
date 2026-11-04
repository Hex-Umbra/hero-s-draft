import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/screens/draft_screen.dart';
import 'package:roguelike_card_game/ui/widgets/relic_carousel/draft_card_reel.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

/// DraftScreen's reel-landing animation is driven by chained `Timer`s and
/// `AnimationController.forward(from: 0.0)` calls made from inside status
/// listeners, and the high-rarity glow controller repeats forever
/// (`..repeat(reverse: true)`), so `pumpAndSettle()` never terminates here.
/// Advance the fake clock in small bounded steps instead, mirroring the
/// `_settle` helper used in map_screen_test.dart.
Future<void> _advance(
  WidgetTester tester,
  Duration total, {
  Duration step = const Duration(milliseconds: 100),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// Une vue large (spec P-43 E3, §4.10) : les mythiques se révèlent dans la
/// même rangée que les trois emplacements — six rouleaux depuis que *Sagesse*
/// est mythique, sept avec *Transcendance* —, que la surface de test par
/// défaut (800 × 600) ne tient pas.
void _largeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap(ProviderContainer container, Widget child, {String locale = 'fr'}) {
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
      locale: Locale(locale, ''),
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  // Transcendance (spec P-43 E3, §4.8, §8 ; A15) : l'écran lit le deck et le
  // bonus de plafond de la run.
  // Sept rouleaux, dont quatre dans la révélation : la vue large du fichier
  // (`_largeView`, défini plus haut dans ce fichier).
  group('Transcendance', () {
    /// Un conteneur sur le registre réel, résolu, dont le deck porte une
    /// Frappe rare à Économe 1 — à son plafond.
    Future<ProviderContainer> ecoDeck() async {
      final container = ProviderContainer(
        overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
      );
      addTearDown(container.dispose);
      await container.read(gameDataLoaderProvider.future);
      container.read(deckProvider.notifier).addCardToMasterDeck(CardInstance(
            data: registry.cards.singleWhere((c) => c.id == 'strike_basic'),
            rarity: CardRarity.rare,
            forgeUpgrades: const ['eco:1'],
          ));
      return container;
    }

    testWidgets('une rune a son plafond fait sortir Transcendance, dont la '
        'modale releve le plafond, le notifie et termine le draft',
        (WidgetTester tester) async {
      _largeView(tester);
      final container = await ecoDeck();
      bool draftCompleted = false;

      await tester.pumpWidget(_wrap(
        container,
        DraftScreen(
          onDraftComplete: () => draftCompleted = true,
          forceLegendary: true,
        ),
      ));
      await tester.pump();
      await _advance(tester, const Duration(milliseconds: 15000));

      expect(find.byType(DraftCardReel), findsNWidgets(7));
      await tester.tap(find.text('Transcendance'));
      await tester.pump();
      await _advance(tester, const Duration(milliseconds: 800));

      expect(find.text('Choisissez la rune dont le plafond monte'),
          findsOneWidget);
      expect(find.text('Niveau maximal 1 → 2'), findsOneWidget);

      await tester.tap(find.text('Économe'));
      await tester.pump();

      expect(container.read(runProvider).runeCapBonus, {'eco': 1});
      expect(draftCompleted, isTrue);
      expect(container.read(notificationProvider).last.message,
          'Économe peut désormais monter jusqu\'au niveau 2.');

      // Le minuteur de la notification expire avant le démontage.
      await _advance(tester, const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('le plafond releve, la rune n y est plus : Transcendance ne '
        'sort pas', (WidgetTester tester) async {
      _largeView(tester);
      final container = await ecoDeck();
      container.read(runProvider.notifier).raiseRuneCap('eco');

      await tester.pumpWidget(_wrap(
        container,
        DraftScreen(onDraftComplete: () {}, forceLegendary: true),
      ));
      await tester.pump();
      await _advance(tester, const Duration(milliseconds: 15000));

      expect(find.byType(DraftCardReel), findsNWidgets(6));
      expect(find.text('Transcendance'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

}
