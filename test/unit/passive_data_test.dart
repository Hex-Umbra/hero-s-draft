import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

/// Le modèle d'un passif partagé (spec P-49, §3).
void main() {
  Map<String, dynamic> passiveJson() => {
        'id': 'regen_armor',
        'name_en': 'Armor Regeneration',
        'name_fr': "Régénération d'Armure",
        'description_en': 'x',
        'description_fr': 'x',
        'trigger': 'endOfTurn',
        'effectType': 'gain_armor',
        'value': 2,
      };

  Map<String, dynamic> masteryJson() => {
        'field': 'value',
        'perPoint': 1,
        'description_en': '+{amount} Block at end of turn',
        'description_fr': '+{amount} Armure en fin de tour',
      };

  PassiveData regen() =>
      PassiveData.fromJson({...passiveJson(), 'mastery': masteryJson()});

  group('classes', () {
    test('absente : le passif est ouvert a toutes les classes', () {
      expect(PassiveData.fromJson(passiveJson()).classes, isNull);
    });

    test('une liste : les classes declarees', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'classes': ['paladin', 'mage'],
      });
      expect(passive.classes, ['paladin', 'mage']);
    });

    test('une liste vide est refusee', () {
      expect(
        () => PassiveData.fromJson({...passiveJson(), 'classes': <String>[]}),
        throwsFormatException,
      );
    });
  });

  group('mastery', () {
    test('absent : null', () {
      expect(PassiveData.fromJson(passiveJson()).mastery, isNull);
    });

    test('lu', () {
      final mastery = regen().mastery!;
      expect(mastery.field, 'value');
      expect(mastery.perPoint, 1);
      expect(mastery.descriptionEn, '+{amount} Block at end of turn');
      expect(mastery.descriptionFr, '+{amount} Armure en fin de tour');
    });

    // `draw` est un parametre de `PassiveData` que la Maitrise ne vise pas :
    // l'exemple reste donc hors de `PassiveMastery.fields` (spec P-49, §6.2).
    test('un field inconnu est refuse', () {
      expect(
        () => PassiveData.fromJson({
          ...passiveJson(),
          'mastery': {...masteryJson(), 'field': 'draw'},
        }),
        throwsFormatException,
      );
    });

    test('un perPoint nul est refuse', () {
      expect(
        () => PassiveData.fromJson({
          ...passiveJson(),
          'mastery': {...masteryJson(), 'perPoint': 0},
        }),
        throwsFormatException,
      );
    });

    test('une description sans {amount} est refusee', () {
      for (final key in ['description_en', 'description_fr']) {
        expect(
          () => PassiveData.fromJson({
            ...passiveJson(),
            'mastery': {...masteryJson(), key: '+1 Armure'},
          }),
          throwsFormatException,
          reason: key,
        );
      }
    });

    test('une description absente est refusee', () {
      final mastery = masteryJson()..remove('description_en');
      expect(
        () => PassiveData.fromJson({...passiveJson(), 'mastery': mastery}),
        throwsFormatException,
      );
    });
  });

  group('withMastery', () {
    test('augmente le parametre designe', () {
      expect(regen().withMastery(3).value, 2 + 3);
    });

    test('un perPoint negatif fait baisser le parametre', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'mastery': {...masteryJson(), 'perPoint': -1},
      });
      expect(passive.withMastery(1).value, 2 - 1);
    });

    test('a 0 point : le passif tel quel', () {
      final passive = regen();
      expect(identical(passive.withMastery(0), passive), isTrue);
    });

    test('sans mastery : le passif tel quel', () {
      final passive = PassiveData.fromJson(passiveJson());
      expect(identical(passive.withMastery(5), passive), isTrue);
    });

    test('le reste du passif est conserve', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'classes': ['paladin'],
        'mastery': masteryJson(),
      }).withMastery(2);
      expect(passive.id, 'regen_armor');
      expect(passive.nameFr, "Régénération d'Armure");
      expect(passive.trigger, RelicTrigger.endOfTurn);
      expect(passive.effectType, 'gain_armor');
      expect(passive.classes, ['paladin']);
      expect(passive.mastery!.perPoint, 1);
    });
  });

  group('PassiveMastery.describe', () {
    test('{amount} vaut perPoint fois les points', () {
      expect(regen().mastery!.describe('fr', 3), '+3 Armure en fin de tour');
      expect(regen().mastery!.describe('en', 1), '+1 Block at end of turn');
    });

    test('le signe est porte par le texte, pas par {amount}', () {
      final mastery = PassiveMastery.fromJson({
        ...masteryJson(),
        'perPoint': -2,
        'description_fr': 'Seuil -{amount}',
      });
      expect(mastery.describe('fr', 2), 'Seuil -4');
    });
  });

  // Les quatre parametres du lot B de P-41 : ce dont les neuf passifs ont
  // besoin, et rien de plus.
  group('les parametres du lot B', () {
    test('absents : une duree de 1, aucun seuil, aucune pioche, rang 0', () {
      final passive = PassiveData.fromJson(passiveJson());
      expect(passive.duration, 1);
      expect(passive.threshold, 0);
      expect(passive.draw, 0);
      expect(passive.displayOrder, 0);
    });

    test('lus quand ils sont declares', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'duration': 2,
        'threshold': 3,
        'draw': 1,
        'displayOrder': 2,
      });
      expect(passive.duration, 2);
      expect(passive.threshold, 3);
      expect(passive.draw, 1);
      expect(passive.displayOrder, 2);
    });

    test('la Maitrise sait allonger une duree', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'duration': 2,
        'mastery': {
          'field': 'duration',
          'perPoint': 1,
          'description_en': '+{amount} turn',
          'description_fr': '+{amount} tour',
        },
      });
      expect(passive.withMastery(2).duration, 4);
      expect(passive.withMastery(2).value, passive.value);
    });

    // `perPoint` negatif : un seuil baisse quand la Maitrise monte. Borner le
    // resultat est l'affaire de la strategie qui le lit (spec P-49, §6.2).
    test('la Maitrise sait faire baisser un seuil', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'threshold': 3,
        'mastery': {
          'field': 'threshold',
          'perPoint': -1,
          'description_en': '-{amount} Skill to gather',
          'description_fr': '-{amount} Competence a reunir',
        },
      });
      expect(passive.withMastery(2).threshold, 1);
      expect(passive.mastery!.describe('fr', 2), '-2 Competence a reunir');
    });

    test('les trois parametres que la Maitrise peut viser sont declares', () {
      expect(PassiveMastery.fields, ['value', 'duration', 'threshold']);
    });
  });
}
