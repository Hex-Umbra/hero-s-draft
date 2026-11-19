import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/game/controllers/debug_run_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/services/save_service.dart';

const paladin = HeroData(
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

void main() {
  group('Checkpoint autosave', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('bump() triggers exactly one save', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Force the orchestrator to start listening.
      container.read(autosaveOrchestratorProvider);

      expect(await SaveService.hasSave(), isFalse);

      container.read(checkpointProvider.notifier).bump();
      // Allow the async SaveService.save() Future kicked off by the listener to complete.
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isTrue);
    });

    test('two bumps still result in a single valid save (no crash on rapid succession)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(autosaveOrchestratorProvider);

      container.read(checkpointProvider.notifier).bump();
      container.read(checkpointProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isTrue);
    });
  });

  group('La mort du heros efface la sauvegarde', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    /// L'orchestrateur actif, une vraie partie sur le disque — le checkpoint
    /// d'avant combat —, puis une run lancee, debug ou non.
    Future<ProviderContainer> savedRun({bool debug = false}) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(autosaveOrchestratorProvider);
      await SaveService.save(container.read);
      expect(await SaveService.hasSave(), isTrue);

      if (debug) container.read(debugRunProvider.notifier).requestDebugRun();
      container.read(runProvider.notifier).startNewRun(paladin);
      return container;
    }

    test('des degats mortels effacent la sauvegarde, sans attendre de clic', () async {
      final container = await savedRun();

      container.read(runProvider.notifier).takeDamage(100);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(runProvider).isDead, isTrue);
      expect(await SaveService.hasSave(), isFalse);
    });

    test('des PV ecrits a 0 hors des degats (statut, ecriture directe) l effacent aussi', () async {
      final container = await savedRun();

      container
          .read(runProvider.notifier)
          .updateHeroStats((s) => s.copyWith(currentPv: 0));
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isFalse);
    });

    test('des degats qui laissent des PV gardent la sauvegarde', () async {
      final container = await savedRun();

      container.read(runProvider.notifier).takeDamage(99);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(runProvider).heroStats.currentPv, 1);
      expect(await SaveService.hasSave(), isTrue);
    });

    test('un checkpoint pris apres la mort ne recree pas la sauvegarde', () async {
      final container = await savedRun();

      container.read(runProvider.notifier).takeDamage(100);
      await Future<void>.delayed(Duration.zero);
      container.read(checkpointProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isFalse);
    });

    test('la mort d une run debug n efface pas la vraie partie', () async {
      final container = await savedRun(debug: true);
      expect(container.read(debugRunProvider).isDebugRun, isTrue);

      container.read(runProvider.notifier).takeDamage(100);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(runProvider).isDead, isTrue);
      expect(await SaveService.hasSave(), isTrue);
    });
  });
}
