import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/debug_taint_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/services/debug_actions.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

const paladin = HeroData(
  id: 'paladin',
  nameEn: 'Paladin',
  nameFr: 'Paladin',
  descriptionEn: 'A holy knight',
  descriptionFr: 'Un saint chevalier',
  iconPath: 'paladin.png',
  maxHp: 100,
  maxMana: 3,
  baseDamage: 5,
  luck: 0,
  armorMastery: 0,
  passiveTrait: 'regen_armor',
);

ProviderContainer _startedRun() {
  final container = ProviderContainer();
  container.read(runProvider.notifier).startNewRun(paladin);
  return container;
}

void main() {
  group('DebugActions — run et heros', () {
    test('updateHeroStats ecrit les PV et contamine la run', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      expect(container.read(debugTaintProvider), isFalse);

      DebugActions.updateHeroStats(
        container.read,
        (s) => s.copyWith(currentPv: 42),
      );

      expect(container.read(runProvider).heroStats.currentPv, 42);
      expect(container.read(debugTaintProvider), isTrue);
    });

    test('setGold fixe l or a la valeur exacte, a la hausse comme a la baisse', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      expect(container.read(inventoryProvider).gold, 50);

      DebugActions.setGold(container.read, 999);
      expect(container.read(inventoryProvider).gold, 999);

      DebugActions.setGold(container.read, 7);
      expect(container.read(inventoryProvider).gold, 7);
    });

    test('updateRun force l acte sans toucher a la carte ni a la position', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final mapBefore = container.read(runProvider).mapNodes;
      final nodeBefore = container.read(runProvider).currentNodeId;

      DebugActions.updateRun(container.read, (s) => s.copyWith(act: 3));

      expect(container.read(runProvider).act, 3);
      expect(container.read(runProvider).mapNodes, same(mapBefore));
      expect(container.read(runProvider).currentNodeId, nodeBefore);
    });

    test('advanceToNextAct incremente l acte ET regenere la carte', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      final mapBefore = container.read(runProvider).mapNodes;

      DebugActions.advanceToNextAct(container.read);

      expect(container.read(runProvider).act, 2);
      expect(container.read(runProvider).mapNodes, isNot(same(mapBefore)));
      expect(container.read(runProvider).currentNodeId, isNull);
      expect(container.read(debugTaintProvider), isTrue);
    });
  });

  group('DebugActions — deck et reliques', () {
    const strike = CardData(
      id: 'strike_basic',
      nameEn: 'Strike',
      nameFr: 'Frappe',
      descriptionEn: 'Deals 6 damage.',
      descriptionFr: 'Inflige 6 degats.',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [CardEffect(type: 'damage', value: 6)],
    );

    test('addCard ajoute une instance au deck maitre et contamine', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      expect(container.read(deckProvider).masterDeck, isEmpty);

      DebugActions.addCard(container.read, strike);

      expect(container.read(deckProvider).masterDeck.length, 1);
      expect(
        container.read(deckProvider).masterDeck.first.data.id,
        'strike_basic',
      );
      expect(container.read(debugTaintProvider), isTrue);
    });

    test('removeCard retire exactement l instance visee', () {
      final container = _startedRun();
      addTearDown(container.dispose);
      DebugActions.addCard(container.read, strike);
      DebugActions.addCard(container.read, strike);
      final victim = container.read(deckProvider).masterDeck.first.uniqueId;

      DebugActions.removeCard(container.read, victim);

      final remaining = container.read(deckProvider).masterDeck;
      expect(remaining.length, 1);
      expect(remaining.first.uniqueId, isNot(victim));
    });
  });
}
