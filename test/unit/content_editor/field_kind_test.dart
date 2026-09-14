import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/field_kind.dart';
import 'package:roguelike_card_game/services/content_editor/field_path.dart';

void main() {
  final card = kEntityDescriptors[EntityCategory.card]!;
  final relic = kEntityDescriptors[EntityCategory.relic]!;
  final hero = kEntityDescriptors[EntityCategory.heroClass]!;
  final enemy = kEntityDescriptors[EntityCategory.enemy]!;
  final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;

  FieldKind kindOf(
    EntityDescriptor descriptor,
    FieldPath path,
    Object? value, {
    bool model = false,
  }) =>
      inferFieldKind(
        path: path,
        value: value,
        descriptor: descriptor,
        hasModelElement: model,
      );

  test('les metadonnees du descripteur passent avant le type JSON', () {
    expect(kindOf(relic, const ['sfx'], 'clang'), FieldKind.asset);
    expect(kindOf(hero, const ['passiveTrait'], null), FieldKind.reference);
    expect(kindOf(hero, const ['themeColor'], '#FF00FF'), FieldKind.color);
    // `rarity` est une chaine, mais une enumeration d'abord.
    expect(kindOf(card, const ['rarity'], 'common'), FieldKind.enumChoice);
    expect(kindOf(enemy, const ['intents', 0, 'type'], 'attack'),
        FieldKind.enumChoice);
    expect(kindOf(forge, const ['eligibleCardTypes'], ['attack']),
        FieldKind.enumMulti);
    expect(kindOf(card, const ['effects', 0, 'type'], 'damage'),
        FieldKind.vocabulary);
  });

  test('le type JSON decide ensuite', () {
    expect(kindOf(card, const ['isExhaust'], false), FieldKind.boolean);
    expect(kindOf(card, const ['cost'], 1), FieldKind.integer);
    expect(kindOf(forge, const ['valueMultiplier'], 1.5), FieldKind.decimal);
    expect(kindOf(relic, const ['emoji'], '🪙'), FieldKind.text);
    expect(kindOf(card, const ['effects'], [
      {'type': 'damage'},
    ]), FieldKind.objectList);
    expect(kindOf(forge, const ['pools'], ['common']), FieldKind.stringList);
    expect(kindOf(card, const ['meta'], {'a': 1}), FieldKind.object);
  });

  test('une liste vide depend de son element modele', () {
    expect(kindOf(card, const ['effects'], <dynamic>[], model: true),
        FieldKind.objectList);
    expect(kindOf(card, const ['effects'], <dynamic>[]), FieldKind.rawJson);
  });

  test('ce qui ne se classe pas devient un petit champ JSON', () {
    expect(kindOf(card, const ['inconnu'], null), FieldKind.rawJson);
    expect(kindOf(card, const ['melange'], [1, 'a']), FieldKind.rawJson);
  });
}
