import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/choice_button.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_style.dart';

import 'contrast.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<Widget> buttons) =>
      tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkNeonTheme,
        home: Scaffold(body: Wrap(children: buttons)),
      ));

  testWidgets('une puce de rarete se lit, choisie ou non, pour chaque rarete',
      (tester) async {
    for (final entry in kRarityColors.entries) {
      await pump(tester, [
        ChoiceButton(
          label: '${entry.key}-repos',
          isSelected: false,
          tint: entry.value,
          onTap: () {},
        ),
        ChoiceButton(
          label: '${entry.key}-choisie',
          isSelected: true,
          tint: entry.value,
          onTap: () {},
        ),
      ]);
      expectReadableChoice(tester, '${entry.key}-repos');
      expectReadableChoice(tester, '${entry.key}-choisie');
    }
  });

  testWidgets('une puce de rarete au repos ecrit dans la teinte de sa rarete',
      (tester) async {
    await pump(tester, [
      ChoiceButton(
        label: 'epic',
        isSelected: false,
        tint: kRarityColors['epic'],
        onTap: () {},
      ),
    ]);
    expect(
      tester.widget<Text>(find.text('epic')).style!.color,
      Color.lerp(kRarityColors['epic'], Colors.white, 0.4),
    );
  });

  testWidgets('une puce ordinaire et « aucun » se lisent, choisis ou non',
      (tester) async {
    await pump(tester, [
      ChoiceButton(label: 'attack', isSelected: false, onTap: () {}),
      ChoiceButton(label: 'skill', isSelected: true, onTap: () {}),
      ChoiceButton(
        label: 'aucun',
        isSelected: false,
        isPlaceholder: true,
        onTap: () {},
      ),
      ChoiceButton(
        label: 'mage',
        isSelected: true,
        identityColor: const Color(0xFF9C27B0),
        onTap: () {},
      ),
    ]);
    for (final label in const ['attack', 'skill', 'aucun', 'mage']) {
      expectReadableChoice(tester, label);
    }
  });

  testWidgets('seule la puce choisie porte la coche et se dit choisie',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, [
      ChoiceButton(label: 'attack', isSelected: true, onTap: () {}),
      ChoiceButton(label: 'skill', isSelected: false, onTap: () {}),
    ]);

    expect(
      find.descendant(
          of: choiceFill('attack'), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: choiceFill('skill'), matching: find.byIcon(Icons.check)),
      findsNothing,
    );
    expect(tester.getSemantics(choiceFill('attack')),
        isSemantics(isSelected: true));
    expect(tester.getSemantics(choiceFill('skill')),
        isSemantics(isSelected: false));
    semantics.dispose();
  });
}
