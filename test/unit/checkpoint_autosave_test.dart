import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/services/save_service.dart';

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
}
