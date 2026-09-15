import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/theme/app_colors.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_button.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_panel.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_style.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/field_anchors.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/property_row.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(1000, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkNeonTheme,
      home: Scaffold(body: child),
    ));
  }

  const control = SizedBox(key: Key('controle'), width: 120, height: 30);

  group('PropertyRow', () {
    testWidgets('la cle se tient a gauche du controle quand la place le permet',
        (tester) async {
      await pump(tester, const PropertyRow(label: 'maxHp', child: control));

      final label = tester.getTopLeft(find.text('maxHp'));
      final field = tester.getTopLeft(find.byKey(const Key('controle')));
      expect(field.dx, greaterThanOrEqualTo(label.dx + 170));
    });

    testWidgets('la cle passe au-dessus quand le controle manque de place',
        (tester) async {
      await pump(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: PropertyRow(label: 'maxHp', child: control),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byKey(const Key('controle'))).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.text('maxHp')).dy),
      );
    });

    testWidgets('un champ obligatoire porte son point, un autre non',
        (tester) async {
      await pump(
        tester,
        const PropertyRow(label: 'cost', isRequired: true, child: control),
      );
      expect(find.byKey(const Key('editeur-obligatoire')), findsOneWidget);

      await pump(tester, const PropertyRow(label: 'luck', child: control));
      expect(find.byKey(const Key('editeur-obligatoire')), findsNothing);
    });

    testWidgets('une faute rougit la cle et s affiche sous le controle',
        (tester) async {
      await pump(
        tester,
        const PropertyRow(
          label: 'cost',
          errorText: 'champ obligatoire absent',
          child: control,
        ),
      );

      expect(tester.widget<Text>(find.text('cost')).style!.color,
          AppColors.danger);
      expect(
        tester.getTopLeft(find.text('champ obligatoire absent')).dy,
        greaterThan(tester.getBottomLeft(find.byKey(const Key('controle'))).dy),
      );
    });

    testWidgets('une mention accompagne la cle', (tester) async {
      await pump(
        tester,
        const PropertyRow(label: 'iconPath', note: 'optionnel', child: control),
      );
      expect(find.text('optionnel'), findsOneWidget);
    });
  });

  testWidgets('un panneau se titre en capitales, avec precision et controle',
      (tester) async {
    await pump(
      tester,
      const EditorPanel(
        icon: Icons.tune,
        title: 'Mécanique',
        caption: 'précision',
        trailing: Text('bascule'),
        children: [Text('rangée 1'), Text('rangée 2')],
      ),
    );

    expect(find.text('MÉCANIQUE'), findsOneWidget);
    expect(find.text('précision'), findsOneWidget);
    expect(find.text('bascule'), findsOneWidget);
    // Un filet sous l'en-tete, un entre les deux rangees.
    expect(find.byType(Divider), findsNWidgets(2));
  });

  group('EditorButton', () {
    testWidgets('un bouton actif appelle son geste', (tester) async {
      var taps = 0;
      await pump(
        tester,
        Center(
          child: EditorButton(
            label: 'Valider',
            icon: Icons.fact_check,
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('Valider'));
      expect(taps, 1);
    });

    testWidgets('le geste principal est le seul bouton plein', (tester) async {
      await pump(
        tester,
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              EditorButton(
                label: 'Valider',
                icon: Icons.fact_check,
                onPressed: () {},
              ),
              EditorButton(
                label: 'Écrire',
                icon: Icons.save,
                tone: EditorButtonTone.primary,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      Color fillOf(String label) => (tester
              .widget<Container>(find
                  .ancestor(of: find.text(label), matching: find.byType(Container))
                  .first)
              .decoration! as BoxDecoration)
          .color!;
      expect(fillOf('Écrire'), EditorColors.accent);
      expect(fillOf('Valider').a, lessThan(1));
    });
  });

  group('FieldAnchors', () {
    testWidgets('une ancre ramene son champ dans la vue', (tester) async {
      final anchors = FieldAnchors();
      await pump(
        tester,
        SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 3000),
              KeyedSubtree(
                key: anchors.keyFor('value'),
                child: const SizedBox(key: Key('champ'), height: 40, width: 100),
              ),
            ],
          ),
        ),
        size: const Size(800, 600),
      );
      expect(tester.getTopLeft(find.byKey(const Key('champ'))).dy,
          greaterThan(600));

      final revealed = anchors.reveal('value');
      await tester.pumpAndSettle();
      await revealed;

      expect(tester.getTopLeft(find.byKey(const Key('champ'))).dy,
          inInclusiveRange(0, 560));
    });

    testWidgets('une ancre sans champ ne leve rien', (tester) async {
      await pump(tester, const SizedBox());
      await expectLater(FieldAnchors().reveal('absent'), completes);
    });
  });
}
