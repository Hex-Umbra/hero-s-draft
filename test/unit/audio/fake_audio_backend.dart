import 'package:roguelike_card_game/services/audio/audio_backend.dart';

/// Backend d'observation : enregistre ce qu'on lui demande au lieu de le jouer.
/// Ajouter un fichier a [missingFiles] simule un asset absent du disque.
class FakeAudioBackend implements AudioBackend {
  final List<String> playedOnce = [];
  final List<double> playedVolumes = [];
  final Set<String> missingFiles = {};
  final List<String> preloadAttempts = [];
  String? currentLoop;
  double? currentLoopVolume;
  int loopStartCount = 0;

  @override
  Future<bool> preload(String file) async {
    preloadAttempts.add(file);
    return !missingFiles.contains(file);
  }

  @override
  void playOnce(String file, {double volume = 1.0}) {
    playedOnce.add(file);
    playedVolumes.add(volume);
  }

  @override
  Future<void> playLoop(String file, {double volume = 1.0, int fadeMs = 0}) async {
    currentLoop = file;
    currentLoopVolume = volume;
    loopStartCount++;
  }

  @override
  Future<void> stopLoop({int fadeMs = 0}) async {
    currentLoop = null;
    currentLoopVolume = null;
  }
}
