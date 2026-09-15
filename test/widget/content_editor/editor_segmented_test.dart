import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_segmented.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_style.dart';

import 'contrast.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required String? selected,
    required ValueChanged<String> onSelected,
  }) =>
      tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkNeonTheme,
        home: Scaffold(
          body: Center(
            child: EditorSegmented<String>(
              selected: selected,
              onSelected: onSelected,
              segments: const [
                EditorSegment(value: 'create', label: 'Créer', icon: Icons.add),
                EditorSegment(
                  value: 'modify',
                  label: 'Modifier',
                  icon: Icons.edit,
                  key: Key('segment-modifier'),
                ),
              ],
            ),
          ),
        ),
      ));

  testWidgets('toucher un segment rappelle sa valeur', (tester) async {
    String? picked;
    await pump(tester, selected: null, onSelected: (v) => picked = v);

    await tester.tap(find.byKey(const Key('segment-modifier')));
    expect(picked, 'modify');
    await tester.tap(find.text('Créer'));
    expect(picked, 'create');
  });

  testWidgets('le segment choisi se dit choisi et porte son anneau',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, selected: 'create', onSelected: (_) {});

    expect(tester.getSemantics(choiceFill('Créer')),
        isSemantics(isSelected: true));
    expect(tester.getSemantics(choiceFill('Modifier')),
        isSemantics(isSelected: false));

    BoxBorder? ringOf(String label) =>
        (tester.widget<Container>(choiceFill(label)).decoration! as BoxDecoration)
            .border;
    expect((ringOf('Créer')! as Border).top.color,
        EditorColors.accent.withValues(alpha: 0.5));
    expect((ringOf('Modifier')! as Border).top.color, Colors.transparent);
    semantics.dispose();
  });

  testWidgets('chaque segment se lit sur son fond, choisi ou non',
      (tester) async {
    await pump(tester, selected: 'modify', onSelected: (_) {});
    expectReadableChoice(tester, 'Créer');
    expectReadableChoice(tester, 'Modifier');
  });
}
