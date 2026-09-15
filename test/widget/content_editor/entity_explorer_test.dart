import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/choice_button.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/entity_explorer.dart';

import 'contrast.dart';

void main() {
  const mage = Color(0xFF9C27B0);
  const ids = <String?, List<String>>{
    null: ['frappe', 'garde'],
    'paladin': ['bouclier'],
    'mage': ['eclair'],
  };

  late List<(String?, String)> picked;

  Future<void> pump(
    WidgetTester tester, {
    String? selectedOwner,
    String? selectedId,
  }) {
    picked = [];
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkNeonTheme,
      home: Scaffold(
        body: SizedBox(
          width: 240,
          child: EntityExplorer(
            idsByOwner: ids,
            selectedOwner: selectedOwner,
            selectedId: selectedId,
            onSelected: (owner, id) => picked.add((owner, id)),
            colorOf: (owner) => switch (owner) {
              null => kNeutralOwnerColor,
              'mage' => mage,
              _ => const Color(0xFF2196F3),
            },
          ),
        ),
      ),
    ));
  }

  Finder group(String owner) => find.byKey(Key('editeur-groupe-$owner'));

  testWidgets('les neutres d abord, puis chaque classe par ordre alphabetique',
      (tester) async {
    await pump(tester);

    final neutral = tester.getTopLeft(group('neutre')).dy;
    final mageTop = tester.getTopLeft(group('mage')).dy;
    final paladin = tester.getTopLeft(group('paladin')).dy;
    expect(neutral, lessThan(mageTop));
    expect(mageTop, lessThan(paladin));
    expect(find.text('ENTITÉS'), findsOneWidget);
    expect(find.text('4'), findsOneWidget, reason: 'le total des entites');
  });

  testWidgets('chaque groupe porte la couleur de son proprietaire',
      (tester) async {
    await pump(tester);

    Color dot(String owner) => (tester
            .widget<Container>(find.descendant(
              of: group(owner),
              matching: find.byKey(const Key('editeur-groupe-pastille')),
            ))
            .decoration! as BoxDecoration)
        .color!;
    expect(dot('mage'), mage);
    expect(dot('neutre'), kNeutralOwnerColor);
    expect(find.descendant(of: group('mage'), matching: find.text('eclair')),
        findsOneWidget);
    expect(find.descendant(of: group('neutre'), matching: find.text('Neutres')),
        findsOneWidget);
  });

  testWidgets('choisir une entite rappelle son proprietaire', (tester) async {
    await pump(tester);

    await tester.tap(find.text('eclair'));
    await tester.tap(find.text('garde'));
    expect(picked, [('mage', 'eclair'), (null, 'garde')]);
  });

  testWidgets('l entite choisie porte la coche, se dit choisie, et tout se lit',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, selectedOwner: 'mage', selectedId: 'eclair');

    expect(
      find.descendant(
          of: choiceFill('eclair'), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: choiceFill('frappe'), matching: find.byIcon(Icons.check)),
      findsNothing,
    );
    expect(tester.getSemantics(choiceFill('eclair')),
        isSemantics(isSelected: true));
    for (final label in const ['eclair', 'frappe', 'bouclier']) {
      expectReadableChoice(tester, label);
    }
    semantics.dispose();
  });

  testWidgets('le filtre ne garde que les entites qui le contiennent',
      (tester) async {
    await pump(tester);

    await tester.enterText(find.byKey(const Key('editeur-filtre')), 'ECL');
    await tester.pump();
    expect(find.text('eclair'), findsOneWidget);
    expect(find.text('frappe'), findsNothing);
    expect(group('neutre'), findsNothing, reason: 'un groupe vide disparait');

    await tester.enterText(find.byKey(const Key('editeur-filtre')), 'zzz');
    await tester.pump();
    expect(find.text('Aucune entité ne correspond.'), findsOneWidget);
  });
}
