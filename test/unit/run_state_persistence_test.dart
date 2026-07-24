import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/missing_save_item.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

void main() {
  group('RunState persistence', () {
    const regenArmor = PassiveData(
      id: 'regenArmor',
      nameFr: "Régénération d'Armure",
      nameEn: 'Armor Regeneration',
      trigger: RelicTrigger.endOfTurn,
      effectType: 'gain_armor',
      value: 2,
    );

    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        skills: [],
        cards: [],
        events: [],
        passives: [regenArmor],
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

    RunState buildRunState() => RunState(
          currentLevel: 5,
          act: 2,
          heroClassId: 'paladin',
          passiveTrait: 'regenArmor',
          activePassive: regenArmor,
          heroStats: EntityStats(
            maxPv: 80,
            currentPv: 60,
            maxMana: 4,
            currentMana: 4,
            armure: 0,
            attaque: 0,
          ),
          mapNodes: const [],
          currentNodeId: 'floor_3_node_1',
          forgeSlots: const ['enduring:1'],
          forgeTargetCardId: 'card-1',
          forgeTargetSessions: const {
            'card-1': ['enduring:1'],
          },
          bonusForgeSlots: 1,
          pendingDrafts: 2,
        );

    test('toJson/fromJsonWithReport round-trips every field', () {
      final json = buildRunState().toJson();
      final (restored, missing) = RunState.fromJsonWithReport(json);

      expect(restored.currentLevel, 5);
      expect(restored.act, 2);
      expect(restored.heroClassId, 'paladin');
      expect(restored.passiveTrait, 'regenArmor');
      expect(restored.activePassive?.id, 'regenArmor');
      expect(restored.heroStats.currentPv, 60);
      expect(restored.currentNodeId, 'floor_3_node_1');
      expect(restored.forgeSlots, ['enduring:1']);
      expect(restored.forgeTargetCardId, 'card-1');
      expect(restored.forgeTargetSessions, {
        'card-1': ['enduring:1'],
      });
      expect(restored.bonusForgeSlots, 1);
      expect(restored.pendingDrafts, 2);
      expect(missing, isEmpty);
    });

    test('falls back to PassiveData.fallback and reports a missing passive', () {
      final json = buildRunState().toJson();
      json['activePassiveId'] = 'removed_passive';
      json['activePassiveNameFr'] = 'Passif Retiré';
      json['activePassiveNameEn'] = 'Removed Passive';
      // Use an unrecognized passiveTrait too, so PassiveData.fallback has no
      // hardcoded match and genuinely falls through to its 'none' default
      // (passiveTrait: 'regenArmor' would otherwise itself be a known
      // fallback fixture and mask the "nothing to fall back to" case).
      json['passiveTrait'] = 'removed_passive';

      final (restored, missing) = RunState.fromJsonWithReport(json);

      expect(restored.activePassive?.id, 'none');
      expect(missing, [
        const MissingSaveItem(
          id: 'removed_passive',
          nameFr: 'Passif Retiré',
          nameEn: 'Removed Passive',
          category: 'passive',
        ),
      ]);
    });

    test('drops a missing forge upgrade id from forgeSlots and reports it', () {
      final json = buildRunState().toJson();
      json['forgeSlots'] = ['enduring:1', 'removed_upgrade:2'];

      final (restored, missing) = RunState.fromJsonWithReport(json);

      expect(restored.forgeSlots, ['enduring:1']);
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
