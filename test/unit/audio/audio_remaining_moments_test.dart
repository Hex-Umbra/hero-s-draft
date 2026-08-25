import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/audio_source.dart';
import 'package:roguelike_card_game/services/audio/game_moment.dart';

import 'fake_audio_backend.dart';

class _Source implements AudioSource {
  @override
  String? get sfx => null;
  @override
  final String? animation;

  const _Source({this.animation});
}

const _ids = <String>[
  'card_hover',
  'card_pickup',
  'card_play_generic',
  'card_play_magic',
  'enemy_attack',
  'enemy_death',
  'card_draw',
  'mana_gain',
  'insufficient_mana',
  'turn_start',
  'turn_end',
];

AudioData _catalogue() => AudioData.fromJson({
      'schemaVersion': 1,
      'sounds': {
        for (final id in _ids) id: {'file': 'sfx/$id.mp3'},
      },
      'moments': {
        'card_hover': {'default': 'card_hover'},
        'card_pickup': {'default': 'card_pickup'},
        'card_play': {
          'default': 'card_play_generic',
          'byAnimation': {'magic': 'card_play_magic'},
        },
        'enemy_attack': {'default': 'enemy_attack'},
        'enemy_death': {'default': 'enemy_death'},
        'card_draw': {'default': 'card_draw'},
        'mana_gain': {'default': 'mana_gain'},
        'insufficient_mana': {'default': 'insufficient_mana'},
        'turn_start': {'default': 'turn_start'},
        'turn_end': {'default': 'turn_end'},
      },
      'music': <String, dynamic>{},
    });

void main() {
  group('Les dix moments restants', () {
    late FakeAudioBackend backend;
    late AudioDirector director;

    setUp(() async {
      backend = FakeAudioBackend();
      director = AudioDirector(
        backend: backend,
        data: _catalogue(),
        settings: () => const AudioSettings(master: 1.0, sfx: 1.0),
      );
      await director.preloadAll();
    });

    test('chaque moment systemique resout vers son son', () {
      director.onMoment(GameMoment.cardHover);
      director.onMoment(GameMoment.cardPickup);
      director.onMoment(GameMoment.enemyAttack);
      director.onMoment(GameMoment.enemyDeath);
      director.onMoment(GameMoment.cardDraw);
      director.onMoment(GameMoment.manaGain);
      director.onMoment(GameMoment.insufficientMana);
      director.onMoment(GameMoment.turnStart);
      director.onMoment(GameMoment.turnEnd);

      expect(backend.playedOnce, [
        'sfx/card_hover.mp3',
        'sfx/card_pickup.mp3',
        'sfx/enemy_attack.mp3',
        'sfx/enemy_death.mp3',
        'sfx/card_draw.mp3',
        'sfx/mana_gain.mp3',
        'sfx/insufficient_mana.mp3',
        'sfx/turn_start.mp3',
        'sfx/turn_end.mp3',
      ]);
    });

    test('cardPlay resout par le type d animation de la carte', () {
      director.onMoment(GameMoment.cardPlay, source: const _Source(animation: 'magic'));

      expect(backend.playedOnce, ['sfx/card_play_magic.mp3']);
    });

    test('cardPlay sans animation connue retombe sur le generique', () {
      director.onMoment(GameMoment.cardPlay, source: const _Source(animation: 'inconnu'));

      expect(backend.playedOnce, ['sfx/card_play_generic.mp3']);
    });
  });
}
