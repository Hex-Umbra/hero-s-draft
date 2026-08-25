import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'audio_backend.dart';

/// La SEULE classe du projet qui importe `flame_audio`.
///
/// Toutes les methodes avalent leurs erreurs : l'audio n'a pas le droit de
/// faire echouer le jeu. Les chemins sont relatifs a `assets/audio/`, le
/// prefixe par defaut de `FlameAudio.audioCache`.
class FlameAudioBackend implements AudioBackend {
  @override
  Future<bool> preload(String file) async {
    try {
      await FlameAudio.audioCache.load(file);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void playOnce(String file, {double volume = 1.0}) {
    try {
      // L'interface est synchrone (fire-and-forget) : le Future retourne
      // par `play` n'est jamais attendu. `ignore()` absorbe silencieusement
      // une eventuelle erreur asynchrone (fichier corrompu, decodeur
      // manquant...) sans la journaliser — un bruitage rate ne doit laisser
      // aucune trace, juste le silence.
      FlameAudio.play(file, volume: volume).ignore();
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
}
