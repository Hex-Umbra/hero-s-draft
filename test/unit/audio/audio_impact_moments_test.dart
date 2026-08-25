import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/game_moment.dart';

import 'fake_audio_backend.dart';

AudioData _catalogue() => AudioData.fromJson({
      'schemaVersion': 1,
      'sounds': {
        'impact_normal': {'file': 'sfx/impact_normal.mp3'},
        'impact_crit': {'file': 'sfx/impact_crit.mp3'},
        'armor_hit': {'file': 'sfx/armor_hit.mp3'},
        'heal': {'file': 'sfx/heal.mp3'},
      },
      'moments': {
        'impact': {'default': 'impact_normal'},
        'impact_crit': {'default': 'impact_crit'},
        'armor_hit': {'default': 'armor_hit'},
        'heal': {'default': 'heal'},
      },
      'music': <String, dynamic>{},
    });

void main() {
  group('Moments d impact', () {
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

    test('les quatre moments d impact resolvent chacun vers leur son', () {
      director.onMoment(GameMoment.impact);
      director.onMoment(GameMoment.impactCrit);
      director.onMoment(GameMoment.armorHit);
      director.onMoment(GameMoment.heal);

      expect(backend.playedOnce, [
        'sfx/impact_normal.mp3',
        'sfx/impact_crit.mp3',
        'sfx/armor_hit.mp3',
        'sfx/heal.mp3',
      ]);
    });
  });
}
