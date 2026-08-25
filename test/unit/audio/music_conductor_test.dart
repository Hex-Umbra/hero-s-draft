import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/music_conductor.dart';
import 'package:roguelike_card_game/services/audio/music_scene.dart';

import 'fake_audio_backend.dart';

AudioData _catalogue() => AudioData.fromJson({
      'schemaVersion': 1,
      'sounds': <String, dynamic>{},
      'moments': <String, dynamic>{},
      'music': {
        'menu': {'file': 'music/menu.mp3', 'volume': 0.6},
        'map': {'file': 'music/map.mp3'},
        'combat': {'file': 'music/combat.mp3'},
      },
    });

MusicConductor _conductor(FakeAudioBackend backend, {bool locked = false}) =>
    MusicConductor(
      backend: backend,
      data: _catalogue(),
      settings: () => const AudioSettings(master: 1.0, music: 1.0),
      locked: locked,
    );

void main() {
  group('MusicConductor', () {
    late FakeAudioBackend backend;

    setUp(() => backend = FakeAudioBackend());

    test('une scene demarre sa piste au volume declare', () {
      _conductor(backend).onScene(MusicScene.menu);

      expect(backend.currentLoop, 'music/menu.mp3');
      expect(backend.loopStartCount, 1);
      expect(backend.currentLoopVolume, closeTo(0.6, 0.0001),
          reason: 'volume de la piste (0.6) x general (1.0) x musique (1.0)');
    });

    test('redemander la scene en cours est un no-op', () {
      final conductor = _conductor(backend);

      conductor.onScene(MusicScene.menu);
      conductor.onScene(MusicScene.menu);
      conductor.onScene(MusicScene.menu);

      expect(backend.loopStartCount, 1,
          reason: 'naviguer entre deux ecrans du meme groupe ne redemarre pas la musique');
    });

    test('changer de scene remplace la piste', () {
      final conductor = _conductor(backend);

      conductor.onScene(MusicScene.menu);
      conductor.onScene(MusicScene.combat);

      expect(backend.currentLoop, 'music/combat.mp3');
      expect(backend.loopStartCount, 2);
    });

    test('une scene sans piste declaree ne casse rien', () {
      final conductor = _conductor(backend);

      conductor.onScene(MusicScene.menu);
      expect(() => conductor.onScene(MusicScene.boss), returnsNormally);
      expect(backend.currentLoop, 'music/menu.mp3',
          reason: 'faute de piste de boss, la precedente continue');
    });

    test('verrouille, aucune piste ne demarre', () {
      _conductor(backend, locked: true).onScene(MusicScene.menu);

      expect(backend.currentLoop, isNull);
    });

    test('le deverrouillage demarre la scene en attente', () {
      final conductor = _conductor(backend, locked: true);

      conductor.onScene(MusicScene.map);
      expect(backend.currentLoop, isNull);

      conductor.unlock();

      expect(backend.currentLoop, 'music/map.mp3');
    });

    test('le deverrouillage sans scene en attente ne joue rien', () {
      final conductor = _conductor(backend, locked: true);

      conductor.unlock();

      expect(backend.currentLoop, isNull);
    });

    test('la coupure arrete la piste en cours', () async {
      var muted = false;
      final conductor = MusicConductor(
        backend: backend,
        data: _catalogue(),
        settings: () => AudioSettings(master: 1.0, music: 1.0, muted: muted),
      );

      conductor.onScene(MusicScene.menu);
      expect(backend.currentLoop, 'music/menu.mp3');

      muted = true;
      await conductor.refreshVolume();

      expect(backend.currentLoop, isNull);
    });
  });
}
