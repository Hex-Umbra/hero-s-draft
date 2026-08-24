import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/services/audio/audio_providers.dart';
import 'package:roguelike_card_game/services/audio/silent_audio_backend.dart';

void main() {
  group('AudioBackend', () {
    test('le backend par defaut est silencieux', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final backend = container.read(audioBackendProvider);

      expect(backend, isA<SilentAudioBackend>());
    });

    test('le backend silencieux ne leve jamais et precharge avec succes', () async {
      const backend = SilentAudioBackend();

      await expectLater(backend.preload('sfx/absent.mp3'), completion(isTrue));
      expect(() => backend.playOnce('sfx/absent.mp3'), returnsNormally);
      await expectLater(backend.playLoop('music/absent.mp3'), completes);
      await expectLater(backend.stopLoop(), completes);
    });
  });
}
