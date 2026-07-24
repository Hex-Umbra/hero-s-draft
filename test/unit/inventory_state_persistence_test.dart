import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/inventory_state.dart';
import 'package:roguelike_card_game/models/missing_save_item.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

void main() {
  group('InventoryState persistence', () {
    const kunai = RelicData(
      id: 'kunai',
      nameFr: 'Croc Kunaï',
      nameEn: 'Kunai Fang',
      trigger: RelicTrigger.onAttackPlayed,
      effectType: 'kunai_charge',
      value: 1,
      rarity: RelicRarity.rare,
      emoji: '🗡️',
    );

    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        skills: [],
        cards: [],
        events: [],
        passives: [],
        relics: [kunai],
        forgeUpgrades: [],
      );
    });

    test('toJson/fromJsonWithReport round-trips gold, relics and bonusShopCards', () {
      const state = InventoryState(
        gold: 120,
        relics: [kunai],
        bonusShopCards: 2,
      );

      final json = state.toJson();
      final (restored, missing) = InventoryState.fromJsonWithReport(json);

      expect(restored.gold, 120);
      expect(restored.bonusShopCards, 2);
      expect(restored.relics.map((r) => r.id), ['kunai']);
      expect(missing, isEmpty);
    });

    test('drops a relic whose id no longer resolves and reports it', () {
      final json = {
        'gold': 50,
        'relics': [
          {'id': 'kunai', 'nameFr': 'Croc Kunaï', 'nameEn': 'Kunai Fang'},
          {'id': 'removed_relic', 'nameFr': 'Vieille Amulette', 'nameEn': 'Old Amulet'},
        ],
        'bonusShopCards': 0,
      };

      final (restored, missing) = InventoryState.fromJsonWithReport(json);

      expect(restored.relics.map((r) => r.id), ['kunai']);
      expect(missing, [
        const MissingSaveItem(
          id: 'removed_relic',
          nameFr: 'Vieille Amulette',
          nameEn: 'Old Amulet',
          category: 'relic',
        ),
      ]);
    });
  });
}
