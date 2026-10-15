import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';
import 'package:roguelike_card_game/services/audio/audio_source.dart';

Map<String, dynamic> valid() => {
      'id': 'smite',
      'heroClass': 'paladin',
      'name_en': 'Smite',
      'name_fr': 'Châtiment',
      'description_en': 'Deal 6 damage and gain 4 armor.',
      'description_fr': 'Inflige 6 degats et gagne 4 armure.',
      'cost': 1,
      'cooldown': 2,
      'type': 'attack',
      'target': 'singleEnemy',
      'animation': 'melee',
      'sfx': 'hit',
      'effects': [
        {'type': 'damage', 'value': 6},
        {'type': 'armor', 'value': 4},
      ],
    };

Matcher refusing(String key) => throwsA(
      isA<FormatException>().having((e) => e.message, 'message', contains(key)),
    );

void main() {
  test('une signature valide se lit entiere', () {
    final s = SignatureData.fromJson(valid());
    expect(s, isA<AudioSource>());
    expect(s.id, 'smite');
    expect(s.heroClass, 'paladin');
    expect(s.nameEn, 'Smite');
    expect(s.nameFr, 'Châtiment');
    expect(s.descriptionEn, 'Deal 6 damage and gain 4 armor.');
    expect(s.descriptionFr, 'Inflige 6 degats et gagne 4 armure.');
    expect(s.cost, 1);
    expect(s.cooldown, 2);
    expect(s.type, CardType.attack);
    expect(s.target, CardTarget.singleEnemy);
    expect(s.animation, 'melee');
    expect(s.sfx, 'hit');
    expect(s.effects, hasLength(2));
    expect(s.effects.first.value, 6);
  });

  test('cooldown absent est refuse', () {
    expect(() => SignatureData.fromJson(valid()..remove('cooldown')),
        refusing('cooldown'));
  });

  test('cooldown 0 est refuse', () {
    expect(() => SignatureData.fromJson(valid()..['cooldown'] = 0),
        refusing('cooldown'));
  });

  test('cooldown negatif est refuse', () {
    expect(() => SignatureData.fromJson(valid()..['cooldown'] = -1),
        refusing('cooldown'));
  });

  test('cost absent ou negatif est refuse', () {
    expect(() => SignatureData.fromJson(valid()..remove('cost')),
        refusing('cost'));
    expect(() => SignatureData.fromJson(valid()..['cost'] = -1),
        refusing('cost'));
  });

  test('type status ou inconnu est refuse', () {
    expect(() => SignatureData.fromJson(valid()..['type'] = 'status'),
        refusing('type'));
    expect(() => SignatureData.fromJson(valid()..['type'] = 'inconnu'),
        refusing('type'));
  });

  test('rarity est refusee, nommee', () {
    expect(() => SignatureData.fromJson(valid()..['rarity'] = 'rare'),
        refusing('rarity'));
  });

  test('isExhaust est refuse, nomme', () {
    expect(() => SignatureData.fromJson(valid()..['isExhaust'] = false),
        refusing('isExhaust'));
  });

  test('category est refusee, nommee', () {
    expect(() => SignatureData.fromJson(valid()..['category'] = 'global'),
        refusing('category'));
  });

  test('effects vide ou absent est refuse', () {
    expect(() => SignatureData.fromJson(valid()..['effects'] = []),
        refusing('effects'));
    expect(() => SignatureData.fromJson(valid()..remove('effects')),
        refusing('effects'));
  });

  test('heroClass absent est refuse', () {
    expect(() => SignatureData.fromJson(valid()..remove('heroClass')),
        refusing('heroClass'));
  });

  test('une prose absente ou vide est refusee, nommee', () {
    expect(() => SignatureData.fromJson(valid()..remove('name_en')),
        refusing('name_en'));
    expect(() => SignatureData.fromJson(valid()..['description_fr'] = ''),
        refusing('description_fr'));
  });

  test('target absente vaut singleEnemy', () {
    final s = SignatureData.fromJson(valid()..remove('target'));
    expect(s.target, CardTarget.singleEnemy);
  });
}
