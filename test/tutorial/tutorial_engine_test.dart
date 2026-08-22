import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/tutorial_fixtures.dart';

import 'tutorial_test_registry.dart';

void main() {
  late TutorialEngine engine;

  setUp(() {
    engine = TutorialEngine(data: buildTutorialTestRegistry());
    engine.resetMockState();
  });

  group('Modèles réels', () {
    test('la main est composée de CardInstance issues du registre', () {
      engine.seedHand([
        TutorialFixtureIds.strike,
        TutorialFixtureIds.defend,
      ]);

      expect(engine.mockState.hand, everyElement(isA<CardInstance>()));
      expect(engine.mockState.hand.first.data.id, 'strike_basic');
      // La valeur vient du JSON, pas d'une constante recopiée.
      expect(engine.mockState.hand.first.data.cost, 1);
    });

    test('l\'ennemi d\'entraînement porte les stats du JSON', () {
      engine.seedEnemy();

      final enemy = engine.mockState.enemy!;
      final slime = engine.fixtures.trainingEnemy;
      expect(enemy.stats.maxPv, slime.maxHp);
      expect(enemy.stats.currentPv, slime.maxHp);
      expect(enemy.data.id, 'slime');
    });

    test('les stats du héros sont un EntityStats', () {
      expect(engine.mockState.heroStats.maxPv, greaterThan(0));
      expect(engine.mockState.heroStats.armure, 0);
    });
  });

  group('playCard passe par les vrais calculs', () {
    test('une attaque retire les dégâts du JSON aux PV de l\'ennemi', () {
      engine.seedEnemy();
      engine.seedHand([TutorialFixtureIds.strike]);

      final slimeHp = engine.fixtures.trainingEnemy.maxHp;
      final strikeDamage = engine.fixtures
          .card(TutorialFixtureIds.strike)
          .effects
          .firstWhere((e) => e.type == 'damage')
          .value;

      final played = engine.playCard(engine.mockState.hand.first);

      expect(played, isTrue);
      expect(engine.mockState.enemy!.stats.currentPv, slimeHp - strikeDamage);
    });

    test('une carte de Défense donne de l\'armure même sans ennemi', () {
      // Régression : le gain d'armure était imbriqué dans `if (enemy != null)`.
      engine.seedHand([TutorialFixtureIds.defend]);
      expect(engine.mockState.enemy, isNull);

      final armorValue = engine.fixtures
          .card(TutorialFixtureIds.defend)
          .effects
          .firstWhere((e) => e.type == 'armor')
          .value;

      engine.playCard(engine.mockState.hand.first);

      expect(engine.mockState.heroStats.armure, armorValue);
    });

    test('une carte trop chère n\'est pas jouée', () {
      engine.seedHand([TutorialFixtureIds.fireball]);
      engine.setMana(0);

      expect(engine.playCard(engine.mockState.hand.first), isFalse);
      expect(engine.mockState.hand, hasLength(1));
    });
  });

  group('L\'absorption d\'armure suit EntityStats.takeDamage', () {
    test('sans armure, tous les dégâts vont aux PV', () {
      final before = engine.mockState.heroStats.currentPv;
      engine.applyDamageToHero(10);
      expect(engine.mockState.heroStats.currentPv, before - 10);
    });

    test('avec armure, l\'armure encaisse en premier', () {
      engine.setHeroArmor(4);
      final before = engine.mockState.heroStats.currentPv;

      engine.applyDamageToHero(10);

      expect(engine.mockState.heroStats.armure, 0);
      expect(engine.mockState.heroStats.currentPv, before - 6);
    });
  });

  // Couverture perdue par le remplacement verbatim de l'étape 1 : ces trois
  // comportements (le `switch` de resetMockState, mergeCards, le level-up de
  // gainXp) étaient exercés par l'ancien fichier de test et ne le sont plus
  // par les tests ci-dessus, qui appellent les helpers de peuplement
  // directement plutôt que de naviguer les étapes.
  group('resetMockState, mergeCards et gainXp restent couverts', () {
    test(
      'nextStep() x5 atteint l\'étape Jouer les cartes avec la main et l\'ennemi attendus',
      () {
        for (var i = 0; i < 5; i++) {
          engine.nextStep();
        }

        expect(engine.currentStepIndex, 5);
        expect(engine.mockState.hand, hasLength(2));
        expect(engine.mockState.enemy, isNotNull);
      },
    );

    test('mergeCards fusionne 3 exemplaires en une carte de rareté supérieure', () {
      engine.seedHand([
        TutorialFixtureIds.strike,
        TutorialFixtureIds.strike,
        TutorialFixtureIds.strike,
      ]);

      engine.mergeCards();

      expect(engine.mockState.hand, hasLength(1));
      expect(engine.mockState.hand.first.rarity, CardRarity.uncommon);
    });

    test('gainXp déclenche un passage de niveau au-delà de xpToNextLevel', () {
      expect(engine.mockState.playerLevel, 1);
      expect(engine.mockState.playerXp, 0);

      engine.gainXp(35);
      expect(engine.mockState.playerXp, 35);
      engine.gainXp(35);
      expect(engine.mockState.playerXp, 70);
      engine.gainXp(35);

      expect(engine.mockState.playerLevel, 2);
      expect(engine.mockState.playerXp, 5); // 105 - 100
    });
  });
}
