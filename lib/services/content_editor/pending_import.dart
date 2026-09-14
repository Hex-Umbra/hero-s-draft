import 'package:meta/meta.dart';

import 'entity_descriptor.dart';

/// Un fichier choisi par l'usager, en attente d'« Ecrire » (spec D12).
///
/// Rien n'est copie au moment du choix : l'import entre dans la meme
/// transaction que l'entite, et se defait avec elle.
@immutable
class PendingImport {
  const PendingImport({
    required this.key,
    required this.slot,
    required this.sourcePath,
    required this.destination,
    this.soundId,
  });

  /// Un son : copie sous `assets/audio/sfx/<soundId>.<extension>`, puis
  /// declare dans `audio.json`.
  factory PendingImport.sound({
    required String key,
    required String sourcePath,
    required String soundId,
  }) =>
      PendingImport(
        key: key,
        slot: const AssetSlot.sound(),
        sourcePath: sourcePath,
        destination: 'assets/audio/sfx/$soundId.${_extensionOf(sourcePath)}',
        soundId: soundId,
      );

  /// Une image : copiee sous le nom que l'emplacement impose.
  factory PendingImport.image({
    required EntityDescriptor descriptor,
    required String id,
    required String key,
    required String sourcePath,
  }) =>
      PendingImport(
        key: key,
        slot: descriptor.assetKeys[key]!,
        sourcePath: sourcePath,
        destination: descriptor.imagePathOf(id, key)!,
      );

  /// La cle de l'entite que l'import alimente : `sfx`, `spritePath`...
  final String key;
  final AssetSlot slot;

  /// Chemin absolu du fichier choisi, separe par `/`.
  final String sourcePath;

  /// Chemin de la copie, relatif a la racine du projet.
  final String destination;

  /// L'identifiant du son a declarer. `null` pour une image.
  final String? soundId;

  String get extension => _extensionOf(sourcePath);

  /// Le chemin qu'`audio.json` enregistre, relatif a `assets/audio/`.
  String get audioFile => destination.substring('assets/audio/'.length);

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    return dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
  }
}
