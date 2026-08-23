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
      'nextStep() x7 atteint l\'étape Jouer les cartes avec la main et l\'ennemi attendus',
      () {
        // Les étapes 02 (choix de classe) et 03 (draft du deck de départ)
        // ont décalé "Jouer des cartes" de l'indice 5 à l'indice 7.
        for (var i = 0; i < 7; i++) {
          engine.nextStep();
        }

        expect(engine.currentStepIndex, 7);
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

  group('Progression d\'XP', () {
    test('le palier suit 100 x 1,5^(niveau-1)', () {
      expect(engine.mockState.xpToNextLevel, 100);

      engine.gainXp(100);

      expect(engine.mockState.playerLevel, 2);
      expect(engine.mockState.xpToNextLevel, 150);
    });

    test('l\'XP excédentaire est reportée et les drafts s\'empilent', () {
      engine.gainXp(260); // 100 -> niv.2, 150 -> niv.3, reste 10

      expect(engine.mockState.playerLevel, 3);
      expect(engine.mockState.playerXp, 10);
      expect(engine.pendingDrafts, 2);
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

    test(
      'setStarterDeck([]) vide le deck, cartes de classe comprises',
      () {
        // Régression : setStarterDeck injectait toujours les cartes de
        // classe, même avec une sélection vide, ce qui rendait
        // masterDeck.isNotEmpty vrai dès la première carte cochée dans
        // TutorialStarterDeckWidget (widget qui appelle setStarterDeck([])
        // tant que la cible de 5 n'est pas atteinte).
        final pool = engine.fixtures.starterPool.take(5).toList();
        engine.chooseHero(engine.fixtures.heroes.first);
        engine.setStarterDeck(pool);
        expect(engine.mockState.masterDeck, isNotEmpty);

        engine.setStarterDeck([]);

        expect(engine.mockState.masterDeck, isEmpty);
      },
    );

    test('la tranche scratch est bien réinitialisée entre deux étapes', () {
      engine.seedEnemy();
      engine.nextStep();
      expect(engine.mockState.enemy, isNull);
    });

    test(
      'changer de classe après un draft vide le deck de l\'ancienne classe',
      () {
        // Régression : Paladin choisi, 5 cartes draftées (masterDeck à 7),
        // Précédent jusqu'à l'étape 02 puis Mage sélectionné. `chooseHero`
        // réécrivait `chosenHero`/`activePassive`/`heroStats` mais jamais
        // `masterDeck` : l'écran de draft, remonté à neuf par la `PageView`,
        // affichait 0/5 pour le Mage pendant que SUIVANT restait actif
        // (masterDeck.isNotEmpty lisait encore les cartes du Paladin).
        final paladin = engine.fixtures.heroes.firstWhere((h) => h.id == 'paladin');
        final mage = engine.fixtures.heroes.firstWhere((h) => h.id == 'mage');

        engine.chooseHero(paladin);
        final pool = engine.fixtures.starterPool.take(5).toList();
        engine.setStarterDeck(pool);
        expect(engine.mockState.masterDeck, hasLength(5 + paladin.skills.length));

        engine.chooseHero(mage);

        expect(engine.mockState.masterDeck, isEmpty);
        expect(engine.mockState.chosenHero?.id, 'mage');
      },
    );
  });

  group('Semis des étapes Fusion et Jouer des cartes depuis le deck', () {
    test(
      'la Fusion sème 3 exemplaires d\'une carte non-unique du deck, en écartant les cartes de classe',
      () {
        final paladin = engine.fixtures.heroes.firstWhere((h) => h.id == 'paladin');
        engine.chooseHero(paladin);
        engine.setStarterDeck([engine.fixtures.card('heavy_strike')]);
        // Les cartes de classe (uniques) du Paladin précèdent la carte
        // choisie dans `masterDeck` : le test n'a de sens que si elles sont
        // bien écartées plutôt que ramassées en premier.
        expect(engine.mockState.masterDeck.first.rarity, CardRarity.unique);

        engine.prepareStep(11); // étape "La Fusion de Cartes"

        expect(engine.mockState.hand, hasLength(3));
        expect(
          engine.mockState.hand.every((c) => c.data.id == 'heavy_strike'),
          isTrue,
        );
        expect(
          engine.mockState.hand.every((c) => c.rarity == CardRarity.common),
          isTrue,
        );
      },
    );

    test('la Fusion se replie sur les fixtures si le deck est vide (étape 03 sautée)', () {
      expect(engine.mockState.masterDeck, isEmpty);

      engine.prepareStep(11);

      expect(engine.mockState.hand, hasLength(3));
      expect(
        engine.mockState.hand.every((c) => c.data.id == TutorialFixtureIds.strike),
        isTrue,
      );
    });

    test(
      'Jouer des cartes sème l\'attaque et la compétence d\'armure du deck quand elles y sont',
      () {
        engine.setStarterDeck([
          engine.fixtures.card('heavy_strike'), // attaque, cible singleEnemy
          engine.fixtures.card('iron_wall'), // compétence, cible self, armure
        ]);

        engine.prepareStep(7); // étape "Jouer des cartes & finir le tour"

        expect(engine.mockState.hand, hasLength(2));
        expect(engine.mockState.hand[0].data.id, 'heavy_strike');
        expect(engine.mockState.hand[1].data.id, 'iron_wall');
      },
    );

    test(
      'Jouer des cartes n\'utilise jamais smite (attaque + armure) comme geste d\'attaque',
      () {
        // Régression (revue de branche) : `smite`, carte de classe du
        // Paladin, est à la fois une attaque `singleEnemy` et porteuse d'un
        // effet `armor` (6 dégâts + 4 Armure). La retenir comme « l'attaque »
        // de la leçon fait gagner de l'Armure en jouant sur l'ennemi :
        // `_isStepActionComplete` se satisfait d'un seul geste au lieu des
        // deux distincts que la leçon enseigne, et ce pour 100 % des
        // parcours Paladin (`smite` précède toujours les cartes draftées
        // dans `masterDeck`).
        final paladin = engine.fixtures.heroes.firstWhere((h) => h.id == 'paladin');
        engine.chooseHero(paladin);
        // masterDeck = [holy_shield, smite, heavy_strike] : smite doit être
        // écartée et la recherche doit se poursuivre jusqu'à heavy_strike.
        engine.setStarterDeck([engine.fixtures.card('heavy_strike')]);

        engine.prepareStep(7);

        expect(
          engine.mockState.hand.map((c) => c.data.id),
          isNot(contains('smite')),
        );
        expect(
          engine.mockState.hand.any((c) => c.data.id == 'heavy_strike'),
          isTrue,
        );
      },
    );

    test(
      'Jouer des cartes se replie sur les fixtures si le deck ne fournit pas les deux gestes',
      () {
        // Le pool interdit les doublons et rien n'oblige à drafter Frappe ou
        // Défense : `concentration` (Compétence, pioche 2, sans Armure) ne
        // couvre ni le geste d'attaque ni le geste d'Armure.
        engine.setStarterDeck([engine.fixtures.card('concentration')]);

        engine.prepareStep(7);

        expect(engine.mockState.hand, hasLength(2));
        expect(
          engine.mockState.hand.map((c) => c.data.id).toList(),
          [TutorialFixtureIds.strike, TutorialFixtureIds.defend],
        );
      },
    );
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

  group('Réarmement des drapeaux d\'étape par prepareStep', () {
    test('armorGainedThisStep est réarmé par prepareStep', () {
      engine.setHeroArmor(4);
      expect(engine.armorGainedThisStep, isTrue);
      engine.prepareStep(engine.currentStepIndex);
      expect(engine.armorGainedThisStep, isFalse);
    });

    test('manaWarningPending est réarmé par prepareStep', () {
      // Régression (ronde de correction 1/5) : `TutorialEngine` est une
      // instance unique partagée par tout le tutoriel, et l'étape "Jouer des
      // cartes" est revisitable via prevStep(). Sans ce réarmement, revenir
      // sur l'étape après avoir déclenché l'avertissement sans confirmer
      // laissait `manaWarningPending` bloqué à `true` : le bandeau
      // s'affichait sans qu'aucune carte n'ait été jouée, et le premier clic
      // "Fin de Tour" de cette nouvelle visite était traité comme la seconde
      // confirmation, contournant silencieusement la double confirmation.
      engine.seedEnemy();
      engine.setMana(3);
      engine.endTurn();
      expect(engine.manaWarningPending, isTrue);

      engine.prepareStep(engine.currentStepIndex);

      expect(engine.manaWarningPending, isFalse);
    });

    test('pendingDrafts est réarmé par prepareStep', () {
      // Régression (ronde de correction 1/5) : `_pendingDrafts` vivait sur
      // `TutorialEngine`, jamais réarmé par `prepareStep`. L'étape XP exige
      // `playerLevel > 1` pour être validée, donc la terminer laisse
      // toujours au moins un draft en attente ; un aller-retour Suivant/
      // Précédent remettait `playerLevel` à 1 (le bouton de niveau 1
      // réapparaissait) sans jamais purger l'ancien draft, et regagner un
      // niveau l'empilait indéfiniment (1, 2, 3...) au lieu de repartir de
      // zéro comme `playerLevel` lui-même.
      engine.gainXp(100);
      expect(engine.pendingDrafts, 1);
      expect(engine.mockState.playerLevel, 2);

      engine.prepareStep(engine.currentStepIndex);

      expect(engine.pendingDrafts, 0);
      expect(engine.mockState.playerLevel, 1);
    });
  });

  group('prepareStep et le découplage des notifications', () {
    test('une étape qui sème main et ennemi n\'émet qu\'une seule notification', () {
      var notifications = 0;
      engine.addListener(() => notifications++);

      // Étape "Jouer des cartes" (indice 7, décalée par le choix de classe
      // puis par le draft du deck de départ) : sème l'ennemi puis la main,
      // les deux passant par les variantes privées sans notification.
      engine.prepareStep(7);

      expect(notifications, 1);
    });
  });

  group('Fin de tour', () {
    test('finir le tour avec du mana exige une seconde confirmation', () {
      engine.seedEnemy();
      engine.seedHand([TutorialFixtureIds.strike]);
      engine.setMana(3);

      expect(engine.endTurn(), isFalse);
      expect(engine.manaWarningPending, isTrue);

      expect(engine.endTurn(), isTrue);
    });

    test('sans mana restant, le tour se termine du premier coup', () {
      engine.seedEnemy();
      engine.setMana(0);

      expect(engine.endTurn(), isTrue);
      expect(engine.manaWarningPending, isFalse);
    });

    test('jouer une carte annule la confirmation en attente', () {
      engine.seedEnemy();
      engine.seedHand([TutorialFixtureIds.strike]);
      engine.setMana(3);
      engine.endTurn();
      expect(engine.manaWarningPending, isTrue);

      engine.playCard(engine.mockState.hand.first);

      expect(engine.manaWarningPending, isFalse);
    });

    test('le nouveau tour remet l\'armure à zéro et le mana au max', () {
      engine.seedEnemy();
      engine.setHeroArmor(7);
      engine.setMana(0);

      engine.endTurn();

      expect(engine.mockState.heroStats.armure, 0);
      expect(
        engine.mockState.heroStats.currentMana,
        engine.mockState.heroStats.maxMana,
      );
    });

    test('finir le tour ne re-verrouille pas l\'étape', () {
      // Régression : la complétion lisait `heroStats.armure`, que `endTurn`
      // remet à 0 — le joueur restait bloqué sur l'étape.
      engine.seedEnemy();
      engine.setHeroArmor(4);
      expect(engine.armorGainedThisStep, isTrue);

      engine.setMana(0);
      engine.endTurn();

      expect(engine.mockState.heroStats.armure, 0);
      expect(engine.armorGainedThisStep, isTrue);
    });

    // Le cas "changer d'étape réarme le drapeau d'armure" est déjà couvert
    // par le groupe "Réarmement des drapeaux d'étape par prepareStep"
    // ci-dessus (Task 4) : pas de doublon ici.
  });
}
