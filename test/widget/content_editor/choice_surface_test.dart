import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/choice_button.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_segmented.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_toolbar.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/entity_explorer.dart';

import 'contrast.dart';

/// Un `InkWell` sans `Material` a lui peint son encre sur celui du
/// `Scaffold`, sous le fond opaque de `editeur-bouton-fond` : le survol et
/// le focus n'y sont alors jamais visibles. Chaque selectionnable du contrat
/// de choix (spec D9) doit donc porter un `Material` transparent entre son
/// fond et son `InkWell`, pour que l'encre se voie.
void main() {
  Future<void> pumpScaffold(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkNeonTheme,
        home: Scaffold(body: child),
      ));

  /// L'`InkWell` peint dans le `Material` le plus proche qui l'englobe :
  /// c'est lui qui doit descendre du fond opaque, pas celui du `Scaffold`.
  void expectMaterialInsideFill(WidgetTester tester, String label) {
    expect(
      find.descendant(of: choiceFill(label), matching: find.byType(Material)),
      findsOneWidget,
      reason: '« $label » peint son encre sous le fond de l ecran',
    );
  }

  testWidgets('une ChoiceButton porte son Material sous son fond',
      (tester) async {
    await pumpScaffold(
      tester,
      ChoiceButton(label: 'attaque', isSelected: false, onTap: () {}),
    );
    expectMaterialInsideFill(tester, 'attaque');
  });

  testWidgets('un segment porte son Material sous son fond', (tester) async {
    await pumpScaffold(
      tester,
      EditorSegmented<String>(
        selected: 'create',
        onSelected: (_) {},
        segments: const [
          EditorSegment(value: 'create', label: 'Créer', icon: Icons.add),
        ],
      ),
    );
    expectMaterialInsideFill(tester, 'Créer');
  });

  testWidgets('un onglet de type porte son Material sous son fond',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpScaffold(
      tester,
      EditorToolbar(selected: EntityCategory.card, onSelected: (_) {}),
    );
    expectMaterialInsideFill(tester, 'Carte');
  });

  testWidgets('une entite de l explorateur porte son Material sous son fond',
      (tester) async {
    await pumpScaffold(
      tester,
      SizedBox(
        width: 240,
        child: EntityExplorer(
          idsByOwner: const {
            null: ['garde'],
          },
          selectedOwner: null,
          selectedId: null,
          onSelected: (_, _) {},
          colorOf: (_) => kNeutralOwnerColor,
        ),
      ),
    );
    expectMaterialInsideFill(tester, 'garde');
  });
}
