import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/data/audio_data.dart';
import '../game_data_service.dart';
import 'audio_backend.dart';
import 'audio_director.dart';
import 'audio_settings.dart';
import 'music_conductor.dart';
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

/// Meme repli que [audioDirectorProvider] : catalogue desactive tant que le
/// chargement asynchrone n'a pas abouti. `locked: kIsWeb` car le web bloque
/// l'autoplay avant un geste utilisateur ; le deverrouillage est cable a la
/// tache 11.
final musicConductorProvider = Provider<MusicConductor>((ref) {
  final registry = ref.watch(gameDataLoaderProvider).valueOrNull;
  return MusicConductor(
    backend: ref.watch(audioBackendProvider),
    data: registry?.audio ?? const AudioData.disabled(),
    settings: () => ref.read(audioSettingsProvider),
    locked: kIsWeb,
  );
});

class AudioSettingsNotifier extends Notifier<AudioSettings> {
  /// Delai de regroupement avant l'ecriture disque.
  ///
  /// Un `Slider` de volume declenche `onChanged` a chaque frame du glisser —
  /// des dizaines d'appels par geste. Sans regroupement, chacun lancerait sa
  /// propre ecriture asynchrone vers `shared_preferences` ; et en cas
  /// d'echec d'ecriture soutenu, le `debugPrint` non deduplique de
  /// `SettingsService.save` tracerait une fois par frame. Le debounce
  /// resout les deux : une seule ecriture par geste, declenchee quand il se
  /// stabilise.
  @visibleForTesting
  static const Duration debounceDelay = Duration(milliseconds: 300);

  Timer? _debounceTimer;
  Completer<void>? _saveCompleter;

  @override
  AudioSettings build() {
    // Un geste interrompu (ecran ferme pendant un glisser) ne doit pas
    // laisser un Timer en vie apres la destruction du notifier.
    ref.onDispose(() => _debounceTimer?.cancel());
    return const AudioSettings();
  }

  /// L'ecriture disque lancee par le dernier reglage modifie.
  ///
  /// Les setters n'attendent pas l'ecriture — un curseur de volume ne doit
  /// pas se figer sur une I/O disque. Ce handle existe pour que les tests
  /// puissent attendre ce que la production laisse volontairement filer.
  /// Assigne de facon synchrone des le premier appel d'un train de mises a
  /// jour, pour qu'un appelant qui le lit immediatement apres un setter
  /// obtienne bien le futur qui aboutira a l'ecriture finale.
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
    // L'etat Riverpod se met a jour immediatement : c'est ce qui garde le
    // curseur reactif independamment du regroupement de l'ecriture.
    state = next;
    _scheduleSave(next);
  }

  /// Regroupe les ecritures rapprochees. Chaque appel annule l'echeance
  /// precedente et en repousse une nouvelle : seule la valeur du DERNIER
  /// appel du train sera ecrite, une seule fois, une fois le geste stabilise.
  void _scheduleSave(AudioSettings next) {
    _debounceTimer?.cancel();
    _saveCompleter ??= Completer<void>();
    _pendingSave = _saveCompleter!.future;
    _debounceTimer = Timer(debounceDelay, () {
      final completer = _saveCompleter!;
      _saveCompleter = null;
      completer.complete(SettingsService.save(next));
    });
  }
}

final audioSettingsProvider =
    NotifierProvider<AudioSettingsNotifier, AudioSettings>(AudioSettingsNotifier.new);

/// Charge les reglages persistes une seule fois, au demarrage.
final audioSettingsHydrationProvider = FutureProvider<void>(
  (ref) => ref.read(audioSettingsProvider.notifier).hydrate(),
);
