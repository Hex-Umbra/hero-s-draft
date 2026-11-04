import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/editor_document.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/document_form.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/field_anchors.dart';

void main() {
  final card = kEntityDescriptors[EntityCategory.card]!;
  final relic = kEntityDescriptors[EntityCategory.relic]!;
  final hero = kEntityDescriptors[EntityCategory.heroClass]!;
  final event = kEntityDescriptors[EntityCategory.event]!;
  final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;

  var structureChanges = 0;

  Future<void> pump(
    WidgetTester tester,
    EditorDocument document,
    EntityDescriptor descriptor, {
    Map<String, List<String>> references = const {},
    Map<String, List<String>> vocabulary = const {},
    Map<String, String> faults = const {},
    FieldAnchors? anchors,
  }) async {
    structureChanges = 0;
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkNeonTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: DocumentForm(
            document: document,
            descriptor: descriptor,
            onChanged: () {},
            onStructureChanged: () => structureChanges++,
            referenceOptions: references,
            vocabulary: vocabulary,
            faults: faults,
            anchors: anchors,
          ),
        ),
      ),
    ));
  }

  EditorDocument templateOf(EntityDescriptor d) => EditorDocument(
        d.decodeTemplate(),
        requiredKeys: d.requiredKeys,
        template: d.decodeTemplate(),
      );

  testWidgets('un entier reste un entier, une saisie illisible est une faute',
      (tester) async {
    final document = templateOf(relic);
    await pump(tester, document, relic);

    await tester.enterText(find.byKey(const Key('editeur-champ-value')), '12');
    expect(document.root['value'], 12);

    await tester.enterText(find.byKey(const Key('editeur-champ-value')), '1a');
    expect(document.root['value'], 12);
    expect(document.conversionFaults.single.field, 'value');
  });

  testWidgets('une liste enumeree qui n est pas une liste se rend et se corrige',
      (tester) async {
    // Atteignable par la vue brute ou un fichier retouche a la main : le
    // formulaire levait en construction.
    final document = EditorDocument({
      'excludesEffects': ['draw'],
      'eligibleCardTypes': 'attack',
    });
    await pump(tester, document, forge);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('skill'));
    expect(document.root['eligibleCardTypes'], ['skill']);
  });

  testWidgets('une cle inconnue du gabarit a son champ', (tester) async {
    final document = EditorDocument({...relic.decodeTemplate(), 'custom_flag': true});
    await pump(tester, document, relic);

    await tester.tap(find.byKey(const Key('editeur-champ-custom_flag')));
    expect(document.root['custom_flag'], isFalse);
  });

  testWidgets('Ajouter clone l element modele d une liste', (tester) async {
    final document = templateOf(card);
    await pump(tester, document, card, vocabulary: const {
      'effects[].type': ['damage'],
    });

    await tester.tap(find.byKey(const Key('editeur-ajouter-effects')));
    expect(document.root['effects'], hasLength(2));
    expect(structureChanges, 1);
  });

  testWidgets('une ressource n est pas un champ de la mecanique',
      (tester) async {
    // Elle a sa propre section, Ressources, que l'ecran compose.
    await pump(
      tester,
      EditorDocument({...relic.decodeTemplate(), 'sfx': 'clang'}),
      relic,
    );
    expect(find.byKey(const Key('editeur-champ-sfx')), findsNothing);
    expect(find.text('sfx'), findsNothing);
  });

  group('une liste de references', () {
    final passive = kEntityDescriptors[EntityCategory.passive]!;
    const catalogue = {
      'classes': ['mage', 'paladin'],
    };

    testWidgets('cocher ajoute dans l ordre du catalogue', (tester) async {
      final document = EditorDocument({
        ...passive.decodeTemplate(),
        'classes': ['paladin'],
      });
      await pump(tester, document, passive, references: catalogue);

      await tester.tap(find.text('mage'));
      expect(document.root['classes'], ['mage', 'paladin']);
    });

    testWidgets('decocher la derniere retire la cle', (tester) async {
      // `[]` et l'absence font echouer le chargement (A5).
      final document = EditorDocument({
        ...passive.decodeTemplate(),
        'classes': ['paladin'],
      });
      await pump(tester, document, passive, references: catalogue);

      await tester.tap(find.text('paladin'));
      expect(document.root.containsKey('classes'), isFalse);
    });
  });

  testWidgets('une paire bilingue qui n est pas faite de chaines garde ses deux '
      'champs', (tester) async {
    // Hors rangee — l'anglais n'est pas une chaine — l'anglais etait saute
    // quand meme, et invisible.
    await pump(
      tester,
      EditorDocument({
        'choices': [
          {
            'text_fr': 'Oui',
            'text_en': null,
            'actions': [
              {'type': 'gold', 'value': 20},
            ],
          },
        ],
      }),
      event,
    );
    expect(find.byKey(const Key('editeur-champ-choices[0].text_fr')),
        findsOneWidget);
    expect(find.byKey(const Key('editeur-champ-choices[0].text_en')),
        findsOneWidget);
  });

  testWidgets('ni id, ni prose, ni skills ne deviennent des champs',
      (tester) async {
    await pump(
      tester,
      EditorDocument({'id': 'x', 'name_fr': 'X', 'skills': ['a'], 'maxHp': 1}),
      hero,
    );
    expect(find.byKey(const Key('editeur-champ-id')), findsNothing);
    expect(find.byKey(const Key('editeur-champ-name_fr')), findsNothing);
    expect(find.byKey(const Key('editeur-champ-skills')), findsNothing);
    expect(find.byKey(const Key('editeur-champ-maxHp')), findsOneWidget);
  });

}
