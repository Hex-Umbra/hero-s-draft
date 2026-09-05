import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/game/controllers/debug_taint_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/services/save_service.dart';

void main() {
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

  group('Drapeau de contamination debug', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('une session neuve part non contaminee', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(debugTaintProvider), isFalse);
    });

    test('drapeau leve : un checkpoint ne declenche aucune sauvegarde', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(autosaveOrchestratorProvider);

      container.read(debugTaintProvider.notifier).taint();
      container.read(checkpointProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isFalse);
    });

    test('startNewRun rabaisse le drapeau et l autosave reprend', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(autosaveOrchestratorProvider);

      container.read(debugTaintProvider.notifier).taint();
      container.read(runProvider.notifier).startNewRun(paladin);
      expect(container.read(debugTaintProvider), isFalse);

      container.read(checkpointProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isTrue);
    });

    test('drapeau baisse : le comportement d autosave existant est intact', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(autosaveOrchestratorProvider);

      container.read(checkpointProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isTrue);
    });
  });
}
