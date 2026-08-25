import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';

void main() {
  group('AudioData', () {
    test('parse un catalogue complet', () {
      final data = AudioData.fromJson({
        'schemaVersion': 1,
        'sounds': {
          'impact_normal': {
            'file': 'sfx/impact_normal.mp3',
            'volume': 0.8,
            'variants': 3,
          },
          'card_play_fire': {'file': 'sfx/card_play_fire.mp3'},
        },
        'moments': {
          'card_play': {
            'default': 'card_play_generic',
            'byAnimation': {'fire': 'card_play_fire'},
          },
          'impact': {'default': 'impact_normal'},
        },
        'music': {
          'menu': {'file': 'music/menu.mp3'},
        },
      });

      expect(data.enabled, isTrue);
      expect(data.sounds['impact_normal']!.volume, 0.8);
      expect(data.sounds['impact_normal']!.variants, 3);
      expect(data.sounds['card_play_fire']!.volume, 1.0);
      expect(data.sounds['card_play_fire']!.variants, 1);
      expect(data.moments['card_play']!.byAnimation['fire'], 'card_play_fire');
      expect(data.moments['impact']!.defaultSound, 'impact_normal');
      expect(data.music['menu']!.file, 'music/menu.mp3');
    });

    test('un catalogue desactive est vide et jamais nul', () {
      const data = AudioData.disabled();

      expect(data.enabled, isFalse);
      expect(data.sounds, isEmpty);
      expect(data.moments, isEmpty);
      expect(data.music, isEmpty);
    });

    test('un moment sans defaut ni variantes reste lisible', () {
      final data = AudioData.fromJson({
        'schemaVersion': 1,
        'sounds': <String, dynamic>{},
        'moments': {'turn_start': <String, dynamic>{}},
        'music': <String, dynamic>{},
      });

      expect(data.moments['turn_start']!.defaultSound, isNull);
      expect(data.moments['turn_start']!.byAnimation, isEmpty);
    });
  });

  group('SoundData.expectedFiles', () {
    test('sans variante declaree, un seul fichier attendu', () {
      const sound = SoundData(file: 'sfx/hover.mp3');

      expect(sound.expectedFiles, ['sfx/hover.mp3']);
    });

    test('les variantes sont numerotees avant l extension', () {
      const sound = SoundData(file: 'sfx/x.mp3', variants: 3);

      expect(sound.expectedFiles, ['sfx/x_1.mp3', 'sfx/x_2.mp3', 'sfx/x_3.mp3']);
    });

    test('un nom sans extension recoit le suffixe sans lever', () {
      const sound = SoundData(file: 'sfx/x', variants: 2);

      expect(() => sound.expectedFiles, returnsNormally);
      expect(sound.expectedFiles, ['sfx/x_1', 'sfx/x_2']);
    });
  });
}
