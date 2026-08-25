import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../models/data/audio_data.dart';
import 'audio_backend.dart';
import 'audio_settings.dart';
import 'audio_source.dart';
import 'game_moment.dart';

/// Point d'entree unique du systeme audio.
///
/// Le code de jeu appelle [onMoment] avec un moment et, si elle existe,
/// l'entite a l'origine du moment. Le directeur resout, applique les
/// reglages, et delegue au backend. Aucun appelant ne connait jamais un
/// nom de fichier.
class AudioDirector {
  AudioDirector({
    required AudioBackend backend,
    required AudioData data,
    required AudioSettings Function() settings,
    Random? random,
  })  : _backend = backend,
        _data = data,
        _settings = settings,
        _random = random ?? Random();

  final AudioBackend _backend;
  final AudioData _data;
  final AudioSettings Function() _settings;
  final Random _random;

  final Set<String> _availableFiles = {};
  final Set<String> _reportedMissing = {};

  /// Precharge tout le catalogue. Volontairement `async` et jamais attendu
  /// par un ecran : un son demande avant la fin du prechargement est
  /// abandonne, pas mis en file.
  Future<void> preloadAll() async {
    if (!_data.enabled) return;
    for (final sound in _data.sounds.values) {
      for (final file in sound.expectedFiles) {
        final ok = await _backend.preload(file);
        if (ok) {
          _availableFiles.add(file);
        } else {
          _reportMissing(file);
        }
      }
    }
  }

  void onMoment(GameMoment moment, {AudioSource? source}) {
    if (!_data.enabled) return;

    final volumeScale = _settings().effectiveSfx;
    if (volumeScale <= 0) return;

    final soundId = _resolve(moment, source);
    if (soundId == null) return;

    final sound = _data.sounds[soundId];
    if (sound == null) return;

    final file = _pickFile(sound);
    if (!_availableFiles.contains(file)) return;

    _backend.playOnce(file, volume: sound.volume * volumeScale);
  }

  /// La chaine de repli, dans l'ordre : son propre a l'entite, son du type
  /// d'animation, son par defaut du moment, silence.
  String? _resolve(GameMoment moment, AudioSource? source) {
    final explicit = source?.sfx;
    if (explicit != null && _data.sounds.containsKey(explicit)) {
      return explicit;
    }

    final moments = _data.moments[moment.jsonKey];
    if (moments == null) return null;

    final animation = source?.animation;
    if (animation != null) {
      final byAnimation = moments.byAnimation[animation];
      if (byAnimation != null) return byAnimation;
    }

    return moments.defaultSound;
  }

  String _pickFile(SoundData sound) {
    final files = sound.expectedFiles;
    if (files.length == 1) return files.first;
    return files[_random.nextInt(files.length)];
  }

  void _reportMissing(String file) {
    if (!_reportedMissing.add(file)) return;
    debugPrint('[audio] fichier declare mais absent : $file');
  }
}
