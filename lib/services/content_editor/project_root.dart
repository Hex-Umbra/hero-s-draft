import 'content_file_system.dart';

/// Trouve la racine de l'arborescence **source** du projet.
///
/// L'application tourne depuis `build/<plateforme>/.../runner/Debug/`, alors
/// que les donnees que l'editeur modifie vivent dans l'arborescence source. On
/// remonte donc depuis le repertoire de l'executable jusqu'au premier
/// repertoire portant a la fois `pubspec.yaml` et `assets/data/`.
///
/// **Deux marqueurs et non un** : `pubspec.yaml` seul se trouve aussi dans le
/// cache des paquets, ou l'on n'a rien a ecrire.
class ProjectRoot {
  const ProjectRoot._();

  /// Nombre maximal de niveaux remontes. Le chemin reel en compte cinq ou six ;
  /// la borne evite de balayer le volume entier quand la racine n'existe pas.
  static const int maxDepth = 12;

  /// La racine, ou `null` si l'application ne tourne pas depuis une
  /// arborescence source. L'editeur refuse alors de s'ouvrir : mieux vaut ne
  /// rien pouvoir faire que d'ecrire au hasard.
  static String? find(ContentFileSystem fs) =>
      findFrom(fs, fs.startDirectory);

  static String? findFrom(ContentFileSystem fs, String from) {
    var current = _trimTrailingSlash(from.replaceAll('\\', '/'));
    for (var level = 0; level < maxDepth; level++) {
      if (isProjectRoot(fs, current)) return current;
      final cut = current.lastIndexOf('/');
      if (cut <= 0) return null;
      current = current.substring(0, cut);
    }
    return null;
  }

  static bool isProjectRoot(ContentFileSystem fs, String directory) =>
      fs.fileExists('$directory/pubspec.yaml') &&
      fs.directoryExists('$directory/assets/data');

  static String _trimTrailingSlash(String path) =>
      path.length > 1 && path.endsWith('/')
          ? path.substring(0, path.length - 1)
          : path;
}
