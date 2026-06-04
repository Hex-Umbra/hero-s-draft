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

    testWidgets('renders Single Target badge in English', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCard(title: 'Strike', targetType: CardTarget.singleEnemy));
      await tester.pumpAndSettle();

      expect(find.text('🎯'), findsOneWidget);
      expect(find.text('Single Target'), findsOneWidget);
    });

    testWidgets('renders Cible unique badge in French', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCard(
        title: 'Frappe',
        targetType: CardTarget.singleEnemy,
        locale: const Locale('fr', ''),
      ));
      await tester.pumpAndSettle();

      expect(find.text('🎯'), findsOneWidget);
      expect(find.text('Cible unique'), findsOneWidget);
    });

    testWidgets('renders All Enemies badge in English', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCard(title: 'Swipe', targetType: CardTarget.allEnemies));
      await tester.pumpAndSettle();

      expect(find.text('💥'), findsOneWidget);
      expect(find.text('All Enemies'), findsOneWidget);
    });

    testWidgets('renders Tous les ennemis badge in French', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCard(
        title: 'Balayage',
        targetType: CardTarget.allEnemies,
        locale: const Locale('fr', ''),
      ));
      await tester.pumpAndSettle();

      expect(find.text('💥'), findsOneWidget);
      expect(find.text('Tous les ennemis'), findsOneWidget);
    });

    testWidgets('renders Self badge in English', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCard(title: 'Defend', targetType: CardTarget.self));
      await tester.pumpAndSettle();

      expect(find.text('🛡️'), findsOneWidget);
      expect(find.text('Self'), findsOneWidget);
    });

    testWidgets('renders Soi-même badge in French', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCard(
        title: 'Défense',
        targetType: CardTarget.self,
        locale: const Locale('fr', ''),
      ));
      await tester.pumpAndSettle();

      expect(find.text('🛡️'), findsOneWidget);
      expect(find.text('Soi-même'), findsOneWidget);
    });

    testWidgets('does not render targeting badge for none target', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestCard(title: 'Meditate', targetType: CardTarget.none));
      await tester.pumpAndSettle();

      expect(find.text('🎯'), findsNothing);
      expect(find.text('💥'), findsNothing);
      expect(find.text('🛡️'), findsNothing);
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
