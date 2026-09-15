import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/reference_panel.dart';

void main() {
  Future<void> pump(WidgetTester tester, ReferencePanel panel) =>
      tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkNeonTheme,
        home: Scaffold(body: SizedBox(width: 300, child: panel)),
      ));

  testWidgets('chaque cle montre ses valeurs en etiquettes, et leur nombre',
      (tester) async {
    await pump(
      tester,
      const ReferencePanel(
        entityCount: 3,
        values: {
          'passiveTrait': ['regen_armor', 'spell_armor'],
        },
      ),
    );

    expect(find.text('VALEURS DÉJÀ UTILISÉES'), findsOneWidget);
    expect(find.text('Relevées dans 3 entités'), findsOneWidget);
    expect(find.text('passiveTrait'), findsOneWidget);
    expect(find.text('regen_armor'), findsOneWidget);
    expect(find.text('spell_armor'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('une couleur porte sa pastille, un chemin le nom de son fichier',
      (tester) async {
    await pump(
      tester,
      const ReferencePanel(
        entityCount: 1,
        values: {
          'themeColor': ['#2196F3'],
          'classCard': ['assets/data/classes/mage/mage.png'],
        },
      ),
    );

    expect(find.text('Relevées dans 1 entité'), findsOneWidget);
    final swatch = tester.widget<Container>(
        find.byKey(const Key('editeur-reference-teinte')));
    expect((swatch.decoration! as BoxDecoration).color,
        const Color(0xFF2196F3));
    expect(find.text('mage.png'), findsOneWidget);
    expect(find.text('assets/data/classes/mage/mage.png'), findsNothing);
  });

  testWidgets('sans valeur, le panneau le dit', (tester) async {
    await pump(tester, const ReferencePanel(entityCount: 0, values: {}));
    expect(find.text('Aucune valeur relevée.'), findsOneWidget);
  });
}
