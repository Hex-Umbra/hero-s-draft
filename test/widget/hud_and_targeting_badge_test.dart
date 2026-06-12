import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

void main() {
  group('UiCard Targeting Badges & Localizations', () {
    Widget buildTestCard({
      required String title,
      required CardTarget targetType,
      Locale locale = const Locale('en', ''),
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', ''), Locale('fr', '')],
        locale: locale,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 140,
              height: 196,
              child: UiCard(
                title: title,
                description: 'Test description',
                targetType: targetType,
              ),
            ),
          ),
        ),
      );
    }

    Widget buildTestCardWithEffects({
      required String title,
      required CardTarget targetType,
      required List<CardEffect> effects,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', ''), Locale('fr', '')],
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 140,
              height: 196,
              child: UiCard(
                title: title,
                description: 'Test description',
                targetType: targetType,
                effects: effects,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('does not render targeting badges for single target in English', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCard(title: 'Strike', targetType: CardTarget.singleEnemy));
      await tester.pumpAndSettle();

      expect(find.text('🎯'), findsNothing);
      expect(find.text('Single Target'), findsNothing);
    });

    testWidgets('does not render targeting badges for single target in French', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCard(
        title: 'Frappe',
        targetType: CardTarget.singleEnemy,
        locale: const Locale('fr', ''),
      ));
      await tester.pumpAndSettle();

      expect(find.text('🎯'), findsNothing);
      expect(find.text('Cible unique'), findsNothing);
    });

    testWidgets('does not render targeting badges for all enemies in English', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCard(title: 'Swipe', targetType: CardTarget.allEnemies));
      await tester.pumpAndSettle();

      expect(find.text('💥'), findsNothing);
      expect(find.text('All Enemies'), findsNothing);
    });

    testWidgets('does not render targeting badges for all enemies in French', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCard(
        title: 'Balayage',
        targetType: CardTarget.allEnemies,
        locale: const Locale('fr', ''),
      ));
      await tester.pumpAndSettle();

      expect(find.text('💥'), findsNothing);
      expect(find.text('Tous les ennemis'), findsNothing);
    });

    testWidgets('does not render targeting badges for self', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCard(title: 'Defend', targetType: CardTarget.self));
      await tester.pumpAndSettle();

      expect(find.text('🛡️'), findsNothing);
      expect(find.text('Self'), findsNothing);
    });

    testWidgets('renders single effect icon for single target card', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCardWithEffects(
        title: 'Strike',
        targetType: CardTarget.singleEnemy,
        effects: const [CardEffect(type: 'damage', value: 6)],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.hardware_rounded), findsOneWidget);
    });

    testWidgets('renders doubled effect icons for all enemies card', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCardWithEffects(
        title: 'Swipe',
        targetType: CardTarget.allEnemies,
        effects: const [CardEffect(type: 'damage', value: 6)],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.hardware_rounded), findsNWidgets(2));
    });

    testWidgets('renders doubled damage icon and single armor icon for all enemies card with both effects (e.g. Warcry)', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCardWithEffects(
        title: 'Warcry',
        targetType: CardTarget.allEnemies,
        effects: const [
          CardEffect(type: 'damage', value: 6),
          CardEffect(type: 'armor', value: 4),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.hardware_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);
    });
  });

  group('HUD Responsive Calculations', () {
    double calculateHudHeight({required double screenWidth, required double textScaleFactor}) {
      final bool isMobile = screenWidth < 600;
      final double baseHudHeight = isMobile ? 100.0 : 88.0;
      return (baseHudHeight * textScaleFactor).clamp(88.0, 140.0);
    }

    double calculateHudWidth({required double screenWidth}) {
      final bool isMobile = screenWidth < 600;
      return isMobile ? screenWidth * 0.90 : screenWidth * 0.52;
    }

    test('mobile layout sizing calculation', () {
      const double mobileWidth = 400.0;
      expect(calculateHudHeight(screenWidth: mobileWidth, textScaleFactor: 1.0), 100.0);
      expect(calculateHudWidth(screenWidth: mobileWidth), 360.0); // 400 * 0.90
    });

    test('desktop layout sizing calculation', () {
      const double desktopWidth = 1200.0;
      expect(calculateHudHeight(screenWidth: desktopWidth, textScaleFactor: 1.0), 88.0);
      expect(calculateHudWidth(screenWidth: desktopWidth), 624.0); // 1200 * 0.52
    });

    test('HUD height scales with text scale factor and clamps correctly', () {
      // Large text scaling
      expect(calculateHudHeight(screenWidth: 400.0, textScaleFactor: 1.5), 140.0); // Clamped to 140.0
      // Small text scaling
      expect(calculateHudHeight(screenWidth: 1200.0, textScaleFactor: 0.8), 88.0); // Clamped to 88.0
    });
  });
}
