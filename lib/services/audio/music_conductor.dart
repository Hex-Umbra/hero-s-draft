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

  /// Scene a reprendre des que le volume effectif redevient positif : soit
  /// parce que le conducteur est verrouille (autoplay web), soit parce que
  /// la boucle est arretee par un volume nul (coupure, ou curseur a 0). Nul
  /// des qu'une boucle est reellement active pour `_current`.
  MusicScene? _pending;

  /// Non-nul si et seulement si le backend a une boucle active pour cette
  /// scene. C'est l'invariant qui rend `refreshVolume()` capable de choisir
  /// entre ajuster le volume en place et redemarrer : voir `_patterns/16-00`
  /// §16.6.
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
      // Stocker la scene dans _pending et annuler _current (au lieu de la
      // laisser pointer vers une boucle arretee) maintient l'invariant
      // ci-dessus meme quand c'est une navigation, pas refreshVolume(), qui
      // rencontre le volume nul (ecran ouvert pendant une coupure). Sans
      // cela, refreshVolume() croirait la boucle active et se contenterait
      // d'un setVolume() qui ne redemarre jamais rien.
      _pending = scene;
      _current = null;
      return;
    }
    _pending = null;
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
  ///
  /// Scene toujours active (`_current` non nul) : ajuste le volume en place
  /// via `setVolume`, sans redemarrer la piste depuis le debut. Scene
  /// arretee par un volume nul precedent (`_current` nul, `_pending` la
  /// retient) : redemarre en repassant par `onScene`, qui pose `_current` et
  /// relance la boucle puisque `scene != _current` (nul) est vrai. C'est ce
  /// second cas qui permet a la musique de reprendre apres une coupure
  /// **sans** attendre qu'un ecran rappelle `onScene()` depuis son
  /// `build()` — l'ecran de reglages, seul construit pour changer le
  /// volume, n'en a pas (`music_scene.dart` : sa scene est heritee).
  Future<void> refreshVolume() async {
    final scene = _current ?? _pending;
    if (scene == null) return;

    final track = _data.music[scene.jsonKey];
    if (track == null) return;

    final volume = track.volume * _settings().effectiveMusic;
    if (volume <= 0) {
      if (_current != null) {
        await _backend.stopLoop(fadeMs: _fadeMs);
        _pending = _current;
        _current = null;
      }
      return;
    }

    if (_current == null) {
      _pending = null;
      onScene(scene);
      return;
    }

    await _backend.setVolume(volume);
  }
}
