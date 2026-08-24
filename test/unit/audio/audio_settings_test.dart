import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/services/audio/audio_providers.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioSettings', () {
    test('le volume effectif est le produit du general et de la categorie', () {
      const settings = AudioSettings(master: 0.5, sfx: 0.8, music: 0.6);

      expect(settings.effectiveSfx, closeTo(0.4, 0.0001));
      expect(settings.effectiveMusic, closeTo(0.3, 0.0001));
    });

    test('la coupure prime sur les deux volumes', () {
      const settings = AudioSettings(master: 1.0, sfx: 1.0, music: 1.0, muted: true);

      expect(settings.effectiveSfx, 0.0);
      expect(settings.effectiveMusic, 0.0);
    });
  });

  group('SettingsService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('aller-retour de persistance', () async {
      const written = AudioSettings(master: 0.3, sfx: 0.4, music: 0.5, muted: true);

      await SettingsService.save(written);
      final read = await SettingsService.load();

      expect(read.master, closeTo(0.3, 0.0001));
      expect(read.sfx, closeTo(0.4, 0.0001));
      expect(read.music, closeTo(0.5, 0.0001));
      expect(read.muted, isTrue);
    });

    test('sans reglage enregistre, retourne les defauts', () async {
      final read = await SettingsService.load();

      expect(read, const AudioSettings());
    });

    test('un JSON corrompu retombe silencieusement sur les defauts', () async {
      SharedPreferences.setMockInitialValues({'settings_v1': 'ceci n est pas du json'});

      final read = await SettingsService.load();

      expect(read, const AudioSettings());
    });

    test('une version de schema inconnue retombe sur les defauts', () async {
      SharedPreferences.setMockInitialValues({
        'settings_v1': '{"schemaVersion": 99, "master": 0.1}',
      });

      final read = await SettingsService.load();

      expect(read, const AudioSettings());
    });
  });

  group('AudioSettingsNotifier', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('la coupure bascule et se persiste', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(audioSettingsProvider.notifier);

      expect(container.read(audioSettingsProvider).muted, isFalse);

      notifier.toggleMute();
      expect(container.read(audioSettingsProvider).muted, isTrue);

      final persisted = await SettingsService.load();
      expect(persisted.muted, isTrue);
    });
  });
}
