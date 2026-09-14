import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/editor_document.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/document_form.dart';

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
            assetField: (key, slot) => Text('ressource $key'),
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

  testWidgets('une enumeration se choisit par bouton', (tester) async {
    final document = templateOf(relic);
    await pump(tester, document, relic);

    await tester.tap(find.text('legendary'));
    expect(document.root['rarity'], 'legendary');
  });

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
      'pools': ['common'],
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

  testWidgets('une ressource absente du document a quand meme son champ',
      (tester) async {
    await pump(tester, templateOf(relic), relic);
    expect(find.text('ressource sfx'), findsOneWidget);
  });

  testWidgets('une reference absente se choisit dans son catalogue',
      (tester) async {
    final document = templateOf(hero);
    await pump(tester, document, hero, references: const {
      'passiveTrait': ['regen_armor'],
    });

    await tester.tap(find.text('regen_armor'));
    expect(document.root['passiveTrait'], 'regen_armor');
  });

  testWidgets('un vocabulaire montre aussi la valeur fautive', (tester) async {
    final document = EditorDocument({
      'effects': [
        {'type': 'skill', 'value': 3},
      ],
    });
    await pump(tester, document, card, vocabulary: const {
      'effects[].type': ['damage'],
    });

    expect(find.text('damage'), findsOneWidget);
    expect(find.text('skill'), findsOneWidget);
  });

  testWidgets('une paire bilingue imbriquee tient sur une rangee',
      (tester) async {
    await pump(tester, templateOf(event), event);
    final fr = tester.getTopLeft(
        find.byKey(const Key('editeur-champ-choices[0].text_fr')));
    final en = tester.getTopLeft(
        find.byKey(const Key('editeur-champ-choices[0].text_en')));
    expect(en.dy, fr.dy);
    expect(en.dx, greaterThan(fr.dx));
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
