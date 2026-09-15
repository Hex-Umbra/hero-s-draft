import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/editor_document.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/ui/theme/app_colors.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/document_form.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_style.dart';
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

  testWidgets('une suite de nombres se range en grille', (tester) async {
    await pump(tester, templateOf(hero), hero);

    final maxHp = tester.getTopLeft(find.byKey(const Key('editeur-champ-maxHp')));
    final maxMana =
        tester.getTopLeft(find.byKey(const Key('editeur-champ-maxMana')));
    final luck = tester.getTopLeft(find.byKey(const Key('editeur-champ-luck')));
    expect(maxMana.dy, maxHp.dy, reason: 'deux nombres voisins, une rangee');
    expect(maxMana.dx, greaterThan(maxHp.dx));
    expect(luck.dy, greaterThan(maxHp.dy), reason: 'trois colonnes au plus');
  });

  testWidgets('un nombre isole garde sa rangee de propriete', (tester) async {
    await pump(tester, templateOf(relic), relic);

    expect(
      tester.getTopLeft(find.byKey(const Key('editeur-champ-value'))).dx,
      greaterThanOrEqualTo(tester.getTopLeft(find.text('value')).dx + 170),
    );
  });

  testWidgets('une faute nommant un champ le borde et s affiche sous lui',
      (tester) async {
    await pump(tester, templateOf(relic), relic,
        faults: const {'value': 'champ obligatoire absent'});

    final field = find.byKey(const Key('editeur-champ-value'));
    expect(
      tester.getTopLeft(find.text('champ obligatoire absent')).dy,
      greaterThan(tester.getBottomLeft(field).dy),
    );
    final decoration = tester.widget<TextField>(field).decoration!;
    expect(
      (decoration.enabledBorder! as OutlineInputBorder).borderSide.color,
      AppColors.danger,
    );
  });

  testWidgets('une rarete prend la couleur du jeu', (tester) async {
    await pump(tester, templateOf(relic), relic);

    expect(
      tester.widget<Text>(find.text('legendary')).style!.color,
      Color.lerp(kRarityColors['legendary'], Colors.white, 0.4),
    );
  });

  testWidgets('chaque champ pose son ancre', (tester) async {
    final anchors = FieldAnchors();
    await pump(tester, templateOf(card), card,
        anchors: anchors,
        vocabulary: const {'effects[].type': ['damage']});

    expect(anchors.keyFor('cost').currentContext, isNotNull);
    expect(anchors.keyFor('effects[0].value').currentContext, isNotNull);
  });

  testWidgets('un element de liste se resume et se retire', (tester) async {
    final document = templateOf(card);
    await pump(tester, document, card, vocabulary: const {
      'effects[].type': ['damage'],
    });

    expect(find.text('#1'), findsOneWidget);
    expect(find.text('damage · 6'), findsOneWidget);

    await tester.tap(find.byKey(const Key('editeur-retirer-effects[0]')));
    expect(document.root['effects'], isEmpty);
    expect(structureChanges, 1);
  });
}
