import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_backend.dart';
import 'silent_audio_backend.dart';

/// Vaut `SilentAudioBackend` par defaut, et c'est deliberé :
/// `main.dart` est le SEUL endroit qui le surcharge par le backend reel.
/// Le defaut inverse aurait impose de modifier 51 fichiers de test.
final audioBackendProvider = Provider<AudioBackend>(
  (ref) => const SilentAudioBackend(),
);
