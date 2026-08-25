import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/game_moment.dart';
import 'package:roguelike_card_game/services/audio/music_scene.dart';

Map<String, dynamic> _readJsonMap(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<dynamic> _readJsonList(String path) =>
    jsonDecode(File(path).readAsStringSync()) as List<dynamic>;

void main() {
  group('Coherence du catalogue audio', () {
    late AudioData audio;

    setUp(() {
      audio = AudioData.fromJson(_readJsonMap('assets/data/audio.json'));
    });

    test('tout son reference par un moment est declare', () {
      final referenced = <String>{};
      for (final moment in audio.moments.values) {
        if (moment.defaultSound != null) referenced.add(moment.defaultSound!);
        referenced.addAll(moment.byAnimation.values);
      }

      final unknown = referenced.difference(audio.sounds.keys.toSet());

      expect(unknown, isEmpty,
          reason: 'Sons references par un moment mais absents de "sounds" : $unknown');
    });

    test('tout champ sfx d un JSON de contenu correspond a un son declare', () {
      const contentFiles = [
        'assets/data/cards.json',
        'assets/data/hero_cards.json',
        'assets/data/enemies.json',
        'assets/data/relics.json',
      ];

      final declared = audio.sounds.keys.toSet();
      final offenders = <String>[];

      for (final path in contentFiles) {
        for (final entry in _readJsonList(path)) {
          final map = entry as Map<String, dynamic>;
          final sfx = map['sfx'] as String?;
          if (sfx != null && !declared.contains(sfx)) {
            offenders.add('$path :: ${map['id']} -> "$sfx"');
          }
        }
      }

      expect(offenders, isEmpty,
          reason: 'Champs sfx pointant vers un son non declare :\n${offenders.join('\n')}');
    });

    test('tout GameMoment a une entree dans "moments"', () {
      final declared = audio.moments.keys.toSet();
      final missing = GameMoment.values
          .map((moment) => moment.jsonKey)
          .where((jsonKey) => !declared.contains(jsonKey))
          .toList();

      expect(missing, isEmpty,
          reason: 'GameMoment sans entree "moments" dans audio.json (silence '
              'permanent, sans erreur) : $missing');
    });

    test('toute MusicScene a une entree dans "music"', () {
      final declared = audio.music.keys.toSet();
      final missing = MusicScene.values
          .map((scene) => scene.jsonKey)
          .where((jsonKey) => !declared.contains(jsonKey))
          .toList();

      expect(missing, isEmpty,
          reason: 'MusicScene sans entree "music" dans audio.json (silence '
              'permanent, sans erreur) : $missing');
    });
  });
}
