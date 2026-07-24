import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/missing_save_item.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

void main() {
  group('MissingSaveItem', () {
    test('two items with the same fields are equal', () {
      const a = MissingSaveItem(
        id: 'kunai',
        nameFr: 'Croc Kunaï',
        nameEn: 'Kunai Fang',
        category: 'relic',
      );
      const b = MissingSaveItem(
        id: 'kunai',
        nameFr: 'Croc Kunaï',
        nameEn: 'Kunai Fang',
        category: 'relic',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('Catalog getById helpers', () {
    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        skills: [],
        cards: [
          const CardData(
            id: 'strike_basic',
            cost: 1,
            type: CardType.attack,
            category: CardCategory.global,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            effects: [],
          ),
        ],
        events: [],
        passives: [
          const PassiveData(
            id: 'regenArmor',
            trigger: RelicTrigger.endOfTurn,
            effectType: 'gain_armor',
            value: 2,
          ),
        ],
        relics: [
          const RelicData(
            id: 'kunai',
            trigger: RelicTrigger.onAttackPlayed,
            effectType: 'kunai_charge',
            value: 1,
            rarity: RelicRarity.rare,
            emoji: '🗡️',
          ),
        ],
        forgeUpgrades: [],
      );
    });

    test('CardData.getById finds an existing card', () {
      expect(CardData.getById('strike_basic')?.id, 'strike_basic');
    });

    test('CardData.getById returns null for an unknown id', () {
      expect(CardData.getById('does_not_exist'), isNull);
    });

    test('RelicData.getById finds an existing relic', () {
      expect(RelicData.getById('kunai')?.id, 'kunai');
    });

    test('RelicData.getById returns null for an unknown id', () {
      expect(RelicData.getById('does_not_exist'), isNull);
    });

    test('PassiveData.getById finds an existing passive', () {
      expect(PassiveData.getById('regenArmor')?.id, 'regenArmor');
    });

    test('PassiveData.getById returns null for an unknown id', () {
      expect(PassiveData.getById('does_not_exist'), isNull);
    });
  });

  group('ForgeUpgradeData.filterValidRefs', () {
    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        skills: [],
        cards: [],
        events: [],
        passives: [],
        relics: [],
        forgeUpgrades: [
          const ForgeUpgradeData(
            id: 'enduring',
            nameEn: 'Enduring',
            nameFr: 'Increvable',
            descriptionEn: 'Never exhausts.',
            descriptionFr: "N'est jamais épuisée.",
            icon: 'shield_rounded',
            color: 'blueAccent',
            pools: ['common'],
          ),
        ],
      );
    });

    test('keeps refs whose id resolves and drops refs whose id does not', () {
      final (kept, missing) = ForgeUpgradeData.filterValidRefs([
        'enduring:1',
        'removed_upgrade:2',
      ]);

      expect(kept, ['enduring:1']);
      expect(missing, [
        const MissingSaveItem(
          id: 'removed_upgrade',
          nameFr: 'removed_upgrade',
          nameEn: 'removed_upgrade',
          category: 'forgeUpgrade',
        ),
      ]);
    });

    test('handles a null input list gracefully', () {
      final (kept, missing) = ForgeUpgradeData.filterValidRefs(null);
      expect(kept, isEmpty);
      expect(missing, isEmpty);
    });
  });
}
