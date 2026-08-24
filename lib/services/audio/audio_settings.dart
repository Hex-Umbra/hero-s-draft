import 'package:flutter/foundation.dart';

/// Reglages audio du joueur. Immuable ; toute modification passe par
/// [copyWith] et produit un nouvel etat Riverpod.
@immutable
class AudioSettings {
  final double master;
  final double sfx;
  final double music;
  final bool muted;

  const AudioSettings({
    this.master = 0.8,
    this.sfx = 1.0,
    this.music = 0.6,
    this.muted = false,
  });

  /// Volume reellement applique aux bruitages : produit du general et de
  /// la categorie, ramene a zero par la coupure globale.
  double get effectiveSfx => muted ? 0.0 : master * sfx;

  double get effectiveMusic => muted ? 0.0 : master * music;

  AudioSettings copyWith({
    double? master,
    double? sfx,
    double? music,
    bool? muted,
  }) =>
      AudioSettings(
        master: master ?? this.master,
        sfx: sfx ?? this.sfx,
        music: music ?? this.music,
        muted: muted ?? this.muted,
      );

  Map<String, dynamic> toJson() => {
        'master': master,
        'sfx': sfx,
        'music': music,
        'muted': muted,
      };

  factory AudioSettings.fromJson(Map<String, dynamic> json) => AudioSettings(
        master: (json['master'] as num?)?.toDouble() ?? 0.8,
        sfx: (json['sfx'] as num?)?.toDouble() ?? 1.0,
        music: (json['music'] as num?)?.toDouble() ?? 0.6,
        muted: json['muted'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is AudioSettings &&
      other.master == master &&
      other.sfx == sfx &&
      other.music == music &&
      other.muted == muted;

  @override
  int get hashCode => Object.hash(master, sfx, music, muted);
}
