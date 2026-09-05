import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/game_moment.dart';
import 'package:roguelike_card_game/services/audio/music_scene.dart';

Map<String, dynamic> _readJsonMap(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

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
      // Les catalogues ont ete eclates : on parcourt l arborescence plutot
      // que d enumerer des chemins. Les entites qui peuvent porter un `sfx`
      // sont les cartes (neutres et de classe), les ennemis et les reliques ;
      // `AudioSource` n est implemente que par ces trois modeles.
      final contentFiles = [
        ...Directory('assets/data/cards').listSync().whereType<File>(),
        ...Directory('assets/data/relics').listSync().whereType<File>(),
        ...Directory('assets/data/classes')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.replaceAll(r'\', '/').contains('/cards/')),
        ...Directory('assets/data/enemies')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('enemy.json')),
      ].where((f) => f.path.endsWith('.json'));

      expect(contentFiles.length, 52,
          reason: '17 cartes + 25 reliques + 6 cartes de classe + 4 ennemis');

      final declared = audio.sounds.keys.toSet();
      final offenders = <String>[];

      for (final file in contentFiles) {
        final map =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final sfx = map['sfx'] as String?;
        if (sfx != null && !declared.contains(sfx)) {
          offenders.add('${file.path} :: ${map['id']} -> "$sfx"');
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
