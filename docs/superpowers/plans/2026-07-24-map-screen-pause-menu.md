# Menu de pause sur l'écran de la carte — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a pause menu to `MapScreen`, reusing the existing `PauseDialog` widget, accessible via an AppBar icon and via interception of the system back button/gesture.

**Architecture:** `MapScreen` (a pure Flutter screen with no Flame `Game` instance) gains one new icon in its existing `AppBar.actions`, one new private method `_showPauseMenu()`, and two new constructor arguments passed to its existing `ScreenScaffold` (`canPop: false`, `onPopInvokedWithResult`) to intercept back-navigation and route it through the same dialog. No other file changes.

**Tech Stack:** Flutter, Riverpod (`flutter_riverpod`), existing `PauseDialog`/`ScreenScaffold` widgets, `flutter_test` for widget tests.

## Global Constraints

- Reuse `lib/ui/widgets/hud/dialogs/pause_dialog.dart` (`PauseDialog`) exactly as-is — **do not modify this file**.
- Reuse `ScreenScaffold`'s existing `canPop` / `onPopInvokedWithResult` constructor parameters exactly as-is — **do not modify `lib/ui/widgets/screen_scaffold.dart`**.
- Do not add, remove, or change any localization key. Use the existing keys verbatim: `l10n.pauseTitle` ("PAUSE" in both locales), `l10n.resumeCombat` ("Reprendre le Combat" / "Resume Combat"), `l10n.backToMainMenu` ("Retour au Menu Principal" / "Back to Main Menu").
- No interaction with the save system (`SaveService`, `CheckpointController`) — the existing autosave checkpoint remains valid when leaving via this menu.
- `dart analyze` must report zero issues after the change (project-wide requirement, see `CLAUDE.md`).
- Test locale convention for widget tests in this repo: set `locale: const Locale('fr', '')` explicitly on the `MaterialApp` and assert on the French display strings (matches `test/widget/shop_screen_test.dart`).

---

### Task 1: Pause menu on MapScreen (icon + back interception)

**Files:**
- Modify: `lib/ui/screens/map_screen.dart`
- Test: `test/widget/map_screen_test.dart`

**Interfaces:**
- Consumes: `PauseDialog.show(BuildContext, {required VoidCallback onResume, required VoidCallback onExit})` from `lib/ui/widgets/hud/dialogs/pause_dialog.dart` (existing, unchanged).
- Consumes: `ScreenScaffold({..., bool? canPop, void Function(bool, dynamic)? onPopInvokedWithResult})` from `lib/ui/widgets/screen_scaffold.dart` (existing, unchanged).
- Produces: nothing consumed by later tasks — this is the only task in the plan.

- [ ] **Step 1: Write the failing widget tests**

Open `test/widget/map_screen_test.dart`. No new imports are needed — the file already imports `package:flutter_localizations/flutter_localizations.dart` and `package:roguelike_card_game/models/data/hero_data.dart` (used by the existing test).

Append these four new `testWidgets` blocks inside `void main() { ... }`, after the existing `testWidgets('MapScreen displays nodes and restricts unavailable nodes', ...)` block (before the closing `}` of `main`):

