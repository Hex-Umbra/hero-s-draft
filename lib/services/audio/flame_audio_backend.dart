import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'audio_backend.dart';

/// Reservoir de lecteurs pre-armes pour UN fichier.
///
/// Existe pour rendre [FlameAudioBackend] testable sans canal de plateforme :
/// l'implementation reelle enveloppe un `AudioPool` d'`audioplayers`.
abstract class SfxPool {
  /// Demarre une lecture sur un lecteur deja arme. Ne doit rien allouer.
  Future<void> start(double volume);
}

/// Cree le reservoir de [file], ou `null` si le fichier est introuvable.
typedef SfxPoolFactory = Future<SfxPool?> Function(String file);

/// La SEULE classe du projet qui importe `flame_audio`.
///
/// Toutes les methodes avalent leurs erreurs : l'audio n'a pas le droit de
/// faire echouer le jeu. Les chemins sont relatifs a `assets/audio/`, le
/// prefixe par defaut de `FlameAudio.audioCache`.
///
/// **Les bruitages passent par un reservoir, jamais par `FlameAudio.play`.**
/// `FlameAudio.play` instancie un `AudioPlayer` natif neuf et enchaine quatre
/// allers-retours de canal de plateforme (`setAudioContext`, `setReleaseMode`,
/// `play`) avant le premier echantillon — d'ou une latence audible, et un
/// empilement des sons en survol rapide qui se vidait d'un coup une fois le
/// geste termine. `AudioPool` paie ce cout une fois, au prechargement :
/// [playOnce] ne fait plus que reserver un lecteur pret et le relancer.
class FlameAudioBackend implements AudioBackend {
  FlameAudioBackend({SfxPoolFactory? poolFactory})
      : _createPool = poolFactory ?? _createFlamePool;

  /// Lecteurs armes d'entree de jeu, par fichier. Un par bruitage : le
  /// reservoir en cree d'autres a la demande si un son se superpose a
  /// lui-meme, et en conserve jusqu'a [_poolMaxPlayers].
  static const int _poolMinPlayers = 1;

  /// Plafond de lecteurs *conserves* par fichier une fois liberes. Borne la
  /// consommation tout en absorbant les rafales — un survol rapide peut
  /// superposer deux ou trois `card_hover` de 84 ms.
  static const int _poolMaxPlayers = 4;

  final SfxPoolFactory _createPool;
  final Map<String, SfxPool> _pools = {};

  @override
  Future<bool> preload(String file) async {
    if (_pools.containsKey(file)) return true;
    final pool = await _createPool(file);
    if (pool == null) return false;
    _pools[file] = pool;
    return true;
  }

  @override
  void playOnce(String file, {double volume = 1.0}) {
    // Contrat de [AudioBackend.playOnce] : sans effet si le fichier n'a pas
    // ete precharge. Ici c'est litteral — pas de reservoir, pas de son, et
    // surtout aucune creation de lecteur sur le chemin de lecture.
    final pool = _pools[file];
    if (pool == null) return;
    try {
      // Fire-and-forget : le Future n'est jamais attendu. `ignore()` absorbe
      // silencieusement une erreur asynchrone (lecteur indisponible, fichier
      // corrompu...) — un bruitage rate ne doit laisser aucune trace, juste
      // le silence.
      pool.start(volume).ignore();
    } catch (_) {
      // Filet pour une eventuelle erreur synchrone avant le premier await.
    }
  }

  @override
  Future<void> playLoop(
    String file, {
    double volume = 1.0,
    int fadeMs = 0,
  }) async {
    // `fadeMs` est accepte mais pas encore honore : `FlameAudio.bgm`
    // n'expose aucun fondu enchaine natif, donc la transition est franche
    // dans cette version. Le parametre reste dans la signature pour que le
    // fondu puisse s'ajouter ici plus tard, sans toucher a `MusicConductor`
    // ni a son contrat.
    try {
      if (FlameAudio.bgm.isPlaying) {
        await FlameAudio.bgm.stop();
      }
      await FlameAudio.bgm.play(file, volume: volume);
    } catch (e) {
      debugPrint('[audio] echec de lecture de la boucle "$file" : $e');
    }
  }

  @override
  Future<void> stopLoop({int fadeMs = 0}) async {
    // Meme limitation que [playLoop] : `fadeMs` n'est pas honore, l'arret
    // est immediat.
    try {
      await FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('[audio] echec d\'arret de la boucle : $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      await FlameAudio.bgm.audioPlayer.setVolume(volume);
    } catch (e) {
      debugPrint('[audio] echec de reglage du volume de la boucle : $e');
    }
  }

  /// `createPool` monte les lecteurs et leur pose la source d'emblee, donc
  /// il charge aussi les octets en cache : il remplace entierement l'ancien
  /// `audioCache.load`. Un fichier absent le fait lever, d'ou le `null` qui
  /// signale l'echec sans rompre le contrat « ne leve jamais ».
  static Future<SfxPool?> _createFlamePool(String file) async {
    try {
      final pool = await FlameAudio.createPool(
        file,
        minPlayers: _poolMinPlayers,
        maxPlayers: _poolMaxPlayers,
      );
      return _FlameSfxPool(pool);
    } catch (_) {
      return null;
    }
  }
}

class _FlameSfxPool implements SfxPool {
  _FlameSfxPool(this._pool);

  final AudioPool _pool;

  @override
  Future<void> start(double volume) => _pool.start(volume: volume);
}
