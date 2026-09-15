import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_app_bar.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_style.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_toolbar.dart';

import 'contrast.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkNeonTheme,
      home: Scaffold(body: child),
    ));
  }

  const labels = [
    'Carte', 'Relique', 'Événement', 'Passif',
    'Amélioration de forge', 'Classe', 'Ennemi',
  ];

  testWidgets('les sept types sont des onglets qui rappellent leur type',
      (tester) async {
    final picked = <EntityCategory>[];
    await pump(tester, EditorToolbar(selected: null, onSelected: picked.add));

    for (final label in labels) {
      expect(find.text(label), findsOneWidget, reason: 'type manquant : $label');
    }
    await tester.tap(find.text('Classe'));
    await tester.tap(find.text('Ennemi'));
    expect(picked, [EntityCategory.heroClass, EntityCategory.enemy]);
  });

  testWidgets('l onglet choisi se souligne, se dit choisi, et tout se lit',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      EditorToolbar(selected: EntityCategory.relic, onSelected: (_) {}),
    );

    BorderSide underline(String label) =>
        ((tester.widget<Container>(choiceFill(label)).decoration!
                    as BoxDecoration)
                .border! as Border)
            .bottom;
    expect(underline('Relique').color, EditorColors.accent);
    expect(underline('Carte').color, Colors.transparent);
    expect(tester.getSemantics(choiceFill('Relique')),
        isSemantics(isSelected: true));
    expect(tester.getSemantics(choiceFill('Carte')),
        isSemantics(isSelected: false));
    for (final label in labels) {
      expectReadableChoice(tester, label);
    }
    semantics.dispose();
  });

  testWidgets('le controle d action se tient au bout de la barre',
      (tester) async {
    await pump(
      tester,
      EditorToolbar(
        selected: EntityCategory.card,
        onSelected: (_) {},
        trailing: const Text('action'),
      ),
    );
    expect(
      tester.getTopLeft(find.text('action')).dx,
      greaterThan(tester.getTopRight(find.text('Ennemi')).dx),
    );
  });

  group('EditorAppBar', () {
    test('le depot se reduit a ses deux derniers dossiers', () {
      expect(shortRoot('C:/Users/moi/Jeux/roguelike_card_game'),
          '…/Jeux/roguelike_card_game');
      expect(shortRoot('/depot'), '/depot');
    });

    testWidgets('titre, badge DEBUG, et le depot quand il y en a un',
        (tester) async {
      await pump(
        tester,
        const EditorAppBar(rootPath: 'C:/Users/moi/Jeux/roguelike_card_game'),
      );
      expect(find.text('ÉDITEUR DE CONTENU'), findsOneWidget);
      expect(find.text('DEBUG'), findsOneWidget);
      expect(find.text('…/Jeux/roguelike_card_game'), findsOneWidget);

      await pump(tester, const EditorAppBar(rootPath: null));
      expect(find.byIcon(Icons.folder_open), findsNothing);
    });
  });
}
