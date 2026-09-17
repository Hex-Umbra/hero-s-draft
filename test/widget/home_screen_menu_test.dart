import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/screens/class_selection_screen.dart';
import 'package:roguelike_card_game/ui/screens/home_screen.dart';
import 'package:roguelike_card_game/ui/screens/starter_deck_draft_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _registry = GameDataRegistry(
  enemies: const [],
  heroes: const [
    HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Le Paladin',
      descriptionEn: 'Survival Oriented',
      descriptionFr: 'Orienté Survie',
      classCard: 'hero_paladin.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
    ),
  ],
  cards: const [],
  events: const [],
  passives: const [],
  relics: const [],
  forgeUpgrades: const [],
);

Future<void> _pumpHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [gameDataLoaderProvider.overrideWith((ref) => _registry)],
  );
  addTearDown(container.dispose);
  await container.read(gameDataLoaderProvider.future);

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
        home: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Enregistre les appels faits au canal plateforme pendant le test.
List<MethodCall> _recordPlatformCalls(WidgetTester tester) {
  final calls = <MethodCall>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    calls.add(call);
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}

/// Les écrans de sélection font tourner des animations en boucle :
/// `pumpAndSettle` n'y terminerait jamais.
Future<void> _pumpTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('the tutorial button carries no NEW badge', (tester) async {
    await _pumpHome(tester);

    expect(find.text('TUTORIEL'), findsOneWidget);
    expect(find.text('NEW'), findsNothing);
  });

  testWidgets('the main menu sits on the left and the debug menu on the right', (
    tester,
  ) async {
    await _pumpHome(tester);

    final screenWidth = tester.view.physicalSize.width;
    final playLeft = tester.getTopLeft(find.text('JOUER')).dx;
    expect(playLeft, lessThan(screenWidth / 3));

    for (final label in ['RUN DEBUG', 'EDITEUR DE CONTENU']) {
      expect(tester.getTopLeft(find.text(label)).dx, greaterThan(screenWidth / 2));
    }
  });

  testWidgets('QUITTER asks the engine to exit the application on desktop', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await _pumpHome(tester);

      await tester.ensureVisible(find.text('QUITTER'));

      // Le binding de test intercepte `exitApplication` : une sortie
      // `required` y lève cette erreur au lieu de fermer le processus, et une
      // sortie `cancelable` n'y lève rien. L'erreur prouve donc l'appel et
      // son type.
      final errors = <Object>[];
      await runZonedGuarded(() async {
        await tester.tap(find.text('QUITTER'));
        await tester.pump();
      }, (error, _) => errors.add(error));

      expect(errors, [
        isA<FlutterError>().having(
          (e) => e.message,
          'message',
          contains('application exit request'),
        ),
      ]);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('QUITTER pops the activity on Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _pumpHome(tester);
      final calls = _recordPlatformCalls(tester);

      await tester.ensureVisible(find.text('QUITTER'));
      await tester.tap(find.text('QUITTER'));
      await tester.pump();

      expect(calls.map((c) => c.method), contains('SystemNavigator.pop'));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('QUITTER is hidden on iOS, where an app may not close itself', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _pumpHome(tester);

      expect(find.text('QUITTER'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the back buttons walk from the starter draft back to home', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.text('JOUER'));
    await _pumpTransition(tester);
    expect(find.byType(ClassSelectionScreen), findsOneWidget);

    await tester.tap(find.text('Sélectionner'));
    await _pumpTransition(tester);
    expect(find.byType(StarterDeckDraftScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await _pumpTransition(tester);
    expect(find.byType(StarterDeckDraftScreen), findsNothing);
    expect(find.byType(ClassSelectionScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await _pumpTransition(tester);
    expect(find.byType(ClassSelectionScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
