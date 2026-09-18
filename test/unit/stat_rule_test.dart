import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';

/// Ce qui reste à `statRules` : convertir une ressource (spec P-41, §7.1).
void main() {
  Map<String, dynamic> ruleJson() => {
        'stat': 'armor',
        'mode': 'convert',
        'to': 'status:might',
        'duration': 1,
      };

  group('StatRule.fromJson', () {
    test('lit la conversion de l armure en Puissance temporaire', () {
      final rule = StatRule.fromJson(ruleJson());
      expect(rule.stat, RuleStat.armor);
      expect(rule.mode, RuleMode.convert);
      expect(rule.to, RuleTarget.statusMight);
      expect(rule.duration, 1);
    });

    test('la duree vaut 1 par defaut', () {
      final rule = StatRule.fromJson(ruleJson()..remove('duration'));
      expect(rule.duration, 1);
    });

    // La Puissance n'est jamais une `stat` de `statRules` : la convertir au
    // gain rouvrirait les deux problemes que l'orientation regle (spec §7.1).
    test('la Puissance en stat est refusee', () {
      expect(
        () => StatRule.fromJson(ruleJson()..['stat'] = 'might'),
        throwsFormatException,
      );
    });

    test('une valeur inconnue est refusee', () {
      for (final bad in const [
        {'stat': 'pv'},
        {'mode': 'convrt'},
        {'to': 'might'},
      ]) {
        expect(
          () => StatRule.fromJson({...ruleJson(), ...bad}),
          throwsFormatException,
          reason: 'valeur refusee : $bad',
        );
      }
    });

    test('une cle de mecanique absente est refusee', () {
      for (final key in const ['stat', 'mode', 'to']) {
        expect(
          () => StatRule.fromJson(ruleJson()..remove(key)),
          throwsFormatException,
          reason: 'cle absente : $key',
        );
      }
    });
  });

  group('StatRule.parseAll', () {
    test('une cle absente : aucune regle', () {
      expect(StatRule.parseAll(null), isEmpty);
    });

    test('une liste : les regles declarees', () {
      expect(StatRule.parseAll([ruleJson()]), hasLength(1));
    });

    test('autre chose qu une liste est refuse', () {
      expect(() => StatRule.parseAll(ruleJson()), throwsFormatException);
    });
  });

  group('HeroData', () {
    Map<String, dynamic> heroJson() => {
          'id': 'berserker',
          'classCard': 'assets/data/classes/berserker/berserker.png',
          'maxHp': 80,
          'maxMana': 3,
          'mightTargets': ['attack'],
        };

    test('sans statRules ni critChance : aucune regle, aucun critique', () {
      final hero = HeroData.fromJson(heroJson());
      expect(hero.statRules, isEmpty);
      expect(hero.critChance, 0);
    });

    test('les deux sont lus quand ils sont declares', () {
      final hero = HeroData.fromJson({
        ...heroJson(),
        'critChance': 10,
        'statRules': [ruleJson()],
      });
      expect(hero.critChance, 10);
      expect(hero.statRules.single.stat, RuleStat.armor);
    });

    // Sans champ ni lecture, une cle serait chargee et jetee en silence — le
    // mode d'echec le plus couteux a diagnostiquer (spec §7.1).
    test('une regle malformee fait echouer le chargement de la classe', () {
      expect(
        () => HeroData.fromJson({
          ...heroJson(),
          'statRules': [ruleJson()..['mode'] = 'block'],
        }),
        throwsFormatException,
      );
    });
  });
}
