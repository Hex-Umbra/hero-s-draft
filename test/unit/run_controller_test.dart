import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

import 'shipped_data.dart';

void main() {
  group('RunController & RunState Tests', () {
    test(
      'RunState constructor sets default bonusShopCards to 0 in inventory',
      () {
        final container = ProviderContainer();
        final inventoryState = container.read(inventoryProvider);
        expect(inventoryState.bonusShopCards, 0);
      },
    );

    test(
      'buyShopExpansion increments bonusShopCards correctly in inventory',
      () {
        final container = ProviderContainer();
        final inventoryController = container.read(inventoryProvider.notifier);
        expect(container.read(inventoryProvider).bonusShopCards, 0);

        inventoryController.buyShopExpansion();
        expect(container.read(inventoryProvider).bonusShopCards, 1);

        inventoryController.buyShopExpansion();
        expect(container.read(inventoryProvider).bonusShopCards, 2);
      },
    );

    test(
      'startNewRun resets bonusShopCards to 0 and gold to 50 in inventory',
      () {
        final container = ProviderContainer();
        final runController = container.read(runProvider.notifier);
        final inventoryController = container.read(inventoryProvider.notifier);

        inventoryController.buyShopExpansion();
        expect(container.read(inventoryProvider).bonusShopCards, 1);

        const dummyHero = HeroData(
          id: 'paladin',
          nameEn: 'Paladin',
          nameFr: 'Paladin',
          descriptionEn: 'A holy knight',
          descriptionFr: 'Un saint chevalier',
          classCard: 'paladin.png',
          maxHp: 100,
          maxMana: 3,
          luck: 0,
          mastery: 0,
        );

        runController.startNewRun(dummyHero);
        expect(container.read(inventoryProvider).bonusShopCards, 0);
        expect(container.read(inventoryProvider).gold, 50);
      },
    );

    test(
      'a start-of-turn passive triggers at start of combat and its armor resets at end of combat',
      () {
        final container = ProviderContainer();
        final runController = container.read(runProvider.notifier);

        const berserkerHero = HeroData(
          id: 'berserker',
          nameEn: 'Berserker',
          nameFr: 'Berserker',
          descriptionEn: 'A raging warrior',
          descriptionFr: 'Un guerrier enragé',
          classCard: 'berserker.png',
          maxHp: 80,
          maxMana: 3,
          luck: 0,
          mastery: 1,
        );

        // activePassive n'est déduit d'aucun repli codé en dur : on le
        // fournit explicitement, comme le ferait le vrai chargement depuis
        // assets/data/passives/ via PassiveData.getById. `gain_armor` sert
        // de témoin : ce test mesure le déclenchement au début du combat et
        // la Maîtrise, pas la formule d'un passif en particulier.
        const startOfTurnArmor = PassiveData(
          id: 'test_passive',
          nameEn: 'Test Passive',
          nameFr: 'Passif de test',
          trigger: RelicTrigger.startOfTurn,
          effectType: 'gain_armor',
          value: 1,
          mastery: PassiveMastery(field: 'value', perPoint: 1),
        );

        runController.startNewRun(berserkerHero, startOfTurnArmor);

        // Set missing HP: 80 max HP, set current to 60 (20 missing HP)
        runController.takeDamage(20);

        // Travel to a node to have currentNodeId set
        runController.travelToNode('node_1');

        // At the start of combat, the passive should trigger. Mastery raises
        // the passive's value first (spec P-49, §6.4): 1 + 1 = 2 armor.
        runController.startCombat();

        expect(runController.state.heroStats.armure, 2);

        // When the node is completed, armor should reset to 0
        runController.completeCurrentNode();
        expect(runController.state.heroStats.armure, 0);
      },
    );

    test(
      'Relic system: addRelic, startOfRun effect, trigger application and stacking',
      () {
        final container = ProviderContainer();
        final runController = container.read(runProvider.notifier);
        final inventoryController = container.read(inventoryProvider.notifier);

        const dummyHero = HeroData(
          id: 'paladin',
          nameEn: 'Paladin',
          nameFr: 'Paladin',
          descriptionEn: 'A holy knight',
          descriptionFr: 'Un saint chevalier',
          classCard: 'paladin.png',
          maxHp: 100,
          maxMana: 3,
          luck: 0,
          mastery: 0,
        );
        runController.startNewRun(dummyHero);

        // 1. startOfRun trigger is applied immediately
        const luckyClover = RelicData(
          id: 'lucky_clover',
          nameEn: 'Lucky Clover',
          nameFr: 'Trèfle Enchanté',
          descriptionEn: '+1 Luck',
          descriptionFr: '+1 Chance',
          trigger: RelicTrigger.startOfRun,
          effectType: 'gain_luck',
          value: 1,
          rarity: RelicRarity.epic,
          emoji: '🍀',
        );

        expect(runController.state.heroStats.luck, 0);
        inventoryController.addRelic(luckyClover);
        expect(runController.state.heroStats.luck, 1);
        expect(inventoryController.state.relics.length, 1);

        // Stacking lucky clover gives +1 luck again
        inventoryController.addRelic(luckyClover);
        expect(runController.state.heroStats.luck, 2);
        expect(inventoryController.state.relics.length, 2);

        // 2. Combat triggers and stacking
        const talisman = RelicData(
          id: 'iron_talisman',
          nameEn: 'Iron Talisman',
          nameFr: 'Talisman de Fer',
          descriptionEn: 'Gain 2 armor',
          descriptionFr: 'Gagne 2 armure',
          trigger: RelicTrigger.startOfTurn,
          effectType: 'gain_armor',
          value: 2,
          rarity: RelicRarity.common,
          emoji: '🪙',
        );

        inventoryController.addRelic(talisman);
        inventoryController.addRelic(talisman); // Stack x2

        expect(runController.state.heroStats.armure, 0);

        // Trigger startOfTurn relics
        runController.applyRelics(RelicTrigger.startOfTurn);
        // Stacking 2 x 2 armure = 4 armure
        expect(runController.state.heroStats.armure, 4);
      },
    );
  });

  group('RunState.cardsPerTurn', () {
    const dummyHero = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Paladin',
      classCard: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      luck: 0,
      mastery: 0,
    );

    test('vaut 5 au démarrage d\'une run', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runController = container.read(runProvider.notifier);
      runController.startNewRun(dummyHero);

      expect(container.read(runProvider).cardsPerTurn, 5);
    });

    test('applyRunRuleModifier ajoute puis retire symétriquement', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runController = container.read(runProvider.notifier);
      runController.startNewRun(dummyHero);

      runController.applyRunRuleModifier(cardsPerTurnAcc: 1);
      expect(container.read(runProvider).cardsPerTurn, 6);

      runController.applyRunRuleModifier(cardsPerTurnAcc: -1);
      expect(container.read(runProvider).cardsPerTurn, 5);
    });
  });

  group('RunController.endTurn', () {
    const hero = HeroData(
      id: 'berserker',
      classCard: 'berserker.png',
      maxHp: 100,
      maxMana: 3,
    );

    test('le passif, puis les reliques de fin de tour', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final runController = container.read(runProvider.notifier);

      // `gain_armor` en temoin : le sujet est l'ordre — le passif, puis les
      // reliques —, pas la formule du passif.
      const endOfTurnArmor = PassiveData(
        id: 'test_passive',
        trigger: RelicTrigger.endOfTurn,
        effectType: 'gain_armor',
        value: 3,
      );
      runController.startNewRun(hero, endOfTurnArmor);
      runController.takeDamage(30);
      container.read(inventoryProvider.notifier).addRelic(
            const RelicData(
              id: 'test_heal',
              trigger: RelicTrigger.endOfTurn,
              effectType: 'heal',
              value: 20,
              rarity: RelicRarity.common,
              emoji: '💧',
            ),
          );

      runController.endTurn();

      // Le passif d'abord, la relique de soin ensuite : l'armure du passif est
      // là, et les 30 PV manquants ont été soignés de 20.
      expect(runController.state.heroStats.armure, 3);
      expect(runController.state.heroStats.currentPv, 90);
    });
  });

  // Payer et ecrire, ou rien (spec P-43 E2, §4.7, A16).
  group('RunController.sharpenRune', () {
    late ProviderContainer container;
    late RunController run;

    setUp(() {
      shippedRuneRegistry(const ['burning', 'eco', 'sharp']);
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
    });

    tearDown(() => container.dispose());

    /// Une Frappe rare portant [runes], seule carte du deck, et [gold] or.
    CardInstance seed(List<String> runes, {required int gold}) {
      container.read(inventoryProvider.notifier).reset(initialGold: gold);
      final card = CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.rare,
        forgeUpgrades: runes,
      );
      container.read(deckProvider.notifier).addCardToMasterDeck(card);
      return card;
    }

    List<String> runesOf(CardInstance card) => container
        .read(deckProvider)
        .masterDeck
        .singleWhere((c) => c.uniqueId == card.uniqueId)
        .forgeUpgrades;

    // Review Focus 2 : l'or tout juste suffisant.
    test('depense 50 x n et ecrit id:n+1 a sa place', () {
      final card = seed(const ['burning:1', 'sharp:2', 'eco:1'], gold: 100);

      expect(run.sharpenRune(card.uniqueId, 'sharp'), isTrue);

      expect(container.read(inventoryProvider).gold, 0);
      expect(runesOf(card), ['burning:1', 'sharp:3', 'eco:1']);
    });

    test('refuse une rune a son plafond, sans rien toucher', () {
      final card = seed(const ['sharp:2', 'eco:1'], gold: 1000);

      expect(run.sharpenRune(card.uniqueId, 'eco'), isFalse);

      expect(container.read(inventoryProvider).gold, 1000);
      expect(runesOf(card), ['sharp:2', 'eco:1']);
    });

    test('refuse faute d or, sans rien toucher', () {
      final card = seed(const ['sharp:2'], gold: 99);

      expect(run.sharpenRune(card.uniqueId, 'sharp'), isFalse);

      expect(container.read(inventoryProvider).gold, 99);
      expect(runesOf(card), ['sharp:2']);
    });
  });
}
