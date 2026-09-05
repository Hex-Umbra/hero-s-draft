import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/tutorial/tutorial_fixtures.dart';

import 'tutorial_test_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry data;
  late TutorialFixtures fixtures;

  setUpAll(() async {
    data = await buildTutorialTestRegistry();
  });

  setUp(() {
    fixtures = TutorialFixtures(data);
  });

  group('Existence des fixtures', () {
    test('les trois classes du tutoriel existent', () {
      expect(fixtures.heroes.map((h) => h.id), ['paladin', 'berserker', 'mage']);
    });

    test('chaque classe a un passif résoluble', () {
      for (final hero in fixtures.heroes) {
        expect(fixtures.passiveFor(hero).id, hero.passiveTrait);
      }
    });

    test('les trois cartes de démonstration existent', () {
      expect(fixtures.card(TutorialFixtureIds.strike).id, 'strike_basic');
      expect(fixtures.card(TutorialFixtureIds.defend).id, 'defend_basic');
      expect(fixtures.card(TutorialFixtureIds.fireball).id, 'fireball');
    });

    test('l\'ennemi et la relique de démonstration existent', () {
      expect(fixtures.trainingEnemy.id, 'slime');
      expect(fixtures.sampleRelic.id, 'iron_talisman');
    });

    test('le Gobelin de l\'étape XP existe', () {
      expect(fixtures.goblin.id, 'gobelin');
    });
  });

  group('Propriétés dont la pédagogie dépend', () {
    test('Frappe est une attaque ciblée qui inflige des dégâts', () {
      final strike = fixtures.card(TutorialFixtureIds.strike);
      expect(strike.type, CardType.attack);
      expect(strike.target, CardTarget.singleEnemy);
      expect(strike.effects.any((e) => e.type == 'damage'), isTrue);
    });

    test('Défense est une Compétence sur soi qui donne de l\'armure', () {
      final defend = fixtures.card(TutorialFixtureIds.defend);
      expect(defend.type, CardType.skill);
      expect(defend.target, CardTarget.self);
      expect(defend.effects.any((e) => e.type == 'armor'), isTrue);
    });

    test('Boule de Feu applique bien Brûlure', () {
      final fireball = fixtures.card(TutorialFixtureIds.fireball);
      expect(fireball.type, CardType.attack);
      expect(
        fireball.effects.any((e) => e.type == 'apply_status' && e.statusId == 'burn'),
        isTrue,
      );
    });

    test('le Slime a une intention d\'attaque exploitable', () {
      final slime = fixtures.trainingEnemy;
      expect(slime.intents, isNotNull);
      expect(slime.intents!, isNotEmpty);
      expect(slime.maxHp, greaterThan(0));
    });

    test('le Talisman de Fer se déclenche en début de tour', () {
      final relic = fixtures.sampleRelic;
      expect(relic.trigger, RelicTrigger.startOfTurn);
      expect(relic.effectType, 'gain_armor');
    });

    test('le pool de départ ne contient que des cartes globales non-statut', () {
      expect(fixtures.starterPool, isNotEmpty);
      expect(fixtures.starterPool.length, greaterThanOrEqualTo(5));
      for (final card in fixtures.starterPool) {
        expect(card.category, CardCategory.global);
        expect(card.type, isNot(CardType.status));
      }
    });
  });

  group('Politique fail-fast', () {
    test('un id absent lève au lieu de retomber sur une valeur en dur', () {
      expect(() => fixtures.card('id_qui_nexiste_pas'), throwsStateError);
    });
  });
}
