import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';

/// Ce test ne verifie rien : il **rapporte**. C'est le tableau de bord du
/// sourcing, deliberement incapable de rougir la CI. Un catalogue troue est
/// l'etat normal du projet pendant tout le chantier P-03.
void main() {
  test('rapport de sourcing : fichiers declares mais absents du disque', () {
    final audio = AudioData.fromJson(
      jsonDecode(File('assets/data/audio.json').readAsStringSync()) as Map<String, dynamic>,
    );

    final expected = <String>[];
    for (final sound in audio.sounds.values) {
      if (sound.variants <= 1) {
        expected.add(sound.file);
      } else {
        final dot = sound.file.lastIndexOf('.');
        for (var i = 1; i <= sound.variants; i++) {
          expected.add('${sound.file.substring(0, dot)}_$i${sound.file.substring(dot)}');
        }
      }
    }
    expected.addAll(audio.music.values.map((m) => m.file));

    final missing =
        expected.where((f) => !File('assets/audio/$f').existsSync()).toList()..sort();
    final present = expected.length - missing.length;

    debugPrint('');
    debugPrint('===== SOURCING AUDIO : $present / ${expected.length} fichiers presents =====');
    if (missing.isEmpty) {
      debugPrint('Catalogue complet.');
    } else {
      for (final file in missing) {
        debugPrint('  manquant : assets/audio/$file');
      }
    }
    debugPrint('=========================================================');

    // Aucune assertion : ce test reussit toujours, par construction.
  });
}
