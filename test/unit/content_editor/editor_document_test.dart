import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/editor_document.dart';

void main() {
  Map<String, dynamic> card() => {
        'cost': 1,
        'animation': 'melee',
        'effects': [
          {'type': 'damage', 'value': 6},
        ],
      };

  test('le document copie sa graine', () {
    final seed = card();
    final document = EditorDocument(seed);
    document.setAt(const ['cost'], 3);
    expect(seed['cost'], 1);
  });

  test('lecture et ecriture par chemin imbrique', () {
    final document = EditorDocument(card());
    document.setAt(const ['effects', 0, 'value'], 9);
    expect(document.valueAt(const ['effects', 0, 'value']), 9);
    expect(document.valueAt(const ['effects', 5, 'value']), isNull);
  });

  test('ecrire une cle absente l ajoute, removeAt la retire', () {
    final document = EditorDocument(card());
    document.setAt(const ['sfx'], 'clang');
    expect(document.root['sfx'], 'clang');
    document.removeAt(const ['sfx']);
    expect(document.root.containsKey('sfx'), isFalse);
  });

  test('ajouter un element clone celui du gabarit, en profondeur', () {
    final template = card();
    final document = EditorDocument({'effects': <dynamic>[]}, template: template);

    expect(document.addElement(const ['effects']), isTrue);
    expect(document.root['effects'], [
      {'type': 'damage', 'value': 6},
    ]);

    document.setAt(const ['effects', 0, 'value'], 99);
    expect((template['effects'] as List).first['value'], 6);
  });

  test('sans gabarit, l element modele est le premier du document', () {
    final document = EditorDocument(card());
    expect(document.addElement(const ['effects']), isTrue);
    expect(document.root['effects'], hasLength(2));
  });

  test('sans modele, rien n est ajoute', () {
    final document = EditorDocument({'effects': <dynamic>[]});
    expect(document.addElement(const ['effects']), isFalse);
  });

  test('retirer un element', () {
    final document = EditorDocument(card());
    document.removeElement(const ['effects'], 0);
    expect(document.root['effects'], isEmpty);
  });

  test('une saisie non convertible devient une faute, effacee par setAt', () {
    final document = EditorDocument(card());
    document.reportConversion(const ['effects', 0, 'value'], 'pas un entier');
    expect(document.conversionFaults.single.field, 'effects[0].value');

    document.setAt(const ['effects', 0, 'value'], 7);
    expect(document.conversionFaults, isEmpty);
  });

  test('toMechanics omet une chaine optionnelle vide, a tout niveau', () {
    final document = EditorDocument(
      {
        'cost': 1,
        'type': '',
        'sfx': '',
        'effects': [
          {'type': 'apply_status', 'statusId': '', 'value': 2},
        ],
      },
      requiredKeys: const {'cost', 'type'},
    );

    final mechanics = jsonDecode(document.toMechanics()) as Map<String, dynamic>;
    expect(mechanics.containsKey('sfx'), isFalse);
    expect(mechanics['type'], '', reason: 'une cle requise n est jamais omise');
    expect((mechanics['effects'] as List).first.containsKey('statusId'), isFalse);
    expect(document.root['sfx'], '', reason: 'le document lui-meme est intact');
  });
}
