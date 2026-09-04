import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/services/save_service.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

void main() {
  group('SaveService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      // startNewRun's default hero passive ('regen_armor') round-trips through
      // RunState.fromJsonWithReport, which looks it up via
      // PassiveData.getById — that requires a populated GameDataRegistry,
      // exactly like test/unit/run_state_persistence_test.dart already sets
      // up for the same reason.
      GameDataRegistry(
        enemies: const [],
        heroes: const [],
        cards: const [],
        events: const [],
        passives: const [
          PassiveData(
            id: 'regen_armor',
            nameFr: "Régénération d'Armure",
            nameEn: 'Armor Regeneration',
            trigger: RelicTrigger.endOfTurn,
            effectType: 'gain_armor',
            value: 2,
          ),
        ],
        relics: const [],
        forgeUpgrades: const [],
      );
    });

    test('hasSave is false before any save exists', () async {
      expect(await SaveService.hasSave(), isFalse);
    });

    test('save then load round-trips run/inventory state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const dummyHero = HeroData(
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
      container.read(runProvider.notifier).startNewRun(dummyHero);
      container.read(inventoryProvider.notifier).gainGold(37);

      await SaveService.save(container.read);
      expect(await SaveService.hasSave(), isTrue);

      final freshContainer = ProviderContainer();
      addTearDown(freshContainer.dispose);
      final result = await SaveService.load(freshContainer.read);

      expect(result.success, isTrue);
      expect(result.missingItems, isEmpty);
      expect(freshContainer.read(runProvider).heroClassId, 'paladin');
      expect(freshContainer.read(inventoryProvider).gold, 87); // 50 starting + 37
    });

    test('a save still carrying a "skills" key loads without error', () async {
      // Saves written before the skill system was removed carry a 'skills'
      // key. Nothing writes it any more and nothing must read it — but an
      // existing save must keep loading rather than being wiped by the
      // catch-all in SaveService.load. This is the only behavioural guarantee
      // of the removal, so it is pinned here.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const dummyHero = HeroData(
        id: 'paladin',
        nameEn: 'Paladin',
        nameFr: 'Paladin',
        descriptionEn: 'A holy knight',
        descriptionFr: 'Un saint chevalier',
        iconPath: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        baseDamage: 5,
        passiveTrait: 'regen_armor',
      );
      container.read(runProvider.notifier).startNewRun(dummyHero);
      await SaveService.save(container.read);

      final prefs = await SharedPreferences.getInstance();
      final payload =
          jsonDecode(prefs.getString('run_save_v1')!) as Map<String, dynamic>;
      payload['skills'] = {'skill1Cooldown': 2, 'skill2Cooldown': 0};
      await prefs.setString('run_save_v1', jsonEncode(payload));

      final freshContainer = ProviderContainer();
      addTearDown(freshContainer.dispose);
      final result = await SaveService.load(freshContainer.read);

      expect(result.success, isTrue);
      expect(freshContainer.read(runProvider).heroClassId, 'paladin');
      expect(await SaveService.hasSave(), isTrue);
    });

    test('clear removes the save', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await SaveService.save(container.read);
      expect(await SaveService.hasSave(), isTrue);

      await SaveService.clear();
      expect(await SaveService.hasSave(), isFalse);
    });

    test('load returns a failed result and clears storage on corrupted JSON', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('run_save_v1', 'not valid json {{{');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = await SaveService.load(container.read);

      expect(result.success, isFalse);
      expect(await SaveService.hasSave(), isFalse);
    });

    test('load returns a failed result on an unknown schemaVersion', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'run_save_v1',
        '{"schemaVersion": 999, "run": {}, "deck": {}, "inventory": {}, "skills": {}}',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = await SaveService.load(container.read);

      expect(result.success, isFalse);
      expect(await SaveService.hasSave(), isFalse);
    });
  });
}
