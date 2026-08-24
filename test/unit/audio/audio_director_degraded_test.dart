import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/game_moment.dart';

import 'fake_audio_backend.dart';

AudioData _catalogue() => AudioData.fromJson({
      'schemaVersion': 1,
      'sounds': {
        'present': {'file': 'sfx/present.mp3'},
        'absent': {'file': 'sfx/absent.mp3'},
        'varie': {'file': 'sfx/varie.mp3', 'variants': 3},
      },
      'moments': {
        'impact': {'default': 'present'},
        'heal': {'default': 'absent'},
        'card_draw': {'default': 'varie'},
      },
      'music': <String, dynamic>{},
    });

AudioDirector _director(FakeAudioBackend backend, {AudioData? data}) => AudioDirector(
      backend: backend,
      data: data ?? _catalogue(),
      settings: () => const AudioSettings(master: 1.0, sfx: 1.0),
      random: Random(7),
    );

void main() {
  group('AudioDirector — mode degrade', () {
    late FakeAudioBackend backend;

    setUp(() => backend = FakeAudioBackend());

    test('un fichier absent rend le moment silencieux, sans exception', () async {
      backend.missingFiles.add('sfx/absent.mp3');
      final director = _director(backend);
      await director.preloadAll();

      expect(() => director.onMoment(GameMoment.heal), returnsNormally);
      expect(backend.playedOnce, isEmpty);
    });

    test('un fichier absent n empeche pas les autres de jouer', () async {
      backend.missingFiles.add('sfx/absent.mp3');
      final director = _director(backend);
      await director.preloadAll();

      director.onMoment(GameMoment.impact);

      expect(backend.playedOnce, ['sfx/present.mp3']);
    });

    test('un catalogue desactive rend tout silencieux sans lever', () async {
      final director = _director(backend, data: const AudioData.disabled());
      await director.preloadAll();

      expect(() => director.onMoment(GameMoment.impact), returnsNormally);
      expect(backend.playedOnce, isEmpty);
      expect(backend.preloadAttempts, isEmpty);
    });

    test('jouer avant la fin du prechargement est silencieux, pas mis en file', () async {
      final director = _director(backend);

      director.onMoment(GameMoment.impact);
      expect(backend.playedOnce, isEmpty);

      await director.preloadAll();
      expect(backend.playedOnce, isEmpty,
          reason: 'le son demande trop tot est abandonne, jamais rejoue');
    });

    test('les variantes sont toutes prechargees et une seule est jouee', () async {
      final director = _director(backend);
      await director.preloadAll();

      director.onMoment(GameMoment.cardDraw);

      expect(
        backend.preloadAttempts,
        containsAll(['sfx/varie_1.mp3', 'sfx/varie_2.mp3', 'sfx/varie_3.mp3']),
      );
      expect(backend.playedOnce, hasLength(1));
      expect(backend.playedOnce.single, matches(r'^sfx/varie_[123]\.mp3$'));
    });
  });
}
