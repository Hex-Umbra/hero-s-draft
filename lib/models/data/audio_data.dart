/// Un son declare dans `assets/data/audio.json`.
///
/// [variants] > 1 declare N fichiers numerotes derives de [file] :
/// `sfx/impact.mp3` avec `variants: 3` designe `sfx/impact_1.mp3`,
/// `_2` et `_3`, tires au hasard a chaque lecture pour casser la repetition.
class SoundData {
  final String file;
  final double volume;
  final int variants;

  const SoundData({required this.file, this.volume = 1.0, this.variants = 1});

  factory SoundData.fromJson(Map<String, dynamic> json) => SoundData(
    file: json['file'] as String,
    volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
    variants: (json['variants'] as num?)?.toInt() ?? 1,
  );
}

/// Les sons possibles pour un moment de jeu : un repli par type d'animation,
/// et un defaut. Les deux sont optionnels — un moment sans aucun des deux
/// se resout en silence, ce qui est un etat normal pendant le sourcing.
class MomentSounds {
  final String? defaultSound;
  final Map<String, String> byAnimation;

  const MomentSounds({this.defaultSound, this.byAnimation = const {}});

  factory MomentSounds.fromJson(Map<String, dynamic> json) {
    final raw = json['byAnimation'] as Map<String, dynamic>?;
    return MomentSounds(
      defaultSound: json['default'] as String?,
      byAnimation: raw == null
          ? const {}
          : raw.map((key, value) => MapEntry(key, value as String)),
    );
  }
}

/// Catalogue audio complet. [enabled] vaut `false` quand le fichier est
/// absent ou illisible : le jeu tourne alors en silence, sans erreur.
class AudioData {
  final int schemaVersion;
  final Map<String, SoundData> sounds;
  final Map<String, MomentSounds> moments;
  final Map<String, SoundData> music;
  final bool enabled;

  const AudioData({
    required this.schemaVersion,
    required this.sounds,
    required this.moments,
    required this.music,
    this.enabled = true,
  });

  const AudioData.disabled()
    : schemaVersion = 0,
      sounds = const {},
      moments = const {},
      music = const {},
      enabled = false;

  factory AudioData.fromJson(Map<String, dynamic> json) {
    Map<String, SoundData> readSounds(String key) {
      final raw = json[key] as Map<String, dynamic>?;
      if (raw == null) return const {};
      return raw.map(
        (id, value) =>
            MapEntry(id, SoundData.fromJson(value as Map<String, dynamic>)),
      );
    }

    final rawMoments = json['moments'] as Map<String, dynamic>?;

    return AudioData(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      sounds: readSounds('sounds'),
      music: readSounds('music'),
      moments: rawMoments == null
          ? const {}
          : rawMoments.map(
              (id, value) => MapEntry(
                id,
                MomentSounds.fromJson(value as Map<String, dynamic>),
              ),
            ),
    );
  }
}
