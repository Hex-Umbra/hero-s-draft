import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/missing_save_item.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

void main() {
  group('DeckState persistence', () {
    const strike = CardData(
      id: 'strike_basic',
      nameFr: 'Frappe',
      nameEn: 'Strike',
      cost: 1,
      type: CardType.attack,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [],
    );

    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        cards: [strike],
        events: [],
        passives: [],
        relics: [],
        forgeUpgrades: [
          const ForgeUpgradeData(
            id: 'sharp',
            nameEn: 'Sharp',
            nameFr: 'Tranchant',
            descriptionEn: '+{val} Damage',
            descriptionFr: '+{val} Dégâts',
            icon: 'hardware_rounded',
            color: 'redAccent',
          ),
        ],
      );
    });

    test('toJson/fromJsonWithReport round-trips piles and re-resolves fresh CardData', () {
      final card = CardInstance(
        uniqueId: 'card-1',
        data: strike,
        forgeUpgrades: const ['sharp:1'],
      );
      final state = DeckState(masterDeck: [card], drawPile: [card]);

      final json = state.toJson();
      final (restored, missing) = DeckState.fromJsonWithReport(json);

      expect(restored.masterDeck.single.uniqueId, 'card-1');
      expect(restored.masterDeck.single.data.id, 'strike_basic');
      expect(restored.masterDeck.single.forgeUpgrades, ['sharp:1']);
      expect(restored.drawPile.single.uniqueId, 'card-1');
      expect(missing, isEmpty);
    });

    test('une carte de lot a costs survit a l aller-retour de DeckState', () {
      const breach = CardData(
        id: 'breach',
        passive: 'regen_armor',
        cost: 0,
        armorCost: 4,
        type: CardType.attack,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      );
      GameDataRegistry(
        enemies: [],
        heroes: [],
        cards: [breach],
        events: [],
        passives: [],
        relics: [],
        forgeUpgrades: [],
      );
      final state = DeckState(
        masterDeck: [CardInstance(data: breach, rarity: CardRarity.rare)],
      );

      final (restored, missing) = DeckState.fromJsonWithReport(state.toJson());

      final card = restored.masterDeck.single;
      expect(missing, isEmpty);
      expect(
        (card.data.passive, card.data.cost, card.data.armorCost),
        ('regen_armor', 0, 4),
      );
      expect(card.rarity, CardRarity.rare);
    });

    test('drops a card whose CardData id no longer resolves and reports it', () {
      final removedCard = CardInstance(
        uniqueId: 'card-2',
        data: const CardData(
          id: 'removed_card',
          nameFr: 'Vieille Carte',
          nameEn: 'Old Card',
          cost: 1,
          type: CardType.attack,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: [],
        ),
      );
      final json = DeckState(masterDeck: [removedCard]).toJson();

      final (restored, missing) = DeckState.fromJsonWithReport(json);

      expect(restored.masterDeck, isEmpty);
      expect(missing, [
        const MissingSaveItem(
          id: 'removed_card',
          nameFr: 'Vieille Carte',
          nameEn: 'Old Card',
          category: 'card',
        ),
      ]);
    });

    test('drops a forge upgrade whose id no longer resolves and reports it, keeping the card', () {
      final card = CardInstance(
        uniqueId: 'card-3',
        data: strike,
        forgeUpgrades: const ['sharp:1', 'removed_upgrade:1'],
      );
      final json = DeckState(masterDeck: [card]).toJson();

      final (restored, missing) = DeckState.fromJsonWithReport(json);

      expect(restored.masterDeck.single.forgeUpgrades, ['sharp:1']);
      expect(missing, [
        const MissingSaveItem(
          id: 'removed_upgrade',
          nameFr: 'removed_upgrade',
          nameEn: 'removed_upgrade',
          category: 'forgeUpgrade',
        ),
      ]);
    });
  });
}
