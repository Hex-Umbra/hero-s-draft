import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/might_target.dart';

/// L'orientation de la Puissance, déclarée par la classe (spec P-41, §7.1).
void main() {
  group('MightTarget.parseAll', () {
    test('lit chaque cible nommee', () {
      expect(
        MightTarget.parseAll(['skill', 'alteration']),
        {MightTarget.skill, MightTarget.alteration},
      );
    });

    test('les trois cibles ensemble', () {
      expect(
        MightTarget.parseAll(['attack', 'skill', 'alteration']),
        MightTarget.values.toSet(),
      );
    });

    test('une liste vide est refusee', () {
      expect(() => MightTarget.parseAll(<String>[]), throwsFormatException);
    });

    test('une valeur qui n est pas une liste est refusee', () {
      expect(() => MightTarget.parseAll('attack'), throwsFormatException);
      expect(() => MightTarget.parseAll(null), throwsFormatException);
    });

    test('une cible inconnue est refusee', () {
      expect(
        () => MightTarget.parseAll(['attack', 'defense']),
        throwsFormatException,
      );
    });
  });

  group('HeroData.mightTargets', () {
    Map<String, dynamic> classJson() => {
          'id': 'mage',
          'classCard': 'assets/data/classes/mage/mage.png',
          'maxHp': 60,
          'maxMana': 3,
          'mightTargets': ['skill', 'alteration'],
        };

    test('lue dans class.json', () {
      expect(
        HeroData.fromJson(classJson()).mightTargets,
        {MightTarget.skill, MightTarget.alteration},
      );
    });

    test('une classe sans mightTargets ne se charge pas', () {
      expect(
        () => HeroData.fromJson(classJson()..remove('mightTargets')),
        throwsFormatException,
      );
    });

    test('construite en code, une classe oriente sa Puissance vers attack', () {
      const hero = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
      );
      expect(hero.mightTargets, {MightTarget.attack});
    });
  });
}
