/// Couche la plus basse du systeme audio : la seule qui parle a une
/// bibliotheque de lecture. Aucune implementation ne leve d'exception —
/// un fichier absent se signale par une valeur de retour, jamais par un throw.
abstract class AudioBackend {
  /// Prepare [file] pour [playOnce] : monte les lecteurs et pose la source,
  /// de sorte que la lecture ne demande plus aucune allocation. Retourne
  /// `false` si le fichier est absent ou illisible. Ne leve jamais.
  Future<bool> preload(String file);

  /// Prepare [file] pour [playLoop] : charge seulement les octets, sans
  /// monter de lecteur.
  ///
  /// Distinct de [preload] parce que les deux chemins n'ont rien de commun :
  /// un bruitage se joue depuis un reservoir de lecteurs pre-armes, une
  /// musique depuis l'unique lecteur de fond. Monter un reservoir pour une
  /// piste de plusieurs minutes serait aussi inutile que couteux.
  ///
  /// Sert surtout de sonde : la valeur de retour dit si la piste existe, ce
  /// qui permet a l'appelant de ne jamais tenter l'impossible. Ne leve jamais.
  Future<bool> preloadMusic(String file);

  /// Joue [file] une fois. Sans effet si le fichier n'a pas ete precharge.
  void playOnce(String file, {double volume = 1.0});

  /// Demarre une boucle, en remplacant celle en cours s'il y en a une.
  /// [fadeMs] est la duree du fondu enchaine.
  Future<void> playLoop(String file, {double volume = 1.0, int fadeMs = 0});

  /// Arrete la boucle en cours. Sans effet s'il n'y en a pas.
  Future<void> stopLoop({int fadeMs = 0});

  /// Ajuste le volume de la boucle en cours, sans la redemarrer. Sans effet
  /// s'il n'y a pas de boucle active. Ne leve jamais.
  Future<void> setVolume(double volume);
}