```dart
  testWidgets('MapScreen shows a pause icon that opens the pause dialog', (
    WidgetTester tester,
  ) async {
    final hero = const HeroData(
      id: 'test_hero',
      nameEn: 'Test',
      nameFr: 'Test',
      descriptionEn: 'Test',
      descriptionFr: 'Test',
      iconPath: 'test',
      maxHp: 10,
      maxMana: 3,
      passiveTrait: 'regenArmor',
      baseDamage: 0,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(runProvider.notifier).startNewRun(hero);

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
          home: const MapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
    expect(find.text('PAUSE'), findsNothing);

    await tester.tap(find.byIcon(Icons.pause_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('PAUSE'), findsOneWidget);
    expect(find.text('Reprendre le Combat'), findsOneWidget);
    expect(find.text('Retour au Menu Principal'), findsOneWidget);
  });

  testWidgets('MapScreen pause dialog Resume button closes the dialog', (
    WidgetTester tester,
  ) async {
    final hero = const HeroData(
      id: 'test_hero',
      nameEn: 'Test',
      nameFr: 'Test',
      descriptionEn: 'Test',
      descriptionFr: 'Test',
      iconPath: 'test',
      maxHp: 10,
      maxMana: 3,
      passiveTrait: 'regenArmor',
      baseDamage: 0,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(runProvider.notifier).startNewRun(hero);

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
          home: const MapScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.pause_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('PAUSE'), findsOneWidget);

    await tester.tap(find.text('Reprendre le Combat'));
    await tester.pumpAndSettle();

    expect(find.text('PAUSE'), findsNothing);
    expect(find.byType(MapScreen), findsOneWidget);
  });

  testWidgets(
    'MapScreen intercepts the system back gesture and opens the pause dialog instead of closing',
    (WidgetTester tester) async {
      final hero = const HeroData(
        id: 'test_hero',
        nameEn: 'Test',
        nameFr: 'Test',
        descriptionEn: 'Test',
        descriptionFr: 'Test',
        iconPath: 'test',
        maxHp: 10,
        maxMana: 3,
        passiveTrait: 'regenArmor',
        baseDamage: 0,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(hero);

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
            home: const MapScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      final bool popped = await navigator.maybePop();
      await tester.pumpAndSettle();

      expect(popped, isFalse);
      expect(find.byType(MapScreen), findsOneWidget);
      expect(find.text('PAUSE'), findsOneWidget);
    },
  );

  testWidgets(
    'MapScreen pause dialog "Back to Main Menu" pops back to the previous screen',
    (WidgetTester tester) async {
      final hero = const HeroData(
        id: 'test_hero',
        nameEn: 'Test',
        nameFr: 'Test',
        descriptionEn: 'Test',
        descriptionFr: 'Test',
        iconPath: 'test',
        maxHp: 10,
        maxMana: 3,
        passiveTrait: 'regenArmor',
        baseDamage: 0,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(hero);

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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MapScreen()),
                  ),
                  child: const Text('Open Map'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Map'));
      await tester.pumpAndSettle();
      expect(find.byType(MapScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_circle_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retour au Menu Principal'));
      await tester.pumpAndSettle();

      expect(find.byType(MapScreen), findsNothing);
      expect(find.text('Open Map'), findsOneWidget);
    },
  );
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/widget/map_screen_test.dart`

Expected: the pre-existing test still passes, but all four new tests FAIL — the first assertion `expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget)` fails with "Expected: exactly one matching candidate / Actual: 0" because the icon doesn't exist yet, and the back-interception test fails because `popped` is `true` (nothing currently blocks the pop).

- [ ] **Step 3: Add the pause dialog import and `_showPauseMenu` method**

In `lib/ui/screens/map_screen.dart`, add this import after the existing `import '../widgets/gold_indicator.dart';` line (line 27):

```dart
import '../widgets/hud/dialogs/pause_dialog.dart';
```

Add the following method to `_MapScreenState`, directly after the `_checkCanMerge` method (after line 179, before the `@override Widget build` method on line 181):

```dart
  void _showPauseMenu() {
    PauseDialog.show(
      context,
      onResume: () => Navigator.of(context).pop(),
      onExit: () => Navigator.of(context).popUntil((route) => route.isFirst),
    );
  }
```

- [ ] **Step 4: Add the pause icon to the AppBar and wire back interception**

In `lib/ui/screens/map_screen.dart`, replace the `actions` line of the `AppBar` (line 435-437):

```dart
        actions: const [
          GoldIndicator(isParchment: true),
        ],
```

with:

```dart
        actions: [
          const GoldIndicator(isParchment: true),
          IconButton(
            icon: const Icon(
              Icons.pause_circle_outline,
              color: Color(0xFF4A3728),
            ),
            onPressed: _showPauseMenu,
          ),
        ],
```

Then replace the `ScreenScaffold` opening (lines 235-236):

```dart
    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.parchment,
```

with:

```dart
    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.parchment,
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showPauseMenu();
        }
      },
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/widget/map_screen_test.dart`

Expected: all 5 tests (the pre-existing one plus the 4 new ones) PASS.

- [ ] **Step 6: Run static analysis**

Run: `dart analyze`

Expected: `No issues found!` (project requirement per `CLAUDE.md` — must be clean after every code change).

- [ ] **Step 7: Commit**

```bash
git add lib/ui/screens/map_screen.dart test/widget/map_screen_test.dart
git commit -m "feat: add pause menu to the map screen"
```
