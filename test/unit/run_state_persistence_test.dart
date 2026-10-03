import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/missing_save_item.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

void main() {
  group('RunState persistence', () {
    const regenArmor = PassiveData(
      id: 'regen_armor',
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
        cards: [],
        events: [],
        passives: [regenArmor],
        relics: [],
        forgeUpgrades: [],
      );
    });

    RunState buildRunState() => RunState(
          currentLevel: 5,
          act: 2,
          heroClassId: 'paladin',
          activePassive: regenArmor,
          heroStats: EntityStats(
            maxPv: 80,
            currentPv: 60,
            maxMana: 4,
            currentMana: 4,
            armure: 0,
            might: 0,
          ),
          mapNodes: const [],
          currentNodeId: 'floor_3_node_1',
          pendingDrafts: 2,
          cardsPerTurn: 7,
        );

    test('toJson/fromJsonWithReport round-trips every field', () {
      final json = buildRunState().toJson();
      final (restored, missing) = RunState.fromJsonWithReport(json);

      expect(restored.currentLevel, 5);
      expect(restored.act, 2);
      expect(restored.heroClassId, 'paladin');
      expect(restored.activePassive?.id, 'regen_armor');
      expect(restored.heroStats.currentPv, 60);
      expect(restored.currentNodeId, 'floor_3_node_1');
      expect(restored.pendingDrafts, 2);
      expect(missing, isEmpty);
    });

    test('cardsPerTurn round-trip et vaut 5 sur une sauvegarde antérieure', () {
      final json = buildRunState().toJson();
      expect(json['cardsPerTurn'], 7);

      final (restored, _) = RunState.fromJsonWithReport(json);
      expect(restored.cardsPerTurn, 7);

      final legacy = Map<String, dynamic>.from(json)..remove('cardsPerTurn');
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.cardsPerTurn, 5);
    });

    // La main maximale, stat de run (spec P-43 E3, §4.3, §8).
    test('maxHandSize round-trip et vaut la main de depart quand la cle '
        'manque', () {
      final json = buildRunState().copyWith(maxHandSize: 7).toJson();
      expect(json['maxHandSize'], 7);

      final (restored, _) = RunState.fromJsonWithReport(json);
      expect(restored.maxHandSize, 7);

      final legacy = Map<String, dynamic>.from(json)..remove('maxHandSize');
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.maxHandSize, GameConstants.startingMaxHandSize);
    });

    test('leaves activePassive null and reports a missing passive', () {
      final json = buildRunState().toJson();
      json['activePassiveId'] = 'removed_passive';
      json['activePassiveNameFr'] = 'Passif Retiré';
      json['activePassiveNameEn'] = 'Removed Passive';

      final (restored, missing) = RunState.fromJsonWithReport(json);

      expect(restored.activePassive, isNull);
      expect(missing, [
        const MissingSaveItem(
          id: 'removed_passive',
          nameFr: 'Passif Retiré',
          nameEn: 'Removed Passive',
          category: 'passive',
        ),
      ]);
    });
  });
}
