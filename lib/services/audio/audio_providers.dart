import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'audio_backend.dart';
import 'audio_settings.dart';
import 'silent_audio_backend.dart';
import '../settings_service.dart';

/// Vaut `SilentAudioBackend` par defaut, et c'est deliberé :
/// `main.dart` est le SEUL endroit qui le surcharge par le backend reel.
/// Le defaut inverse aurait impose de modifier 51 fichiers de test.
final audioBackendProvider = Provider<AudioBackend>(
  (ref) => const SilentAudioBackend(),
);

class AudioSettingsNotifier extends Notifier<AudioSettings> {
  @override
  AudioSettings build() => const AudioSettings();

  /// L'ecriture disque lancee par le dernier reglage modifie.
  ///
  /// Les setters n'attendent pas l'ecriture — un curseur de volume ne doit
  /// pas se figer sur une I/O disque. Ce handle existe pour que les tests
  /// puissent attendre ce que la production laisse volontairement filer.
  Future<void>? _pendingSave;

  @visibleForTesting
  Future<void>? get pendingSave => _pendingSave;

  /// Charge les reglages persistes. Appele une fois au demarrage.
  Future<void> hydrate() async {
    state = await SettingsService.load();
  }

  void setMaster(double value) => _update(state.copyWith(master: value));
  void setSfx(double value) => _update(state.copyWith(sfx: value));
  void setMusic(double value) => _update(state.copyWith(music: value));
  void toggleMute() => _update(state.copyWith(muted: !state.muted));

  void _update(AudioSettings next) {
    state = next;
    _pendingSave = SettingsService.save(next);
  }
}

final audioSettingsProvider =
    NotifierProvider<AudioSettingsNotifier, AudioSettings>(AudioSettingsNotifier.new);
