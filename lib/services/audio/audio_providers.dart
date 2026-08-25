import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import '../../models/data/audio_data.dart';
import '../game_data_service.dart';
import 'audio_backend.dart';
import 'audio_director.dart';
import 'audio_settings.dart';
import 'silent_audio_backend.dart';
import '../settings_service.dart';

/// Vaut `SilentAudioBackend` par defaut, et c'est deliberé :
/// `main.dart` est le SEUL endroit qui le surcharge par le backend reel.
/// Le defaut inverse aurait impose de modifier 51 fichiers de test.
final audioBackendProvider = Provider<AudioBackend>(
  (ref) => const SilentAudioBackend(),
);

/// Le directeur depend du catalogue, donc du chargement asynchrone des
/// donnees. Tant que celui-ci n'a pas abouti, on rend un directeur sur
/// catalogue desactive : silencieux, jamais nul, jamais en erreur.
final audioDirectorProvider = Provider<AudioDirector>((ref) {
  final registry = ref.watch(gameDataLoaderProvider).valueOrNull;
  final director = AudioDirector(
    backend: ref.watch(audioBackendProvider),
    data: registry?.audio ?? const AudioData.disabled(),
    settings: () => ref.read(audioSettingsProvider),
  );
  unawaited(director.preloadAll());
  return director;
});

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
