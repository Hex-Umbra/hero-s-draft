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

  // L'effet de la Maîtrise, dit par l'écart effectif du paramètre (spec P-43
  // E3, §4.11, A23).
  group('PassiveData.describeMastery', () {
    test('{amount} vaut l ecart du parametre entre les deux nombres de points',
        () {
      expect(regen().describeMastery('fr', from: 0, to: 3),
          '+3 Armure en fin de tour');
      expect(regen().describeMastery('en', from: 2, to: 3),
          '+1 Block at end of turn');
    });

    test('le signe est porte par le texte, pas par {amount}', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'mastery': {
          ...masteryJson(),
          'perPoint': -2,
          'description_fr': 'Seuil -{amount}',
        },
      });
      // `value` 2 : deux points la portent à −2, un écart de 4.
      expect(passive.describeMastery('fr', from: 0, to: 2), 'Seuil -4');
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

    // `perPoint` negatif : un seuil baisse quand la Maitrise monte. Un
    // plancher, s'il est declare, vit dans `withMastery` (spec P-43 E3, A23) ;
    // celui-ci n'en a pas.
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
      expect(passive.describeMastery('fr', from: 0, to: 2),
          '-2 Competence a reunir');
    });

    test('les trois parametres que la Maitrise peut viser sont declares', () {
      expect(PassiveMastery.fields, ['value', 'duration', 'threshold']);
    });
  });

  // Le plancher de la Maîtrise (spec P-43 E3, §3.6, §4.11 ; D43, D60, A23).
  group('le plancher', () {
    Map<String, dynamic> fluxJson({int? floor = 2, int perPoint = -1}) => {
          ...passiveJson(),
          'threshold': 3,
          'mastery': {
            'field': 'threshold',
            'perPoint': perPoint,
            'floor': ?floor,
            'description_en': '-{amount} Skill to gather',
            'description_fr': '-{amount} Competence a reunir',
          },
        };

    test('lu dans le bloc mastery ; absent, aucun plancher', () {
      expect(PassiveData.fromJson(fluxJson()).mastery!.floor, 2);
      expect(PassiveData.fromJson(fluxJson(floor: null)).mastery!.floor,
          isNull);
    });

    test('refuse un plancher sur un perPoint qui n est pas negatif', () {
      expect(() => PassiveData.fromJson(fluxJson(perPoint: 1)),
          throwsFormatException);
    });

    test('refuse un plancher au-dessus de la valeur de base du parametre', () {
      expect(() => PassiveData.fromJson(fluxJson(floor: 4)),
          throwsFormatException);
      expect(PassiveData.fromJson(fluxJson(floor: 3)).mastery!.floor, 3);
    });

    test('withMastery ne descend jamais sous le plancher', () {
      final flux = PassiveData.fromJson(fluxJson());
      expect(flux.withMastery(1).threshold, 2);
      expect(flux.withMastery(9).threshold, 2);
    });

    test('describeMastery dit l ecart effectif, plancher compris, et rien '
        'quand rien ne change', () {
      final flux = PassiveData.fromJson(fluxJson());
      expect(flux.describeMastery('fr', from: 0, to: 9),
          '-1 Competence a reunir');
      expect(flux.describeMastery('fr', from: 1, to: 2), isNull);
    });
  });
}
