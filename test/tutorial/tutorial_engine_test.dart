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
    engine.prepareStep(engine.currentStepIndex);
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

  group('Parcours à état', () {
    test('la classe choisie survit aux changements d\'étape', () {
      final paladin = engine.fixtures.heroes.first;
      engine.chooseHero(paladin);

      engine.nextStep();
      engine.nextStep();

      expect(engine.mockState.chosenHero?.id, 'paladin');
      expect(engine.mockState.activePassive?.id, 'regenArmor');
    });

    test('les stats du héros dérivent de la classe choisie', () {
      final mage = engine.fixtures.heroes.firstWhere((h) => h.id == 'mage');
      engine.chooseHero(mage);
      engine.prepareStep(engine.currentStepIndex);

      expect(engine.mockState.heroStats.maxPv, 60);
      expect(engine.mockState.heroStats.maxMana, 3);
    });

    test('le deck drafté survit aux changements d\'étape', () {
      final pool = engine.fixtures.starterPool.take(5).toList();
      engine.chooseHero(engine.fixtures.heroes.first);
      engine.setStarterDeck(pool);

      final expectedSize = 5 + engine.fixtures.heroes.first.skills.length;
      engine.nextStep();

      expect(engine.mockState.masterDeck, hasLength(expectedSize));
    });

    test('la tranche scratch est bien réinitialisée entre deux étapes', () {
      engine.seedEnemy();
      engine.nextStep();
      expect(engine.mockState.enemy, isNull);
    });
  });

  group('Verrou des étapes d\'amont', () {
    test('minReachableStep vaut 0 avant l\'étape 03', () {
      expect(engine.minReachableStep, 0);
    });

    test('une fois l\'étape 03 franchie, on ne redescend plus sous 03', () {
      while (engine.currentStepIndex < 3) {
        engine.nextStep();
      }
      expect(engine.minReachableStep, 3);

      engine.prevStep();
      engine.prevStep();
      engine.prevStep();

      expect(engine.currentStepIndex, 3);
    });
  });

  group('Réarmement de armorGainedThisStep', () {
    test('armorGainedThisStep est réarmé par prepareStep', () {
      engine.setHeroArmor(4);
      expect(engine.armorGainedThisStep, isTrue);
      engine.prepareStep(engine.currentStepIndex);
      expect(engine.armorGainedThisStep, isFalse);
    });
  });

  group('prepareStep et le découplage des notifications', () {
    test('une étape qui sème main et ennemi n\'émet qu\'une seule notification', () {
      var notifications = 0;
      engine.addListener(() => notifications++);

      // Étape "Jouer des cartes" (indice 5) : sème l'ennemi puis la main,
      // les deux passant par les variantes privées sans notification.
      engine.prepareStep(5);

      expect(notifications, 1);
    });
  });
}
