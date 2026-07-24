import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/draft_screen.dart';
import 'package:roguelike_card_game/ui/widgets/relic_carousel/draft_card_reel.dart';
import 'package:roguelike_card_game/ui/widgets/draft/draft_choice_card.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';

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

/// Pins the hero's luck stat very low so the two "level-up" mythic rolls
/// (Trèfle à 4 feuilles / Miroir) can never trigger, keeping tests that
/// don't care about the mythic flow deterministic (mythicChance = 0.5 +
/// luck * 0.15, which is guaranteed negative here).
void _setLuck(ProviderContainer container, int luck) {
  final notifier = container.read(runProvider.notifier);
  final state = container.read(runProvider);
  notifier.updateState(state.copyWith(heroStats: state.heroStats.copyWith(luck: luck)));
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
  testWidgets('DraftScreen renders 3 draft choices without crashing', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    _setLuck(container, -50);

    await tester.pumpWidget(
      _wrap(
        container,
        DraftScreen(onDraftComplete: () {}),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(DraftCardReel), findsNWidgets(3));

    // Unmount so DraftCardReel's infinite glow-pulse ticker gets disposed
    // instead of leaking past the end of this test.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('DraftScreen shows French labels when locale is fr', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    _setLuck(container, -50);

    await tester.pumpWidget(
      _wrap(
        container,
        DraftScreen(onDraftComplete: () {}),
        locale: 'fr',
      ),
    );
    await tester.pump();

    expect(find.text('RÉCOMPENSE DE COMBAT'), findsOneWidget);
    expect(find.text('Choisissez une amélioration pour votre héros'), findsOneWidget);
    expect(find.text('COMBAT REWARD'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'DraftScreen completes the draft and applies a stat modifier when a choice is tapped',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Very negative luck removes any chance of mythic bonus choices, so
      // the base 3 choices land and become tappable deterministically.
      _setLuck(container, -50);

      bool draftCompleted = false;

      await tester.pumpWidget(
        _wrap(
          container,
          DraftScreen(onDraftComplete: () => draftCompleted = true),
        ),
      );
      await tester.pump();

      final statsBefore = container.read(runProvider).heroStats;

      // Let all 3 reels finish their spin/landing animation. Worst case is
      // the 3rd slot landing as legendary: 1200 + 2*600 + 400 (legendary
      // stagger) + ~840 (roll-settle + rarity reveal) ≈ 3.6s.
      await _advance(tester, const Duration(milliseconds: 4500));

      final cardFinder = find.byType(DraftChoiceCard).first;
      expect(cardFinder, findsOneWidget);
      await tester.tap(cardFinder);
      await tester.pump();

      // _onChoiceSelected applies the stat modifier after a 300ms delay.
      await _advance(tester, const Duration(milliseconds: 800));

      expect(draftCompleted, isTrue);

      final statsAfter = container.read(runProvider).heroStats;
      final changed = statsAfter.maxPv != statsBefore.maxPv ||
          statsAfter.attaque != statsBefore.attaque ||
          statsAfter.armorMastery != statsBefore.armorMastery ||
          statsAfter.maxMana != statsBefore.maxMana ||
          statsAfter.luck != statsBefore.luck ||
          statsAfter.critChance != statsBefore.critChance ||
          statsAfter.critMultiplier != statsBefore.critMultiplier;
      expect(changed, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'DraftScreen reveals mythic bonus choices and only allows selection once resolved',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      bool draftCompleted = false;

      // forceLegendary guarantees both extra "level-up" rolls come back
      // mythic (see DraftScreen._rollRarity), so the mythic reveal flow is
      // deterministic regardless of the hero's luck stat.
      await tester.pumpWidget(
        _wrap(
          container,
          DraftScreen(
            onDraftComplete: () => draftCompleted = true,
            forceLegendary: true,
          ),
        ),
      );
      await tester.pump();

      // Only the base 3 choices are visible/tappable before resolution.
      expect(find.byType(DraftCardReel), findsNWidgets(3));

      // Drive the full sequence: base reels land (~3.6s) -> alert animation
      // (1.4s) -> mythic reels spin/land (~3.4s) -> reveal-complete delay
      // (1.5s). Budget generously.
      await _advance(tester, const Duration(milliseconds: 13000));

      // Mythic choices ("Trèfle à 4 feuilles" and "Miroir") are now revealed
      // alongside the base 3 in the main grid.
      expect(find.text('Trèfle à 4 feuilles'), findsOneWidget);
      expect(find.text('Miroir'), findsOneWidget);
      expect(find.byType(DraftCardReel), findsNWidgets(5));

      final statsBefore = container.read(runProvider).heroStats;

      await tester.tap(find.text('Trèfle à 4 feuilles'));
      await tester.pump();
      await _advance(tester, const Duration(milliseconds: 800));

      expect(draftCompleted, isTrue);
      expect(
        container.read(runProvider).heroStats.luck,
        statsBefore.luck + 1,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
