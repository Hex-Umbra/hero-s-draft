import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/event_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/event_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

import 'shipped_data.dart';

void main() {
  // Le registre réel, pour les événements livrés.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventController Unit Tests', () {
    late ProviderContainer container;
    late EventController eventController;
    late RunController runController;
    late InventoryController inventoryController;

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

    final EventData testEvent = EventData(
      id: 'test_event',
      titleEn: 'Mysterious Shrine',
      titleFr: 'Sanctuaire Mystérieux',
      descriptionEn: 'You find a glowing shrine.',
      descriptionFr: 'Vous trouvez un sanctuaire brillant.',
      choices: [
        EventChoice(
          textEn: 'Pray for strength (+2 Strength, -10 HP)',
          textFr: 'Prier pour la force (+2 Force, -10 PV)',
          actions: [
            EventAction(type: 'gain_might', value: 2),
            EventAction(type: 'take_damage', value: 10),
          ],
        ),
        EventChoice(
          textEn: 'Search for gold (+50 Gold)',
          textFr: 'Chercher de l\'or (+50 Or)',
          actions: [EventAction(type: 'gain_gold', value: 50)],
        ),
        EventChoice(
          textEn: 'Touch the altar (Gain a random Relic)',
          textFr: 'Toucher l\'autel (Gagner une relique aléatoire)',
          actions: [EventAction(type: 'gain_relic', value: 1)],
        ),
      ],
    );

    final List<RelicData> testRelicPool = [
      const RelicData(
        id: 'r_common',
        nameEn: 'Common Ring',
        nameFr: 'Anneau Commun',
        descriptionEn: 'Gain 2 armor at turn start',
        descriptionFr: 'Gagne 2 armure en début de tour',
        trigger: RelicTrigger.startOfTurn,
        effectType: 'gain_armor',
        value: 2,
        rarity: RelicRarity.common,
        emoji: '🪙',
      ),
      const RelicData(
        id: 'r_rare',
        nameEn: 'Rare Sword',
        nameFr: 'Épée Rare',
        descriptionEn: 'Gain 2 Strength at run start',
        descriptionFr: 'Gagne 2 Force au début de la run',
        trigger: RelicTrigger.startOfRun,
        effectType: 'gain_might',
        value: 2,
        rarity: RelicRarity.rare,
        emoji: '⚔️',
      ),
      const RelicData(
        id: 'r_legendary',
        nameEn: 'Crown',
        nameFr: 'Couronne',
        descriptionEn: '+1 Luck at run start',
        descriptionFr: '+1 Chance au début de la run',
        trigger: RelicTrigger.startOfRun,
        effectType: 'gain_luck',
        value: 1,
        rarity: RelicRarity.legendary,
        emoji: '👑',
      ),
    ];

    setUp(() {
      container = ProviderContainer();
      eventController = container.read(eventProvider.notifier);
      runController = container.read(runProvider.notifier);
      inventoryController = container.read(inventoryProvider.notifier);

      runController.startNewRun(dummyHero);
    });

    test('initializeEvent sets state with a random event from list', () {
      eventController.initializeEvent([testEvent]);
      expect(eventController.state.activeEvent?.id, testEvent.id);
      expect(eventController.state.isResolved, false);
      expect(eventController.state.selectedChoice, null);
    });

    test(
      'selectChoice resolves simple actions correctly (strength and damage)',
      () {
        eventController.setEvent(testEvent);
        final choice = testEvent.choices[0]; // Pray Choice

        eventController.selectChoice(
          choice,
          [],
        );

        expect(eventController.state.isResolved, true);
        expect(eventController.state.selectedChoice, choice);
        // Hero stats update: strength + 2
        expect(runController.state.heroStats.might, 2);
        // HP decreases by 10
        expect(runController.state.heroStats.currentPv, 90);
      },
    );

    test('selectChoice resolves gold choice', () {
      eventController.setEvent(testEvent);
      final choice = testEvent.choices[1]; // Gold Choice
      final initialGold = inventoryController.state.gold;

      eventController.selectChoice(
        choice,
        [],
      );

      expect(inventoryController.state.gold, initialGold + 50);
    });

    test(
      'selectChoice selects relic based on luck and mockRoll (legendary)',
      () {
        eventController.setEvent(testEvent);
        final choice = testEvent.choices[2]; // Relic Choice

        // Roll is 0.5, which is < legChance (1.0 + 0 * 0.5 = 1.0)
        // This should pick a Legendary relic from our pool
        final chosen = eventController.selectChoice(
          choice,
          testRelicPool,
          mockRoll: 0.5,
        );

        expect(chosen, isNotNull);
        expect(chosen!.rarity, RelicRarity.legendary);
        expect(chosen.id, 'r_legendary');
        // Verify the relic is added to inventory state
        expect(inventoryController.state.relics.contains(chosen), true);
      },
    );

    test('selectChoice selects relic based on luck and mockRoll (common)', () {
      eventController.setEvent(testEvent);
      final choice = testEvent.choices[2]; // Relic Choice

      // Roll is 50.0, which is > any high rarity chance, so it should fallback to common
      final chosen = eventController.selectChoice(
        choice,
        testRelicPool,
        mockRoll: 50.0,
      );

      expect(chosen, isNotNull);
      expect(chosen!.rarity, RelicRarity.common);
      expect(chosen.id, 'r_common');
      expect(inventoryController.state.relics.contains(chosen), true);
    });
  });

  // Le Colporteur (spec P-43 E3, §3.4, §4.9 ; D23, D63, A2, A19, A20) et les
  // faits que reçoit `EventChoice.isSelectable` (C4.4, C4.5).
  group('le Colporteur', () {
    late ProviderContainer container;
    late EventController events;
    late RunController run;
    late InventoryController inventory;
    late EventData peddler;

    const paladin = HeroData(
      id: 'paladin',
      classCard: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
    );

    RelicData relic(String id, RelicRarity rarity) => RelicData(
          id: id,
          nameEn: id,
          nameFr: id,
          trigger: RelicTrigger.startOfCombat,
          effectType: 'gain_armor',
          value: 1,
          rarity: rarity,
          emoji: '⬜',
        );

    setUpAll(() async {
      peddler = (await loadGameDataRegistry(rootBundle))
          .events
          .singleWhere((e) => e.id == 'relic_peddler');
    });

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      events = container.read(eventProvider.notifier);
      run = container.read(runProvider.notifier);
      inventory = container.read(inventoryProvider.notifier);
      run.startNewRun(paladin);
    });

    EventChoice sale() => peddler.choices[0];
    EventChoice remedies() => peddler.choices[1];

    test('la relique visee est la plus faible, au hasard parmi les ex aequo',
        () {
      inventory.addRelic(relic('rare', RelicRarity.rare));
      inventory.addRelic(relic('first', RelicRarity.common));
      inventory.addRelic(relic('second', RelicRarity.common));

      final seen = <String>{};
      for (var i = 0; i < 50; i++) {
        events.setEvent(peddler);
        seen.add(events.state.tradedRelic!.id);
      }
      expect(seen, {'first', 'second'});
    });

    test('aucune relique visee sur un inventaire vide, ni sans action '
        'trade_relic', () {
      events.setEvent(peddler);
      expect(events.state.tradedRelic, isNull);

      inventory.addRelic(relic('common', RelicRarity.common));
      events.setEvent(EventData(id: 'other', choices: [
        EventChoice(actions: [EventAction(type: 'gain_gold', value: 10)]),
      ]));
      expect(events.state.tradedRelic, isNull);
    });

    test('vendre cede la relique visee contre 40 or par rang, et defait sa '
        'regle de run', () {
      // La Sacoche du glaneur, rare (rang 2) : 40 × 3 or ; `loseRelic`
      // défait sa règle de run.
      inventory.addRelic(shippedRelic('gleaners_pouch'));
      expect(run.currentState.extraCombatCards, 1);
      final goldBefore = inventory.state.gold;
      events.setEvent(peddler);

      events.selectChoice(sale(), const []);

      expect(inventory.state.relics, isEmpty);
      expect(run.currentState.extraCombatCards, 0);
      expect(inventory.state.gold, goldBefore + 120);
    });

    test('les remedes cedent la relique sans or et soignent 20 % des PV max, '
        'arrondis', () {
      // 87 PV max : 20 % font 17,4, arrondis à 17 (`.round()`).
      run.applyHeroStatModifier(maxPvAcc: -13);
      run.takeDamage(50);
      expect(run.currentState.heroStats.currentPv, 37);
      inventory.addRelic(relic('common', RelicRarity.common));
      final goldBefore = inventory.state.gold;
      events.setEvent(peddler);

      events.selectChoice(remedies(), const []);

      expect(inventory.state.relics, isEmpty);
      expect(inventory.state.gold, goldBefore);
      expect(run.currentState.heroStats.currentPv, 37 + 17);
    });

    test('isChoiceSelectable : la vente suit la relique visee', () {
      events.setEvent(peddler);
      expect(events.isChoiceSelectable(sale(), const []), isFalse);

      inventory.addRelic(relic('common', RelicRarity.common));
      events.setEvent(peddler);
      expect(events.isChoiceSelectable(sale(), const []), isTrue);
    });

    // L'or, lu sur l'inventaire (n° 1 du tour 5) : avec le cas des remèdes de
    // l'écran, il épingle les trois entiers positionnels d'`isSelectable`.
    test('isChoiceSelectable lit l or de l inventaire', () {
      final offering = EventChoice(
        actions: [EventAction(type: 'spend_gold', value: 40)],
      );
      events.setEvent(EventData(id: 'altar', choices: [offering]));

      inventory.reset(initialGold: 39);
      expect(events.isChoiceSelectable(offering, const []), isFalse);

      inventory.reset(initialGold: 40);
      expect(events.isChoiceSelectable(offering, const []), isTrue);
    });

    test('isSelectable : un choix trade_relic suit le fait hasTradedRelic', () {
      expect(sale().isSelectable(100, 0, 100, hasTradedRelic: false, hasSharpenableRune: false), isFalse);
      expect(sale().isSelectable(100, 0, 100, hasTradedRelic: true, hasSharpenableRune: false), isTrue);
    });

    test('requiresHpBelowPercent se lit dans la donnee : sur 100 PV max, 29 '
        'passe a 30 %, 30 non', () {
      final choice = EventChoice.fromJson({
        'text_fr': 'Boire',
        'requiresHpBelowPercent': 30,
        'actions': <dynamic>[],
      });
      expect(choice.requiresHpBelowPercent, 30);
      expect(choice.isSelectable(29, 0, 100, hasTradedRelic: false, hasSharpenableRune: false), isTrue);
      expect(choice.isSelectable(30, 0, 100, hasTradedRelic: false, hasSharpenableRune: false), isFalse);

      for (final bad in <Object>[0, 101, '50']) {
        expect(
          () => EventChoice.fromJson({
            'requiresHpBelowPercent': bad,
            'actions': <dynamic>[],
          }),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });

    test('les valeurs de trade_relic et heal_percent sont bornees au '
        'chargement', () {
      for (final (type, bad) in <(String, Object)>[
        ('trade_relic', -1),
        ('trade_relic', '40'),
        ('heal_percent', 0),
        ('heal_percent', 101),
      ]) {
        expect(
          () => EventAction.fromJson({'type': type, 'value': bad}),
          throwsFormatException,
          reason: '$type $bad',
        );
      }
      expect(
          EventAction.fromJson({'type': 'trade_relic', 'value': 0}).value, 0);
      expect(
          EventAction.fromJson({'type': 'heal_percent', 'value': 100}).value,
          100);
    });

    test('le Colporteur livre : ses actions, et la moitie des PV pour les '
        'remedes', () {
      List<(String, Object?)> actionsOf(EventChoice choice) =>
          [for (final a in choice.actions) (a.type, a.value)];

      expect(peddler.choices, hasLength(3));
      expect(actionsOf(sale()), [('trade_relic', 40)]);
      expect(sale().requiresHpBelowPercent, isNull);
      expect(actionsOf(remedies()),
          [('trade_relic', 0), ('heal_percent', 20)]);
      expect(remedies().requiresHpBelowPercent, 50);
      expect(peddler.choices[2].actions, isEmpty);
    });
  });

  // Le Rémouleur (spec P-43 E3, §3.4, §4.9 ; D42(b), A4, A19, A21).
  group('le Remouleur', () {
    late ProviderContainer container;
    late EventController events;
    late RunController run;
    late InventoryController inventory;
    late List<ForgeUpgradeData> runes;
    late EventData grinder;

    const paladin = HeroData(
      id: 'paladin',
      classCard: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
    );

    setUpAll(() async {
      grinder = (await loadGameDataRegistry(rootBundle))
          .events
          .singleWhere((e) => e.id == 'wandering_grinder');
    });

    setUp(() {
      // Les runes livrées, que `raiseRuneLevel` lit dans le registre.
      runes = shippedRuneRegistry(shippedRuneIds()).forgeUpgrades;
      container = ProviderContainer();
      addTearDown(container.dispose);
      events = container.read(eventProvider.notifier);
      run = container.read(runProvider.notifier);
      inventory = container.read(inventoryProvider.notifier);
      run.startNewRun(paladin);
      events.setEvent(grinder);
    });

    EventChoice hand() => grinder.choices[0];

    /// Une Frappe rare portant [carried], posée dans le deck.
    CardInstance seedRare(List<String> carried) {
      final card = CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.rare,
        forgeUpgrades: carried,
      );
      container.read(deckProvider.notifier).addCardToMasterDeck(card);
      return card;
    }

    List<String> runesOf(CardInstance card) => container
        .read(deckProvider)
        .masterDeck
        .singleWhere((c) => c.uniqueId == card.uniqueId)
        .forgeUpgrades;

    test('confier une rune perd 10 % des PV max, arrondis, et monte la paire '
        'choisie, sans or', () {
      // 87 PV max : 10 % font 8,7, arrondis à 9 (`.round()`).
      run.applyHeroStatModifier(maxPvAcc: -13);
      final card = seedRare(const ['sharp:1']);
      final goldBefore = inventory.state.gold;

      events.selectChoice(
        hand(),
        const [],
        sharpenTarget: (cardId: card.uniqueId, runeId: 'sharp'),
      );

      expect(run.currentState.heroStats.currentPv, 87 - 9);
      expect(runesOf(card), ['sharp:2']);
      expect(inventory.state.gold, goldBefore);
    });

    test('isChoiceSelectable : le Remouleur suit les runes du deck qui '
        'peuvent monter', () {
      seedRare(const ['eco:1']);
      expect(events.isChoiceSelectable(hand(), runes), isFalse);

      seedRare(const ['sharp:1']);
      expect(events.isChoiceSelectable(hand(), runes), isTrue);
    });

    test('isSelectable : sharpen_rune suit hasSharpenableRune ; '
        'lose_hp_percent refuse des PV au plus egaux a son cout', () {
      expect(
        hand().isSelectable(100, 0, 100,
            hasTradedRelic: false, hasSharpenableRune: false),
        isFalse,
      );
      expect(
        hand().isSelectable(100, 0, 100,
            hasTradedRelic: false, hasSharpenableRune: true),
        isTrue,
      );
      // 10 % de 100 PV max : à 10 PV le choix tuerait, à 11 non.
      expect(
        hand().isSelectable(10, 0, 100,
            hasTradedRelic: false, hasSharpenableRune: true),
        isFalse,
      );
      expect(
        hand().isSelectable(11, 0, 100,
            hasTradedRelic: false, hasSharpenableRune: true),
        isTrue,
      );
    });

    test('les valeurs de lose_hp_percent et sharpen_rune sont bornees au '
        'chargement', () {
      for (final (type, bad) in <(String, Object)>[
        ('lose_hp_percent', 0),
        ('lose_hp_percent', 101),
        ('sharpen_rune', 0),
        ('sharpen_rune', '1'),
      ]) {
        expect(
          () => EventAction.fromJson({'type': type, 'value': bad}),
          throwsFormatException,
          reason: '$type $bad',
        );
      }
      expect(
          EventAction.fromJson({'type': 'lose_hp_percent', 'value': 100})
              .value,
          100);
      expect(EventAction.fromJson({'type': 'sharpen_rune', 'value': 1}).value,
          1);
    });

    test('le Remouleur livre : ses actions', () {
      expect(grinder.choices, hasLength(2));
      expect(
        [for (final a in hand().actions) (a.type, a.value)],
        [('lose_hp_percent', 10), ('sharpen_rune', 1)],
      );
      expect(grinder.choices[1].actions, isEmpty);
    });
  });
}
