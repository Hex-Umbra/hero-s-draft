import '../../models/data/audio_data.dart';
import 'audio_backend.dart';
import 'audio_settings.dart';
import 'music_scene.dart';

/// Traduit une scene en piste de fond, et rien d'autre.
///
/// Le fondu enchaine n'est pas ici : le conducteur decide *quelle* piste et
/// *si* elle change, le backend sait la faire entrer en douceur. Cette
/// frontiere garde le conducteur deterministe, donc testable sans timer.
class MusicConductor {
  MusicConductor({
    required AudioBackend backend,
    required AudioData data,
    required AudioSettings Function() settings,
    bool locked = false,
  })  : _backend = backend,
        _data = data,
        _settings = settings,
        _locked = locked;

  static const int _fadeMs = 400;

  final AudioBackend _backend;
  final AudioData _data;
  final AudioSettings Function() _settings;

  bool _locked;
  MusicScene? _pending;
  MusicScene? _current;

  MusicScene? get currentScene => _current;

  /// Idempotent : redemander la scene en cours ne fait rien. C'est ce qui
  /// rend sur de l'appeler depuis un `build()`, y compris au retour arriere.
  void onScene(MusicScene scene) {
    if (_locked) {
      _pending = scene;
      return;
    }
    if (scene == _current) return;
    if (!_data.enabled) return;

    final track = _data.music[scene.jsonKey];
    if (track == null) return; // Piste non declaree : la precedente continue.

    _current = scene;

    final volume = track.volume * _settings().effectiveMusic;
    if (volume <= 0) {
      _backend.stopLoop(fadeMs: _fadeMs);
      return;
    }
    _backend.playLoop(track.file, volume: volume, fadeMs: _fadeMs);
  }

  /// Appele au premier geste utilisateur sur le web, ou l'autoplay est bloque.
  void unlock() {
    if (!_locked) return;
    _locked = false;

    final pending = _pending;
    _pending = null;
    if (pending != null) onScene(pending);
  }

  /// A appeler quand les reglages changent : reapplique le volume, ou coupe.
  Future<void> refreshVolume() async {
    final scene = _current;
    if (scene == null) return;

    final track = _data.music[scene.jsonKey];
    if (track == null) return;

    final volume = track.volume * _settings().effectiveMusic;
    if (volume <= 0) {
      await _backend.stopLoop(fadeMs: _fadeMs);
      // Annuler _current ici (et pas dans onScene) est delibere : c'est ce
      // qui permet a la musique de reprendre apres une coupure. Sans ca, le
      // prochain onScene() pour cette meme scene resterait un no-op via
      // `scene == _current` et ne relancerait jamais la boucle.
      _current = null;
      return;
    }
    await _backend.playLoop(track.file, volume: volume, fadeMs: _fadeMs);
  }
}
