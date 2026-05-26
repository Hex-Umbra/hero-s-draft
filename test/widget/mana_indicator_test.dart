import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/widgets/hud/mana_indicator.dart';

void main() {
  testWidgets(
      'ManaIndicator renders correct number of crystals and active ones', (
    WidgetTester tester,
  ) async {
    // Build the widget with 3 max crystals and 2 current crystals
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ManaIndicator(
            currentMana: 2,
            maxMana: 3,
          ),
        ),
      ),
    );

    // Verify presence of 3 diamond icons (since maxMana is 3)
    final diamondFinder = find.byIcon(Icons.diamond);
    expect(diamondFinder, findsNWidgets(3));

    // Verify active mana vs inactive mana using icon colors
    // Active crystal color is cyanAccent, inactive is white24.
    final list = tester.widgetList<Icon>(diamondFinder).toList();
    expect(list[0].color, Colors.cyanAccent);
    expect(list[1].color, Colors.cyanAccent);
    expect(list[2].color, Colors.white24);
  });
}
