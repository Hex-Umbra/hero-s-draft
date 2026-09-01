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
  final conductor = MusicConductor(
    backend: ref.watch(audioBackendProvider),
    data: registry?.audio ?? const AudioData.disabled(),
    settings: () => ref.read(audioSettingsProvider),
    locked: kIsWeb,
  );
  unawaited(conductor.preloadAll());
  return conductor;
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

  /// Derniere valeur programmee pour l'ecriture, en attente du declenchement
  /// du debounce. Distinct de `state` : `state` peut deja avoir avance au
  /// prochain appel avant que ce train-ci n'ait ete ecrit (impossible en
  /// pratique avec un seul Timer partage, mais le champ garde le couple
  /// valeur/completer explicite plutot que de recapturer `state` au moment
  /// du flush).
  AudioSettings? _pendingValue;

  @override
  AudioSettings build() {
    // Un geste interrompu (ecran ferme, ou conteneur detruit pendant un
    // glisser) ne doit ni laisser un Timer en vie, ni perdre le dernier
    // reglage : on ecrit tout de suite ce qui restait en attente plutot que
    // de simplement annuler l'echeance.
    ref.onDispose(() {
      _debounceTimer?.cancel();
      // Sans ecriture en attente, `_flushPendingSave` ne fait rien (voir son
      // propre garde) : pas besoin de dupliquer ce test ici via `isActive`.
      _flushPendingSave();
    });
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
    _pendingValue = next;
    _saveCompleter ??= Completer<void>();
    _pendingSave = _saveCompleter!.future;
    _debounceTimer = Timer(debounceDelay, _flushPendingSave);
  }

  /// Ecrit immediatement la derniere valeur en attente et resout le
  /// `Completer` partage avec elle. Point unique appele soit par le `Timer`
  /// a l'echeance normale du debounce, soit par `onDispose` si le conteneur
  /// est detruit avant : dans les deux cas, la derniere valeur programmee
  /// doit finir sur le disque et `pendingSave` doit se resoudre, jamais
  /// rester en suspens.
  ///
  /// Idempotent : sans ecriture en attente (deja ecrite par un flush
  /// precedent, ou jamais programmee), ne fait rien — pas d'ecriture
  /// parasite. `SettingsService.save` avale deja ses propres erreurs et ne
  /// rejette jamais, donc le `Completer`, complete avec son `Future`, ne
  /// peut lui non plus jamais se resoudre en erreur.
  void _flushPendingSave() {
    _debounceTimer = null;
    final completer = _saveCompleter;
    final value = _pendingValue;
    if (completer == null || value == null) return;
    _saveCompleter = null;
    _pendingValue = null;
    completer.complete(SettingsService.save(value));
  }
}

final audioSettingsProvider =
    NotifierProvider<AudioSettingsNotifier, AudioSettings>(AudioSettingsNotifier.new);

/// Charge les reglages persistes une seule fois, au demarrage.
final audioSettingsHydrationProvider = FutureProvider<void>(
  (ref) => ref.read(audioSettingsProvider.notifier).hydrate(),
);
