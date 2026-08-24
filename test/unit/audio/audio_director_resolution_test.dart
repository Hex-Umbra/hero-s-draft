import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/audio_source.dart';
import 'package:roguelike_card_game/services/audio/game_moment.dart';

import 'fake_audio_backend.dart';

class _Source implements AudioSource {
  @override
  final String? sfx;
  @override
  final String? animation;

  const _Source({this.sfx, this.animation});
}

AudioData _catalogue() => AudioData.fromJson({
      'schemaVersion': 1,
      'sounds': {
        'propre': {'file': 'sfx/propre.mp3'},
        'feu': {'file': 'sfx/feu.mp3'},
        'generique': {'file': 'sfx/generique.mp3'},
      },
      'moments': {
        'card_play': {
          'default': 'generique',
          'byAnimation': {'fire': 'feu'},
        },
        'turn_start': <String, dynamic>{},
      },
      'music': <String, dynamic>{},
    });

Future<AudioDirector> _director(FakeAudioBackend backend) async {
  final director = AudioDirector(
    backend: backend,
    data: _catalogue(),
    settings: () => const AudioSettings(master: 1.0, sfx: 1.0),
    random: Random(42),
  );
  await director.preloadAll();
  return director;
}

void main() {
  group('AudioDirector — chaine de repli', () {
    late FakeAudioBackend backend;

    setUp(() => backend = FakeAudioBackend());

    test('niveau 1 : le champ sfx de la source prime sur tout', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.cardPlay,
          source: const _Source(sfx: 'propre', animation: 'fire'));

      expect(backend.playedOnce, ['sfx/propre.mp3']);
    });

    test('niveau 2 : a defaut, le type d animation de la source', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.cardPlay, source: const _Source(animation: 'fire'));

      expect(backend.playedOnce, ['sfx/feu.mp3']);
    });

    test('niveau 3 : a defaut, le son par defaut du moment', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.cardPlay, source: const _Source(animation: 'inconnu'));

      expect(backend.playedOnce, ['sfx/generique.mp3']);
    });

    test('niveau 3 : un moment systemique sans source prend le defaut', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.cardPlay);

      expect(backend.playedOnce, ['sfx/generique.mp3']);
    });

    test('niveau 4 : un moment sans defaut se resout en silence', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.turnStart);

      expect(backend.playedOnce, isEmpty);
    });

    test('niveau 4 : un moment absent du catalogue se resout en silence', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.enemyDeath);

      expect(backend.playedOnce, isEmpty);
    });

    test('un sfx pointant vers un son inconnu retombe sur le niveau suivant', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.cardPlay,
          source: const _Source(sfx: 'inexistant', animation: 'fire'));

      expect(backend.playedOnce, ['sfx/feu.mp3']);
    });

    test('la coupure globale rend silencieux', () async {
      final director = AudioDirector(
        backend: backend,
        data: _catalogue(),
        settings: () => const AudioSettings(muted: true),
        random: Random(42),
      );
      await director.preloadAll();

      director.onMoment(GameMoment.cardPlay);

      expect(backend.playedOnce, isEmpty);
    });

    test('le volume du son est multiplie par le volume des bruitages', () async {
      final director = AudioDirector(
        backend: backend,
        data: AudioData.fromJson({
          'schemaVersion': 1,
          'sounds': {
            'generique': {'file': 'sfx/generique.mp3', 'volume': 0.8},
          },
          'moments': {
            'card_play': {'default': 'generique'},
          },
          'music': <String, dynamic>{},
        }),
        settings: () => const AudioSettings(master: 1.0, sfx: 0.5),
        random: Random(42),
      );
      await director.preloadAll();

      director.onMoment(GameMoment.cardPlay);

      expect(backend.playedVolumes.single, closeTo(0.4, 0.0001));
    });
  });
}
