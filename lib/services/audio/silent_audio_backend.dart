import 'audio_backend.dart';

/// Backend par defaut : se comporte comme si tout fonctionnait, sans
/// produire le moindre son. C'est ce qui rend `flutter test` muet sans
/// qu'aucun test existant n'ait a surcharger quoi que ce soit.
class SilentAudioBackend implements AudioBackend {
  const SilentAudioBackend();

  @override
  Future<bool> preload(String file) async => true;

  @override
  void playOnce(String file, {double volume = 1.0}) {}

  @override
  Future<void> playLoop(String file, {double volume = 1.0, int fadeMs = 0}) async {}

  @override
  Future<void> stopLoop({int fadeMs = 0}) async {}
}
