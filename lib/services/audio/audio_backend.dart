/// Couche la plus basse du systeme audio : la seule qui parle a une
/// bibliotheque de lecture. Aucune implementation ne leve d'exception —
/// un fichier absent se signale par une valeur de retour, jamais par un throw.
abstract class AudioBackend {
  /// Charge [file] en cache. Retourne `false` si le fichier est absent
  /// ou illisible. Ne leve jamais.
  Future<bool> preload(String file);

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
