import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/widgets/hud/player_health_bar.dart';

void main() {
  testWidgets(
    'PlayerHealthBar renders health, armor, and attack values correctly',
    (WidgetTester tester) async {
      // Build the widget with static values
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerHealthBar(
              currentPv: 50,
              maxPv: 100,
              armure: 20,
              effectiveAttaque: 5,
            ),
          ),
        ),
      );

      // Verify health text "50 / 100 PV"
      expect(find.text('50 / 100 PV'), findsOneWidget);

      // Verify attack value "5"
      expect(find.text('5'), findsOneWidget);

      // Verify armor value "20"
      expect(find.text('20'), findsOneWidget);
    },
  );
}
